{ lib, ... }:

{
  xdg.configFile."starship.toml".source = ../files/starship.toml;
}
