# Devcontainer CLI convenience wrappers (podman-backed).
#
# Each function checks for `devcontainer`/`podman` at call time  -- sourcing this file is always
# safe even on a host without either tool; calling one without them errors
# clearly instead of silently doing nothing.
#
# `--docker-path podman` is required on every devcontainer CLI invocation:
# the CLI spawns a binary literally named `docker`, which doesn't exist here
# (only podman does) -- it does not go through the docker->podman nu alias in
# podman-alias.nu, since that only affects nu's own command dispatch, not
# child processes spawned by other programs.

def devc-require-cli [] {
    if (which devcontainer | is-empty) {
        error make {msg: "devcontainer CLI not found on PATH (npm install -g @devcontainers/cli)"}
    }
    if (which podman | is-empty) {
        error make {msg: "podman not found on PATH"}
    }
}

# Discover .devcontainer/devcontainer.json (named "default") and any
# .devcontainer/<name>/devcontainer.json variants under the cwd.
def devc-configs [] {
    let dir = ".devcontainer"
    if not ($dir | path exists) {
        return []
    }

    let default_path = ($dir | path join "devcontainer.json")
    let default_cfg = if ($default_path | path exists) {
        [{name: "default", path: $default_path}]
    } else {
        []
    }

    let named_cfgs = (
        ls $dir
        | where type == dir
        | each {|d|
            let p = ($d.name | path join "devcontainer.json")
            if ($p | path exists) {
                {name: ($d.name | path basename), path: $p}
            } else {
                null
            }
        }
        | where $it != null
    )

    $default_cfg | append $named_cfgs
}

# Resolve a single config: by name if given, auto-picked if there's only one,
# else an interactive prompt.
def devc-resolve-config [name?: string] {
    let configs = (devc-configs)

    if ($configs | is-empty) {
        error make {msg: "No .devcontainer/devcontainer.json or .devcontainer/*/devcontainer.json found here"}
    }

    if $name != null {
        let found = ($configs | where name == $name)
        if ($found | is-empty) {
            let have = ($configs | get name | str join ", ")
            error make {msg: $"No devcontainer config named '($name)' \(have: ($have)\)"}
        }
        return ($found | get 0)
    }

    if ($configs | length) == 1 {
        return ($configs | get 0)
    }

    let picked_name = ($configs | get name | input list "Multiple devcontainer configs found, pick one:")
    $configs | where name == $picked_name | get 0
}

def devc-container-row [name?: string] {
    let cfg = (devc-resolve-config $name)
    let cwd = ($env.PWD | path expand)
    let cfg_abs = ($cfg.path | path expand)
    let rows = (
        ^podman ps -a
            --filter $"label=devcontainer.local_folder=($cwd)"
            --filter $"label=devcontainer.config_file=($cfg_abs)"
            --format json
        | from json
    )
    if ($rows | is-empty) {
        null
    } else {
        $rows | get 0
    }
}

# Force a full rebuild: removes the existing container and rebuilds the
# image with --no-cache, for fresh dependency installs (not just picking up
# a spec change -- plain `devc up`/`--remove-existing-container` alone
# already does that, since podman's build cache is content-addressed and
# rebuilds any changed instruction on its own; --build-no-cache is only
# needed when the Dockerfile text itself didn't change but you still want
# e.g. apt/cargo/nix to fetch fresh versions).
def "devc rebuild" [name?: string] {
    devc-require-cli
    let cfg = (devc-resolve-config $name)
    ^devcontainer up --docker-path podman --workspace-folder . --config $cfg.path --remove-existing-container --build-no-cache
}

# Start the in-container log bridge if this project ships one, so app logs show up
# in `podman logs`/lazydocker. Idempotent; a no-op for projects without the script.
# Needed because `devcontainer up` reusing an existing (stopped) container does NOT
# re-run postStartCommand -- only a fresh create does, so we start it here too.
def devc-start-log-bridge [cfg_path: string] {
    let bridge = ".devcontainer/scripts/console-log-bridge.sh"
    if ($bridge | path exists) {
        ^devcontainer exec --docker-path podman --workspace-folder . --config $cfg_path -- bash $bridge
    }
}

# Bring the devcontainer up (build/create/start as needed). Idempotent.
def "devc up" [name?: string] {
    devc-require-cli
    let cfg = (devc-resolve-config $name)
    ^devcontainer up --docker-path podman --workspace-folder . --config $cfg.path
    devc-start-log-bridge $cfg.path
}

# Ensure the container is up, then exec a command in it (default: nu).
def --wrapped "devc enter" [name?: string, ...cmd: string] {
    devc-require-cli
    let cfg = (devc-resolve-config $name)
    # Deliberately NOT piped anywhere -- piping an external command's output
    # into another nu command (even `ignore`) makes nu buffer it instead of
    # streaming to the terminal, and `| ignore` specifically discards it
    # entirely rather than showing it late. `up` can take a long time
    # (feature install, postCreateCommand); staying silent that whole time
    # looks exactly like a hang. The one-line trade-off is the final JSON
    # summary from `up` printing before the interactive session starts.
    ^devcontainer up --docker-path podman --workspace-folder . --config $cfg.path
    devc-start-log-bridge $cfg.path
    let shell = if ($cmd | is-empty) { ["nu"] } else { $cmd }
    ^devcontainer exec --docker-path podman --workspace-folder . --config $cfg.path -- ...$shell
}

# Sugar for `devc enter <name> nvim` -- the actual daily-driver command.
def --wrapped "devc nvim" [name?: string, ...args: string] {
    devc enter $name nvim ...$args
}

# Stop the container (leaves it around, just exited) -- the default "done for
# now" action; `devc rm` actually removes it.
def "devc stop" [name?: string] {
    devc-require-cli
    let row = (devc-container-row $name)
    if $row == null {
        print "No matching container."
    } else {
        ^podman stop $row.Id
    }
}

# Remove the container entirely (does not touch the built image).
def "devc rm" [name?: string] {
    devc-require-cli
    let row = (devc-container-row $name)
    if $row == null {
        print "No matching container."
    } else {
        ^podman rm $row.Id
    }
}

# Copy the host's env.local.nu into the container's ~/.config/nushell/, so
# host-specific shell env vars follow you into the devcontainer. Overwrites any
# existing copy. `devcontainer exec` forwards stdin when not on a TTY, so the
# host file is piped in via `cat` (nu has no `<` redirect for externals).
def "devc copy-env" [name?: string] {
    devc-require-cli
    let cfg = (devc-resolve-config $name)
    let host_src = ($nu.default-config-dir | path join "env.local.nu")
    if not ($host_src | path exists) {
        error make {msg: $"Host env.local.nu not found at ($host_src)"}
    }
    let row = (devc-container-row $name)
    if $row == null or $row.State != "running" {
        devc up $name
    }
    open --raw $host_src
        | ^devcontainer exec --docker-path podman --workspace-folder . --config $cfg.path -- bash -c 'mkdir -p ~/.config/nushell && cat > ~/.config/nushell/env.local.nu'
}

# List every devcontainer (any config) tied to the current workspace.
def "devc ps" [] {
    devc-require-cli
    let cwd = ($env.PWD | path expand)
    let configs = (devc-configs | each {|c| {path: ($c.path | path expand), name: $c.name} })
    let rows = (
        ^podman ps -a --filter $"label=devcontainer.local_folder=($cwd)" --format json
        | from json
    )
    $rows | each {|r|
        let cfg_path = ($r.Labels | get "devcontainer.config_file"? | default "")
        let cfg_name = ($configs | where path == $cfg_path | get name? | get 0? | default $cfg_path)
        {
            name: ($r.Names | get 0)
            config: $cfg_name
            state: $r.State
            status: $r.Status
        }
    }
}
