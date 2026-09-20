# home-manager

Home dotfiles, declaratively managed with [Home Manager](https://github.com/nix-community/home-manager).

## Where things live

```
nixos-config    NixOS system declarations (desktop + NixOS-in-WSL)
home-manager    ← this repo: home dotfiles + CLI "batteries" (package bundles)
```

- This repo owns both *config* and the *binaries* (nushell, neovim, yazi,
  tealdeer, fzf, …). Packages are selected per host via
  `home.bundles.*` (see `modules/bundles.nix`):

  | Bundle | Contents | Default |
  |--------|----------|---------|
  | `base` | devcontainer-safe CLI tooling (`pkgs/base.nix`) | on for every target |
  | `baseExtra` | visual/GUI extras — fonts, VS Code (`pkgs/base-extra.nix`) | off |
  | `wsl` | WSL dev-host extras (`pkgs/wsl.nix`) | off |

  The `programs.<tool>` HM modules and the bundle lists share one nixpkgs
  instance, so overlapping entries (e.g. yazi) dedupe to identical store paths.
  Also owns reusable **Nix devShell templates** (see
  [Devshell templates](#devshell-templates)) for scaffolding project-local dev
  environments.
- **Dev toolchains** (dotnet, java, rust, node, …) belong in project-local
  `nix develop` environments — never installed here directly. The devshell
  templates provide the seed configs for those.

One exception to "HM owns the binary": `programs.ghostty` keeps
`package = null` — not for a collision reason, but because the system-wide
ghostty package (nixos-config's `modules/desktop/terminal.nix`) owns the
user units, and `null` also disables HM's onChange `+validate-config` hook
(which would need a real binary to exec at activation).

## Targets / flavors

Each target enables a set of feature flags (`home.modules.*`), which modules
use with `lib.mkIf`/`lib.optionalString` to include or omit files.

| Target | Use | Flags on |
|--------|-----|----------|
| `container` | lean dev container (standalone) | `bundles.base` (default), `defaultShell: zsh` |
| `wsl` | foreign-WSL dev host (standalone) | `bundles.wsl`, `wsl`, `podmanAlias`, `defaultShell: zsh` |

The NixOS hosts (desktop + NixOS-WSL) are not built here: they consume
`hmModules.default` through `nixos-config`'s
`home-manager.users.<name>.imports` and set the `home.modules.*` flags
themselves — one source of truth per host, nothing mirrored between repos
(see [NixOS integration](#nixos-integration-recommended)).

Flags: `gaming`, `theming`, `session`, `podmanAlias`, `wsl`,
`defaultShell` (`nu` | `zsh`; drives ghostty's `command`, the WSL bash
hand-off and nixos-config's `termapp` together — see `modules/flavors.nix`)
plus the `bundles`
switches (see
`modules/bundles.nix`). `wsl` skips GUI-only dotfiles (ghostty, mpv, tinty,
owl.jpg) 

## Applying

Standalone (any distro with Nix — foreign systems included):

```sh
# Lean dev container: base batteries + dotfiles.
home-manager switch --flake github:GooseRooster/home-manager#container --impure

# Foreign-WSL dev host: base + wsl extras + dotfiles.
home-manager switch --flake github:GooseRooster/home-manager#wsl --impure
```

Both standalone targets use `--impure` because their `hosts/*.nix` read
`$USER`/`$HOME` at eval time — the uid-1000 user's name varies by distro/image
(NixOS-WSL `nixos`, Ubuntu-WSL `ubuntu`, …), so it can't be hardcoded.

From a local checkout:

```sh
home-manager switch --flake .#wsl --impure
```

First-time bootstrap on a foreign system without `home-manager` on PATH yet
(fetches HM itself via `nix run`, then subsequent switches use the HM binary
installed into the user profile):

```sh
nix run github:nix-community/home-manager/master -- \
  switch --flake github:GooseRooster/home-manager#container --impure
```

On NixOS, prefer wiring it through `nixos-config` (see below) so `nixos-rebuild
switch` applies it with rollback.

### Full foreign-WSL flow

A fresh WSL distro bootstraps in two commands after Nix is installed:

```sh
# 1) Enable flakes system-wide (once per distro).
sudo tee -a /etc/nix/nix.conf >/dev/null <<'EOF'
experimental-features = nix-command flakes
trusted-users = root <your-user>
EOF
sudo systemctl restart nix-daemon.service   # skip on distros without systemd

# 2) CLI batteries (nushell, neovim, yazi, lazygit, …) + dotfiles in one go.
nix run github:nix-community/home-manager/master -- \
  switch --flake github:GooseRooster/home-manager#wsl --impure
```

## Adding a host

For a **foreign** (non-NixOS) host, add it here in two spots:

1. `hosts/<name>.nix` — set `home.username`/`home.homeDirectory` and the
   `home.modules.*` flags. Copy `hosts/wsl.nix` for one whose user varies by
   distro (reads `$USER`/`$HOME` via `--impure`).
2. `flake.nix` — add a `homeConfigurations.<name>` and, if it should also be
   reusable for NixOS integration, an `hmModules.<name>` bundle.

For a **NixOS** host, don't add anything here — wire it through `nixos-config`
(see below), which sets the flags per host.

`homeConfigurations` is the standalone target (`home-manager switch --flake .#<name>`);
`hmModules` is the reusable module for NixOS integration below. For a host that
needs a non-`gooze` user, set `home.username`/`home.homeDirectory` in its
`hosts/<name>.nix` (see `hosts/wsl.nix` for the env-driven variant).

### NixOS integration (recommended)

Add this repo + the HM tool as inputs in `nixos-config/flake.nix`:

```nix
inputs = {
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";

  dotfiles.url = "github:GooseRooster/home-manager";
  dotfiles.inputs.home-manager.follows = "home-manager";
  dotfiles.inputs.nixpkgs.follows = "nixpkgs";
};
```

Then per host (e.g. in `hosts/home/default.nix`):

```nix
{ inputs, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager.users.gooze = {
    imports = [ inputs.dotfiles.hmModules.default ];
    # Set the flags to mirror the system-side toggles (bundles.base is
    # default-on; enable baseExtra for desktop hosts):
    home.bundles.baseExtra.enable = true;
    home.modules.gaming.enable = true;
    home.modules.theming.enable = true;
  };
}
```

`hmModules.default` is the shared base (no username/homeDirectory, no flags) —
NixOS's HM integration infers the user from `home-manager.users.<name>`, so each
host sets only the flags it needs. Per-host flags live in the **nixos-config**
host file, next to the system-side toggles they mirror (e.g. `home.modules.session`
mirrors `modules.desktop.session`).

## Yazi plugin updates

Plugins are fully declarative: pinned to a `rev` + `hash` in
`modules/yazi.nix` via `programs.yazi.plugins` (fetched from the Nix store,
no runtime network or git). To update one, bump its `rev`/`hash` — or (`bash scripts/update-yazi-plugins.sh`).

## Neovim

~/.config/nvim is fully declarative: the [MiniMax](https://github.com/nvim-mini/MiniMax)
base config is vendored in `vendor/nvim/` (a pure upstream mirror) and merged
at eval time with the repo's custom overlay (`files/nvim/`) by
`modules/nvim.nix` — the overlay wins on conflict. MiniMax is built almost
entirely on [`mini.nvim`](https://github.com/nvim-mini/mini.nvim) (one
maintainer, ~35 modules) and Neovim's built-in `vim.pack`, with no Mason and
no lazy.nvim — a config meant to be read start-to-end, with a smaller
dependency surface than a "distribution" like LazyVim (traded against a few
capability gaps: `mini.completion` vs blink.cmp, `mini.pick` vs
snacks/telescope, no bundled test-runner UI beyond what individual plugins
bring). The vendored copy is a read-only store symlink, so `vim.pack`'s
lockfile lives at the managed path as a mutable file instead (see the
[gotcha](#gotcha-worth-remembering) below).

`bash scripts/update-nvim.sh` to refresh `vendor/nvim/` against upstream
(review the diff manually; nothing auto-merges).

### Environment profile

Which languages load is decided at runtime by the environment profile
(`files/nvim/lua/config/profile.lua`): everything defaults to the lean
baseline + `NVIM_LANGS` opt-ins (typically `export NVIM_LANGS=...,rust` from
a project's `.dev.local.sh` — the personal/gitignored hook, not `.envrc`);
`NVIM_PROFILE=full` is a deliberate per-machine opt-in for hosts that
genuinely carry every toolchain.

LSP servers are Mason-free: a server enables only when its feature is in the
profile **and** its binary resolves on PATH. A small set of **native** tools
(`lua-language-server`, `clangd`, `rust-analyzer`, `neocmakelsp`, `codelldb`,
`stylua`) therefore comes from PATH — home profile (`pkgs/base.nix`) or
project devshell — since prebuilt native binaries cannot run on NixOS.
Consequence for projects: a rust/clang/cmake project must provide its
tooling via the devshell (`devshell-init rust` / `clang` scaffolds it) —
opening nvim outside such a shell simply leaves those servers off.

### Structure

There is no "MiniMax" plugin to `import` — the upstream repo's
`configs/nvim-<version>/` directory *is* the entire config, meant to be
copied once and diverged from. So `vendor/nvim/` +
`bash scripts/update-nvim.sh` only track upstream's reference config for
review; nothing regenerates automatically, and nothing auto-merges — review
the diff by hand after running it.

The repo's own overlay (`files/nvim/`) layers on top of that vendor mirror:
`lua/config/{profile,clue,run,xmldoc}.lua` (env-driven language profile,
mini.clue helpers, the stack-agnostic Run/Unit-test group convention, the C#
XML-doc snippet) plus `plugin/50-custom/*.lua` (one file per integration —
LSP, DAP, dotnet, kulala/REST, zk notes, markdown, theming, notifications,
and so on).

### What's in the config today

- **LSP, Mason-free** (`plugin/50-custom/lsp.lua` + `lua/config/profile.lua`)
  — an `NVIM_PROFILE`/`NVIM_LANGS` environment-driven language profile:
  a server enables only when
  `profile.has(feature)` **and** its binary resolves on PATH (lspconfig's
  `cmd[1]`, with a fallback-binary override table for servers whose `cmd` is
  a function). No PATH binary means the server silently never attaches — no
  errors, no Mason install prompts. Binaries come from `pkgs/base.nix` or a
  project devshell. Tree-sitter parsers for enabled features install
  alongside.
- **DAP + dotnet** (`plugin/50-custom/dap.lua`, `easy-dotnet.lua`) — a single
  narrow left dapui column (scopes + breakpoints + repl); codelldb
  (rust/C/C++) and python/debugpy adapters register when their feature +
  binary are present; easy-dotnet registers its own adapter. Dotnet sessions
  additionally get a bottom row with the CPU/mem profiler widgets, shown
  only for `session.config.type == 'easy-dotnet'`. easy-dotnet's managed
  console (the process's stdout/stderr panel, which pops open unprompted on
  every run/debug) is patched to auto-hide itself immediately — press
  `<Leader>rT` to reveal it on demand instead. `<Leader>r`/`<Leader>u` are
  meant to mean "Run"/"Unit test" regardless of stack (see
  `lua/config/run.lua` for the letter convention); only dotnet implements
  them today, and its own bare test-runner shortcuts were moved off
  `<Leader>r`/`t`/`d`/`e`/`p` onto `<Leader>u*` to avoid shadowing that
  group. For a full multi-pane dapui layout (extra columns, always-on
  profiler row), override per-project with a `.nvim.lua` calling
  `require('dapui').setup({...})` again.
- **Keymap clues** (`lua/config/clue.lua`, `plugin/50-custom/mini-clue-icons.lua`)
  — which-key-style group labels via `mini.clue`. Global groups append to
  `Config.leader_group_clues`; buffer-scoped groups (dotnet, kulala's REST
  client, zk notes, markdown) go through `add_buf()`, which appends to
  `vim.b[bufnr].miniclue_config.clues` — verified against `mini.clue`'s own
  source that this *concatenates* rather than overrides, so more than one
  `FileType` autocmd can safely target the same buffer. Both the global and
  buffer-local paths prefix a hand-picked Nerd Font glyph onto known group
  descriptions (written as `\xEF\x..\x..` UTF-8 byte escapes, not literal
  characters — several editors/terminals silently mangle raw
  Private-Use-Area bytes on save).
- **Notifications** (`plugin/50-custom/notify.lua`, `fidget.lua`) — `vim.notify`
  routes through `mini.notify` so every notification lands in
  `<Leader>en`'s history, with a hand-rolled wrapper (rather than
  `mini.notify`'s own bare `make_notify()`) that additionally honors the
  nvim-notify/snacks `id`/`replace` convention — needed so spinner-style
  progress messages (e.g. easy-dotnet's job spinner, one `vim.notify` call
  per animation frame) update one notification in place instead of stacking
  a new popup per frame. `fidget.nvim` sits alongside it for animated
  LSP-progress spinners specifically (mini.notify has no spinner primitive
  of its own).
- **Diagnostics** — gutter signs are icon glyphs for Warning/Error (Info/Hint
  stay signless, matching the stock severity filter); inline text comes from
  `tiny-inline-diagnostic.nvim` instead of Neovim's built-in virtual text.
- **Ported LazyVim `core_extras` equivalents** — kept: yanky,
  dial, inc-rename (upgrades the stock `<Leader>lr` in place), navic,
  mini-animate, startuptime; dropped: neogen, illuminate, outline,
  smear-cursor, dot (mini-surround and mini-hipatterns were already native).
  `goto-preview.nvim` ("peek" a definition/type/implementation/declaration
  in a float without leaving the cursor) rounds out the `<Leader>l`
  "+Language" group as uppercase siblings of the existing jump-to actions
  (`lS`/`lT`/`lI`/`lD`, plus `lq` to close preview floats).
- **Explorer & pickers** — stock `mini.files` (widened preview pane,
  `<CR>` opens-and-closes on a file) and `mini.pick`/`mini.extra`
  (`<C-j>`/`<C-k>` navigation) needed no porting; `mini.icons` already
  supplies file/directory/LSP-kind icons everywhere it's asked to.
- **Theming** — `osc-colors.nvim` (reads the terminal's live palette) drives
  the colorscheme, replacing stock `miniwinter`.
- **cairn.nvim** (file arena/quick-jump) on `<Leader>c`, **herdr-nvim**
  (agent-output sidebar) on `<Leader>a`, **kulala.nvim** (REST client) on
  buffer-local `<Leader>R` in `.http` files, **zk** notes on buffer-local
  `<Leader>z` in notebook markdown — each with its own `mini.clue` group.

### Gotcha worth remembering

`vim.pack`'s lockfile (`nvim-pack-lock.json`) needs to be genuinely absent
from the deployed config, not just present-and-writable: MiniMax's upstream
repo ships one (a snapshot of the maintainer's installed revisions), so a
naive vendor mirror turns it into a read-only store symlink sitting exactly
where `vim.pack` needs to *overwrite* it on every install/update — breaking
every `vim.pack.add()` call outright. `modules/nvim.nix` `rm`s it
from the build output before the overlay lands, so home-manager never
manages that path and `vim.pack` is free to create a real mutable file there
on first run. If you ever see `vim.pack.add()` failing to persist lock data
after touching the vendor mirror, check whether a vendored lockfile snuck
back in.

## Devshell templates

Reusable Nix devShell scaffolds for project-local dev environments, shipped in
`files/devshell-templates/` and materialized on switch into
`~/.local/share/devshell-templates/`. The `devshell-init` helper drops a
template into a target repo. Deployed by `modules/scripts.nix` (every host).

Currently available:

- **`dotnet`** — .NET SDK 10 + `dart-sass` + local-tool-manifest restore + dev
  cert export to `./.certs/` + auto-created `./.dev.local.sh` personal hook
  (pre-wired with `NVIM_LANGS=...,dotnet` + `EasyDotnet`). See
  `files/devshell-templates/dotnet/README.md` for adoption details and a
  couple of NLog gotchas worth remembering.
- **`rust`** — `rust-analyzer` + `codelldb` (vscode-lldb standalone adapter)
  on PATH; `./.dev.local.sh` is auto-created with `NVIM_LANGS=...,rust` so
  nvim's rust extra loads only inside the shell. Toolchain itself comes from
  the host's rustup.
- **`clang`** — `clang-tools` (clangd) + `codelldb` + `cmake`/`neocmakelsp`;
  `./.dev.local.sh` is auto-created with `NVIM_LANGS=...,clang,cmake` for
  C/C++ (+ CMake) projects.

The rust/clang templates exist because mason's prebuilt native servers can't
run on NixOS — those tools are environment-sourced, per the
[Environment profile](#environment-profile--mason-on-nixos) section above.

`devshell-init` copies real, writable files (dereferencing the Nix-store
symlinks that back the templates) — never symlinks back into the store —
and skips each template's `README.md` (reference docs only, read it
straight from `~/.local/share/devshell-templates/<name>/README.md`).

Usage from any repo:

```sh
devshell-init                     # list available templates
devshell-init dotnet              # scaffold into CWD
devshell-init dotnet path/to/repo # scaffold into a target dir
devshell-init dotnet --force      # allow overwrite of existing flake.nix / .envrc
```

Templates are personal reference material — each is a snapshot you copy and
then diverge from per-project. Refresh a template in-place when you learn
something worth propagating back to future scaffolds.

## Mutable state

| Tool | Mechanism |
|------|-----------|
| Neovim | `vendor/nvim/` + eval-time merge; `nvim-pack-lock.json` written at runtime |
| yazi plugins | `programs.yazi.plugins` (pinned rev + hash, Nix store) |
| tldr cache | `tealdeer/config.toml` with `auto_update = true` |
| tinty theme repos | tinty-managed; run `tinty sync` once per machine |

## Local overrides

`~/.config/nushell/env.local.nu` is materialized once by
`home.activation.materializeEnvLocal` and never overwritten. Put per-host
secrets/API keys there.


