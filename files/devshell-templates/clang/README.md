# clang — devshell template

Self-contained Nix devShell for C/C++ (and CMake) projects. Drop into a repo
via `devshell-init clang` (see `~/repos/home-manager` for the scaffolder).

## What ships

- **`clangd`** via nixpkgs `clang-tools` — nvim's LSP resolves it from PATH.
- **`codelldb`** via the `vscode-extensions.vadimcn.vscode-lldb` standalone
  adapter (no top-level nixpkgs attr) — nvim's C/C++ DAP resolves it from
  PATH.
- **`cmake` + `neocmakelsp`** — the cmake nvim feature's LSP, same
  environment-sourced treatment.
- **`.envrc`** with `use flake` plus `NVIM_LANGS=...,clang,cmake` so the nvim
  clangd/cmake extras load only inside this shell.
- **`./.dev.local.sh`** sourced if present — the per-developer hook.

The compiler itself comes from the host (gcc is on the home profile); add a
pinned `clang` in `flake.nix` if the project needs a specific version.

## Adoption checklist

After `devshell-init clang`:

1. Append to the target repo's `.gitignore`:
   ```
   /.dev.local.sh
   /.direnv/
   ```
2. Enter the shell: `direnv allow` or `nix develop`.
3. (Optional) add a `.dev.local.sh` for personal tools / env vars.
4. Verify nvim inside the shell: `:checkhealth vim.lsp` and
   `:lua print(vim.fn.exepath("clangd"))` should point at the devshell PATH.

## Why clangd/codelldb/neocmakelsp aren't installed by mason here

Mason ships prebuilt native binaries; on NixOS those can't run (no `/lib64`
loader — the stub-ld error). The nvim config therefore treats them as
environment-sourced tools everywhere (see
`files/nvim/lua/config/profile.lua` → `nix_substitutes`): the binary must be
on PATH (devshell or home profile), and mason is bypassed for it. On
non-NixOS machines mason remains the fallback when no PATH binary exists.
