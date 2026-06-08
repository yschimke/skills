
# ===========================================================================
#  module: java
#    software : Temurin JDK 17 + 21 (via Nix), JAVA_HOME, JDK TLS fix
#    hosts    : cache.nixos.org (install)
#             : Gradle / Maven / toolchain registries (build, advisory)
#  Host set mirrors skills/compose-preview/references/agent-cloud.md.
# ===========================================================================
register_module java
need_host cache.nixos.org      "prebuilt Temurin JDK from the Nix cache"
want_host services.gradle.org  "Gradle distributions (wrapper download)"
want_host repo.gradle.org      "Gradle libraries / tooling artifacts"
want_host central.sonatype.com "Maven Central artifacts"
want_host api.foojay.io        "Java distro metadata for Gradle toolchains"
want_host api.adoptium.net     "JDK/toolchain provisioning API"
want_host jitpack.io           "dependencies published via JitPack"

module_java() {
  log "Installing Temurin JDK 17 + 21 via Nix..."
  nix_ensure temurin-bin-17 nixpkgs#temurin-bin-17 --accept-flake-config
  nix_ensure temurin-bin-21 nixpkgs#temurin-bin-21 --accept-flake-config

  # Default JAVA_HOME -> 17 (the toolchain most repos here pin to); 21 stays
  # on PATH for projects that opt into it.
  command -v java >/dev/null 2>&1 || die "java not on PATH after install."
  add_env JAVA_HOME "$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"

  # Cloud fix: a Nix JDK ignores the system trust store, so teach it about the
  # sandbox proxy CA now (otherwise Gradle HTTPS fails with PKIX errors).
  cooee_trust_cas_in_jdk "$JAVA_HOME"

  ok "java ready: $(java -version 2>&1 | head -1)"
}
