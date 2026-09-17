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
plus the `bundles` switches (see
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

## LazyVim starter updates

~/.config/nvim is fully declarative: the [LazyVim
starter](https://github.com/LazyVim/starter) is vendored in
`vendor/lazyvim-starter/` (a pure upstream mirror) and merged at eval time
with the repo's lua overlay (`files/nvim/lua`) by `modules/nvim.nix` — the
overlay wins on conflict, and the starter's inert example plugin is dropped.
The vendored copy is a read-only store symlink, so `lazy-lock.json` lives in
the data dir instead (see `files/nvim/lua/config/lazy.lua`).

`bash scripts/update-starter.sh` to update the vendored copy.

### Environment profile & mason on NixOS

Which languages load is decided at runtime by the environment profile
(`files/nvim/lua/config/profile.lua`): everything defaults to the lean
baseline + `NVIM_LANGS` opt-ins (typically `export NVIM_LANGS=...,rust` from
a project's `.dev.local.sh` — the personal/gitignored hook, not `.envrc`);
`NVIM_PROFILE=full` is a deliberate per-machine opt-in for hosts that
genuinely carry every toolchain.

Mason remains the installer for anything that runs fine from a prebuilt
download (node/jar/pip/python-venv/static-Go packages — pyright, vtsls,
hadolint, ...). A small set of **native** tools (`lua-language-server`,
`clangd`, `rust-analyzer`, `neocmakelsp`, `codelldb`, `stylua`) is instead
resolved from PATH — home profile or project devshell — because mason's
prebuilt ELFs cannot run on NixOS. See `nix_substitutes` in `profile.lua`;
`plugins/lsp.lua`, `plugins/mason.lua` and `plugins/dap.lua` consume it.
Consequence for projects: a rust/clang/cmake project must provide its
tooling via the devshell (`devshell-init rust` / `clang` scaffolds it) —
opening nvim outside such a shell simply leaves those servers off.

## MiniMax experiment (roadmap)

An experimental, side-by-side [MiniMax](https://github.com/nvim-mini/MiniMax)
config lives at `~/.config/nvim-minimax`, booted via `nvim-minimax` (zsh alias
/ nu `def`, both set `NVIM_APPNAME=nvim-minimax`). It never touches
`~/.config/nvim` or the primary LazyVim setup's data/state dirs — fully
additive, safe to ignore.

Rationale: MiniMax leans almost entirely on `mini.nvim` (one maintainer, ~35
modules) plus Neovim's built-in `vim.pack`, instead of LazyVim's dozen+
separate plugin authors + lazy.nvim + Mason. Smaller dependency surface,
config meant to be read start-to-end, no auto-updating "distribution" layer —
traded against real capability gaps out of the box (`mini.completion` vs
blink.cmp, `mini.pick` vs snacks picker, no Mason/DAP/testing baseline). The
goal here isn't to replace LazyVim outright, but to dogfood it far enough to
make that call deliberately.

Vendoring mirrors the LazyVim starter pattern with one structural difference:
LazyVim is a real runtime plugin dependency (`vendor/lazyvim-starter` is just
the empty project skeleton; actual behavior comes from the separately-fetched
`LazyVim/LazyVim` plugin). MiniMax has no such split — there is no "MiniMax"
plugin to `import`; the upstream repo's `configs/nvim-<version>/` directory
*is* the entire config, meant to be copied once and diverged from. So
`vendor/minimax/` + `scripts/update-minimax.sh` only track upstream's
reference config for review; nothing regenerates automatically.

`vim.pack`'s own lockfile (`nvim-pack-lock.json`) is written straight into
`~/.config/nvim-minimax` at runtime — `recursive = true` home-manager file
sets materialize as a real writable directory of per-file store symlinks, not
one read-only directory symlink, so genuinely *new* files (like `lazyvim.json`
already sitting happily inside `~/.config/nvim` today) need no lazy.nvim-style
`lockfile = ...` workaround.

**Correction, found the hard way**: that reasoning doesn't extend to a file
that's *vendored* — `nvim-pack-lock.json` ships as part of MiniMax's own
upstream repo (a snapshot of revisions its maintainer had installed), so it
was copied into `vendor/minimax/` during Phase 0 like everything else, which
made it a managed, read-only symlink into the store at exactly the path
`vim.pack` needs to *overwrite* every time it installs/updates a plugin —
breaking every `vim.pack.add()` call outright. Fixed in `modules/nvim-minimax.nix`
by `rm`-ing it from `$out` before it's ever linked, so home-manager never
manages that path at all and `vim.pack` is free to create a genuine mutable
file there on first run (same mechanism as `lazyvim.json`, just reached by
removal instead of the file never having existed upstream). Verified live:
`vim.pack.add()` now succeeds and writes a real `nvim-pack-lock.json`, which
also self-healed (`"Repaired corrupted lock data"`) the revisions for every
plugin installed while the bug was present, since a lockfile write had never
actually succeeded before.

One migration wrinkle worth knowing if this ever recurs (a vendored/overlay
file being removed in a *future* update): `home-manager switch`'s cleanup
step didn't retroactively delete the stale symlink left over from the
previous generation — it had to be removed by hand
(`rm ~/.config/nvim-minimax/nvim-pack-lock.json`) once, after switching, to
let `vim.pack` actually claim the path. Not fully root-caused (home-manager's
per-file cleanup for entries inside a `recursive = true` directory apparently
doesn't always catch up in one switch); a one-time nuisance, not an ongoing
one, since this specific path is now permanently excluded going forward.

Phases (0–3 done so far):

- [x] **Phase 0 — scaffolding.** `vendor/minimax/`, `modules/nvim-minimax.nix`,
  `scripts/update-minimax.sh`, `nvim-minimax` shell alias/def.
- [x] **Phase 1 — keymap parity.** `<leader><leader>` → `Pick files`,
  `<leader>/` → `Pick grep_live` (`files/nvim-minimax/plugin/45_keymaps_extra.lua`;
  additions — MiniMax's own `<leader>ff`/`<leader>fg` stay).
- [x] **Phase 2 — plugin port (low-risk bucket).** Ported as a
  `files/nvim-minimax/` overlay (`lua/config/{profile,clue}.lua` +
  `plugin/50-custom/*.lua`), merged onto `vendor/minimax/` in
  `modules/nvim-minimax.nix` the same way `modules/nvim.nix` layers
  `files/nvim/lua` over `vendor/lazyvim-starter`. `lua/config/profile.lua` is
  a trimmed fork of the LazyVim side's module — same `NVIM_PROFILE`/
  `NVIM_LANGS` env vars, `nix_substitutes`/`tool_source()`/Mason dropped
  entirely (see Phase 5). Notable deviations from a literal port:
  - `dap.lua` — a middle ground, not a straight trim: a single narrow left
    column (scopes + breakpoints + repl, 42 cols) is always shown; the
    easy-dotnet CPU/mem profiler row is added to the layout dynamically, only
    for sessions actually driven by easy-dotnet's own DAP adapter (detected
    via `session.config.type == 'easy-dotnet'` — verified against
    easy-dotnet.nvim's own `auto_register_dap`/`constants.debug_adapter_name`
    source). No separate stacks/watches/console panes, no right column — for
    a full multi-pane layout (45-col left + 40-col right + bottom perfmon
    row), see `~/repos/CSPWeb`'s `.nvim.lua`, which still works unchanged as
    a per-project override (`require('dapui').setup({...})` again). Still
    dropped: `nvim-dap-virtual-text`, `mason-nvim-dap` (no Mason at all —
    debug adapters expected on PATH via the environment). Verified headlessly
    by invoking the `dap.listeners.before.launch.dapui_config` callback
    directly with fake session objects (no session / `easy-dotnet` type /
    other adapter type) and inspecting `require('dapui.config').layouts` —
    bottom panel present only for the `easy-dotnet` case, and correctly gone
    again for a subsequent non-dotnet session (no leaked state). Per-language
    `dap.adapters.*`/`dap.configurations.*` wiring is Phase 5 territory.
  - `easy-dotnet.lua` — picker changed `"snacks"` → `"basic"`: MiniMax has no
    snacks/telescope/fzf-lua, and easy-dotnet has no native `mini.pick`
    integration (its own fallback order is snacks → fzf → telescope →
    basic). Revisit if that changes upstream.
  - `luasnip.lua` — LuaSnip coexists fine with `mini.snippets` (different
    concern: `mini.completion` only needs an omnifunc + optional snippet
    *source*, not a specific engine); the `jsregexp` build step is wired via
    `Config.on_packchanged`, matching `40_plugins.lua`'s own
    `nvim-treesitter` `:TSUpdate` hook pattern.
  - `cairn.lua` — remapped off its own `<leader>m*` defaults to `<leader>a*`:
    MiniMax's stock `20_keymaps.lua` already claims `<leader>m` for
    `mini.map`. No actual keymap collision (different exact sequences), but
    `mini.clue` would've had two different group descriptions registered for
    the same prefix.
- [x] **Phase 3 — explorer & clues.** `yazi.nvim` dropped, stock `mini.files`
  used (nothing to port — already default). which-key group labels
  translated to `mini.clue`: global groups (`cairn.lua`) append to
  `Config.leader_group_clues`; buffer-scoped groups (`easy-dotnet.lua`,
  `markdown.lua`, `zk.lua`) use a small shared helper
  (`lua/config/clue.lua`'s `add_buf()`) that appends to
  `vim.b[bufnr].miniclue_config.clues` — verified against `mini.clue`'s own
  source (`H.get_config` *concatenates* global + buffer-local clue lists, it
  doesn't override) that this is the correct, collision-safe mechanism, since
  more than one `FileType` autocmd can target the same buffer (e.g. both
  `markdown.lua` and `zk.lua` fire on `FileType markdown`).

  One correctness subtlety worth remembering if you touch these files:
  `Config.on_filetype`/`Config.later` fire the *first* matching event once,
  so a *newly*-registered `FileType` autocmd inside that callback won't
  retroactively fire for the very buffer that triggered it (`zk.lua`,
  `markdown.lua`, `easy-dotnet.lua` all call their buffer-setup function once
  directly, in addition to registering the ongoing autocmd, to cover that
  buffer too — see the comments in those files).

  All of the above verified with a real headless `vim.pack` install (network,
  not just `nix build`) against a scratch `$XDG_CONFIG_HOME`/`$XDG_DATA_HOME`,
  opening markdown/`.cs` scratch files, with and without `NVIM_LANGS=dotnet` —
  no Lua errors, correct plugins/keymaps/clues present or absent as expected.

- [x] **Phase 4 — theme polish.** `osc-colors.nvim` gained a
  `highlights/mini.lua` integration upstream (registered in its
  `integrations` table alongside `lualine`/`snacks`/..., `mini = true` by
  default). Wired into MiniMax via `plugin/50-custom/theme.lua` — overrides
  the stock `miniwinter` colorscheme (`vendor/minimax/plugin/30_mini.lua`,
  left untouched; this file runs later in the same synchronous `now()` phase
  and repaints over it, so there's no flash — nothing reaches the screen
  until all of `plugin/*.lua` finishes sourcing regardless). `use_lazy_specs`
  explicitly disabled (a no-op without lazy.nvim anyway, but there's nothing
  for it to ever find in this config). Verified headlessly two ways: a fresh
  sandbox with no cached OSC-query palette correctly no-ops and leaves
  `miniwinter` in place (documented behavior — `osc-colors` needs a real
  terminal round-trip or a prior cache, neither exists in `--headless` with
  no UI); copying in the *actual* cached palette from `~/.cache/nvim/osc-colors-palette.lua`
  (same file your LazyVim setup already produced) makes it apply correctly —
  `vim.g.colors_name == 'osc-colors'` and `MiniStatuslineModeNormal` etc. get
  real palette-derived colors, not fallback links. First real interactive
  launch of `nvim-minimax` will populate its own cache
  (`$XDG_CACHE_HOME/nvim-minimax/osc-colors-palette.lua`, separate namespace
  from the LazyVim config's cache) via the same live `UIEnter`/`FocusGained`
  OSC query your LazyVim setup already went through once.
- [ ] **Phase 5 — LSP layer, Mason-free (in progress).** One
  `after/lsp/<server>.lua` + `vim.lsp.enable(name, profile.has(feature))` per
  entry in `profile.lua`'s existing `feature_order` (python, rust,
  typescript, java, clang, cmake, docker, sql, json, yaml, nushell, git,
  dotnet) — server defaults sourced from each LazyVim extra as reference, not
  a dependency. `profile.lua`'s language-selection logic ports almost as-is;
  `nix_substitutes`/`tool_source()`/`mason.lua` are dropped entirely (nothing
  routes through Mason in this config — binaries come from `pkgs/base.nix`
  or project devshells, same as the NixOS-unsafe tools already do today).
  Languages needing more than a bare lspconfig entry (rust → rustaceanvim,
  typescript → vtsls settings, dotnet → existing easy-dotnet/lazydotnet) get
  their extra plugin added via `vim.pack.add()` per-language as reached.

  Also sweeping up the LazyVim side's stack-agnostic `core_extras` (always
  on, not gated by any of the 13 language features) alongside the
  language-specific ones, since they're the same shape of work. Approach for
  these: port the LazyVim extra close to verbatim rather than redesign —
  they're small, self-contained, and already well-tuned. First one done:
  `plugin/50-custom/kulala.lua` (`lazyvim.plugins.extras.util.rest`) —
  verbatim keymap set, `<Leader>R` group appended to
  `Config.leader_group_clues`, treesitter parsers for `http`/`graphql` added
  matching `40_plugins.lua`'s own `ensure_installed` pattern. One deviation:
  lazy.nvim's per-key `ft = "http"` restriction (some keymaps only existed
  in `.http` buffers) has no `vim.pack` equivalent, so every key is global
  now — harmless, kulala's own functions no-op/error gracefully outside an
  `.http` buffer, and a couple of them (scratchpad, replay) are meant to be
  reachable from anywhere anyway. Verified live (`.http` scratch file,
  `NVIM_APPNAME=nvim-minimax`): filetype detection, both a buffer-scoped key
  (`<Leader>Rs`) and a global one (`<Leader>Rb`), module loads cleanly,
  parsers install successfully.
  `core_extras` disposition, decided explicitly rather than porting all of
  them: **kept** — mini-surround (already native), yanky, dial, inc-rename,
  navic, mini-animate, mini-hipatterns (already native), startuptime.
  **Ditched** — neogen, illuminate, outline, smear-cursor, dot.

  All six newly-ported ones (`plugin/50-custom/{yanky,dial,inc-rename,navic,
  mini-animate,startuptime}.lua`) verified live (real `home-manager switch`,
  real `vim.pack` install, `NVIM_APPNAME=nvim-minimax`), including the two
  worth flagging specifically:
  - `yanky.lua`'s `[y`/`]y` (cycle yank-history forward/backward)
    intentionally shadows `mini.bracketed`'s own "yank" target (`:h
    MiniBracketed.yank`, active by default, same keys, different mechanism)
    — confirmed `]y` resolves to yanky's `<Plug>(YankyCycleForward)`, not
    mini.bracketed's. Also shadows MiniMax's stock `[p`/`]p` (a strict
    subset of yanky's indent-aware put) for the same reason.
  - `inc-rename.lua`'s `<Leader>lr` intentionally overrides MiniMax's stock
    `vim.lsp.buf.rename()` binding on the same key (a strict upgrade, live
    preview) — confirmed the live mapping resolves to inc-rename.lua's own
    function, not the stock one.
  - `navic.lua`: winbar is set directly per-window (`LspAttach`/
    `BufWinEnter`/`WinEnter`), not through a statusline plugin's `winbar`
    section like the LazyVim setup's own `lualine.lua` does it (no lualine
    here) — confirmed empty (not a permanently-reserved blank line) for
    windows with no navic-capable attached client.
  - `startuptime.lua`: no "append one item" API on `mini.starter` — its
    `config.items` stays `nil` unless set explicitly (falls back to a
    private default list at render time). Replicated that exact default
    composition via the same public `MiniStarter.sections.*` generators
    upstream uses internally, plus one new "Startup time" item — confirmed
    present in the resolved `MiniStarter.config.items`.

`bash scripts/update-minimax.sh` to refresh `vendor/minimax/` against
upstream (review the diff manually; nothing auto-merges).

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
| LazyVim starter | `vendor/lazyvim-starter/` + eval-time merge |
| MiniMax (experimental) | `vendor/minimax/` + eval-time copy; `nvim-pack-lock.json` written at runtime |
| yazi plugins | `programs.yazi.plugins` (pinned rev + hash, Nix store) |
| tldr cache | `tealdeer/config.toml` with `auto_update = true` |
| tinty theme repos | tinty-managed; run `tinty sync` once per machine |

## Local overrides

`~/.config/nushell/env.local.nu` is materialized once by
`home.activation.materializeEnvLocal` and never overwritten. Put per-host
secrets/API keys there.


