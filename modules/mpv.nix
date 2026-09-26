{ config, lib, ... }:

let
  cfg = config.home.modules;

  # GUI/desktop-only configs are skipped on WSL.
  desktopOnly = !cfg.wsl.enable;
in
lib.mkIf desktopOnly {
  # mpv.conf is declarative here; the file is picked up by external/flatpak
  # mpv runs.
  home.file.".config/mpv/mpv.conf" = {
    force = true;
    text = lib.generators.toKeyValue { } {
      vo = "gpu-next";
      gpu-api = "vulkan";
      hwdec = "vaapi";
      hwdec-codecs = "all";
      deband = "yes";
      dither-depth = "auto";
      panscan = "0.8";
      pipewire-buffer = "50";
      target-peak = "1000";
    };
  };
}
