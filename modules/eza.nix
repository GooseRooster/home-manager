{ ... }:

# eza — a modern `ls` replacement. Only wired into zsh (see modules/zsh.nix);
# nushell has no ls/ll/la aliases today and this doesn't add any, so its
# behavior there is unchanged.
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    colors = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
