# Backend work request - ranking, cities, challenge limits, admin visibility, notifications

> Paste this document into the Laravel project's AI session
> (`/home/jmoura/projects/conec/conectenis`). It is self-contained.

## Context

QA/dogfooding on the Flutter app surfaced a batch of backend bugs and gaps.
The client-side work (ranking screen redesign, map avatars/clustering,
notifications overhaul, a couple of bug fixes) has already shipped or is
shipping alongside this request - the items below are the parts that need
Laravel-side changes before the corresponding client feature is fully
functional. Existing conventions unchanged: Sanctum bearer auth, snake_case
JSON, ISO-8601 dates with timezone, `422` validation errors, `403` for
non-participants, `404` unknown ids, `409` invalid state transitions.

---

## 1. Ranking points bug: only the losing player updates (urgent)

After a match result is approved by both participants, `GET /rankings`
only reflects the change for the **losing** player - the winner's entry
never updates (rank/points stay stale, or they don't appear at all if this
was their qualifying match). Please audit the points-awarding logic that
runs on result approval and fix it to credit **both** participants:

- **Winner: +100 points**
- **Loser: +20 points**

per completed, approved match. Apply this per-match; if the ranking system
already has a different point formula in place, replace it with this one.

## 2. City ranking filter bug: registered city not matching (urgent)

A user registered with city "Cerquilho" does not appear when the app
requests `GET /rankings?geo=city&city_id={their_home_city_id}` - i.e.
filtering by their own home city excludes them entirely. Please
investigate:

- Is `home_city_id` actually being populated/resolved at registration
  time from the address the user entered? The Flutter client never sends
  `home_city_id` directly - it's expected to be derived server-side from
  the registered address (city name -> city record).
- Is the `/rankings` city filter doing an exact `city_id` match against
  a value that's null or mismatched for some users?

This is likely affecting more than just this one report - anyone whose
`home_city_id` wasn't correctly backfilled/resolved would have the same
problem.

## 3. New cities endpoint (required for the new city picker)

The ranking screen now lets a user browse rankings for any city, not just
their own. Add:

```
GET /cities?search={query}
```

- `search` (string, optional): filters by city name, case-insensitive,
  partial match. Omitted/empty returns a reasonable default set (e.g. most
  populous, or the requester's own state first - your call).
- Response: array of cities that have at least one active registered user,
  e.g.:

```json
[
  { "id": 42, "name": "Cerquilho", "state": "SP" },
  { "id": 7, "name": "Jundiaí", "state": "SP" }
]
```

No pagination needed for v1 - a typeahead search should keep result sets
small.

## 4. Ranking query: make `format` and `ntrp_level` optional

Today `GET /rankings` is always called with a specific `format`
(singles/doubles) and `ntrp_level`, which narrows the leaderboard to
"people at my exact level and format." Product wants the **default**
ranking view to show everyone in a city together on one leaderboard, with
format/NTRP as opt-in filters. Please make both params optional:

- `format` omitted -> include all formats combined (don't filter by
  format at all).
- `ntrp_level` omitted -> include all levels combined.
- `gender` already supports an "all" value client-side and will
  continue to be sent - no change needed there.

The client will still send these when the user explicitly picks a filter
in the UI; the change needed is just: don't require them, and treat an
absent value as "no restriction" rather than defaulting to some fixed
value or erroring.

## 5. Duplicate-active-challenge false positive + new 2-per-type limit

A user attempting to create a **public** challenge is blocked with a
message equivalent to "you already have a challenge near this datetime,"
even when they have no such challenge. Please investigate the validation
query behind this - likely candidates: a datetime-proximity window that's
too wide, or a cancelled/declined/expired challenge that's still being
counted as "active."

Separately, please replace whatever ad-hoc datetime-proximity rule exists
today with a clear, simple cap:

- A user may have at most **2 active challenges of each type**
  simultaneously: 2 active `direct` + 2 active `public` (4 total max, but
  the cap is per-type, not combined).
- "Active" = any status that isn't a terminal one (`completed`,
  `cancelled`, `declined`, `expired`).
- A 3rd creation attempt of a type that's already at its cap should
  return a `422` with a clear, specific pt-BR message, e.g. "Você já tem
  2 desafios diretos ativos. Finalize ou cancele um deles para criar um
  novo." (adjust wording per type).

## 6. Admin accounts excluded from every player-facing surface

Admin-role users are internal service accounts, not players. They must
not appear anywhere a regular player would see or interact with another
player:

- `GET /players/nearby` - exclude admins from results entirely.
- Challenge creation/candidate flows - admins must not be selectable as
  a direct-challenge opponent or as a public-challenge candidate.
- `GET /rankings` - admins must not appear in any leaderboard or count
  toward `user_position`/rank calculations for other users.

This should be a query-level exclusion (`WHERE role != 'admin'` or
equivalent), not something the client filters - the client trusts
whatever these endpoints return.

## 7. Notifications: delete endpoints (new)

The app is adding swipe-to-delete and a "clear all" action for
notifications. No delete capability exists today (only per-id mark-read).
Please add, both scoped to the authenticated user's own notifications:

```
DELETE /notifications/{id}
```
Deletes a single notification. `404` if it doesn't belong to the
requester or doesn't exist.

```
DELETE /notifications
```
Deletes **all** of the requester's notifications (read and unread).

Both should return `204 No Content` on success, consistent with other
delete endpoints in the API.

---

## Priority

Sections 1, 2, 5 are bugs affecting current users right now - please
prioritize those. Sections 3, 4, 6, 7 are needed for client features that
are either shipping now in a degraded/fallback state (ranking defaults to
the old behavior until 4 lands; notification delete/clear-all UI exists
but 404s until 7 lands) or are net-new asks (3, 6).

## Questions / next steps

Ping back on the Flutter side if:
- Any of the payload shapes above don't match what you'd rather ship.
- The 2-per-type challenge limit should be configurable instead of
  hardcoded, or should count differently than described.
- You want the cities endpoint's "default set when search is empty"
  behavior specified more precisely before building it.
