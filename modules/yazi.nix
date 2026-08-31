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
    rev = "c591a36e7263e95497715d525e9c46c2f0a880ac";
    hash = "sha256-mWT0yF2iG9+gYEuNiffpM93POlBqY+QKdFh5jSAxYls=";
  };

  plugins = {
    full-border = "${pluginsRepo}/full-border.yazi";
    recycle-bin = fetchPlugin { owner = "uhs-robert"; repo = "recycle-bin.yazi"; rev = "fe48a02778574b59ea15e289895f896a4e7e14eb"; hash = "sha256-ghmjM4jmXNC4+P2sl70UhI+8Vv5k3PZV7AwV7iBj1I4="; };
    bunny = fetchPlugin { owner = "stelcodes"; repo = "bunny.yazi"; rev = "71b14a3d624572f4884354c2e218296e9ece07cc"; hash = "sha256-uQO0C00yOFPWq8KEO/kEZM6tFZRc9SiXfgN7kzlwDeA="; };
    compress = fetchPlugin { owner = "KKV9"; repo = "compress.yazi"; rev = "80e5268ec74c7ac17d4d739e13a9958cba4c70d3"; hash = "sha256-9cdA8D/TtwHcLqrtoyIixA0YJmTs+c8FSNrjxp8CYI0="; };
    starship = fetchPlugin { owner = "Rolv-Apneseth"; repo = "starship.yazi"; rev = "ea92cf49380466f07231c952b409831e6afd2156"; hash = "sha256-Jvoc/7YaOOppu8K2lJaVgiuBIyanRHHjEA6ZvnrFtiQ="; };
    mount = "${pluginsRepo}/mount.yazi";
    what-size = fetchPlugin { owner = "pirafrank"; repo = "what-size.yazi"; rev = "ec94d9a8496241d91dcfb2a864214871c326ddc5"; hash = "sha256-slM9qypEy8A4l3KodE7bmyixA+1c4X7hgoGcQP7R25k="; };
    yatline = fetchPlugin { owner = "imsi32"; repo = "yatline.yazi"; rev = "c5d4b487d6277dd68ea9d3c6537641bf4ae9cf8e"; hash = "sha256-HjTRAfUHs6vlEWKruQWeA2wT/Mcd+WEHM90egFTYcWQ="; };
    yatline-modified-time = fetchPlugin { owner = "wekauwau"; repo = "yatline-modified-time.yazi"; rev = "2d334719fc24ca034e46affb05187bcb2ee55225"; hash = "sha256-sus3GNM6CEfL5AmhJfRLT56MH3+xU20vcIfW9+C1RLg="; };
    yatline-selected-size = fetchPlugin { owner = "pakhromov"; repo = "yatline-selected-size.yazi"; rev = "d15f43104d925dea9aa67e74d739e21b3f7fb71e"; hash = "sha256-+KUXxnsrHNKVthmSvY3YdSPcX8gdAOmc0e84uYJc+1U="; };
    yatline-disk-usage = fetchPlugin { owner = "pakhromov"; repo = "yatline-disk-usage.yazi"; rev = "77bdde75ba6da9ac585bf0111b03b18974ada862"; hash = "sha256-VOmQS6IQ1Ik8H9ijOL+OecX4RB0ZREsJToRVKuNVhv4="; };
    yatline-created-time = fetchPlugin { owner = "wekauwau"; repo = "yatline-created-time.yazi"; rev = "7cd5e216554b0d6fcfd04bcde617726194a110ba"; hash = "sha256-yhm/tzRHBL011Gp+bOqT+Ck/0BcR5smo49Gqfv0L3oI="; };
    simple-status = fetchPlugin { owner = "Ape"; repo = "simple-status.yazi"; rev = "d0da1049c417c2d5eec8bf5171ff9aad5c2ae773"; hash = "sha256-c6Y8qMnZAA/azV7lCqzwXN2qlgWi6BS6B0nInbR/sb4="; };
    ouch = fetchPlugin { owner = "ndtoan96"; repo = "ouch.yazi"; rev = "cfe4f507ef7337c8ad4c90eef68ea91fc6694759"; hash = "sha256-t1kUo4+YODeTG9d5Yq/vxElcmRHIebC5TRv+uDGG88c="; };
    yatline-githead = fetchPlugin { owner = "imsi32"; repo = "yatline-githead.yazi"; rev = "929e52cd6ff9ef0130756260ee5f0af69ce5debe"; hash = "sha256-1r7AY0Yzr32YZl2g74ylx+1vGoNg04PMkDXnaB0X+lk="; };
    linemode-plus = fetchPlugin { owner = "barbanevosa"; repo = "linemode-plus.yazi"; rev = "4d0d034c08aaa7c62666456ce4f0d63f1ac4eda5"; hash = "sha256-ekQI1yyZEmX44YjicFz51Eh6csN9OwVXoh8Ituk/jJs="; };
    mediainfo = fetchPlugin { owner = "boydaihungst"; repo = "mediainfo.yazi"; rev = "73a36587bd896a20a0c84c0b79b341a0cb7e7b92"; hash = "sha256-cdIVIqVxsr+V1I/pqAhr2dxfujTL/de7DFTAOd2jfUk="; };
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
