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

    # Local "inherit" flavor — pulls every color from the terminal palette so
    # tinty scheme swaps retint yazi live. Declared declaratively; not fetched.
    flavors = {
      "inherit" = ../files/yazi/flavors/inherit.yazi;
    };
  };

  # Plugin *list* is declared here; the plugins themselves are fetched by yazi's
  # own `ya pkg install` (latest, self-updating) — see files/yazi/package.toml.
  xdg.configFile."yazi/package.toml".source = ../files/yazi/package.toml;

  # Fetch/refresh the plugins declared in package.toml (git on PATH for `ya`).
  home.activation.installYaziPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run() {
      export PATH="${pkgs.git}/bin:${pkgs.yazi}/bin:$PATH"
      ${pkgs.yazi}/bin/ya pkg install
    }
    run
  '';
}
