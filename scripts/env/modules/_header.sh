#!/usr/bin/env bash
# ===========================================================================
#  coo.ee/env — composable dev-environment bootstrapper   (SIMULATION)
# ---------------------------------------------------------------------------
#  This is the HEADER fragment. The hosted service concatenates:
#       _header.sh  +  <module>.sh ...  +  _footer.sh
#  to produce the script served at  https://coo.ee/env/<modules>.
#  The checked-in file  scripts/env/java,android  is one such rendering.
#  Edit fragments here; do not hand-edit the rendered artifact.
#  See scripts/env/README.md.
# ===========================================================================
set -euo pipefail

COOEE_VERSION="0.1.0-sim"

# ---- logging --------------------------------------------------------------
if [[ -t 2 ]]; then
  _c_red=$'\033[31m'; _c_yel=$'\033[33m'; _c_grn=$'\033[32m'
  _c_blu=$'\033[34m'; _c_rst=$'\033[0m'
else
  _c_red=; _c_yel=; _c_grn=; _c_blu=; _c_rst=
fi
log()  { printf '%s[coo.ee]%s %s\n'   "$_c_blu" "$_c_rst" "$*" >&2; }
ok()   { printf '%s[coo.ee] OK%s %s\n' "$_c_grn" "$_c_rst" "$*" >&2; }
warn() { printf '%s[coo.ee] !!%s %s\n' "$_c_yel" "$_c_rst" "$*" >&2; }
die()  { printf '%s[coo.ee] XX%s %s\n' "$_c_red" "$_c_rst" "$*" >&2; exit 1; }

# ---- persisted environment ------------------------------------------------
# Everything we export is also written to a profile file so a *new* shell can
# pick it up, and forwarded to the host harness env files when present
# (Claude Code SessionStart: $CLAUDE_ENV_FILE, GitHub Actions: $GITHUB_ENV).
COOEE_PROFILE="${COOEE_PROFILE:-$HOME/.config/coo-ee/env.sh}"
mkdir -p "$(dirname "$COOEE_PROFILE")"
: > "$COOEE_PROFILE"

add_env() {  # add_env KEY VALUE — export now and persist for later shells
  local key=$1 val=$2
  export "${key}=${val}"
  printf 'export %s=%q\n' "$key" "$val" >> "$COOEE_PROFILE"
  [[ -n "${CLAUDE_ENV_FILE:-}" ]] && printf '%s=%s\n' "$key" "$val" >> "$CLAUDE_ENV_FILE" || true
  [[ -n "${GITHUB_ENV:-}"     ]] && printf '%s=%s\n' "$key" "$val" >> "$GITHUB_ENV"     || true
}

# ---- idempotent nix package install ---------------------------------------
# Safe to run repeatedly: installs only what's missing, treats an already
# present package as success, so the whole script is a no-op on a warm box
# and a repair on a cold/partial one.
nix_ensure() {  # nix_ensure <match> <flakeref> [extra nix flags...]
  local match=$1; shift
  if nix profile list 2>/dev/null | grep -qiF -- "$match"; then
    ok "already present: $match"; return 0
  fi
  local out
  if out=$(nix profile install "$@" 2>&1); then
    ok "installed: $match"
  elif grep -qiF "already installed" <<<"$out"; then
    ok "already present: $match"
  else
    printf '%s\n' "$out" >&2
    return 1
  fi
}

# ---- cloud-specific fixes -------------------------------------------------
# Sandboxes (Claude Code, etc.) route HTTPS through a TLS-terminating proxy
# whose CA is trusted in the *system* store. A Nix-provided JDK ships its own
# read-only cacerts and ignores the system store, so Java/Gradle downloads die
# with "PKIX path building failed" right after the JDK lands. Fix: make a
# writable copy of the JDK truststore, import any extra/local CAs, and point
# Java at the copy. No-op on a laptop with no extra CAs.
cooee_extra_ca_files() {
  local f
  for f in /usr/local/share/ca-certificates/*.crt \
           /etc/pki/ca-trust/source/anchors/*.crt \
           "${NODE_EXTRA_CA_CERTS:-}" "${COOEE_EXTRA_CA:-}"; do
    [[ -n "$f" && -f "$f" ]] && printf '%s\n' "$f"
  done
}

cooee_trust_cas_in_jdk() {  # cooee_trust_cas_in_jdk <java_home>
  local java_home=$1
  command -v keytool >/dev/null 2>&1 || { warn "keytool missing; skipping JDK TLS fix."; return 0; }
  local src="$java_home/lib/security/cacerts"
  [[ -f "$src" ]] || { warn "no cacerts under $java_home; skipping JDK TLS fix."; return 0; }

  local -a extra
  mapfile -t extra < <(cooee_extra_ca_files | sort -u)
  if (( ${#extra[@]} == 0 )); then
    log "No extra/proxy CAs detected; JDK default truststore is fine."
    return 0
  fi

  local store="$HOME/.config/coo-ee/cacerts"
  install -m 0644 "$src" "$store"          # writable copy (Nix store path is read-only)
  local n=0 crt
  for crt in "${extra[@]}"; do
    n=$((n+1))
    if keytool -importcert -noprompt -trustcacerts \
         -keystore "$store" -storepass changeit \
         -alias "cooee-extra-$n" -file "$crt" >/dev/null 2>&1; then
      ok "trusted extra CA: $crt"
    else
      warn "could not import CA: $crt"
    fi
  done

  # Append, don't clobber, any JAVA_TOOL_OPTIONS already in the environment.
  local opts="-Djavax.net.ssl.trustStore=$store -Djavax.net.ssl.trustStorePassword=changeit"
  add_env JAVA_TOOL_OPTIONS "${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }$opts"
  ok "JDK now trusts ${#extra[@]} extra CA(s) via JAVA_TOOL_OPTIONS."
}

# ---- module + host registry ----------------------------------------------
# Modules register themselves (so _footer runs them in order) and declare the
# hosts they need, each with a human reason used in the remediation banner.
MODULES=()
declare -A _HOST_REASON=()   # required to INSTALL — probed, hard-fail if blocked
declare -A _WANT_REASON=()   # recommended for BUILDS — advisory only (may be wildcards)
register_module() { MODULES+=("$1"); }
need_host()       { _HOST_REASON["$1"]="$2"; }   # need_host <host> <reason>
want_host()       { _WANT_REASON["$1"]="$2"; }   # want_host <host|*.host> <reason>

# ---- preconditions: tools, OS, and host reachability ----------------------
probe_host() {
  # Reachable == we got *any* HTTP response (even 403/404). "000" == the
  # connection itself was blocked (DNS/proxy/TLS), which is the allowlist case.
  local host=$1 code
  code=$(curl -sS -o /dev/null -w '%{http_code}' \
           --connect-timeout 5 --max-time 12 "https://${host}/" 2>/dev/null) || true
  [[ -n "$code" && "$code" != "000" ]]
}

print_allowlist_help() {
  local missing=("$@") h
  {
    echo
    echo "${_c_yel}+- Network not configured -------------------------------------${_c_rst}"
    echo "${_c_yel}|${_c_rst} The sandbox cannot reach the hosts this install needs."
    echo "${_c_yel}|${_c_rst} Add these to your environment's allowed hosts:"
    echo "${_c_yel}|${_c_rst}"
    for h in "${missing[@]}"; do
      printf '%s|%s     %s   %s(%s)%s\n' \
        "$_c_yel" "$_c_rst" "$h" "$_c_yel" "${_HOST_REASON[$h]}" "$_c_rst"
    done
    echo "${_c_yel}|${_c_rst}"
    echo "${_c_yel}|${_c_rst} Where to set it:"
    echo "${_c_yel}|${_c_rst}   - Claude Code on the web: environment -> Network access ->"
    echo "${_c_yel}|${_c_rst}       Custom -> Allowed domains (keep the default package list)."
    echo "${_c_yel}|${_c_rst}   - OpenAI Codex: environment -> Internet access -> On ->"
    echo "${_c_yel}|${_c_rst}       add to the domain allowlist (allow GET/HEAD)."
    echo "${_c_yel}|${_c_rst}   - Antigravity / Gemini Managed Agents: declare the hosts"
    echo "${_c_yel}|${_c_rst}       in the sandbox network allowlist."
    echo "${_c_yel}+-------------------------------------------------------------${_c_rst}"
    echo
  } >&2
}

check_preconditions() {
  command -v curl >/dev/null 2>&1 || die "curl is required but not installed."
  [[ "$(uname -s)" == "Linux" ]] || warn "Designed for Linux sandboxes; $(uname -s) is untested."

  log "Checking ${#_HOST_REASON[@]} required host(s)..."
  local missing=() h
  for h in "${!_HOST_REASON[@]}"; do
    if probe_host "$h"; then ok "reachable  $h"
    else warn "BLOCKED    $h  (${_HOST_REASON[$h]})"; missing+=("$h"); fi
  done

  if (( ${#missing[@]} )); then
    print_allowlist_help "${missing[@]}"
    if [[ "${COOEE_IGNORE_HOST_CHECK:-0}" == "1" ]]; then
      warn "COOEE_IGNORE_HOST_CHECK=1 set — continuing despite blocked hosts."
    else
      die "${#missing[@]} required host(s) blocked. Fix the allowlist above, or re-run with COOEE_IGNORE_HOST_CHECK=1 to try anyway."
    fi
  else
    ok "All required hosts reachable."
  fi

  print_recommended_hosts   # advisory: build-time hosts, never fatal
}

# Build-time hosts (Gradle/Maven/Android registries, possibly wildcards) are
# not needed to install, so we don't probe them — we just remind you to allow
# them before the project actually builds.
print_recommended_hosts() {
  (( ${#_WANT_REASON[@]} )) || return 0
  local h
  {
    echo
    echo "${_c_blu}i Recommended for builds${_c_rst} — add these too if you'll build the project:"
    for h in "${!_WANT_REASON[@]}"; do
      printf '    %s   %s(%s)%s\n' "$h" "$_c_blu" "${_WANT_REASON[$h]}" "$_c_rst"
    done
    echo
  } >&2
}
