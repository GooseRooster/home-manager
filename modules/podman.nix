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

  systemd.user.services.podman = lib.mkIf cfg.podmanAlias.enable {
    Unit = {
      Description = "Podman API Service";
      Requires = [ "podman.socket" ];
      After = [ "podman.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.podman}/bin/podman system service";
      ExecStop = "${pkgs.podman}/bin/podman system service --timeout=0";
    };
  };
}
