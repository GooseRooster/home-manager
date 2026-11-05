# AGENTS.md

Operational guidance for coding agents working in this repository. For the
project description and architecture, see [README.md](README.md).

## This host

**This machine runs the `silver-hour-gaming` target.** Apply changes with:

```bash
home-manager switch --flake '.#silver-hour-gaming' --impure
```

> Quote the flake reference: `silver-hour-gaming` contains a hyphen, which Nix
> parses as subtraction in an unquoted attribute path.

`--impure` is required: `hosts/*.nix` read `$USER`/`$HOME` at eval time.

### The targets

| Target | Apply (local checkout) |
|---|---|
| `container` | `home-manager switch --flake '.#container' --impure` |
| `wsl` | `home-manager switch --flake '.#wsl' --impure` |
| `silver-hour` | `home-manager switch --flake '.#silver-hour' --impure` |
| `silver-hour-gaming` | `home-manager switch --flake '.#silver-hour-gaming' --impure` |

The same lines against the pushed remote, which is what `hms`/`hmb` use:

```bash
home-manager switch --flake github:GooseRooster/home-manager#container --impure
home-manager switch --flake github:GooseRooster/home-manager#wsl --impure
home-manager switch --flake github:GooseRooster/home-manager#silver-hour --impure
home-manager switch --flake github:GooseRooster/home-manager#silver-hour-gaming --impure
```

`hms`/`hmb` pick the target from `~/.config/home-manager-host`, which the
target itself writes (`hosts/*.nix`, one per target) — so on this machine they
resolve to `silver-hour-gaming` on their own. They build the *remote* flake
(`github:GooseRooster/home-manager`); use the local path for changes that are
not pushed yet.

> Each host writes the marker only when it is applied **there** — so the
> container and the WSL host need one explicit switch (`hms container`,
> `hms wsl`) before `hms` alone works on them. Until then the helpers refuse
> to guess rather than applying the wrong target.

### Do not apply the plain `silver-hour` target here

`silver-hour-gaming` = `silver-hour` + `gaming`, `steamAdwaita`,
`jackify` and `bundles.flatpak.gaming`. Switching the plain `silver-hour`
target on this host replaces the profile with the non-gaming one and removes
the gaming content from it: the Jackify AppImage
(`~/Modding/General Tools/Jackify`), the Adwaita-for-Steam skin
(`~/.config/AdwSteamGtk/`) and the gaming Flatpaks. The home is then in a
half-applied state until the gaming target is switched back.

## Layout

```
flake.nix          — outputs: homeConfigurations.<container|wsl|silver-hour|silver-hour-gaming>
home.nix           — the module set every target imports
hosts/*.nix        — per-target feature flags (the table in the README)
modules/           — one file per concern (gnome-extensions, theming-tools-silver-hour, …)
pkgs/              — pinned builds not in nixpkgs (EGO extensions, installers)
files/             — static file contents copied verbatim into $HOME
files/scripts/     — shell scripts installed into the profile
```

## Conventions

- **Never edit files under `~/.config/…` directly.** They are symlinks into
  the nix store and are replaced on every switch. Change the source in
  `files/` or `modules/` and re-switch.
- `~/.config/gnomad/config.toml` is the one exception: gnomad owns it, and it
  is *not* managed by home-manager. Hand edits survive a switch.
- The ChromaLeon → tinty bridge is **not** in this repository. It lives in
  gnomad (`assets/chromaleon-bridge/`) and is consumed as
  `gnomad.packages.<system>.chromaleon-bridge`; `modules/theming-tools-silver-hour.nix`
  only wires the systemd units around it. Do not copy it back here.
- `home.file` entries are content-addressed: changing any one of them
  rebuilds the whole `home-manager-files` tree, so keep large payloads out of
  it (see the Jackify note in `modules/jackify.nix`).
- Feature flags are `home.modules.*` and `home.bundles.*`; modules gate on them
  with `lib.mkIf`/`lib.optionalString` rather than duplicating the target
  lists.
