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
home-manager switch --flake github:GooseRooster/home-manager#devcontainer
```

From a local checkout:

```sh
home-manager switch --flake .#desktop
```

On NixOS, prefer wiring it through `nixos-config` (see below) so `nixos-rebuild
switch` applies it with rollback.

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
  home-manager.users.gooze.imports = [ inputs.dotfiles.hmModules.desktop ];
}
```

## First build (fill in yazi plugin hashes)

The yazi plugins in `modules/yazi.nix` use `lib.fakeHash` (pinned to the same
git revs the old `yazi/package.toml` used). On the first `home-manager switch`
Nix will error with the real hash for each fetch — copy each into `modules/yazi.nix`.
Standard Nix workflow; after that, builds are locked.

## Mutable state, declaratively

| Tool | Old (chezmoi bootstrap) | Now |
|------|------------------------|-----|
| LazyVim starter | `git clone` + `rm .git` | `home.activation.cloneLazyVim` (idempotent, self-updating) |
| yazi plugins | `ya pkg install` | `programs.yazi.plugins` / `flavors` |
| tldr cache | `tldr --update` | `tealdeer/config.toml` with `auto_update = true` |
| television channels | `tv update-channels` | `home.activation.updateTvChannels` |

## Not yet migrated

Still living in the old dotfiles repo, pending a new home (likely `nix-cli`,
which already has a `quadlets/` dir):

- `devcontainer-templates/` — the `.devcontainer` scaffolding copied by
  `devcontainer-init`. The script now looks in
  `$DEVCONTAINER_TEMPLATES_DIR` (default `~/.local/share/devcontainer-templates`).
- `container_templates/` — the podman quadlets (Windows VM, omnitools, searxng).
- The dev container `local/setup.sh` hooks still assume brew + `bootstrap-cli.sh`;
  they should be rewritten to `nix profile install github:GooseRooster/nix-cli#base`
  + `home-manager switch --flake github:GooseRooster/home-manager#devcontainer`.

## Local overrides

`~/.config/nushell/env.local.nu` is materialized once by
`home.activation.materializeEnvLocal` and never overwritten (chezmoi's `create_`
pattern). Put per-host secrets/API keys there.
