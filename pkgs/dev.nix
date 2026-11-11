# Cross-stack dev toolchains (home.bundles.dev — on for the WSL and
# silver-hour targets, off for the lean container). Lets a repo without a
# flake (a colleague's dotnet project, a random Rust clone) get LSP + DAP from
# the profile; a project devshell still wins, since `use flake` prepends its
# packages to PATH.
#
# These are the same tools the devshell templates (files/devshell-templates/)
# pin per project, and the binaries nvim's profile bundles expect on PATH
# (files/nvim/lua/config/profile.lua).
#
# Deliberate absences:
#   - rust-analyzer: `rustup` (pkgs/base.nix) already ships a rust-analyzer
#     proxy, so the nixpkgs package would collide in the profile. The
#     component is added by modules/dev-toolchains.nix instead, which also
#     keeps it matched to each project's rust-toolchain.toml.
#   - clang: collides with gcc's `cc`/`c++`. clang-tools carries clangd only.
{ pkgs }:

with pkgs;
[
  # .NET — SDK 10 plus 8 (LTS) so net8 projects can also run/test. roslyn-ls
  # and netcoredbg are built against the nixpkgs runtime (see the dotnet
  # template's flake.nix for why the bundled ones fail). The SDK set is
  # repeated in modules/dev-toolchains.nix (DOTNET_ROOT) — keep both in sync.
  (dotnetCorePackages.combinePackages [
    dotnetCorePackages.sdk_10_0
    dotnetCorePackages.sdk_8_0
  ])
  roslyn-ls
  netcoredbg
  dart-sass

  # Rust / C / C++
  vscode-extensions.vadimcn.vscode-lldb.adapter # codelldb
  clang-tools
  cmake
  neocmakelsp

  # TypeScript (cssls/html come from vscode-langservers-extracted in base)
  vtsls
]
