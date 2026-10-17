# silver-hour variant of base-extra (home.bundles.baseExtra + silverHour flag).
# The image already installs all Nerd Fonts system-wide (its `fonts` recipe
# module) and ships VS Code natively, so the Silverblue host drops the entire
# font block plus vscode and keeps only the visual/misc extras.
{ pkgs }:

with pkgs;
[
  cava
  chafa
  zk
  lazydocker
  ramalama
  claude-code
  opencode
  devcontainer
  resterm
]
