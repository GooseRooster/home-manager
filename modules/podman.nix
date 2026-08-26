{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;
in
{
  # Rootless podman socket. On NixOS, `virtualisation.podman.dockerCompat` only
  # exposes the *rootful* /var/run/docker.sock — lazydocker (and any docker CLI
  # client) needs the per-user socket instead, plus DOCKER_HOST pointing at it
  # (set in modules/nushell.nix). This is the declarative equivalent of
  # `systemctl --user enable --now podman.socket`.
  systemd.user.sockets.podman = lib.mkIf cfg.podmanAlias.enable {
    Unit.Description = "Podman API Socket";
    Socket.ListenStream = "%t/podman/podman.sock";
    Socket.SocketMode = "0660";
    Install.WantedBy = [ "sockets.target" ];
  };

  # Mirrors podman's canonical upstream user unit (see the podman package's
  # share/systemd/user/podman.service). The previous ExecStop was broken:
  # `podman system service --timeout=0` doesn't stop a running server, it
  # spawns a new one that then hits systemd's stop timeout and leaves the
  # unit in `failed`, at which point the socket-activated retry loop breaks
  # and lazydocker sees a dead socket. `--time=0` on ExecStart stops the
  # server from self-exiting after 5s of idle (the socket-activation default),
  # which is what was churning the unit into that failure state after a WSL
  # sleep. KillMode=process + no ExecStop lets systemd shut it down cleanly
  # with SIGTERM.
  systemd.user.services.podman = lib.mkIf cfg.podmanAlias.enable {
    Unit = {
      Description = "Podman API Service";
      Requires = [ "podman.socket" ];
      After = [ "podman.socket" ];
      Documentation = "man:podman-system-service(1)";
    };
    Service = {
      Type = "exec";
      KillMode = "process";
      Environment = "LOGGING=--log-level=info";
      ExecStart = "${pkgs.podman}/bin/podman $LOGGING system service --time=0";
      TimeoutStopSec = 30;
    };
  };
}
