{ lib, ... }:

{
  xdg.configFile."topgrade.toml" = {
    source = ../files/topgrade.toml;
    force = true;
  };
}
