# ConecTenis — Backend integration

## Laravel API (Sail / WSL)

| Item | Value |
|------|--------|
| WSL path | `/home/jmoura/projects/conec/conectenis` |
| Windows path | `\\wsl.localhost\Ubuntu\home\jmoura\projects\conec\conectenis` |
| Sail URL (from Windows) | `http://localhost` (port **80**) |
| API base URL | `http://localhost/api` |
| Android emulator | `http://10.0.2.2/api` |
| Physical device (LAN) | `http://<your-pc-ip>/api` |

Start API (from Windows):

```bash
wsl -d Ubuntu -- bash -lc "cd ~/projects/conec/conectenis && ./vendor/bin/sail up -d"
```

## Mock vs live API

| `USE_MOCK_API` | Behavior |
|----------------|----------|
| `true` (default) | Map, players, places, invitations, chat, matches use in-app mock data (Jundiaí seeds). |
| `false` | Map, players, places, invitations, and chat call Laravel. Match logging may still be mock-only. |

**Auth always uses the live Laravel API** (register, login, logout, user, forgot/reset password), regardless of `USE_MOCK_API`.

Seeded admin (after `sail artisan db:seed`): `admin@conec.com.br` / `12345678`. Demo players use password `password`.

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
API_BASE_URL=http://localhost/api
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

## Places (`/api/places/*`)

| Method | Path | Notes |
|--------|------|--------|
| `GET` | `/api/places/nearby` | Query: `lat`, `lng`, optional `radius` (km, default 50) |
| `POST` | `/api/places` | `{ name, latitude, longitude }` |
| `GET` | `/api/places/{id}` | |
| `PUT` | `/api/places/{id}` | Creator only — `{ name?, latitude?, longitude? }` |
| `POST` | `/api/places/{id}/ratings` | After completed match at place — `{ stars, comment? }` |
| `POST` | `/api/places/{id}/reports` | `{ reason, details? }` — `details` required if `reason=other` (min 10 chars) |

## Play invitations (`/api/play-invitations/*`)

| Method | Path | Notes |
|--------|------|--------|
| `GET` | `/api/play-invitations` | Query: `role` = `all` \| `sent` \| `received` |
| `POST` | `/api/play-invitations` | `{ invitee_id, place_id, scheduled_at, message? }` |
| `GET` | `/api/play-invitations/{id}` | |
| `POST` | `/api/play-invitations/{id}/accept` | Invitee, status `pending` |
| `POST` | `/api/play-invitations/{id}/decline` | Invitee, status `pending` |
| `POST` | `/api/play-invitations/{id}/cancel` | Inviter, status `pending` |
| `POST` | `/api/play-invitations/{id}/complete` | Either participant, status `accepted` |
| `POST` | `/api/play-invitations/{id}/rate-player` | Status `completed` — `{ stars, comment? }` |
| `POST` | `/api/play-invitations/{id}/report-player` | `{ reason, details? }` |

### Place report reasons (`place_reports.reason`)

| Code | Label (PT) |
|------|------------|
| `bad_conditions` | Quadra/local em más condições que prejudica o jogo |
| `does_not_exist` | Local não existe |
| `wrong_location` | Pin / localização incorreta no mapa |
| `duplicate` | Local duplicado |
| `no_access` | Sem acesso ao local |
| `incorrect_name` | Nome enganoso ou incorreto |
| `other` | Outro (detalhar no texto, min 10 caracteres) |

### User report reasons (`user_reports.reason`)

| Code | Label (PT) |
|------|------------|
| `skill_mismatch` | Nível de jogo não condiz com o perfil |
| `disrespectful` | Comportamento desrespeitoso |
| `no_show` | Não compareceu no horário combinado |
| `harassment` | Assédio ou mensagens inadequadas |
| `unsportsmanlike` | Conduta antidesportiva durante o jogo |
| `other` | Outro (detalhar no texto, min 10 caracteres) |

## Manual E2E checklist (places + invitations)

1. Set `USE_MOCK_API=false`, restart app, ensure Sail is up.
2. User A logs in, opens a player profile, taps **Convidar para jogar**, picks date/time and place (or creates one).
3. User B logs in on another device/emulator, opens **Convites** tab, accepts invitation.
4. Either user taps **Marcar como realizada**, then rates player and place.
5. Verify decline/cancel flows and overlap error (second invite within ±2h).
6. Map **Lugares** filter shows nearby places; **Adicionar local** works.

### Google Maps (Android)

Set `GOOGLE_MAPS_API_KEY` in `.env`. The Android build injects it from `.env` or `android/local.properties` (`android/app/build.gradle.kts`). **Stop the app and run a full rebuild** after changing the key (hot reload is not enough).

On the map tab, switch to **Lugares** for blue place pins. **Adicionar local** opens a map where you tap or drag the pin before saving; the main map then refreshes and centers on the new place.

## Reverb

When Reverb is enabled on the API, set `REVERB_*` in `.env` to match Laravel `.env`.
