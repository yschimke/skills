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

# ---- the script itself parses ---------------------------------------------

bash -n "$INSTALL_SH" 2>"$WORK/syntax.err"
check "install.sh parses" "0" "$?"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
