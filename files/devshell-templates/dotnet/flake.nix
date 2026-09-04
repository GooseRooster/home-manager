{
  # Dotnet dev shell — self-contained Nix devShell for .NET projects.
  #
  # Provides:
  #   * .NET SDK 10 (bump the attribute when you need a different major).
  #   * roslyn-ls (Microsoft.CodeAnalysis.LanguageServer) — the C# LSP behind
  #     C# Dev Kit, incl. Razor/Blazor cohosting. Built against the nixpkgs
  #     dotnet runtime, so no dynamically-linked dotnet-tool headaches. Point
  #     your editor's LSP client at `Microsoft.CodeAnalysis.LanguageServer`.
  #   * dart-sass, exposing `sass` on PATH. Drop it from the packages list if
  #     your project has no SCSS.
  #   * .config/dotnet-tools.json restored on shell entry — pin project-shared
  #     tools (nswag, jb, dotnet-ef, ...) there so teammates and CI both use
  #     identical versions. Empty by default; edit to taste.
  #   * A stable ASP.NET Core dev HTTPS cert exported into ./.certs/ and
  #     Kestrel wired at it via env vars (gitignore ./.certs/ in your project).
  #   * ./.dev.local.sh sourced on shell entry if present — the per-developer
  #     personalization hook. See ./.dev.local.sh.example.
  #
  # Entry points:
  #   * direnv users:  `direnv allow`   (auto-activates via .envrc)
  #   * everyone else: `nix develop`
  description = "Dotnet dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Intentionally minimal. Anything project-specific belongs in the
          # dotnet-tools manifest (shared, pinned) or ./.dev.local.sh (personal).
          #
          # Deliberately NOT included:
          #   * openssh — host ssh + agent are already available on the host.
          #   * nodejs  — dart-sass provides the sass binary directly. Add it
          #               back only if you actually need npm.
          packages = with pkgs; [
            dotnetCorePackages.sdk_10_0
            roslyn-ls
            dart-sass
          ];

          # DOTNET_ROOT points the SDK at the nixpkgs-installed layout. Without
          # this, tools that shell out (e.g. NSwag.ConsoleCore) sometimes miss
          # it.
          DOTNET_ROOT = "${pkgs.dotnetCorePackages.sdk_10_0}/share/dotnet";

          # Skip telemetry + first-run banner spam on shell entry.
          DOTNET_CLI_TELEMETRY_OPTOUT = "1";
          DOTNET_NOLOGO = "1";

          shellHook = ''
            # DOTNET_CLI_HOME must be set here (not as an mkShell env attr) so
            # $HOME is expanded by the shell, not treated as a literal string
            # by Nix. Without this, `dotnet` writes first-run state to CWD.
            export DOTNET_CLI_HOME="$HOME"

            # ── PATH: global dotnet tools stay useful for personal additions
            # from ./.dev.local.sh. Local tools are invoked via `dotnet <tool>`.
            export PATH="$HOME/.dotnet/tools:$PATH"

            # ── Restore dotnet local tools (if any pinned in the manifest).
            # Cheap no-op when the manifest hasn't changed; the marker keeps
            # re-entry latency low.
            if [ -f .config/dotnet-tools.json ]; then
              marker=".config/.tools-restored"
              if [ ! -f "$marker" ] \
                 || [ .config/dotnet-tools.json -nt "$marker" ]; then
                echo "==> dotnet tool restore"
                dotnet tool restore >/dev/null && touch "$marker"
              fi
            fi

            # ── Stable dev HTTPS certificate.
            # Exported into ./.certs/ (gitignore it in your project) and pointed
            # at via env below. Trusting the cert on the host is a one-off:
            #     dotnet dev-certs https --trust
            # (Linux/WSL: NSS store, see .NET docs for the manual root-store step.)
            if [ ! -f .certs/localhost.pem ] || [ ! -f .certs/localhost.key ]; then
              mkdir -p .certs
              echo "==> exporting ASP.NET dev cert -> .certs/localhost.{pem,key}"
              dotnet dev-certs https \
                --export-path .certs/localhost.pem \
                --format PEM \
                --no-password >/dev/null
            fi
            export ASPNETCORE_Kestrel__Certificates__Default__Path="$PWD/.certs/localhost.pem"
            export ASPNETCORE_Kestrel__Certificates__Default__KeyPath="$PWD/.certs/localhost.key"

            # ── Personal hook. Gitignored; teammates without one see nothing.
            #    Copy .dev.local.sh.example -> .dev.local.sh to opt in.
            if [ -f ./.dev.local.sh ]; then
              # shellcheck source=/dev/null
              . ./.dev.local.sh
            fi
          '';
        };
      });
    };
}
