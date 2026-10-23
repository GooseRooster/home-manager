# home-manager

Home dotfiles, declaratively managed with [Home Manager](https://github.com/nix-community/home-manager).

## Where things live

```
nixos-config    NixOS system declarations (desktop + NixOS-in-WSL)
home-manager    ← this repo: home dotfiles + CLI "batteries" (package bundles)
```

- This repo owns both *config* and the *binaries* (zsh, neovim, yazi,
  tealdeer, fzf, …). Packages are selected per host via
  `home.bundles.*` (see `modules/bundles.nix`):

  | Bundle | Contents | Default |
  |--------|----------|---------|
  | `base` | devcontainer-safe CLI tooling (`pkgs/base.nix`) | on for every target |
  | `baseExtra` | visual/GUI extras (`pkgs/base-extra.nix`) | off |
  | `wsl` | WSL dev-host extras (`pkgs/wsl.nix`) | off |

- **User-facing Flatpaks** live here too (`modules/flatpak.nix`), installed
  per-user with `flatpak --user` via nix-flatpak's home-manager module, gated
  on `home.bundles.flatpak.*`:

  | Bundle | Contents |
  |--------|----------|
  | `flatpak.base` | media/graphics/misc GUI apps (`pkgs/flatpak-base.nix`) |
  | `flatpak.multimedia` | Stremio (`pkgs/flatpak-multimedia.nix`) |
  | `flatpak.gaming` | Proton management, emulators (`pkgs/flatpak-gaming.nix`) |

- **GNOME Shell extensions** live here too (`modules/gnome-extensions.nix`,
  flag `home.bundles.gnomeExtensions.enable`): the user-level extensions
  (`~/.local/share/gnome-shell/extensions`) are pinned builds from
  extensions.gnome.org, with their settings in dconf. The image's own
  extensions stay in `/usr/share/gnome-shell/extensions`.
- **GNOME desktop settings** (`modules/gnome-settings.nix`, flag
  `home.modules.gnomeSettings.enable`): the Multitasking panel, the alert
  sound, the default applications and the keyboard shortcuts — the parts of
  GNOME that are a personal preference rather than image policy.

### Other conventions

The `programs.<tool>` HM modules and the bundle lists share one nixpkgs
instance, so overlapping entries (e.g. yazi) dedupe to identical store paths.
Also owns reusable **Nix devShell templates** (see
[Devshell templates](#devshell-templates)) for scaffolding project-local dev
environments. **Dev toolchains** (dotnet, java, rust, node, …) belong in
project-local `nix develop` environments — never installed here directly.


## Targets / flavors

Each target enables a set of feature flags (`home.modules.*`), which modules
use with `lib.mkIf`/`lib.optionalString` to include or omit files.

| Target | Use | Flags on |
|--------|-----|----------|
| `container` | lean dev container | `bundles.base` (default) |
| `wsl` | foreign-WSL dev host | `bundles.wsl`, `wsl`, `podmanAlias` |
| `silver-hour` | atomic Fedora image | `silverHour`, `bundles.baseExtra`, `bundles.flatpak.base`, `bundles.gnomeExtensions`, `gnomeSettings`, `podmanAlias` |
| `silver-hour-gaming` | the image + gaming content | the above plus `gaming`, `steamAdwaita`, `bundles.flatpak.gaming` |

Flags: `gaming`, `steamAdwaita`, `podmanAlias`, `wsl`, `silverHour`,
`gnomeSettings`, plus the `bundles` switches (see `modules/bundles.nix`).
`silverHour` selects the GNOME-image profile: the image's own fonts and VS
Code are used, so the bundle lists leave them out, and the theming stack is
gnomad + tinty (`modules/theming-tools-silver-hour.nix`) rather than a
session shell. The silver-hour targets turn on `gnomeSettings` and
`bundles.gnomeExtensions` (see
[GNOME extensions & desktop settings](#gnome-extensions--desktop-settings)).

## Steam (Adwaita-for-Steam)

`modules/steam-adwaita.nix` ports the NixOS gaming module's
[Adwaita-for-Steam](https://github.com/tkashkin/Adwaita-for-Steam) integration
to standalone Home Manager, enabled with `home.modules.steamAdwaita.enable`
(`silver-hour-gaming` only):

- `pkgs/adwaita-for-steam/default.nix` packages the upstream installer and
  stages a writable temp copy, since Steam's mutable `steamui` must be patched
  at runtime.
- `target` defaults to `auto`: it prefers native `~/.steam/steam`, then Flatpak
  `~/.var/app/com.valvesoftware.Steam/.steam/steam`, and no-ops when Steam is
  absent. `native`, `flatpak`, or an explicit path are also accepted.
- A user service re-applies the skin at login and whenever
  `~/.config/AdwSteamGtk/custom.css` changes (the path unit debounces rapid
  theming-tool writes).
- `modules/theming-tools-silver-hour.nix` adds the
  [tinted-adwaita-for-steam](https://github.com/GooseRooster/tinted-adwaita-for-steam)
  tinty item (gated on `steamAdwaita`), whose hook writes that `custom.css`.

## ChromaLeon → tinty bridge

`modules/theming-tools-silver-hour.nix` turns ChromaLeon's live GNOME Shell
colours into a tinted8 scheme for tinty. It is not a separate theme choice:
the scheme follows ChromaLeon rather than re-extracting colours in a vacuum.

- The accent is ChromaLeon's `accent-color` (or the mapped GNOME accent when
  `gnome-colors` is on), and is kept exact in `ui.accent.normal`.
- The background anchor is ChromaLeon's *actual* shell surface, resolved from
  the generated `chromaleon-shell*.css` by evaluating its `st-mix(...)`
  expressions. That means `tint-shell`, `tint-panel`, `tinting-strength`,
  `darker`, `full-light`, and `prefer-light` are followed automatically.
- Wallpaper swatches are extracted with GdkPixbuf via GJS
  (`files/scripts/chromaleon_pixels.js`), matching ChromaLeon's
  aspect-preserving `64x64` scale. ImageMagick is the fallback.
- The eight palette slots are placed in OKLCH: wallpaper hues are normalised
  into consistent lightness/chroma bands, missing hues are synthesized from
  the wallpaper's median chroma, and collapsed slots (notably red/yellow) are
  pushed apart. The accent slot is never modified.
- The terminal stays deliberately a sibling of the shell, not a clone. The
  depth dial moves the background away from the shell surface in OKLCH
  (luminance separation plus a little chroma recession) while leaving the
  accent exact.

The dial is a Home Manager option:

```nix
home.modules.chromaleon.depth = 1; # 0 = exact shell match, 3 = deep
```

To inspect the current result without applying it:

```sh
URI=$(dconf read /org/gnome/desktop/background/picture-uri-dark | tr -d "'")
WP=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.unquote(sys.argv[1][7:]))' "$URI")
gjs files/scripts/chromaleon_pixels.js "$WP" \
  | python3 files/scripts/chromaleon_palette.py --pixels-b64 \
      --accent "$(dconf read /org/gnome/shell/extensions/chromaleon/accent-color | tr -d "'")" \
      --variant dark \
      --shell-css "$HOME/.cache/chromaleon/chromaleon-shell-dark.css" \
      --audit
```

The audit prints the resolved shell surfaces, each palette slot's OKLCH
coordinates, contrast against the background, ΔE from the accent, and any
warnings (synthesized hues, a slot below 4.5:1, etc.). The accent's ANSI copy
is allowed to sit slightly below 4.5:1 rather than silently changing the
user's chosen colour.

## Applying

Every target is a standalone Home Manager configuration:

```sh
# Lean dev container: base batteries + dotfiles.
home-manager switch --flake github:GooseRooster/home-manager#container --impure

# Foreign-WSL dev host: base + wsl extras + dotfiles.
home-manager switch --flake github:GooseRooster/home-manager#wsl --impure

# Atomic Fedora image (workstation), and its gaming flavour.
home-manager switch --flake github:GooseRooster/home-manager#silver-hour --impure
home-manager switch --flake github:GooseRooster/home-manager#silver-hour-gaming --impure
```

All targets use `--impure` because their `hosts/*.nix` read `$USER`/`$HOME` at
eval time


From a local checkout:

```sh
home-manager switch --flake .#wsl --impure
```

The `hms`/`hmb` zsh helpers do the same against the remote flake (see
`files/zsh/functions.zsh`):

```sh
hms                 # switch the default target (silver-hour)
hms silver-hour-gaming
hmb                 # build only, no activation
```

First-time bootstrap on a foreign system without `home-manager` on PATH yet
(fetches HM itself via `nix run`, then subsequent switches use the HM binary
installed into the user profile):

```sh
nix run github:nix-community/home-manager/master -- \
  switch --flake github:GooseRooster/home-manager#container --impure
```

### Full foreign-WSL flow

A fresh WSL distro bootstraps in two commands after Nix is installed:

```sh
# 1) Enable flakes system-wide (once per distro).
sudo tee -a /etc/nix/nix.conf >/dev/null <<'EOF'
experimental-features = nix-command flakes
trusted-users = root <your-user>
EOF
sudo systemctl restart nix-daemon.service   # skip on distros without systemd

# 2) CLI batteries (zsh, neovim, yazi, lazygit, …) + dotfiles in one go.
nix run github:nix-community/home-manager/master -- \
  switch --flake github:GooseRooster/home-manager#wsl --impure
```

## Adding a host

1. `hosts/<name>.nix` — set `home.username`/`home.homeDirectory` and the
   `home.modules.*` / `home.bundles.*` flags. Copy `hosts/wsl.nix` for a host
   whose user varies by distro (reads `$USER`/`$HOME` via `--impure`).
2. `flake.nix` — add a `homeConfigurations.<name>` entry pointing at it.


## GNOME extensions & desktop settings

Two modules cover the GNOME side of the user profile, both enabled on the
silver-hour targets (`hosts/silver-hour.nix`):

| Module | Flag | Owns |
|--------|------|------|
| `modules/gnome-extensions.nix` | `home.bundles.gnomeExtensions.enable` | the user-level GNOME Shell extensions + their settings |
| `modules/gnome-settings.nix` | `home.modules.gnomeSettings.enable` | multitasking, alert sound, default apps, keyboard shortcuts |

### Extensions

The extensions are pinned builds from extensions.gnome.org, listed in
`pkgs/gnome-extensions.nix`:

```
id         extension uuid (also the directory name GNOME expects)
name       human-readable name
schema     dconf path of the extension's GSettings schema
version    version as reported by the build's metadata.json
versionTag EGO's internal version id (shell-version specific)
sha256     flat SHA-256 of the published zip
```

Each build is fetched with `fetchurl`, unpacked and — where the extension
has a GSettings schema — compiled with `glib-compile-schemas`. The zips only
ship the `*.gschema.xml`, but GNOME needs a compiled `gschemas.compiled`
next to it (`ExtensionBase.getSettings()` builds a
`Gio.SettingsSchemaSource` from `<extension>/schemas`), so the compilation
happens in the derivation instead of in a post-install step.

The result is symlinked into `~/.local/share/gnome-shell/extensions/<uuid>` —
the only place GNOME looks for user extensions. It follows the symlink when
enumerating, and only requires the directory name to equal the uuid.

**The enabled list is not owned here.** The image ships its own list of
enabled extensions in `/etc/dconf/db/local.d`, and extensions installed by
hand (MosaicWM) are the user's business too. The activation step therefore
*appends* the managed uuids to `org.gnome.shell enabled-extensions` and
leaves everything else alone.

### Desktop settings

`modules/gnome-settings.nix` declares the deviations from the image's GNOME
defaults

- **Multitasking** — no edge tiling, workspaces on all displays, the window
  switcher restricted to the current workspace.
- **Sound** — the alert sound is a custom canberra theme (`__custom`) in
  `~/.local/share/sounds/__custom`: `index.theme` plus `bell-terminal.ogg`
  and `bell-window-system.ogg` symlinked to the "Swing" sample of the GNOME
  sound theme. The theme files are written as plain files, not store
  symlinks, so gnome-control-center can still rewrite them when the alert
  sound changes.
- **Default applications** — the web browser is Zen (`xdg.mimeApps`); every
  other category keeps the image's default.
- **Keyboard shortcuts** — window management, workspace switching, the
  overview shortcuts, plus custom bindings for the terminal (`<Super>Return`
  → `ghostty`) and the image's GSR screenshot/recording helpers:
  `<Super>Print` → `gsr-shot full`, `<Alt><Super>1` → `gsr-rec screen`,
  `<Alt><Super>2` → `gsr-rec --mic screen`, and `<Alt><Super>q` →
  `gsr-rec stop`.

### Updating the extension pins

```sh
python3 scripts/update-gnome-extensions.py           # bump the pins
python3 scripts/update-gnome-extensions.py --check   # report only
python3 scripts/update-gnome-extensions.py --shell 51 # target a GNOME version
```

The script asks extensions.gnome.org which builds exist for the target
GNOME version (default: the running shell's), compares them against the
pins, and rewrites `version`/`versionTag`/`sha256` in place. It also diffs
the new build against the pinned one and reports what would break:

- the build no longer lists the target GNOME in its `shell-version`
- the schema moved, or a managed key was removed or changed type
- upstream's newest release has no build for the target GNOME version

**Blocking** findings mean the settings in `modules/gnome-extensions.nix`
no longer match upstream and have to be fixed by hand — the script never
rewrites the *values* of those settings, they are opinions, not pins.

Build gate after a bump: `nix build .#homeConfigurations.silver-hour.activationPackage`.

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
a project's `.envrc.local` — the personal/gitignored hook sourced by the tracked `.envrc`);
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


## Devshell templates

Reusable Nix devShell scaffolds for project-local dev environments, shipped in
`files/devshell-templates/` and materialized on switch into
`~/.local/share/devshell-templates/`. The `devshell-init` helper drops a
template into a target repo. Deployed by `modules/scripts.nix` (every host).

Currently available:

- **`dotnet`** — .NET SDK 10 + `dart-sass` + local-tool-manifest restore + dev
  cert export to `./.certs/` + auto-created `./.envrc.local` personal hook
  (pre-wired with `NVIM_LANGS=...,dotnet` + `use_dotnet_personal EasyDotnet
  lazydotnet`, a direnv stdlib helper from `modules/direnv.nix`). See
  `files/devshell-templates/dotnet/README.md` for adoption details and a
  couple of NLog gotchas worth remembering.
- **`rust`** — `rust-analyzer` + `codelldb` (vscode-lldb standalone adapter)
  on PATH; `./.envrc.local` is auto-created with `NVIM_LANGS=...,rust` so
  nvim's rust extra loads only inside the shell. Toolchain itself comes from
  the host's rustup.
- **`clang`** — `clang-tools` (clangd) + `codelldb` + `cmake`/`neocmakelsp`;
  `./.envrc.local` is auto-created with `NVIM_LANGS=...,clang,cmake` for
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

## Local overrides

`~/.config/zsh/extra.zsh` is materialized once by
`home.activation.materializeZshExtra` and never overwritten. Put per-host
secrets/API keys there.


