# ConecTenis — Backend integration

## Laravel API (Sail / WSL)

| Item | Value |
|------|--------|
| WSL path | `/home/jmoura/projects/conec/conectenis` |
| Windows path | `\\wsl.localhost\Ubuntu\home\jmoura\projects\conec\conectenis` |
| Sail URL (from Windows) | `http://localhost:8000` |
| API base URL | `http://localhost:8000/api` |
| Android emulator | `http://10.0.2.2:8000/api` |
| Physical device (LAN) | `http://<your-pc-ip>:8000/api` |

Start API (from Windows):

```bash
wsl -d Ubuntu -- bash -lc "cd ~/projects/conec/conectenis && ./vendor/bin/sail up -d"
```

## Mock vs live API

| `USE_MOCK_API` | Behavior |
|----------------|----------|
| `true` (default) | Map, players, courts, chat, matches use in-app mock data (Jundiaí seeds). |
| `false` | All feature endpoints call Laravel (requires routes from `openapi.yaml` to be implemented). |

**Auth always uses the live Laravel API** (register, login, logout, user, forgot/reset password), regardless of `USE_MOCK_API`.

## Auth (`/api/auth/*`, Sanctum bearer token)

| Method | Path | Body | Response |
|--------|------|------|----------|
| `POST` | `/api/auth/register` | `name`, `email`, `password`, `password_confirmation`, `device_name` | `201` — `{ token, token_type, user }` |
| `POST` | `/api/auth/login` | `email`, `password`, `device_name` | `200` — `{ token, token_type, user }` |
| `GET` | `/api/auth/user` | Bearer token | `200` — `{ id, name, email, email_verified_at, roles }` |
| `POST` | `/api/auth/logout` | Bearer token | `200` — `{ message }` |
| `POST` | `/api/auth/forgot-password` | `email` | `200` — `{ message }` |
| `POST` | `/api/auth/reset-password` | `token`, `email`, `password`, `password_confirmation` | `200` — `{ message }` |

Legacy alias: `POST /api/sanctum/token` (same as login).

Password reset emails link to `conectenis://reset-password?token=...&email=...` (configured in Laravel `MOBILE_PASSWORD_RESET_URL`).

## Flutter environment

Copy `.env.example` to `.env`:

```env
API_BASE_URL=http://localhost:8000/api
USE_MOCK_API=true
```

Set `API_BASE_URL` per platform (see table above). Auth works with Sail running; other features can stay on mock until API routes exist.

Global user session: `authStateProvider` (Riverpod) — `ref.watch(authStateProvider).value` gives `UserProfile?` (`id`, `name`, `email`, `roles`, plus local onboarding fields).

## Windows build (NuGet / geolocator)

If `geolocator_windows` fails on **AWS CodeArtifact** timeout, this project ships [`nuget.config`](../nuget.config) (nuget.org only). CMake sets `NUGET_CONFIG` automatically.

If you still see CodeArtifact, disable the feed in your user config:

```powershell
# Edit %APPDATA%\NuGet\NuGet.Config and remove the "3 Birds Nuget - AWS" source, or:
dotnet nuget disable source "3 Birds Nuget - AWS"
```

If build fails on **native assets** / `objective_c`, see **[WINDOWS_BUILD.md](WINDOWS_BUILD.md)** (`PUB_CACHE` and paths without spaces).

## Reverb

When Reverb is enabled on the API, set `REVERB_*` in `.env` to match Laravel `.env`.
