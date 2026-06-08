
# ===========================================================================
#  module: android
#    software : android-tools (adb/fastboot) via Nix, ANDROID_HOME
#    hosts    : cache.nixos.org (install)
#             : Google / JetBrains / fonts registries (build, advisory)
#  Host set mirrors skills/compose-preview/references/agent-cloud.md.
#  Assumes `java` is also requested (Android builds need a JDK).
# ===========================================================================
register_module android
need_host cache.nixos.org        "prebuilt android-tools from the Nix cache"
want_host dl.google.com          "Android SDK cmdline-tools, platforms, build-tools"
want_host maven.google.com       "AndroidX / AGP artifacts"
want_host packages.jetbrains.team "JetBrains-hosted Compose/tooling artifacts"
want_host "*.jetbrains.com"       "JetBrains downloads, plugins, Compose artifacts"
want_host fonts.googleapis.com   "downloadable font metadata (Compose)"
want_host fonts.gstatic.com      "downloadable font binaries (Compose)"

module_android() {
  log "Installing Android platform-tools (adb, fastboot) via Nix..."
  export NIXPKGS_ALLOW_UNFREE=1
  nix_ensure android-tools nixpkgs#android-tools --impure

  # The full SDK (platforms + build-tools) is licensed and large, and the
  # versions belong to the project, not this bootstrap. We only set a
  # conventional ANDROID_HOME; the repo's own androidenv flake fills it in.
  local sdk="${ANDROID_HOME:-$HOME/.android/sdk}"
  mkdir -p "$sdk"
  add_env ANDROID_HOME "$sdk"
  ok "android tools ready: $(adb --version 2>/dev/null | head -1 || echo 'adb installed')"
  warn "ANDROID_HOME=$sdk (platform-tools only); run the project's androidenv"
  warn "flake for platforms/build-tools (see scripts/env/README.md)."
}
