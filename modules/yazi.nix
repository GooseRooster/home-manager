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
    rev = "4dc7f1b6458c2578f4494f10d468c68c1082214f";
    hash = "sha256-BSAOkL4H4LVMbTRFv4kzGGRpLgtKkfNTEsDH2EQ219Q=";
  };

  plugins = {
    full-border = "${pluginsRepo}/full-border.yazi";
    recycle-bin = fetchPlugin { owner = "uhs-robert"; repo = "recycle-bin.yazi"; rev = "fe48a02778574b59ea15e289895f896a4e7e14eb"; hash = "sha256-ghmjM4jmXNC4+P2sl70UhI+8Vv5k3PZV7AwV7iBj1I4="; };
    bunny = fetchPlugin { owner = "stelcodes"; repo = "bunny.yazi"; rev = "71b14a3d624572f4884354c2e218296e9ece07cc"; hash = "sha256-uQO0C00yOFPWq8KEO/kEZM6tFZRc9SiXfgN7kzlwDeA="; };
    compress = fetchPlugin { owner = "KKV9"; repo = "compress.yazi"; rev = "80e5268ec74c7ac17d4d739e13a9958cba4c70d3"; hash = "sha256-9cdA8D/TtwHcLqrtoyIixA0YJmTs+c8FSNrjxp8CYI0="; };
    starship = fetchPlugin { owner = "Rolv-Apneseth"; repo = "starship.yazi"; rev = "ea92cf49380466f07231c952b409831e6afd2156"; hash = "sha256-Jvoc/7YaOOppu8K2lJaVgiuBIyanRHHjEA6ZvnrFtiQ="; };
    mount = "${pluginsRepo}/mount.yazi";
    what-size = fetchPlugin { owner = "pirafrank"; repo = "what-size.yazi"; rev = "1cb456f8c428a393a65708b45b8c56404d52f326"; hash = "sha256-lhanC44L4haM7cgqCOhfxk0Rpi/FueBgIdXDiXuzevc="; };
    yaziline = fetchPlugin { owner = "llanosrocas"; repo = "yaziline.yazi"; rev = "2c4ffc78c18042d1b3ab91ac8fd55bb661f10437"; hash = "sha256-Z9Zzv+QF3+dBGQFa8oqLiZjGPPPaW3a5q4CIZWBnLSI="; };
    ouch = fetchPlugin { owner = "ndtoan96"; repo = "ouch.yazi"; rev = "cfe4f507ef7337c8ad4c90eef68ea91fc6694759"; hash = "sha256-t1kUo4+YODeTG9d5Yq/vxElcmRHIebC5TRv+uDGG88c="; };
    linemode-plus = fetchPlugin { owner = "barbanevosa"; repo = "linemode-plus.yazi"; rev = "4d0d034c08aaa7c62666456ce4f0d63f1ac4eda5"; hash = "sha256-ekQI1yyZEmX44YjicFz51Eh6csN9OwVXoh8Ituk/jJs="; };
    mediainfo = fetchPlugin { owner = "boydaihungst"; repo = "mediainfo.yazi"; rev = "d2dd310bfbc3a819acf1c9c9c32f402ab6774d3a"; hash = "sha256-nmhn2lcs5F+MRlmqBPbsU74NNiO0Y0Js4YEjRfD9IPE="; };
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
