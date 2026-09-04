# rust — devshell template

Self-contained Nix devShell for Rust projects. Drop into a repo via
`devshell-init rust` (see `~/repos/home-manager` for the scaffolder).

## What ships

- **`rust-analyzer`** via nixpkgs — nvim's LSP resolves it from PATH.
- **`codelldb`** via the `vscode-extensions.vadimcn.vscode-lldb` standalone
  adapter (no top-level nixpkgs attr) — nvim's rust DAP resolves it from PATH.
- **`.envrc`** with `use flake` plus `NVIM_LANGS=...,rust` so the nvim rust
  extra (rustaceanvim, DAP, formatters) loads only inside this shell.
- **`./.dev.local.sh`** sourced if present — the per-developer hook.

Toolchain (rustc/cargo) is expected from the host's `rustup`; pin a project
toolchain (fenix / rust-bin) in `flake.nix` only if builds must be
bit-reproducible.

## Adoption checklist

After `devshell-init rust`:

1. Append to the target repo's `.gitignore`:
   ```
   /.dev.local.sh
   /.direnv/
   ```
2. Enter the shell: `direnv allow` or `nix develop`.
3. (Optional) add a `.dev.local.sh` for personal tools / env vars.
4. Verify nvim inside the shell: `:checkhealth vim.lsp` and
   `:lua print(vim.fn.exepath("rust-analyzer"))` should point at the
   devshell PATH.

## Why rust-analyzer/codelldb aren't installed by mason here

Mason ships prebuilt native binaries; on NixOS those can't run (no `/lib64`
loader — the stub-ld error). The nvim config therefore treats them as
environment-sourced tools everywhere (see
`files/nvim/lua/config/profile.lua` → `nix_substitutes`): the binary must be
on PATH (devshell or home profile), and mason is bypassed for it. On
non-NixOS machines mason remains the fallback when no PATH binary exists.
