{
  config,
  lib,
  pkgs,
  ...
}:

# Session plumbing for the dev bundle (pkgs/dev.nix): what the dotnet devshell
# template sets per project, set here once so repos without a flake work too.
# A devshell's own env attrs override these on entry.
#
# ~/.dotnet/tools is deliberately NOT put on PATH: the global-tool apphosts use
# the host's glibc loader and fail against the Nix runtime (see
# modules/direnv.nix). easy-dotnet finds its tool dll by path, and
# `use_dotnet_personal` in an .envrc.local still provides lazydotnet.
let
  # Same SDK set as pkgs/dev.nix — keep both in sync.
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.sdk_10_0
    pkgs.dotnetCorePackages.sdk_8_0
  ];
in
{
  config = lib.mkIf config.home.bundles.dev.enable {
    home.sessionVariables = {
      DOTNET_ROOT = "${dotnet}/share/dotnet";
      EASY_DOTNET_ROSLYN_DLL_PATH = "${pkgs.roslyn-ls}/lib/roslyn-ls/Microsoft.CodeAnalysis.LanguageServer.dll";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      DOTNET_NOLOGO = "1";
    };

    # rust-analyzer comes from rustup's proxy (pkgs/dev.nix explains why), which
    # errors until the component exists. Best-effort for the default toolchain
    # only: no default toolchain or offline means skip, never fail the switch.
    home.activation.rustAnalyzerComponent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rustup=${pkgs.rustup}/bin/rustup
      if $rustup default >/dev/null 2>&1 \
         && ! $rustup component list --installed 2>/dev/null | grep -q '^rust-analyzer'; then
        run $rustup component add rust-analyzer rust-src \
          || echo "WARN: 'rustup component add rust-analyzer' failed (offline?), skipping." >&2
      fi
    '';
  };
}
