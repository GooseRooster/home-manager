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
no runtime network or git). To update one, bump its `rev`/`hash` — or let the
weekly CI `yazi-plugins` job open a PR doing exactly that
(`bash scripts/update-yazi-plugins.sh` works locally too).

## LazyVim starter updates

~/.config/nvim is fully declarative: the [LazyVim
starter](https://github.com/LazyVim/starter) is vendored in
`vendor/lazyvim-starter/` (a pure upstream mirror) and merged at eval time
with the repo's lua overlay (`files/nvim/lua`) by `modules/nvim.nix` — the
overlay wins on conflict, and the starter's inert example plugin is dropped.
The vendored copy is a read-only store symlink, so `lazy-lock.json` lives in
the data dir instead (see `files/nvim/lua/config/lazy.lua`).

A weekly CI `update-starter` job mirrors upstream into `vendor/` and opens a
PR (`bash scripts/update-starter.sh` works locally too).

## Devshell templates

Reusable Nix devShell scaffolds for project-local dev environments, shipped in
`files/devshell-templates/` and materialized on switch into
`~/.local/share/devshell-templates/`. The `devshell-init` helper drops a
template into a target repo. Deployed by `modules/scripts.nix` (every host).

Currently available:

- **`dotnet`** — .NET SDK 10 + `dart-sass` + local-tool-manifest restore + dev
  cert export to `./.certs/` + optional `./.dev.local.sh` personal hook. See
  `files/devshell-templates/dotnet/README.md` for adoption details and a
  couple of NLog gotchas worth remembering.

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
| LazyVim starter | `vendor/lazyvim-starter/` + eval-time merge (CI-synced) |
| yazi plugins | `programs.yazi.plugins` (pinned rev + hash, Nix store) |
| tldr cache | `tealdeer/config.toml` with `auto_update = true` |
| tinty theme repos | tinty-managed; run `tinty sync` once per machine |

## Local overrides

`~/.config/nushell/env.local.nu` is materialized once by
`home.activation.materializeEnvLocal` and never overwritten. Put per-host
secrets/API keys there.


