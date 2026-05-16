# ConecTenis — Backend integration

## Laravel API (Sail / WSL)

| Item | Value |
|------|--------|
| WSL path | `/home/jmoura/projects/conec/conectenis` |
| Windows path | `\\wsl.localhost\Ubuntu\home\jmoura\projects\conec\conectenis` |
| Sail URL (from Windows) | `http://localhost:8000` |
| API base URL | `http://localhost:8000/api` |
| Android emulator | `http://10.0.2.2:8000/api` |

Start API (from Windows):

```bash
wsl -d Ubuntu -- bash -lc "cd ~/projects/conec/conectenis && ./vendor/bin/sail up -d"
```

## Mock vs live API

| `USE_MOCK_API` | Behavior |
|----------------|----------|
| `true` (default) | Map, players, courts, chat, matches use in-app mock data (Jundiaí seeds). Login still hits Laravel if reachable. |
| `false` | All endpoints call Laravel (requires routes from `openapi.yaml` to be implemented). |

**Register:** works in mock mode locally. For production login, create users in Laravel (Tinker) until `POST /register` exists.

## Auth (implemented on API today)

- `POST /api/sanctum/token` — body: `email`, `password`, `device_name` → `{ token, token_type }`
- `GET /api/user` — Bearer token → Laravel user (`id`, `name`, `email`)

## Flutter environment

Copy `.env.example` to `.env`. Set `USE_MOCK_API=true` until map/chat/match endpoints exist on the API (see `docs/openapi.yaml`).

## Reverb

When Reverb is enabled on the API, set `REVERB_*` in `.env` to match Laravel `.env`.
