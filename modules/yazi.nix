{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # Gaming-specific bunny hops, spliced into init.lua when gaming.enable is set.
  # Two leading tabs match the surrounding hop lines in files/yazi/init.lua.
  gamingHops = ''
		{ key = "m", path = "~/Modding/", desc = "Modding" },
		{ key = "e", path = "~/Emulation", desc = "Emulation" },
		{ key = "s", path = "~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common", desc = "Steam Library" },
'';

  # yazi plugin sources — pinned to the same revs chezmoi's package.toml used.
  # NOTE: `lib.fakeHash` stands in until the first build; run once and paste the
  # reported hashes (standard Nix workflow). See README "First build".
  fetchPlugin = { owner, repo, rev }: pkgs.fetchFromGitHub {
    inherit owner repo rev;
    hash = lib.fakeHash;
  };

  yaziPluginsRepo = fetchPlugin { owner = "yazi-rs"; repo = "plugins"; rev = "4c63ed3"; };

  plugins = {
    full-border = "${yaziPluginsRepo}/full-border.yazi";
    recycle-bin = fetchPlugin { owner = "uhs-robert"; repo = "recycle-bin"; rev = "82da16a"; };
    bunny = fetchPlugin { owner = "stelcodes"; repo = "bunny"; rev = "71b14a3"; };
    compress = fetchPlugin { owner = "KKV9"; repo = "compress"; rev = "e60e122"; };
    starship = fetchPlugin { owner = "Rolv-Apneseth"; repo = "starship"; rev = "159eaba"; };
    mount = "${yaziPluginsRepo}/mount.yazi";
    what-size = fetchPlugin { owner = "pirafrank"; repo = "what-size"; rev = "179ebf6"; };
    yatline = fetchPlugin { owner = "imsi32"; repo = "yatline"; rev = "c5d4b48"; };
    yatline-modified-time = fetchPlugin { owner = "wekauwau"; repo = "yatline-modified-time"; rev = "2d33471"; };
    yatline-selected-size = fetchPlugin { owner = "pakhromov"; repo = "yatline-selected-size"; rev = "7d9402a"; };
    yatline-disk-usage = fetchPlugin { owner = "pakhromov"; repo = "yatline-disk-usage"; rev = "77bdde7"; };
    yatline-created-time = fetchPlugin { owner = "wekauwau"; repo = "yatline-created-time"; rev = "7cd5e21"; };
    simple-status = fetchPlugin { owner = "Ape"; repo = "simple-status"; rev = "d0da104"; };
    ouch = fetchPlugin { owner = "ndtoan96"; repo = "ouch"; rev = "406ce6c"; };
    yatline-githead = fetchPlugin { owner = "imsi32"; repo = "yatline-githead"; rev = "929e52c"; };
    linemode-plus = fetchPlugin { owner = "barbanevosa"; repo = "linemode-plus"; rev = "4d0d034"; };
    mediainfo = fetchPlugin { owner = "boydaihungst"; repo = "mediainfo"; rev = "e079a00"; };
  };

in
{
  programs.yazi = {
    enable = true;

    settings = lib.importTOML ../files/yazi/yazi.toml;
    keymap = lib.importTOML ../files/yazi/keymap.toml;
    theme = lib.importTOML ../files/yazi/theme.toml;

    initLua = builtins.replaceStrings
      [ "{{ GAMING_HOPS }}" ]
      [ (lib.optionalString cfg.gaming.enable gamingHops) ]
      (builtins.readFile ../files/yazi/init.lua);

    inherit plugins;

  };
}
