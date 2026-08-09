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

**`GET /api/conversations`** — each row gains three fields:

```json
[
  {
    "id": 12,
    "other_user_id": 34,
    "other_user_name": "Mariana Silva",
    "other_avatar_url": null,
    "last_message": "Fechado então! Reservo a quadra 3.",
    "last_message_user_id": 34,
    "updated_at": "2026-08-05T09:12:00-03:00",
    "unread_count": 2,
    "presence_label": null
  }
]
```

- `unread_count` (int, required): messages the authenticated user has not
  read in this conversation. The Flutter model already parses it (defaults
  to 0 when absent), and the Mensagens tab badge is the sum across rows.
- `last_message_user_id` (int|null, required): id of whoever sent
  `last_message`. Without it the conversation list preview is ambiguous —
  users can't tell if they or the other person sent the last message. The
  Flutter model already parses this field (`Conversation.lastMessageSenderId`)
  and prefixes the preview with "Você:" / the other user's name once
  present; it's a no-op prefix until this field ships.
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

## 9. Public wall: filter by gender preference server-side

`GET /api/challenges?role=public_nearby` (Mural tab) currently returns
public challenges regardless of `gender_preference`, and only
`can_apply=false` silently blocks the wrong gender from applying — which
reads as a bug ("it shows up for me but won't let me join"). The client now
filters the list locally against the authenticated user's own gender as a
stopgap, but the correct fix is server-side: exclude rows from
`public_nearby` where `gender_preference` is set and doesn't match the
requesting user's `gender`. This also saves the client from ever seeing
challenges it can't act on.

## 10. Persistent doubles group chat (approved — please implement)

All 4 participants of a doubles challenge (both pairs) get one shared
thread. Design decisions below are final — please implement to this spec
rather than re-deriving them:

- **Creation trigger**: automatic, server-side, when the challenge
  transitions to `accepted` (i.e. all 4 players are locked in — same
  moment the challenge leaves `pending_candidates`/`candidates_awaiting_accept`).
  No client action creates it; no thread exists before that point.
- **Lifecycle**: the thread becomes **read-only** the moment the challenge
  reaches a terminal status (`completed`, `cancelled`, `expired`,
  `declined`). History stays visible in `GET /conversations` and
  `GET /conversations/{id}/messages` — only new messages are blocked.
- **Unread counts**: merge into the same `unread_count` field / same
  Mensagens nav badge as 1:1 conversations — no separate badge concept.

### Data model
Extend the existing `conversations` resource rather than introducing a
parallel one — add a participants join (`conversation_participants
(conversation_id, user_id)`) so a row can have >1 other participant, and
two new fields:

- `type`: `"direct"` (today's 1:1 rows, unchanged) | `"group"` (new).
- `challenge_id`: int, only set for `type: "group"`, links back to the
  doubles challenge.

### `GET /api/conversations` — group row shape
```json
{
  "id": 88,
  "type": "group",
  "challenge_id": 501,
  "title": "Duplas: Quadra Vila Olímpia",
  "participants": [
    { "id": 12, "name": "Você", "avatar_url": null },
    { "id": 34, "name": "Mariana Silva", "avatar_url": null },
    { "id": 56, "name": "Pedro Alves", "avatar_url": null },
    { "id": 78, "name": "Carla Nunes", "avatar_url": null }
  ],
  "last_message": "Confirmado, até sábado!",
  "last_message_user_id": 34,
  "updated_at": "2026-08-05T09:12:00-03:00",
  "unread_count": 1,
  "is_archived": false
}
```
- `title` (string, required for `type: group`): short label for the list
  row (e.g. the place name or "Duplas #{challenge_id}") since there's no
  single "other user" name to show.
- `participants` (array, required for `type: group`): every member
  including the requesting user (flagged by matching their own id) — the
  client uses this to render the avatar stack and to label who sent each
  message (`Message.user_id` → lookup by `id` here). `other_user_id` /
  `other_user_name` / `other_avatar_url` stay `null` on group rows.
- `is_archived` (bool, required for `type: group`): `true` once the
  challenge hits a terminal status. `direct` rows can omit this (defaults
  false).
- Existing `direct` rows are unaffected — omit `type`/`challenge_id` or
  send `type: "direct"`, your call, as long as old rows keep working.

### Messages
`GET /api/conversations/{id}/messages` and `POST /api/messages` need no
shape change — `Message.user_id` already identifies the sender, and the
client resolves the display name via the conversation's `participants`
list. `POST /api/messages` against an archived (`is_archived: true`)
group conversation → `409` (existing convention for invalid state).

### Notifications
When the group thread is created, notify all 4 participants (reuse the
existing notification pipeline / `type` vocabulary from §2 — e.g. a new
`type: "group_chat_started"` pointing at the conversation).

## 11. Pest scenarios to add

- Conversation read: send 2 messages A→B, `GET /conversations` as B shows
  `unread_count: 2`; `POST /conversations/{id}/read` as B → 204 and count 0.
- Messages badge total: unread counts sum across conversations.
- `last_message_user_id` on `GET /conversations` matches the sender of the
  most recent message, both when A sent last and when B sent last.
- `public_nearby` excludes challenges whose `gender_preference` doesn't
  match the requesting user's gender (§9).
- `POST /notifications/read-all` zeroes `unread_notifications_count` on the
  next `GET /auth/user`.
- Notification `data.challenge_id` present for every challenge lifecycle
  event.
- (If §3 lands) `weekly_delta` reflects snapshot movement.
- Play-invitation and matches routes removed → `404` (or deprecation path).
- Doubles group chat (§10): challenge with 4 confirmed players transitions
  to `accepted` → a `type: group` conversation exists with all 4 as
  `participants` and `is_archived: false`; challenge transitions to
  `completed` → same conversation now `is_archived: true` and
  `POST /messages` against it → `409`; a message from any of the 4 bumps
  `unread_count` for the other 3 and sums into their Mensagens badge.
