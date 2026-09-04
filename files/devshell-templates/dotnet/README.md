# dotnet — devshell template

Self-contained Nix devShell for .NET web/service projects. Drop into a repo
via `devshell-init dotnet` (see `~/repos/home-manager` for the scaffolder).

## What ships

- **`.NET SDK 10`** via nixpkgs `dotnetCorePackages.sdk_10_0`.
- **`dart-sass`** exposing `sass` on PATH for SCSS builds. Drop from
  `packages` if unused.
- **`.config/dotnet-tools.json`** — pinned local tool manifest, empty by
  default. Add project-shared tools here (nswag, jb ReSharper CLI,
  dotnet-ef, ...); `dotnet tool restore` runs on shell entry.
- **`.envrc`** — `use flake` plus `NVIM_LANGS=...,dotnet`, so nvim's dotnet
  feature (easy-dotnet/Roslyn LSP, Razor support) loads only inside this
  shell.
- **`.certs/localhost.{pem,key}`** exported from `dotnet dev-certs https`
  on first shell entry, with `ASPNETCORE_Kestrel__Certificates__Default__*`
  env vars pre-set to point at them.
- **`./.dev.local.sh`** sourced if present — the per-developer hook. Copy
  `.dev.local.sh.example` to opt in.

## Adoption checklist

After `devshell-init dotnet`:

1. Append to the target repo's `.gitignore`:
   ```
   /.certs/
   /.dev.local.sh
   /.direnv/
   /.envrc.local
   /.config/.tools-restored
   ```
2. Trust the dev cert on your host once:
   ```
   dotnet dev-certs https --trust
   ```
   (Linux/WSL: NSS-store step is manual — see .NET docs.)
3. Enter the shell: `direnv allow` or `nix develop`.
4. Populate `.config/dotnet-tools.json` with any tools the project needs,
   then `dotnet tool restore`.
5. (Optional) `cp .dev.local.sh.example .dev.local.sh` and edit for personal
   tools / env vars / aliases.

## NLog: repo-local log file for `tail -F`

Two gotchas hit while wiring an NLog debug-only file target into a project
that uses this template. Captured here because they'll bite again next time.

### 1. NLog config gets reloaded during `builder.Build()`

`NLog.Web.UseNLog()` registers a `ConfigureServices` callback that, when
`builder.Build()` fires, reloads NLog config from `appsettings.json`. Any
targets/rules added to `LogManager.Configuration` *before* `Build()` are
wiped. Add them *after*:

```csharp
var app = builder.Build();

#if DEBUG
    // ... construct FileTarget, add rules ...
    LogManager.ReconfigExistingLoggers();
#endif
```

### 2. Relative `FileName` resolves to `bin/<Config>/<TFM>/`

`FileTarget.FileName` is resolved against `AppContext.BaseDirectory`, not
the CWD. A relative `"logs/console-dev.log"` lands in
`bin/Debug/net10.0/logs/`, not the project source dir — invisible to a dev
tailing `<project>/logs/`. Resolve to an absolute path from
`AppContext.BaseDirectory`:

```csharp
var projectDir = Path.GetFullPath(Path.Combine(
    AppContext.BaseDirectory, "..", "..", ".."));
var devLogPath = Path.Combine(projectDir, "logs", "console-dev.log");
```

Three levels up from `bin/<Config>/<TFM>/` lands on the project source dir.
Gate the whole block on `#if DEBUG` so `dotnet publish` scenarios (different
layout) are never in scope.
