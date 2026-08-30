{ lib, pkgs, ... }:

# tealdeer: auto-refresh the tldr page cache on use (replaces `tldr --update`).
{
  programs.tealdeer = {
    enable = true;
    # Keep the on-use auto_update (the pre-native behavior); the weekly
    # HM-provided timer stays off.
    enableAutoUpdates = false;
    settings.updates.auto_update = true;
  };
}
