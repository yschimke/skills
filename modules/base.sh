
# ===========================================================================
#  module: base — install Nix (Determinate Systems installer, daemonless)
# ===========================================================================
register_module base
need_host install.determinate.systems   "Determinate Nix installer + binaries"
need_host cache.nixos.org                "Nix binary cache (substituter)"
need_host channels.nixos.org            "nixpkgs channel / flake source"
need_host github.com                     "nixpkgs + flake inputs"
need_host objects.githubusercontent.com  "GitHub release assets for flake inputs"

module_base() {
  if command -v nix >/dev/null 2>&1; then
    ok "Nix already installed: $(nix --version)"
  else
    log "Installing Nix (Determinate Systems installer, daemonless)..."
    # --init none: no systemd in most sandboxes. flakes: needed for nix#pkgs.
    curl -fsSL https://install.determinate.systems/nix \
      | sh -s -- install linux \
          --no-confirm \
          --init none \
          --extra-conf "experimental-features = nix-command flakes"
    ok "Nix installed."
  fi

  # Put nix on PATH for the rest of THIS script...
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
  command -v nix >/dev/null 2>&1 || die "Nix not on PATH after install."

  # ...and for future shells (a PATH prepend, not a frozen snapshot).
  echo 'export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"' \
    >> "$COOEE_PROFILE"
  [[ -n "${CLAUDE_ENV_FILE:-}" ]] && printf 'PATH=%s\n' "$PATH" >> "$CLAUDE_ENV_FILE" || true
  [[ -n "${GITHUB_ENV:-}"     ]] && printf 'PATH=%s\n' "$PATH" >> "$GITHUB_ENV"     || true

  ok "base ready: $(nix --version)"
}
