# Backend work request — UI redesign gaps (RN10)

> Paste this document into the Laravel project's AI session
> (`/home/jmoura/projects/conec/conectenis`). It is self-contained.

## Context

The Flutter app was redesigned to the approved dark/lime prototype. The
navigation is now **Mapa · Mensagens · Desafios · Notificações · Perfil**
(bottom tabs), the dashboard home and ranking tabs were retired, and the nav
bar shows **unread badges** for messages, pending challenge invites and
unread notifications. All existing endpoints keep working unchanged — this
request covers only the gaps the redesign exposed, plus documentation
housekeeping.

Conventions (unchanged): Sanctum bearer auth, snake_case JSON, ISO-8601
dates with timezone, Laravel-standard `422` validation errors, `403` for
non-participants, `404` unknown ids, `409` invalid state transitions.

---

## 1. Conversations: unread count (required for the Mensagens badge)

The nav badge and the conversation list need per-conversation unread counts.

**`GET /api/conversations`** — each row gains two fields:

```json
[
  {
    "id": 12,
    "other_user_id": 34,
    "other_user_name": "Mariana Silva",
    "other_avatar_url": null,
    "last_message": "Fechado então! Reservo a quadra 3.",
    "updated_at": "2026-08-05T09:12:00-03:00",
    "unread_count": 2,
    "presence_label": null
  }
]
```

- `unread_count` (int, required): messages the authenticated user has not
  read in this conversation. The Flutter model already parses it (defaults
  to 0 when absent), and the Mensagens tab badge is the sum across rows.
- `presence_label` (string|null, optional, nice-to-have): pt-BR presence
  line for the thread header, e.g. `"online"` or `"visto por último há 2 h"`.
  Omit or send null if presence tracking is out of scope.

**`POST /api/conversations/{id}/read`** (new) — marks every message in the
conversation as read for the authenticated user. Response `204`. The app
will call it when a thread is opened. Requires a `message_reads` (or
per-message `read_at`) mechanism — implementation detail is yours.

Suggested schema: `message_reads (message_id, user_id, read_at)` or a
`conversation_participants.last_read_at` column (simpler; unread_count =
messages newer than `last_read_at` from the other user).

## 2. Notifications: mark-all-read + count semantics

- **`POST /api/notifications/read-all`** (new): marks all of the user's
  unread notifications as read. Response `204`. (Today the app loops
  `POST /api/notifications/{id}/read` one by one — works, but N requests.)
- **`unread_notifications_count`** on `GET /api/auth/user` must decrement
  when notifications are marked read (the app refetches the user after
  marking to refresh the nav badge — make sure the count is computed live,
  not cached).
- Notification payload contract the redesigned UI maps to icons/titles —
  keep `type` within this vocabulary (or extend the list here):

| `type` value | UI rendering |
|---|---|
| `challenge_received` | tennis icon, "Novo desafio recebido" |
| `challenge_accepted` / `challenge_declined` / `challenge_cancelled` | tennis icon, "Desafio aceito/atualizado" |
| `new_candidate` | group icon, "Novo candidato" |
| `match_reminder` / `challenge_scheduled` | calendar icon, "Partida agendada" |
| `evaluation_pending` / `result_*` | review icon, "Avaliação pendente" |
| `ranking_up` / `ranking_*` | trending icon, "Ranking atualizado" |

Each notification's `data` object should carry `message` (pt-BR body) and
`challenge_id` when the event points at a challenge (the app deep-links to
`/challenges/{id}`).

## 3. Rankings: weekly movement (optional, prototype parity)

The prototype shows ▲/▼ movement per ranking row. If cheap to compute
(snapshot diff of `ranking_stats`), add to `GET /api/rankings` rows and
`user_position`:

```json
{ "rank": 4, "points": 1310, "wins": 17, "weekly_delta": 2, "player": { ... } }
```

`weekly_delta` (int, optional): positions gained (+) / lost (−) in the last
7 days. The app renders arrows only when the field is present.

## 4. Achievements (optional, new endpoint)

The Perfil tab shows achievement chips. Today they are derived client-side
from the record (first win, 10 wins, 30 matches, top-15). A server source
would make them consistent:

**`GET /api/user/achievements`** → `200`:

```json
{ "data": [
  { "code": "first_win", "label": "Primeira vitória", "unlocked_at": "2026-06-01T10:00:00-03:00" },
  { "code": "streak_5", "label": "Sequência de 5", "unlocked_at": null }
] }
```

Only unlocked achievements need to be returned (`unlocked_at != null`).
Low priority — the client fallback stays until this ships.

## 5. Gender `prefer_not_to_say` (optional)

The prototype's onboarding offers "Prefiro não dizer". The API `gender`
enum is `male|female` today and the app only shows those two. If product
wants the third option: extend the enum/validation to accept
`prefer_not_to_say` (nullable stays allowed) — the Flutter enum already
tolerates unknown values by treating them as null.

## 6. Retire legacy resources (confirmation requested)

The redesign **deleted the client code** for these — no app version after
this release calls them:

- `GET/POST /api/play-invitations*` (all 9 routes)
- `GET /api/matches`, `GET /api/matches/rivals`, `POST /api/matches`

Please confirm nothing else consumes them, then remove routes/controllers
(or keep them one release behind a deprecation log line — your call).

## 7. Documentation housekeeping (no code)

These routes are **live and called by the app** but missing from
`INTEGRATION.md` / API docs — please document them:

- `PUT /api/user/location` — body `{latitude, longitude}` → full user JSON.
  Called after login/social-login and on location permission grants.
- `PUT /api/challenges/{id}` — creator edits a public challenge while
  `pending_candidates` (sparse body: message, place_id, google_place_id,
  open_location, scheduled_start/end, min/max_ntrp, gender_preference,
  profession_preference).
- `POST /api/challenges/{id}/result/reject` — participant rejects a
  proposed result; status returns to `pending_score`.

## 8. Reverb note (client-side, FYI — no backend action)

`pusher_channels_flutter` 2.4.x (current) cannot point at a custom
websocket host, so the app ignores `REVERB_HOST/PORT/SCHEME` today and
Reverb must stay disabled (`REVERB_APP_KEY` empty). The client-side fix is
upgrading `pusher_channels_flutter` to ≥2.6.0, which requires migrating
`flutter_secure_storage` to 10.x — tracked in the Flutter repo
(`lib/features/chat/services/reverb_service.dart`). When that lands, only
`POST /api/broadcasting/auth` and the `MessageSent` event on
`private-conversation.{id}` are needed server-side (already documented).

## 9. Pest scenarios to add

- Conversation read: send 2 messages A→B, `GET /conversations` as B shows
  `unread_count: 2`; `POST /conversations/{id}/read` as B → 204 and count 0.
- Messages badge total: unread counts sum across conversations.
- `POST /notifications/read-all` zeroes `unread_notifications_count` on the
  next `GET /auth/user`.
- Notification `data.challenge_id` present for every challenge lifecycle
  event.
- (If §3 lands) `weekly_delta` reflects snapshot movement.
- Play-invitation and matches routes removed → `404` (or deprecation path).
