{
  config, lib, pkgs, tvCable, ...
}:

# Television: community cable channels linked straight from the pinned
# television flake input (see flake.nix — tvCable is cable/unix) — replaces
# the old `bootstrap` step's `tv update-channels`, so channel updates ride
# along with `nix flake update`. Unlike `tv update-channels` (which skips
# channels with unmet requirements at download time), the full set is linked;
# tv handles missing binaries at runtime with a popup when such a channel is
# selected.
let
  # Optionally overlaid with repo-local channels (files/television/cable) —
  # same merge semantics as the nvim overlay.
  cableDir = pkgs.runCommand "television-cable" { } ''
    mkdir -p $out
    cp -r ${tvCable}/. $out/
    chmod -R u+w $out
  '' + lib.optionalString (builtins.pathExists ../files/television/cable) ''
    cp -rf ${../files/television/cable}/. $out/
  '';
in
{
  home.file.".config/television/cable" = {
    source = cableDir;
    recursive = true;
  };
}
