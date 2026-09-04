{
  # Rust dev shell — self-contained Nix devShell for Rust projects.
  #
  # Provides:
  #   * rust-analyzer — from nixpkgs, NOT nvim's mason. Mason's rust-analyzer
  #     is a prebuilt native binary that cannot run on NixOS; nvim's
  #     environment profile (files/nvim/lua/config/profile.lua) only ever
  #     expects this from PATH.
  #   * codelldb — the vscode-lldb standalone adapter exposing bin/codelldb
  #     on PATH (no top-level nixpkgs attr; the extension's passthru.adapter
  #     is the packaged standalone build). Same mason story as above; nvim's
  #     rust DAP locates it via PATH.
  #   * Toolchain: rustc/cargo come from the host's rustup (home profile).
  #     Pin a project toolchain here (fenix / rust-bin) only if builds need
  #     to be bit-reproducible.
  #   * ./.dev.local.sh sourced on shell entry if present — the per-developer
  #     personalization hook.
  #
  # Entry points:
  #   * direnv users:  `direnv allow`   (auto-activates via .envrc)
  #   * everyone else: `nix develop`
  description = "Rust dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Intentionally minimal — the nvim-relevant tooling only. Add
          # project-specific tools (linkers, probe-rs, ...) as needed.
          packages = with pkgs; [
            rust-analyzer
            vscode-extensions.vadimcn.vscode-lldb.adapter
          ];

          shellHook = ''
            # ── Personal hook. Gitignored; teammates without one see nothing.
            #    Create .dev.local.sh to opt in.
            if [ -f ./.dev.local.sh ]; then
              # shellcheck source=/dev/null
              . ./.dev.local.sh
            fi
          '';
        };
      });
    };
}
