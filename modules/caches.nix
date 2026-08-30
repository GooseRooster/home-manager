{ lib, pkgs, ... }:

# tealdeer: auto-refresh the tldr page cache on use (replaces `tldr --update`).
# The binary comes from nix-cli's #base bundle
{
  programs.tealdeer = {
    enable = true;
    package = pkgs.emptyDirectory;
    # The weekly tldr-update timer would exec the empty package above. The
    # on-use auto_update below (the pre-native behavior) refreshes the cache.
    enableAutoUpdates = false;
    settings.updates.auto_update = true;
  };
}
