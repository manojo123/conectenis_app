# Backend work request - direct challenge open location + challenge expiration

> Paste this document into the Laravel project's AI session
> (`/home/jmoura/projects/conec/conectenis`). It is self-contained.

## Context

QA surfaced two gaps in challenge handling. The Flutter side of #1 has already
shipped; #2 is entirely backend work (there is no client-side piece). Existing
conventions unchanged: Sanctum bearer auth, snake_case JSON, ISO-8601 dates
with timezone, `422` validation errors, `403` for non-participants, `404`
unknown ids, `409` invalid state transitions.

---

## 1. `open_location` on `POST /challenges/direct`

Direct challenges currently require a court (`place_id` or `google_place_id`)
up front. Users want to send a direct challenge to a specific opponent while
leaving the court to be agreed on afterward - the same "Local em aberto"
option that public challenges already have.

The Flutter app now sends `open_location: bool` on `POST /challenges/direct`
(mirroring the existing `POST /challenges/public` payload). Please:

- Accept `open_location` (bool, default `false`) on `POST /challenges/direct`.
- When `open_location: true`, `place_id`/`google_place_id` are optional -
  don't require either. Return the created challenge with
  `open_location: true` and `place: null`.
- When `open_location` is `false` or absent, keep the current behavior:
  require one of `place_id`/`google_place_id`.
- Note: `docs/BACKEND_PROMPT.md`'s "Challenge create" section already
  describes this rule as applying to **both** `/challenges/direct` and
  `/challenges/public` ("Accept place_id OR google_place_id. Require one when
  location is not open"). Please confirm whether `/challenges/direct` already
  implements this or whether this is new work.
- Open question for you: once the opponent accepts a direct challenge with no
  court set, is there (or should there be) a way for either participant to
  attach a `place_id` afterward once they agree on one? Flag if this needs a
  new endpoint/field, or if it's already covered by the existing
  `PUT /challenges/{id}` update path (today that's public-challenge-only per
  `edit_public_challenge_screen.dart` - direct challenges have no edit
  screen).

## 2. Auto-expire stale challenges

The `expired` challenge status exists in the API/model and is already treated
as terminal everywhere (ranking exclusions, the 2-active-per-type cap,
history filtering), but nothing ever sets it. A direct challenge that's never
accepted, or a public challenge no one applies to, sits in
`pending_acceptance` / `pending_candidates` / `candidates_awaiting_accept`
forever, even long after its `scheduled_start` has passed.

Please add a scheduled job (Laravel scheduler, suggest every 15 minutes) that
finds non-terminal challenges past their deadline and flips them to
`expired`. Proposed rule - please confirm/adjust per your product judgment:

- `pending_acceptance` (direct, opponent never responded): expire once
  `scheduled_start` has passed.
- `pending_candidates` / `candidates_awaiting_accept` (public, no one
  accepted): expire once `scheduled_start` has passed.
- `accepted` (confirmed match, never played/scored): expire some grace
  period after `scheduled_end` (suggest 24h) if no result was submitted, so
  matches don't stay open indefinitely waiting on a score that will never
  come. Confirm the grace period you want.
- Leave alone: `completed`, `cancelled`, `declined`, and already-`expired`
  challenges.

Also:

- Double-check this doesn't fight with the "2 active challenges per type"
  cap from `docs/BACKEND_PROMPT_RANKING_MAP_NOTIFICATIONS.md` §5 - `expired`
  is already listed there as a terminal/non-active status, so a challenge
  this job expires should immediately free up that user's slot.
- Should participants get a notification when their challenge auto-expires?
  If yes, please pick a notification `type` string containing `expired` and
  let us know it - the Flutter notifications screen matches on substrings
  like `declined`/`cancelled`/`result`, and `expired` isn't one of them yet,
  so we'll add that case once we know the exact type value you're sending.
