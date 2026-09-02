# ── General nu config ───────────────────────────────────────────────────────
$env.config.show_banner = false
$env.config.edit_mode = 'vi'


# ── Aliases ──────────────────────────────────────────────────────────────────
# export alias grep = rg
alias chrome = ungoogled-chromium
alias python = python3


# ── Functions: misc ───────────────────────────────────────────────────────────
def get-os-release-field [field: string] {
  open /etc/os-release
  | lines
  | where {|l| $l starts-with $"($field)="}
  | get -o 0
  | default ""
  | str replace $"($field)=" ""
  | str trim -c '"'
}

# Nerd-font glyph for the running distro, used to build the __OS_KEY__ prefix
# ("╭─" + glyph) substituted into the fastfetch config. Each `pattern` is matched
# as a case-insensitive regex against ID / ID_LIKE / VARIANT_ID / IMAGE_ID from
# /etc/os-release, top-down — so the first (most-specific) row wins. Universal Blue
# images and distro derivatives are listed before their base distro on purpose.
# Fill in the nerd-font glyph for each distro you want branded; rows left "" (or an
# unmatched distro) fall back to the plain "╭─".
def distro-glyph [] {
  let ident = (
    [ID ID_LIKE VARIANT_ID IMAGE_ID]
    | each {|f| get-os-release-field $f }
    | str join " "
    | str lowercase
  )

  let table = [
    [pattern     glyph];
    # ── Universal Blue images (match before their Fedora base) ──
    [bluefin     "󱍢"]
    # ── derivatives (match before the distro they are built on) ──
    [manjaro     ""]
    [endeavouros ""]
    [mint        "󰣭"]
    [pop         ""]
    [kali        ""]
    [rocky       ""]
    [alma        ""]
    [centos      ""]
    # ── base distros ──
    [fedora      ""]
    [ubuntu      ""]
    [debian      ""]
    [arch        ""]
    [opensuse    ""]
    [nixos       ""]
    [gentoo      ""]
    [alpine      ""]
    [void        ""]
    [rhel        "󱄛"]
  ]

  $table
  | where {|row| $ident =~ $row.pattern }
  | get -o 0.glyph
  | default ""
}

def fastfetch [...args: string] {
  # Only want the greeting to fire if we are not within a container
  # (distrobox sets CONTAINER_ID).
  if not ("CONTAINER_ID" in $env) {
    let ff_dir    = ($nu.home-dir | path join ".config" "fastfetch")
    let config    = ($ff_dir | path join "config.jsonc")
    let logo_file = ($ff_dir | path join "logo.txt")   # per-machine, never committed to dotfiles

    if not ($config | path exists) {
      # custom config not deployed on this machine yet — fall back to plain fastfetch
      ^fastfetch ...$args
    } else {
      let is_bluefin = (
        (get-os-release-field "VARIANT_ID") == "bluefin"
        or (get-os-release-field "IMAGE_ID") == "bluefin"
      )

      let os_key = $"╭─(distro-glyph)"

      let ublue_ff_conf = "/etc/ublue-os/fastfetch.json"
      let bluefin_logo_dir = if ($ublue_ff_conf | path exists) {
        (open $ublue_ff_conf | get -o logo-directory | default "/usr/share/ublue-os/fastfetch")
      } else {
        "/usr/share/ublue-os/fastfetch"
      }

      let logo_flags = if ($logo_file | path exists) {
        ["--file" $logo_file]
      } else if $is_bluefin and ($bluefin_logo_dir | path exists) {
        let pick = (ls $bluefin_logo_dir | get name | shuffle | first)
        ["--file-raw" $pick]
      } else {
        []   # fastfetch falls back to its own builtin distro logo
      }

      let tmp = (mktemp -t "fastfetch-config.XXXXXX.jsonc" | str trim)
      open $config --raw | str replace --all "__OS_KEY__" $os_key | save -f $tmp
      ^fastfetch --config $tmp ...$logo_flags ...$args
      rm -f $tmp
    }
  }
}


# ── Functions: navigation ─────────────────────────────────────────────────────
# Dotfile listing
def "l." [] {
    ls -a | where name =~ '^\.'
}

# Yazi — cd on exit
def --env y [...args: string] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX" | str trim)
    yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp | str trim)
    if $cwd != "" and $cwd != $env.PWD and ($cwd | path type) == "dir" {
        cd $cwd
    }
    rm -f $tmp
}

# Make a dir and cd into it
def --env mkcd [name: string] {
    mkdir $name
    cd $name
}

# Home, clear, greeting
def --env home [] {
    cd ~
    clear
    fastfetch
}

# Notebook, for use with zk
def --env notebook [] {
  cd ~
  mkdir notes
  cd notes
}

# ── Functions: file ops ───────────────────────────────────────────────────────
# Backup a file
def backup [filename: path] {
    cp $filename $"($filename).bak"
}

# Smart copy — auto-recurse if source is a directory
def copy [...args: string] {
    if ($args | length) == 2 and ($args.0 | path type) == "dir" {
        let from = ($args.0 | str trim --right --char "/")
        cp -r $from $args.1
    } else {
        cp ...$args
    }
}


# ── Functions: Containers and VMs ───────────────────────────────────────────────────────
# Distrobox: enter container, drop into nu (nu is on PATH via Nix).
def dbx [name: string] {
  ^distrobox enter $name -- nu
}


# ── Custom completions ────────────────────────────────────────────────────────
# Carapace - see env.nu for script bootstrap
# Should handle the vast majority of things
source $"($nu.cache-dir)/carapace.nu"

# dotnet - we delegate to dotnet's built in completion library.
def "nu-complete dotnet" [context: string] {
    dotnet complete $context | lines
}

export extern "dotnet" [
    ...args: string@"nu-complete dotnet"
]


# ── Prompt & shell integrations ───────────────────────────────────────────────
let autoload_dir = ($nu.data-dir | path join "vendor/autoload")
mkdir $autoload_dir

# starship - the pretty prompt that shows things like toolchain version and git branch
try-cmd-init "starship" { starship init nu | save -f ($autoload_dir | path join "starship.nu") }

# See env.nu for script bootstrap - zoxide makes folder nav way easier.
source ~/.zoxide.nu


# Podman/docker integration (DOCKER_HOST + `docker`→podman alias).
# Templated by chezmoi on podman_alias_enabled; a no-op comment file when off.
source ~/.config/nushell/podman-alias.nu


# ── Greeting ───────────────────────────────────────────────────────────────────
# Gated on is-interactive: `nu --lsp` (spawned by editors as a language
# server) and `nu -c ...` also load this file, and both read/write raw
# protocol data or script output on stdout. Unguarded output here — like
# this banner — gets mixed into that stream and corrupts it (e.g. neovim's
# LSP client fails to find "Content-Length" because fastfetch's art is
# sitting in front of it).
if $nu.is-interactive {
    fastfetch
}
