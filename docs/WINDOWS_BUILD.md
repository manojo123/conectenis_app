# Windows desktop build

## Layout (no spaces in tool paths)

Keep Flutter, pub cache, and this repo on paths **without spaces** so Windows native assets (`path_provider` / `objective_c`) build reliably:

| Path | Purpose |
|------|---------|
| `C:\projects\flutter` | Flutter SDK |
| `C:\projects\conec\conectenis_app` | This app |
| `C:\pub-cache` | Pub package cache (`PUB_CACHE`) |

Optional short junctions (same folders, for typing):

```powershell
# Administrator PowerShell if creation at C:\ fails
cmd /c rmdir C:\flutter 2>nul
cmd /c rmdir C:\conec 2>nul
New-Item -ItemType Junction -Path C:\flutter -Target "C:\projects\flutter"
New-Item -ItemType Junction -Path C:\conec -Target "C:\projects\conec"
```

## User environment (one-time)

Set in **Windows → Environment variables → User**:

- `Path` — include `C:\projects\flutter\bin` (remove any `...\Jorge Moura\projects\flutter\bin` entry)
- `PUB_CACHE` = `C:\pub-cache`

Restart Cursor/terminals after changing env vars.

## Daily workflow

```powershell
cd C:\projects\conec\conectenis_app
flutter run -d windows
```

Or press **F5** with **conectenis_app (Windows)** (workspace sets `PUB_CACHE` and `NUGET_CONFIG`).

After moving the project or SDK, run once:

```powershell
flutter clean
flutter pub get
```

## NuGet / geolocator

If `geolocator_windows` hits **AWS CodeArtifact** timeouts, this repo ships [`nuget.config`](../nuget.config). CMake and the Windows launch config set `NUGET_CONFIG` to it.

## Android

Android builds work from the same project path; `android/local.properties` points at `C:\projects\flutter`.
