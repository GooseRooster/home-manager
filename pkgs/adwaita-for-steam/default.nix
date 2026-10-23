# Adwaita-for-Steam wrapper. Upstream is a pure script collection (no build
# system), so this packages a launcher that runs install.py from a copy of
# the pinned source tree. install.py copies the skin into the mutable
# ~/.steam/steam/steamui, so it must run at *runtime*, not build time.
#
# The launcher stages a writable temp copy first: shutil.copytree preserves
# source modes, and copying straight out of the Nix store would create a
# read-only skin tree in ~/.steam that the installer then can't patch.
{
  lib,
  stdenv,
  python3,
  src,
}:

stdenv.mkDerivation {
  pname = "steam-adwaita-skin";
  version = "unstable";

  inherit src;

  dontBuild = true;

  nativeBuildInputs = [ ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/adwaita-for-steam" "$out/bin"
    cp -r . "$out/lib/adwaita-for-steam/"

    cat > "$out/bin/steam-adwaita-install" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# cp --no-preserve: writable copy, so install.py can patch/customise it
src='@out@/lib/adwaita-for-steam'
cp -r --no-preserve=mode,ownership "$src/." "$work/"
cd "$work"
exec '@python@' install.py "$@"
WRAP

    substituteInPlace "$out/bin/steam-adwaita-install" \
      --subst-var-by out "$out" \
      --subst-var-by python ${lib.getExe python3}

    chmod +x "$out/bin/steam-adwaita-install"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Adwaita for Steam — skin that makes Steam look like a native GNOME app";
    homepage = "https://github.com/tkashkin/Adwaita-for-Steam";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
