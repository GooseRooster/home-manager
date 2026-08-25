# home-manager

Home dotfiles, declaratively managed with [Home Manager](https://github.com/nix-community/home-manager).

## Where things live

```
nixos-config    NixOS system declarations (desktop + NixOS-in-WSL)
nix-cli         CLI "batteries" via plain Nix (buildEnv + NixOS modules)
home-manager    ← this repo: home dotfiles
```

- **nix-cli** owns *binaries* (nushell, neovim, yazi, tealdeer, television, …).
- **home-manager** owns *config* and the mutable state those tools need (yazi
  plugins, tldr/television caches, the LazyVim starter).
- **Dev toolchains** (dotnet, java, rust, node, …) belong in dev containers or
  `nix develop` environments — never here.

## Targets / flavors

Each target enables a set of feature flags (`home.modules.*`), the HM equivalent
of chezmoi's `chezmoi.toml` `[data]` flags and `.chezmoiignore.tmpl`.

| Target | Use | Flags on |
|--------|-----|----------|
| `desktop` | NixOS desktop | `gaming`, `theming` |
| `wsl` | NixOS-WSL dev host | `wsl`, `podmanAlias` |
| `devcontainer` | lean container | `devcontainer`, `podmanAlias` |

Flags: `gaming`, `theming`, `podmanAlias`, `devcontainer`, `wsl` (see
`modules/flavors.nix`). `devcontainer`/`wsl` skip GUI-only dotfiles (ghostty,
mpv, tinty, owl.jpg) the same way the old `.chezmoiignore.tmpl` did.

## Applying

Standalone (any distro with Nix):

```sh
home-manager switch --flake github:GooseRooster/home-manager#desktop
home-manager switch --flake github:GooseRooster/home-manager#wsl
home-manager switch --flake github:GooseRooster/home-manager#devcontainer --impure
```

The `devcontainer` target uses `--impure` because `hosts/devcontainer.nix` reads
`$USER`/`$HOME` at eval time — the container's uid-1000 user varies by base image
(`vscode`, `ubuntu`, …), so it can't be hardcoded.

From a local checkout:

```sh
home-manager switch --flake .#desktop
```

On NixOS, prefer wiring it through `nixos-config` (see below) so `nixos-rebuild
switch` applies it with rollback.

## Adding a host

Like `nixos-config`'s `hosts/` + `nixosConfigurations`, add a host here in two spots:

1. `hosts/<name>.nix` — set `home.username`/`home.homeDirectory` and the
   `home.modules.*` flags (copy `hosts/wsl.nix` as a template).
2. `flake.nix` — add `<name>` to both `homeConfigurations.<name> = mkHome "<name>"`
   and `hmModules.<name> = mkHostModule "<name>"`.

`homeConfigurations` is the standalone target (`home-manager switch --flake .#<name>`);
`hmModules` is the reusable module for NixOS integration below. For a host that
needs a non-`gooze` user, set `home.username`/`home.homeDirectory` in its
`hosts/<name>.nix` (see `hosts/devcontainer.nix` for the env-driven variant).

### NixOS integration (recommended)

Add this repo + the HM tool as inputs in `nixos-config/flake.nix`:

```nix
inputs = {
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";

  dotfiles.url = "github:GooseRooster/home-manager";
  dotfiles.inputs.home-manager.follows = "home-manager";
  dotfiles.inputs.nix-cli.follows = "cli";
  dotfiles.inputs.nixpkgs.follows = "nixpkgs";
};
```

Then per host (e.g. in `hosts/home/default.nix`):

```nix
{ inputs, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager.users.gooze = {
    imports = [ inputs.dotfiles.hmModules.default ];
    # Set the flags to mirror the system-side toggles:
    home.modules.gaming.enable = true;
    home.modules.theming.enable = true;
  };
}
```

`hmModules.default` is the shared base (no username/homeDirectory, no flags) —
NixOS's HM integration infers the user from `home-manager.users.<name>`, so each
host sets only the flags it needs. (The `hmModules.desktop`/`wsl`/`devcontainer`
bundles are for standalone `homeConfigurations`, where username/flags must be set.)

## Yazi plugin updates

Plugins are fully declarative: pinned to a `rev` + `hash` in
`modules/yazi.nix` via `programs.yazi.plugins` (fetched from the Nix store,
no runtime network or git). To update one, bump its `rev`/`hash` — the CI
`yazi-plugins` job (see Roadmap) can do this via PR.

## Bootstrap

Mutable, network-dependent state (the LazyVim starter, `tinty` theme repos,
television channels) is initialised by a single idempotent `bootstrap` command —
run it **once per machine**, after the first switch and once you're online:

```sh
bootstrap
```

It's safe to re-run (each step skips itself once done, and the LazyVim clone is
keyed on `~/.config/nvim/init.lua`, so a failed offline run retries cleanly next
time). Re-run it any time a step reports a network failure.

## Mutable state, declaratively

| Tool | Old (chezmoi bootstrap) | Now |
|------|------------------------|-----|
| LazyVim starter | `git clone` + `rm .git` | `bootstrap` (idempotent, self-updating) |
| yazi plugins | `ya pkg install` | `programs.yazi.plugins` (pinned rev + hash, Nix store) |
| tldr cache | `tldr --update` | `tealdeer/config.toml` with `auto_update = true` |
| television channels | `tv update-channels` | `bootstrap` |
| tinty theme repos | `tinty sync` | `bootstrap` |

## Local overrides

`~/.config/nushell/env.local.nu` is materialized once by
`home.activation.materializeEnvLocal` and never overwritten (chezmoi's `create_`
pattern). Put per-host secrets/API keys there.

## Roadmap

### Planned

- **CI** (`.github/workflows/`), to close the loop on the two non-declarative
  pieces below. Using Determinate Systems actions (`determinate-nix-action`,
  `magic-nix-cache-action`, `update-flake-lock`):
  - `check` — run `nix flake check` (builds every `homeConfigurations`) on push
    & PR to gate broken configs.
  - `update-flake-lock` — scheduled `nix flake update` that opens a PR with a
    fresh lock file (`nixpkgs` / `home-manager` / `nix-cli`).
  - `lazyvim` — scheduled job that watches `LazyVim/starter` for a new default
    commit and opens a PR pinning it, so the `bootstrap` clone stays
    reproducible and reviewed instead of silently tracking `HEAD`.
  - `yazi-plugins` — scheduled job that bumps the pinned `rev`/`hash` in
    `modules/yazi.nix` and opens a PR, gated on a build.

- **Make LazyVim's non-declarative clone declarative via CI PRs** — yazi plugins
  are already declarative (pinned rev/hash); the `bootstrap` clone still tracks
  `HEAD`.
  The `lazyvim` job pins the starter to a rev CI bumps, giving self-updating
  behavior *plus* rollback/pin-at-will.
