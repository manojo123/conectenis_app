# Laravel API changes for Conectenis mobile app

Use this prompt in the **conectenis** Laravel project Cursor instance. The Flutter app already sends `date_of_birth` and applies client-side workarounds where noted; these API updates remove 403/404 issues and align contracts.

## 1. Replace `age` with `date_of_birth` on user profile

- Add nullable `date_of_birth` (`date`) on `users` (migration).
- Expose `date_of_birth` in `GET /api/auth/user`, login/register responses, and `PUT /api/user/profile`.
- Accept `date_of_birth` (ISO date `Y-m-d`) in profile update validation; stop requiring `age` or map legacy `age` only for backward compatibility during transition.
- Return `avatar_url` as a **full URL** (e.g. `Storage::url()` or `asset('storage/...')`) so mobile does not need to prefix `/storage/...` paths.

## 2. Place ratings — allow authenticated users

`PlacePolicy::rate` currently requires a completed play invitation at the place. Mobile users get **403 "This action is unauthorized"** when rating from place detail.

**Change:** allow any authenticated user to rate a place (or document a softer rule, e.g. visited / nearby). Update `PlacePolicy::rate` and add/adjust feature tests for `POST /api/places/{place}/ratings`.

## 3. Nearby places — filter by name

`GET /api/places/nearby` should accept optional query param `name` (string) and filter places whose name contains the term (case-insensitive).

- Update `NearbyPlacesRequest` rules: `'name' => ['nullable', 'string', 'max:255']`.
- Apply `where('name', 'like', '%'.$name.'%')` (or Scout) in the controller/repository.
- Add a feature test: seed places, call with `name=tennis`, assert filtered results.

## 4. Place detail — include recent reviews

`GET /api/places/{id}` should include `recent_reviews` in `PlaceResource` (author name, comment, stars), same shape the app expects:

```json
"recent_reviews": [
  { "author": "Maria", "comment": "Ótimo!", "stars": 5 }
]
```

## 5. Place update — creator OR admin

`PlacePolicy::update` should return true when:

- `auth()->id() === $place->created_by_user_id`, **or**
- user has `admin` role (Spatie).

Add policy tests for creator, admin, and other users.

## 6. Player profile — current user by id

`GET /api/players/{id}` should return the authenticated user’s public profile when `{id}` is their own id (same payload as other players). Today the app falls back client-side; fixing the API avoids 404 for self-links from challenges.

## 7. Optional: place report message

`POST /api/places/{id}/reports` — return Portuguese message in JSON: `"message": "Denúncia enviada com sucesso."` (app already shows a fixed PT string).

## 8. Chat — challenge timeline entries

When a direct challenge is created between two users who have a conversation, both should see a **non-deletable** timeline item in `GET /api/conversations/{id}/messages` (merged chronologically with normal messages).

Return items with `"type": "challenge"`:

```json
{
  "type": "challenge",
  "challenge_id": 42,
  "challenge_status": "pending_acceptance",
  "summary": "Desafio de tênis · Pendente",
  "created_at": "2026-05-23T14:00:00Z"
}
```

- Create these when `POST /api/challenges/direct` succeeds (for creator + each participant conversation).
- Do not allow `DELETE /messages/{id}` on challenge items.
- Update status text when challenge status changes (optional v2).

## 9. Case-insensitive search

- `GET /api/players/nearby?name=` — filter with `LOWER(name) LIKE %term%` (or equivalent).
- `GET /api/places/nearby?name=` — same.

## Run migrations & tests

- `php artisan migrate`
- Run Pest tests for profile, places, players, and challenges.

---

## Product meeting — additional API (Flutter ready)

See also `docs/BACKEND_PROMPT_CHALLENGE_RESULT.md` for approval workflow extensions below.

### A. Doubles evaluation — `winner_team`

When `format=doubles` and `skip_score=false`:

- Accept `winner_team` as array of **exactly 2** user ids (both must be challenge participants on the same side).
- **Reject** `winner_user_id` for doubles (422).
- Singles: keep `winner_user_id` (required unless `skip_score`).

### B. Per-opponent ratings — `opponent_ratings[]`

For doubles evaluation, accept:

```json
"opponent_ratings": [
  { "user_id": 3, "punctuality_stars": 5, "comment": "Ótimo jogo" },
  { "user_id": 4, "punctuality_stars": 4 }
]
```

- Validate each `user_id` is on the **opponent team** (2 users for doubles).
- Singles may continue using `opponent_punctuality_stars` + `opponent_comment`, or accept a single-element `opponent_ratings[]`.
- Include `opponent_ratings` in `ChallengeResource.result` when present.

### C. Participant teams — `team` field

Each participant in `ChallengeResource` (including creator) should expose `team: 1|2`:

- Team 1 vs team 2 for versus UI (singles: one player per team; doubles: two per team).
- Assign teams at accept/fill time.

### D. Hybrid nearby places + challenge create

`GET /api/places/nearby` (no `name` required for court picker) returns unified rows:

```json
{
  "source": "app",
  "id": 12,
  "name": "Clube Esportivo",
  "address": "Rua X",
  "latitude": -23.18,
  "longitude": -46.88,
  "distance_km": 0.5
}
```

```json
{
  "source": "google",
  "google_place_id": "ChIJ...",
  "name": "Arena Tennis",
  "address": "Av. Brasil",
  "latitude": -23.19,
  "longitude": -46.88,
  "distance_km": 1.2
}
```

Challenge create (`POST /challenges/direct`, `POST /challenges/public`):

- Accept **`place_id`** (int, app DB) **OR** **`google_place_id`** (string).
- Require one when location is not open; reject both missing when `open_location=false`.

---

**Flutter already handles (no API required for mock):** client-side name filter when API ignores `name`; self player via auth profile; relative avatar URL resolution (including rewriting `localhost` → `10.0.2.2` on Android).
