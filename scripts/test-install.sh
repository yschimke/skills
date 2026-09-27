#!/usr/bin/env bash
#
# Self-test for scripts/install.sh.
#
# install.sh is the bootstrap every cloud sandbox runs before anything else
# works, and its trickiest parts — "is a usable JDK already on disk?", "which
# sdkmanager packages are missing?" — are pure functions of the filesystem.
# This exercises those against fabricated JDK/SDK/project layouts so a
# regression shows up here instead of in a fresh session that can't build.
#
# No dependencies beyond bash + coreutils; nothing here touches the network.
#
# Usage: scripts/test-install.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SH="$SCRIPT_DIR/install.sh"
[[ -f "$INSTALL_SH" ]] || { echo "cannot find $INSTALL_SH" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# install.sh is a top-to-bottom script, not a library, so lift out just the
# function definitions (top-level `name() { … }`, including one-liners) and
# source those.
awk '
  {
    if (!infn && $0 ~ /^[a-z_][a-z0-9_]*\(\)[[:space:]]*\{/) {
      print
      if ($0 !~ /\}[[:space:]]*$/) infn = 1
      next
    }
    if (infn) {
      print
      if ($0 ~ /^\}$/) infn = 0
    }
  }
' "$INSTALL_SH" > "$WORK/functions.sh"
# shellcheck disable=SC1090
source "$WORK/functions.sh"

for fn in log die jdk_major_of find_installed_jdk install_openjdk_major \
          android_home_writable write_local_properties; do
  declare -F "$fn" >/dev/null \
    || { echo "extraction failed: $fn not defined" >&2; exit 1; }
done

pass=0
fail=0
check() { # check <name> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    echo "ok   - $1"
    pass=$((pass + 1))
  else
    echo "FAIL - $1"
    echo "         expected: [$2]"
    echo "         actual:   [$3]"
    fail=$((fail + 1))
  fi
}

# Fabricate a JDK: `release` file plus a `bin/java` that prints a plausible
# `-version` banner, so both detection paths can be exercised.
mk_jdk() { # mk_jdk <dir> <java-version>
  mkdir -p "$1/bin"
  printf '#!/bin/sh\necho "openjdk version \\"%s\\" 2026-01-01" >&2\n' "$2" > "$1/bin/java"
  chmod +x "$1/bin/java"
  printf 'JAVA_VERSION="%s"\n' "$2" > "$1/release"
}

JVMS="$WORK/jvm"
mk_jdk "$JVMS/temurin-17" "17.0.19"
mk_jdk "$JVMS/java-21-openjdk-amd64" "21.0.10"
mk_jdk "$JVMS/legacy-8" "1.8.0_402"
mk_jdk "$JVMS/no-release-17" "17.0.19"; rm "$JVMS/no-release-17/release"
mkdir -p "$JVMS/not-a-jdk"

# ---- jdk_major_of ---------------------------------------------------------

check "jdk_major_of reads the release file" \
  "17" "$(jdk_major_of "$JVMS/temurin-17")"
check "jdk_major_of reads the release file (21)" \
  "21" "$(jdk_major_of "$JVMS/java-21-openjdk-amd64")"
check "jdk_major_of maps legacy 1.8 to 8" \
  "8" "$(jdk_major_of "$JVMS/legacy-8")"
check "jdk_major_of falls back to java -version" \
  "17" "$(jdk_major_of "$JVMS/no-release-17")"
check "jdk_major_of rejects a directory that is not a JDK" \
  "" "$(jdk_major_of "$JVMS/not-a-jdk" || true)"
check "jdk_major_of rejects an empty path" \
  "" "$(jdk_major_of "" || true)"

# ---- find_installed_jdk ---------------------------------------------------
#
# The regression that motivated this: a Temurin 17 symlinked into
# /usr/lib/jvm by a tarball installer, with a *different* major on PATH. The
# old lookup only knew the apt layout, so it went to apt for a JDK that was
# already there — and a stale apt index turned that into a hard failure.

check "find_installed_jdk accepts a matching JAVA_HOME" \
  "$JVMS/temurin-17" "$(JAVA_HOME="$JVMS/temurin-17" find_installed_jdk 17 || true)"

wrong_major_result="$(JAVA_HOME="$JVMS/java-21-openjdk-amd64" find_installed_jdk 17 || true)"
check "find_installed_jdk never returns a JAVA_HOME of the wrong major" \
  "no" "$([[ "$wrong_major_result" == "$JVMS/java-21-openjdk-amd64" ]] && echo yes || echo no)"
if [[ -n "$wrong_major_result" ]]; then
  check "find_installed_jdk falls through to a genuine 17 instead" \
    "17" "$(jdk_major_of "$wrong_major_result")"
fi

# The remaining cases need the real search paths, so probe whatever this host
# actually has rather than fabricating /usr/lib/jvm entries.
host_17="$(JAVA_HOME="" find_installed_jdk 17 || true)"
if [[ -n "$host_17" ]]; then
  check "find_installed_jdk returns a real JDK 17 root, verified" \
    "17" "$(jdk_major_of "$host_17")"
else
  echo "skip - no JDK 17 on this host to verify find_installed_jdk against"
fi
check "find_installed_jdk reports nothing for an implausible major" \
  "" "$(JAVA_HOME="" find_installed_jdk 3 || true)"

# ---- install_openjdk_major ------------------------------------------------
#
# When a JDK is already on disk it must not shell out to apt at all, and it
# must return *only* the path — `log` output on stdout would be captured into
# JAVA_HOME by the caller's command substitution.

FAKEBIN="$WORK/bin"
mkdir -p "$FAKEBIN"
printf '#!/bin/sh\necho "apt-get invoked: $*" >&2\nexit 1\n' > "$FAKEBIN/apt-get"
chmod +x "$FAKEBIN/apt-get"

if [[ -n "$host_17" ]]; then
  apt_log="$WORK/apt.log"
  captured="$(PATH="$FAKEBIN:$PATH" JAVA_HOME="" install_openjdk_major 17 2>"$apt_log")"
  check "install_openjdk_major returns the bare path, no log noise" \
    "$host_17" "$captured"
  check "install_openjdk_major does not reach apt when a JDK is on disk" \
    "0" "$(grep -c 'apt-get invoked' "$apt_log")"
else
  echo "skip - no JDK 17 on this host to exercise install_openjdk_major"
fi

# ---- android_home_writable ------------------------------------------------

check "android_home_writable: existing writable directory" \
  "yes" "$(ANDROID_HOME="$WORK" android_home_writable && echo yes || echo no)"
check "android_home_writable: leaf not yet created under a writable parent" \
  "yes" "$(ANDROID_HOME="$WORK/not/created/yet" android_home_writable && echo yes || echo no)"
# Walking up must terminate at / rather than spinning on dirname("/").
check "android_home_writable: terminates on a path with no existing ancestor" \
  "0" "$(ANDROID_HOME="/nonexistent-$$/a/b/c" timeout 5 bash -c \
        'source "$0"; ANDROID_HOME="$1" android_home_writable; exit 0' \
        "$WORK/functions.sh" "/nonexistent-$$/a/b/c" >/dev/null 2>&1; echo $?)"

# ---- sdkmanager package -> directory mapping ------------------------------
#
# The idempotency check in install_android_sdk relies on package coordinates
# mapping onto directories by swapping ';' for '/'.

pkg_dir() { printf '%s\n' "${1//;//}"; }
check "package path: platforms;android-36"   "platforms/android-36"   "$(pkg_dir 'platforms;android-36')"
check "package path: platforms;android-37.0" "platforms/android-37.0" "$(pkg_dir 'platforms;android-37.0')"
check "package path: build-tools;36.0.0"     "build-tools/36.0.0"     "$(pkg_dir 'build-tools;36.0.0')"
check "package path: platform-tools"         "platform-tools"         "$(pkg_dir 'platform-tools')"

check "default required packages still name android-36" \
  "1" "$(grep -c 'ANDROID_SDK_PACKAGES:-platforms;android-36 platform-tools build-tools;36.0.0' "$INSTALL_SH")"
check "default extras name android-37.0, never android-37" \
  "1" "$(grep -c 'ANDROID_SDK_EXTRA_PACKAGES-platforms;android-37.0' "$INSTALL_SH")"

# ---- write_local_properties -----------------------------------------------

proj_a="$WORK/proj-a"; mkdir -p "$proj_a"; touch "$proj_a/settings.gradle.kts"
( cd "$proj_a" && ANDROID_HOME=/opt/android-sdk write_local_properties >/dev/null 2>&1 )
check "write_local_properties records sdk.dir" \
  "sdk.dir=/opt/android-sdk" "$(cat "$proj_a/local.properties")"

( cd "$proj_a" && ANDROID_HOME=/somewhere/else write_local_properties >/dev/null 2>&1 )
check "write_local_properties never overwrites an existing sdk.dir" \
  "sdk.dir=/opt/android-sdk" "$(cat "$proj_a/local.properties")"

proj_b="$WORK/proj-b"; mkdir -p "$proj_b"; touch "$proj_b/settings.gradle"
printf 'foo=bar' > "$proj_b/local.properties"   # deliberately no trailing newline
( cd "$proj_b" && ANDROID_HOME=/opt/android-sdk write_local_properties >/dev/null 2>&1 )
check "write_local_properties does not glue onto an unterminated last line" \
  "foo=bar
sdk.dir=/opt/android-sdk" "$(cat "$proj_b/local.properties")"

proj_c="$WORK/proj-c"; mkdir -p "$proj_c"   # no settings.gradle* — not a Gradle root
( cd "$proj_c" && ANDROID_HOME=/opt/android-sdk write_local_properties >/dev/null 2>&1 )
check "write_local_properties leaves a non-Gradle directory alone" \
  "" "$(ls -A "$proj_c")"

# ---- release discovery ----------------------------------------------------
#
# Both of these are network-shaped, so `curl` is replaced by a stub that records
# how it was called and replays canned bodies. Nothing here touches the network.

REPO="yschimke/compose-ai-tools"
MAX_RELEASE_CANDIDATES=5
CURL_LOG="$WORK/curl.log"
: >"$CURL_LOG"

# Stands in for curl. CURL_MODE decides which sources answer.
curl() {
  printf '%s\n' "$*" >>"$CURL_LOG"
  local url="${*: -1}"
  case "$url" in
    *releases.atom*)
      [[ "${CURL_MODE:-ok}" == "ok" ]] || return 22
      cat <<'ATOM'
<entry><link href="https://github.com/yschimke/compose-ai-tools/releases/tag/v0.19.61"/></entry>
<entry><link href="https://github.com/yschimke/compose-ai-tools/releases/tag/clients-v0.2.0"/></entry>
<entry><link href="https://github.com/yschimke/compose-ai-tools/releases/tag/v0.19.60"/></entry>
<entry><link href="https://github.com/yschimke/compose-ai-tools/releases/tag/v0.19.60"/></entry>
ATOM
      ;;
    *api.github.com*)
      [[ "${CURL_MODE:-ok}" == "all-blocked" ]] && return 22
      cat <<'JSON'
[{"tag_name": "v0.19.61", "draft": false},
 {"tag_name": "clients-v0.2.0", "draft": false},
 {"tag_name": "v0.19.60", "draft": false}]
JSON
      ;;
    *) return 22 ;;
  esac
}

check "candidate_versions reads the atom feed, newest first, CLI tags only" \
  "0.19.61
0.19.60" "$(CURL_MODE=ok candidate_versions 2>/dev/null)"

# The reported sandbox failure: the agent proxy 403s releases.atom because it is
# not a repository-scoped GitHub API path, while /repos/<owner>/<repo>/releases
# is allowed. This used to `die` and end the install.
check "candidate_versions falls back to the repo-scoped API when the feed is blocked" \
  "0.19.61
0.19.60" "$(CURL_MODE=atom-blocked candidate_versions 2>/dev/null)"

check "candidate_versions reports failure when neither source is reachable" \
  "1" "$(CURL_MODE=all-blocked candidate_versions >/dev/null 2>&1; echo $?)"

# GitHub signs release-asset redirects for GET only, so a HEAD comes back 401 on
# an asset that downloads fine — which made every release look unready.
: >"$CURL_LOG"
url_is_downloadable "https://example.test/asset.tar.gz" >/dev/null 2>&1 || true
check "url_is_downloadable probes with a ranged GET, not a HEAD" \
  "yes" "$(grep -q -- '-r 0-0' "$CURL_LOG" && ! grep -q -- 'fsIL' "$CURL_LOG" && echo yes)"

unset -f curl

# ---- ensure_bin_on_path / prune_old_cli_versions -------------------------
#
# `compose-preview update` re-runs install.sh; when the CLI was already current
# it exited before the PATH hint, so ~/.local/bin never reached PATH. The fix
# writes a marked block to each shell's startup file, exactly once.

PATH_MARKER="$(grep -m1 '^PATH_MARKER=' "$INSTALL_SH" | sed 's/^PATH_MARKER="//; s/"$//')"
FAKE_HOME="$WORK/home"
mkdir -p "$FAKE_HOME/.config/fish"
: >"$FAKE_HOME/.bashrc"
: >"$FAKE_HOME/.bash_profile"
: >"$FAKE_HOME/.zshrc"
run_path_setup() {
  HOME="$FAKE_HOME" XDG_CONFIG_HOME="$FAKE_HOME/.config" ZDOTDIR="$FAKE_HOME" \
    BIN_DIR="$FAKE_HOME/.local/bin" MODIFY_PATH="${1:-1}" CLAUDE_CLOUD="${2:-0}" \
    PATH="/usr/bin:/bin" ensure_bin_on_path 2>/dev/null
}
run_path_setup
run_path_setup
check "PATH block lands in .bashrc exactly once" \
  "1" "$(grep -c 'compose-preview: put the CLI on PATH' "$FAKE_HOME/.bashrc")"
check "PATH block lands in .bash_profile exactly once" \
  "1" "$(grep -c 'compose-preview: put the CLI on PATH' "$FAKE_HOME/.bash_profile")"
check "PATH block lands in .zshrc exactly once" \
  "1" "$(grep -c 'compose-preview: put the CLI on PATH' "$FAKE_HOME/.zshrc")"
check "PATH block is written relative to \$HOME" \
  "yes" "$(grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$FAKE_HOME/.bashrc" && echo yes)"
check "fish gets its own conf.d file" \
  "yes" "$(grep -Fq 'set -gx PATH "$HOME/.local/bin" $PATH' "$FAKE_HOME/.config/fish/conf.d/compose-preview.fish" && echo yes)"
check "the bash block really puts the dir on PATH" \
  "yes" "$(HOME="$FAKE_HOME" PATH=/usr/bin:/bin bash --norc --noprofile -c ". '$FAKE_HOME/.bashrc'; case :\$PATH: in *:$FAKE_HOME/.local/bin:*) echo yes;; esac")"
check "the bash block doesn't duplicate an existing PATH entry" \
  "1" "$(HOME="$FAKE_HOME" PATH="$FAKE_HOME/.local/bin:/usr/bin" bash --norc --noprofile -c ". '$FAKE_HOME/.bashrc'; echo \$PATH" | tr ':' '\n' | grep -c "^$FAKE_HOME/.local/bin$")"
if command -v fish >/dev/null 2>&1; then
  check "the fish file really puts the dir on PATH" \
    "yes" "$(HOME="$FAKE_HOME" fish --no-config -c "source '$FAKE_HOME/.config/fish/conf.d/compose-preview.fish'; contains -- '$FAKE_HOME/.local/bin' \$PATH; and echo yes")"
fi

OPT_OUT_HOME="$WORK/home-optout"; mkdir -p "$OPT_OUT_HOME"; : >"$OPT_OUT_HOME/.bashrc"
HOME="$OPT_OUT_HOME" BIN_DIR="$OPT_OUT_HOME/.local/bin" MODIFY_PATH=0 CLAUDE_CLOUD=0 \
  ensure_bin_on_path 2>/dev/null
check "--no-modify-path leaves startup files alone" "0" "$(wc -c <"$OPT_OUT_HOME/.bashrc" | tr -d ' ')"
HOME="$OPT_OUT_HOME" BIN_DIR="$OPT_OUT_HOME/.local/bin" MODIFY_PATH=1 CLAUDE_CLOUD=1 \
  ensure_bin_on_path 2>/dev/null
check "cloud sandboxes leave startup files alone" "0" "$(wc -c <"$OPT_OUT_HOME/.bashrc" | tr -d ' ')"

CLI_DEST="$WORK/cli"
mkdir -p "$CLI_DEST/compose-preview-2.7.0/bin" "$CLI_DEST/compose-preview-2.28.0/bin" "$CLI_DEST/other"
CLI_DEST="$CLI_DEST" VERSION=2.28.0 prune_old_cli_versions 2>/dev/null
check "prune_old_cli_versions keeps only the current CLI" \
  "compose-preview-2.28.0 other" "$(ls "$CLI_DEST" | tr '\n' ' ' | sed 's/ $//')"

# ---- wanted_companion_skills ----------------------------------------------
eval "$(sed -n '/^COMPANION_SKILLS=(/,/^)/p; /^DEFAULT_COMPANION_SKILLS=(/,/^)/p' "$INSTALL_SH")"
WS_ROOT="$WORK/ws"; mkdir -p "$WS_ROOT/compose-preview"
ws() { SKILL_DIR="$WS_ROOT/compose-preview" wanted_companion_skills | paste -sd' ' -; }
check "default companion set is compose-ui-builder only" \
  "compose-ui-builder" "$(ALL_SKILLS=0 SKILLS_REQUESTED= ws)"
check "--skills adds to the default set" \
  "compose-preview-review compose-preview-ci compose-ui-builder" "$(ALL_SKILLS=0 SKILLS_REQUESTED=compose-preview-ci,compose-preview-review ws)"
check "--all-skills installs every companion" \
  "${COMPANION_SKILLS[*]}" "$(ALL_SKILLS=1 SKILLS_REQUESTED= ws)"
mkdir -p "$WS_ROOT/figma-catalog-import"; echo abc >"$WS_ROOT/figma-catalog-import/.skill-version"
check "previously installed companions keep updating" \
  "compose-ui-builder figma-catalog-import" "$(ALL_SKILLS=0 SKILLS_REQUESTED= ws)"
check "an unknown --skills name is rejected" \
  "1" "$(bash "$INSTALL_SH" --skills nope --cli-only >/dev/null 2>&1; echo $?)"
# ---- skills_managed_elsewhere ---------------------------------------------
#
# An npx or plugin install has SKILL.md but no `.skill-version` (only this
# installer writes it), so `compose-preview update` must leave that content alone.
NPX_SKILL="$WORK/npx/compose-preview"; mkdir -p "$NPX_SKILL"; : >"$NPX_SKILL/SKILL.md"
check "npx-installed skill content is managed elsewhere" \
  "yes" "$(SKILL_DIR="$NPX_SKILL" skills_managed_elsewhere && echo yes || echo no)"
OURS_SKILL="$WORK/ours/compose-preview"; mkdir -p "$OURS_SKILL"; : >"$OURS_SKILL/SKILL.md"; echo abc >"$OURS_SKILL/.skill-version"
check "installer-owned skill content is refreshed" \
  "no" "$(SKILL_DIR="$OURS_SKILL" skills_managed_elsewhere && echo yes || echo no)"
check "a fresh machine is not managed elsewhere" \
  "no" "$(SKILL_DIR="$WORK/none/compose-preview" skills_managed_elsewhere && echo yes || echo no)"

# ---- resolve_cli_home ------------------------------------------------------
# npx replaces the whole skill folder on update, so the CLI must not live there.
CH_HOME="$WORK/chhome"; mkdir -p "$CH_HOME"
check "npx-managed skills put the CLI in the data dir" \
  "$CH_HOME/.local/share/compose-preview" \
  "$(HOME="$CH_HOME" XDG_DATA_HOME= COMPOSE_PREVIEW_HOME= SKILL_DIR="$NPX_SKILL" resolve_cli_home)"
check "XDG_DATA_HOME is honoured" \
  "$CH_HOME/xdg/compose-preview" \
  "$(HOME="$CH_HOME" XDG_DATA_HOME="$CH_HOME/xdg" COMPOSE_PREVIEW_HOME= SKILL_DIR="$NPX_SKILL" resolve_cli_home)"
check "installer-owned skills keep the CLI in the skill dir" \
  "$OURS_SKILL" "$(SKILL_DIR="$OURS_SKILL" resolve_cli_home)"
check "a fresh machine keeps the CLI in the skill dir" \
  "$WORK/none/compose-preview" "$(SKILL_DIR="$WORK/none/compose-preview" resolve_cli_home)"

# installed_repo_skills names only the repo's skills the user actually has.
eval "$(sed -n '/^COMPANION_SKILLS=(/,/^)/p' "$INSTALL_SH")"
ROOT_SK="$WORK/root"; mkdir -p "$ROOT_SK/compose-preview" "$ROOT_SK/compose-preview-ci" "$ROOT_SK/someone-else"
: >"$ROOT_SK/compose-preview/SKILL.md"; : >"$ROOT_SK/compose-preview-ci/SKILL.md"; : >"$ROOT_SK/someone-else/SKILL.md"
check "installed_repo_skills lists only kept repo skills" \
  "compose-preview compose-preview-ci" "$(SKILL_DIR="$ROOT_SK/compose-preview" installed_repo_skills | paste -sd' ')"
check "update_skills_via_npx is a no-op for curl installs" \
  "" "$(SKILLS_VIA_NPX=0 SKILL_DIR="$ROOT_SK/compose-preview" update_skills_via_npx 2>&1)"

FAKE_NPX_BIN="$WORK/npxbin"; mkdir -p "$FAKE_NPX_BIN"
printf '#!/bin/sh\necho "$*" >"%s/npx.args"\n' "$WORK" >"$FAKE_NPX_BIN/npx"; chmod +x "$FAKE_NPX_BIN/npx"
PATH="$FAKE_NPX_BIN:$PATH" SKILLS_VIA_NPX=1 SKILL_DIR="$ROOT_SK/compose-preview" update_skills_via_npx 2>/dev/null
check "update_skills_via_npx updates the kept skills globally" \
  "-y skills update -g -y compose-preview compose-preview-ci" "$(cat "$WORK/npx.args")"

# No npx, or npx fails: fall back to refreshing the same folders in place.
# Run in subshells so the install_skills_bundle stub doesn't leak.
NO_NPX_BIN="$WORK/nonpx"; mkdir -p "$NO_NPX_BIN"
for tool in bash sh cat paste dirname; do ln -sf "$(command -v $tool)" "$NO_NPX_BIN/$tool"; done
check "without npx, skills are refreshed in place" \
  "--in-place compose-preview compose-preview-ci" \
  "$( install_skills_bundle() { echo "$*"; }
      PATH="$NO_NPX_BIN" SKILLS_VIA_NPX=1 SKILL_DIR="$ROOT_SK/compose-preview" update_skills_via_npx 2>/dev/null )"
FAIL_NPX_BIN="$WORK/failnpx"; mkdir -p "$FAIL_NPX_BIN"
printf '#!/bin/sh\nexit 1\n' >"$FAIL_NPX_BIN/npx"; chmod +x "$FAIL_NPX_BIN/npx"
check "a failed npx update falls back to refreshing in place" \
  "--in-place compose-preview compose-preview-ci" \
  "$( install_skills_bundle() { echo "$*"; }
      PATH="$FAIL_NPX_BIN:$PATH" SKILLS_VIA_NPX=1 SKILL_DIR="$ROOT_SK/compose-preview" update_skills_via_npx 2>/dev/null )"

# The in-place refresh copies the named skills and writes no marker.
IP_SRC="$WORK/ipsrc/skills-main/skills"
mkdir -p "$IP_SRC/compose-preview" "$IP_SRC/compose-preview-ci" "$IP_SRC/compose-ui-builder"
for n in compose-preview compose-preview-ci compose-ui-builder; do echo new >"$IP_SRC/$n/SKILL.md"; done
tar -czf "$WORK/ip.tar.gz" -C "$WORK/ipsrc" skills-main
IP_ROOT="$WORK/iproot"; mkdir -p "$IP_ROOT/compose-preview" "$IP_ROOT/compose-preview-ci"
echo old >"$IP_ROOT/compose-preview/SKILL.md"; echo old >"$IP_ROOT/compose-preview-ci/SKILL.md"
(
  TMP="$WORK/iptmp"; mkdir -p "$TMP"; SKILLS_REPO=yschimke/skills SKILLS_REF=main
  resolve_skills_sha() { echo abc123; }
  curl() { while [[ $# -gt 0 ]]; do [[ "$1" == -o ]] && { cp "$WORK/ip.tar.gz" "$2"; return 0; }; shift; done; }
  SKILL_DIR="$IP_ROOT/compose-preview" install_skills_bundle --in-place compose-preview compose-preview-ci 2>/dev/null
)
check "in-place refresh updates the named skills" \
  "new new" "$(cat "$IP_ROOT/compose-preview/SKILL.md" "$IP_ROOT/compose-preview-ci/SKILL.md" | paste -sd' ' -)"
check "in-place refresh adds no other skills and writes no marker" \
  "compose-preview compose-preview-ci|" \
  "$(ls "$IP_ROOT" | paste -sd' ' -)|$(ls "$IP_ROOT"/*/.skill-version 2>/dev/null)"

# ---- the script itself parses ---------------------------------------------

bash -n "$INSTALL_SH" 2>"$WORK/syntax.err"
check "install.sh parses" "0" "$?"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
