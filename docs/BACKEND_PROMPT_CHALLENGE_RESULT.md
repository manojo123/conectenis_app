# Laravel API — Challenge result approval workflow

Use this in the **conectenis** Laravel Cursor instance. The Flutter app is ready for this contract (`pending_result_approval`, `result`, `can_submit_result`, `can_approve_result`, `POST .../result/approve`).

## Business rules

1. When any participant submits the match result (score + optional ratings), the challenge must **not** become `completed` immediately.
2. Status becomes **`pending_result_approval`** (“Aguardando aprovação”).
3. **All** participants must approve (2 in singles, 4 in doubles) before status → **`completed`** (“Realizado”).
4. **Concurrency:** only one proposed result. If a second `POST /evaluation` arrives while a result exists, return **`409 Conflict`** with a clear message. The app reloads the challenge detail.
5. After **`completed`**, the result is **locked** (no edits, no new evaluation).
6. The submitter’s approval counts automatically (they proposed the result).
7. Notify all other participants when a result is proposed (push/in-app — use existing notification system).

## New status

Add enum/value: `pending_result_approval` (label PT: “Aguardando aprovação”).

## Database (suggested)

- `challenge_results` table: `challenge_id`, `submitted_by_user_id`, `skip_score`, `winner_user_id`, `my_games_won`, `opponent_games_won` (from submitter POV or normalized), rating fields, `created_at`
- `challenge_result_approvals` table: `challenge_result_id`, `user_id`, `approved_at` (nullable until approved)
- Unique constraint on `challenge_id` in `challenge_results` (one active proposal)

## `POST /api/challenges/{id}/evaluation`

**When no result exists yet:**

- Validate as today, with doubles extensions (see below)
- Create `challenge_results` + auto-approval row for submitter
- Set challenge `status = pending_result_approval`
- Notify other participant user ids
- Return **`200`** with full **`ChallengeResource`** (see JSON below)

**Doubles (`format=doubles`):**

- Require `winner_team: [userId, userId]` when `skip_score=false` (both on same team).
- Do **not** accept `winner_user_id` for doubles.
- Accept `opponent_ratings[]` with one entry per opponent (2 entries); each `user_id` must be on the other team.

**Singles:**

- Require `winner_user_id` when `skip_score=false`.
- Accept `opponent_punctuality_stars` + `opponent_comment` and/or single-element `opponent_ratings[]`.

**When result already exists:**

- Return **`409`** `{ "message": "O resultado já foi informado por outro participante." }`
- Do not create duplicate rows

## `POST /api/challenges/{id}/result/approve`

- Authenticated user must be a participant
- Idempotent: if already approved, return current challenge
- Set `approved_at` for this user
- If **all** participant user ids have approved → `status = completed`
- Notify participants when fully completed
- Return updated **`ChallengeResource`**

## `GET /api/challenges/{id}` (and list) — extend `ChallengeResource`

```json
{
  "id": 1,
  "status": "pending_result_approval",
  "format": "doubles",
  "creator_team": 1,
  "participants": [
    { "user": { "id": 2, "name": "Maria" }, "team": 2, "status": "accepted" }
  ],
  "can_submit_result": false,
  "can_approve_result": true,
  "result": {
    "skip_score": false,
    "winner_team": [2, 5],
    "winner_team_label": "Maria / Pedro",
    "score_label": "6 × 4",
    "submitted_by_user_id": 1,
    "submitted_by_name": "João",
    "my_games_won": 6,
    "opponent_games_won": 4,
    "opponent_ratings": [
      { "user_id": 2, "user_name": "Maria", "punctuality_stars": 5, "comment": "Ótimo jogo" },
      { "user_id": 5, "user_name": "Pedro", "punctuality_stars": 4 }
    ],
    "place_quality_stars": 4,
    "place_comment": "Quadra boa",
    "approvals": [
      { "user_id": 1, "user_name": "João", "approved": true, "approved_at": "2026-05-23T12:00:00Z" },
      { "user_id": 2, "user_name": "Maria", "approved": false, "approved_at": null }
    ]
  }
}
```

Singles example (legacy fields still supported):

```json
{
  "id": 2,
  "status": "pending_result_approval",
  "can_submit_result": false,
  "can_approve_result": true,
  "result": {
    "skip_score": false,
    "winner_user_id": 2,
    "winner_name": "Maria Silva",
    "score_label": "6 × 4",
    "submitted_by_user_id": 1,
    "submitted_by_name": "João",
    "my_games_won": 6,
    "opponent_games_won": 4,
    "opponent_punctuality_stars": 5,
    "opponent_comment": "Ótimo jogo",
    "place_quality_stars": 4,
    "place_comment": "Quadra boa",
    "approvals": [
      { "user_id": 1, "user_name": "João", "approved": true, "approved_at": "2026-05-23T12:00:00Z" },
      { "user_id": 2, "user_name": "Maria", "approved": false, "approved_at": null }
    ]
  }
}
```

Compute for current user:

- `can_submit_result`: `true` when `status` in (`accepted`, `pending_score`) and no `result` row
- `can_approve_result`: `true` when `status == pending_result_approval`, result exists, current user has not approved yet

Participant ids = creator + accepted participants (all slots filled for doubles).

## Tests (Pest)

1. First evaluation → `pending_result_approval`, submitter auto-approved
2. Second evaluation → 409
3. Other participant approves → still pending until all approve
4. Last approval → `completed`
5. Evaluation after `completed` → 403
6. Approve twice → idempotent 200
7. Doubles evaluation with `winner_team` (no `winner_user_id`) → 200
8. Doubles evaluation with `winner_user_id` → 422
9. Doubles `opponent_ratings` must include both opponents from other team

## Routes

```php
Route::post('challenges/{challenge}/evaluation', ...);
Route::post('challenges/{challenge}/result/approve', ...)->middleware('auth:sanctum');
```
