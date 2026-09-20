{ config, lib, pkgs, ... }:

let
  cfg = config.home.modules;

  # Gaming-specific bunny hops, spliced into init.lua when gaming.enable is set.
  # Two leading tabs match the surrounding hop lines in files/yazi/init.lua.
  gamingHops = ''
		{ key = "m", path = "~/Modding/", desc = "Modding" },
		{ key = "e", path = "~/Emulation", desc = "Emulation" },
		{ key = "s", path = "~/.local/share/Steam/steamapps/common", desc = "Steam Library" },
'';

  # yazi plugins, declaratively pinned to a rev + hash (from the old
  # package.toml). Update a plugin by bumping its rev/hash (or via CI PRs).
  fetchPlugin = { owner, repo, rev, hash }: pkgs.fetchFromGitHub {
    inherit owner repo rev hash;
  };

  # full-border and mount live in the official yazi-rs/plugins monorepo.
  pluginsRepo = fetchPlugin {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "f703392df78b5fba5e8f9f1ad0b1cb6d3def9736";
    hash = "sha256-O1yYAhsf7xMqUrTTSLac06WSxCvUQqedH3DWqGwn/Ok=";
  };

  plugins = {
    full-border = "${pluginsRepo}/full-border.yazi";
    recycle-bin = fetchPlugin { owner = "uhs-robert"; repo = "recycle-bin.yazi"; rev = "fe48a02778574b59ea15e289895f896a4e7e14eb"; hash = "sha256-ghmjM4jmXNC4+P2sl70UhI+8Vv5k3PZV7AwV7iBj1I4="; };
    bunny = fetchPlugin { owner = "stelcodes"; repo = "bunny.yazi"; rev = "71b14a3d624572f4884354c2e218296e9ece07cc"; hash = "sha256-uQO0C00yOFPWq8KEO/kEZM6tFZRc9SiXfgN7kzlwDeA="; };
    compress = fetchPlugin { owner = "KKV9"; repo = "compress.yazi"; rev = "80e5268ec74c7ac17d4d739e13a9958cba4c70d3"; hash = "sha256-9cdA8D/TtwHcLqrtoyIixA0YJmTs+c8FSNrjxp8CYI0="; };
    starship = fetchPlugin { owner = "Rolv-Apneseth"; repo = "starship.yazi"; rev = "ea92cf49380466f07231c952b409831e6afd2156"; hash = "sha256-Jvoc/7YaOOppu8K2lJaVgiuBIyanRHHjEA6ZvnrFtiQ="; };
    mount = "${pluginsRepo}/mount.yazi";
    what-size = fetchPlugin { owner = "pirafrank"; repo = "what-size.yazi"; rev = "1cb456f8c428a393a65708b45b8c56404d52f326"; hash = "sha256-lhanC44L4haM7cgqCOhfxk0Rpi/FueBgIdXDiXuzevc="; };
    yaziline = fetchPlugin { owner = "llanosrocas"; repo = "yaziline.yazi"; rev = "029b27d55361b4b87d0982237f9730b49b4e7a3a"; hash = "sha256-oYvbhAi1xHn8XKgnwBYrHBqRReX4kJDkmSTs15RS/2U="; };
    ouch = fetchPlugin { owner = "ndtoan96"; repo = "ouch.yazi"; rev = "596b66697f40fd8b36f1063fed22f64354f74c1f"; hash = "sha256-RW49EJiEyPodkKpUd0Ad0ztr/obODpC6ShWIee8aT3Q="; };
    linemode-plus = fetchPlugin { owner = "barbanevosa"; repo = "linemode-plus.yazi"; rev = "4d0d034c08aaa7c62666456ce4f0d63f1ac4eda5"; hash = "sha256-ekQI1yyZEmX44YjicFz51Eh6csN9OwVXoh8Ituk/jJs="; };
    mediainfo = fetchPlugin { owner = "boydaihungst"; repo = "mediainfo.yazi"; rev = "f1cec0b43a6b5904e1638ad050f044c4eb1383da"; hash = "sha256-p+wfTgQ4Td7Q/AIzsECzijam3NcPXxEPrpnUnT/028E="; };
    sduf = fetchPlugin { owner = "shafayetejaman"; repo = "sduf.yazi"; rev = "f43ba4afd1a1192a4f59c9ac63bf534a9bb26124"; hash = "sha256-Ey9bJSb4Vewv28rZIcdgc2dwcRTt+dvyt6Upl9cIsKc="; };
  };
in
{
  programs.yazi = {
    enable = true;

    # We define our own `y` (cd-on-exit) wrapper in config.nu — don't add
    # yazi's, or nushell sees `y` twice.
    enableNushellIntegration = false;

    settings = lib.importTOML ../files/yazi/yazi.toml;
    keymap = lib.importTOML ../files/yazi/keymap.toml;
    theme = lib.importTOML ../files/yazi/theme.toml;

    initLua = builtins.replaceStrings
      [ "{{ GAMING_HOPS }}" ]
      [ (lib.optionalString cfg.gaming.enable gamingHops) ]
      (builtins.readFile ../files/yazi/init.lua);

    inherit plugins;

    # Local "inherit" flavor — pulls every color from the terminal palette so
    # tinty scheme swaps retint yazi live. Declared declaratively; not fetched.
    flavors = {
      "inherit" = ../files/yazi/flavors/inherit.yazi;
    };
  };

  # force: HM owns these even if a pre-existing file is present.
  xdg.configFile = {
    "yazi/yazi.toml".force = true;
    "yazi/keymap.toml".force = true;
    "yazi/theme.toml".force = true;
    "yazi/init.lua".force = true;
    "yazi/flavors/inherit.yazi".force = true;
  };
}
