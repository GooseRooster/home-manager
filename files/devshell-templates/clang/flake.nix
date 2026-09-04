{
  # C/C++ dev shell — self-contained Nix devShell for C/C++ (+ CMake) projects.
  #
  # Provides:
  #   * clangd — via nixpkgs clang-tools, NOT nvim's mason. Mason's clangd is
  #     a prebuilt native binary that cannot run on NixOS; nvim's environment
  #     profile (files/nvim/lua/config/profile.lua) only ever expects this
  #     from PATH.
  #   * codelldb — the vscode-lldb standalone adapter exposing bin/codelldb
  #     on PATH (no top-level nixpkgs attr; the extension's passthru.adapter
  #     is the packaged standalone build). Same mason story; nvim's C/C++
  #     DAP locates it via PATH.
  #   * cmake + neocmakelsp — the cmake nvim feature's LSP; also environment-
  #     sourced for the same reason. (cmakelang/cmakelint formatters/linters
  #     are pip-based mason installs and keep working from mason.)
  #   * Toolchain: gcc/clang are expected from the host (gcc is on the home
  #     profile). Add a pinned clang from nixpkgs here if the project needs
  #     a specific compiler version.
  #   * ./.dev.local.sh sourced on shell entry if present — the per-developer
  #     personalization hook.
  #
  # Entry points:
  #   * direnv users:  `direnv allow`   (auto-activates via .envrc)
  #   * everyone else: `nix develop`
  description = "C/C++ dev shell";

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
          # Intentionally minimal — the nvim-relevant tooling only. Drop
          # cmake/neocmakelsp from `packages` (and `cmake` from .envrc's
          # NVIM_LANGS) if the project doesn't use CMake.
          packages = with pkgs; [
            clang-tools
            vscode-extensions.vadimcn.vscode-lldb.adapter
            cmake
            neocmakelsp
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
