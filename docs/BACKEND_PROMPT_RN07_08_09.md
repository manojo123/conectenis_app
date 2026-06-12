# Laravel API — RN07 Mural, RN08 Ranking, RN09 Evaluation

Use this in the **conectenis** Laravel Cursor instance. The Flutter app implements this contract for challenge walls, segmented ranking, and bidirectional multi-criteria post-game evaluation.

Builds on [`BACKEND_PROMPT_CHALLENGE_RESULT.md`](BACKEND_PROMPT_CHALLENGE_RESULT.md) (result approval workflow).

---

## RN07 — Challenge list API enhancements

### `GET /api/challenges`

Extend existing `role` parameter with optional filters and sorting.

| Param | Type | Default | Purpose |
|-------|------|---------|---------|
| `role` | string | `all` | `created`, `received`, `public_nearby`, `all` |
| `status` | string or array | — | Filter by status(es) |
| `scheduled_from` | ISO date | — | `scheduled_start >=` |
| `scheduled_to` | ISO date | — | `scheduled_start <=` |
| `include_history` | bool | `false` | When `false`, exclude `cancelled`, `completed`, `declined`, `expired` |
| `sort` | string | `scheduled_start` | `priority` (actionable first) or `scheduled_start` |
| `radius_km` | int | config default | For `role=public_nearby` only |

### Priority sort (`sort=priority`)

Applies to `role=created` and `role=received`:

1. `pending_acceptance`, `pending_candidates`, `candidates_awaiting_accept`
2. `accepted`
3. `pending_score`, `pending_result_approval`
4. Historical statuses (only when `include_history=true`)

Within each tier: `scheduled_start ASC` (soonest first).

### Public nearby (`role=public_nearby`)

- Default `radius_km` → **50** (`config/dashboard.php` → `PUBLIC_NEARBY_DEFAULT_RADIUS_KM`)
- Allowed options: `[10, 25, 50, 100]`
- Haversine filter on user lat/lng; NTRP + gender + format profile match (existing logic)
- Extend **`ChallengeResource`** for list items:

```json
{
  "id": 42,
  "type": "public",
  "format": "singles",
  "status": "pending_candidates",
  "distance_km": 12.4,
  "can_apply": true,
  "has_applied": false
}
```

- `can_apply`: authenticated user eligible and not already candidate/participant
- `has_applied`: user already applied (disable CTA in app)

### Tests (Pest)

1. `created` + `include_history=false` excludes completed/cancelled
2. `sort=priority` returns pending_acceptance before accepted
3. `status` + date range filters work
4. `public_nearby` default radius 50 km
5. `can_apply` / `has_applied` flags correct per user

---

## RN08 — Ranking & scoring

### Point rules

Update `config/ranking.php`:

```php
'points_per_win' => (int) env('RANKING_POINTS_PER_WIN', 100),
'points_per_loss_incentive' => (int) env('RANKING_POINTS_PER_LOSS_INCENTIVE', 25),
```

| Outcome | Winner | Loser |
|---------|--------|-------|
| Validated win (consensual score) | +100 | 0 |
| Validated loss (consensual score) | 0 | +25 |
| Declined / expired | 0 | 0 |
| W.O. / no score within 24h | 0 | 0 |

- Award on `status → completed` after all approvals
- Loser incentive only when `skip_score=false` and score recorded
- Keep `RankingService::canAwardPoints()` (repeat opponent same month → no ranking points; match still in personal history)

### Pending score expiry

Change `ExpirePendingScoreChallengesCommand` from 1 week → **24 hours**.
Set `closed_reason = no_score_24h` when auto-closing.

### `GET /api/rankings`

**Required segmentation** — leaderboards are isolated per axis combination:

| Param | Values | Required |
|-------|--------|----------|
| `ntrp_level` | float (e.g. `4.0`) | yes |
| `gender` | `male`, `female`, `all` | yes |
| `format` | `singles`, `doubles` | yes |
| `geo` | `country`, `state`, `city` | yes |
| `state` | UF code | when `geo=state` |
| `city_id` | int | when `geo=city` |
| `country` | ISO | default `BR` |
| `limit` | int | default 50 |

**Response:**

```json
{
  "segment_label": "Simples · NTRP 4.0 · Masculino · São Paulo/SP",
  "user_position": {
    "rank": 12,
    "points": 275,
    "wins": 3,
    "matches_played": 5
  },
  "data": [
    {
      "rank": 1,
      "points": 500,
      "wins": 5,
      "matches_played": 6,
      "player": { "id": 1, "name": "João", "ntrp_rating": 4.0, "gender": "male" },
      "city": { "id": 10, "name": "São Paulo", "state": "SP" }
    }
  ]
}
```

### Schema

Extend `ranking_stats` unique key:

`(user_id, city_id, scope, ntrp_level, gender, format)`

Or rebuild via aggregation job from completed challenges filtered by segment.

`scope` mapping: `city` geo → user's city; `state` → state-wide; `country` → national.

### Tests (Pest)

1. Winner +100, loser +25 on completed challenge
2. Declined/expired → 0 points both
3. Repeat opponent same month → second match 0 ranking points
4. Segmented query returns only matching NTRP/gender/format
5. `user_position` reflects authenticated user in segment

---

## RN09 — Bidirectional multi-criteria evaluation

### Opponent ratings (required 1–5 each)

Per rated opponent in `opponent_ratings[]`:

| Field | Required |
|-------|----------|
| `user_id` | yes |
| `punctuality_stars` | yes |
| `fair_play_stars` | yes |
| `communication_stars` | yes |
| `comment` | no |

Singles legacy: `opponent_punctuality_stars` + `opponent_fair_play_stars` + `opponent_communication_stars` + `opponent_comment` still accepted.

### Place ratings (when challenge has `place_id`)

| Field | Required |
|-------|----------|
| `court_quality_stars` | yes |
| `infrastructure_stars` | yes |
| `place_comment` | no |

Legacy `place_quality_stars` accepted as alias for `court_quality_stars` during transition.

### `POST /api/challenges/{id}/evaluation`

Extend existing endpoint:

- Validate all required star fields (422 if missing)
- Persist to `user_ratings` (one row per opponent rated, linked to `challenge_id`)
- Persist to `place_ratings` (linked to `challenge_id`)
- Store full payload on `challenge_results` JSON columns for display

**Request example (doubles):**

```json
{
  "skip_score": false,
  "my_games_won": 6,
  "opponent_games_won": 4,
  "winner_team": [2, 5],
  "opponent_ratings": [
    {
      "user_id": 3,
      "punctuality_stars": 5,
      "fair_play_stars": 5,
      "communication_stars": 4,
      "comment": "Ótimo jogo"
    },
    {
      "user_id": 4,
      "punctuality_stars": 4,
      "fair_play_stars": 5,
      "communication_stars": 5
    }
  ],
  "court_quality_stars": 4,
  "infrastructure_stars": 3,
  "place_comment": "Estacionamento limitado"
}
```

### `POST /api/challenges/{id}/result/approve`

**Require ratings from approver** (RN09.1 bidirectional):

- Body accepts same `opponent_ratings[]` + place fields as evaluation
- Return **422** if any required star field missing for opponents on other team
- Persist ratings to `user_ratings` / `place_ratings` **before** marking approval
- Idempotent: if already approved, return current challenge (ratings not duplicated)

**Request example:**

```json
{
  "opponent_ratings": [
    {
      "user_id": 1,
      "punctuality_stars": 5,
      "fair_play_stars": 5,
      "communication_stars": 5,
      "comment": "Pontual e educado"
    }
  ],
  "court_quality_stars": 5,
  "infrastructure_stars": 4
}
```

### `ChallengeResource.result` — extended display

```json
{
  "result": {
    "opponent_ratings": [
      {
        "user_id": 2,
        "user_name": "Maria",
        "punctuality_stars": 5,
        "fair_play_stars": 5,
        "communication_stars": 4,
        "comment": "Ótimo jogo"
      }
    ],
    "court_quality_stars": 4,
    "infrastructure_stars": 3,
    "place_comment": "Boa quadra"
  }
}
```

### Profile APIs

**`GET /api/players/{id}`** — extend `recent_reviews`:

```json
{
  "average_rating": 4.6,
  "rating_dimensions": {
    "punctuality": 4.8,
    "fair_play": 4.7,
    "communication": 4.3
  },
  "recent_reviews": [
    {
      "author": "João",
      "comment": "Pontual",
      "stars": 5,
      "punctuality_stars": 5,
      "fair_play_stars": 5,
      "communication_stars": 4,
      "created_at": "2026-06-01T10:00:00Z"
    }
  ]
}
```

**`GET /api/places/{id}`** — same pattern with `court_quality` and `infrastructure` dimensions.

### Database

Ensure migrations exist:

- `challenge_results`, `challenge_result_approvals` (from result approval doc)
- `user_ratings`: add `punctuality_stars`, `fair_play_stars`, `communication_stars`, `challenge_id`
- `place_ratings`: add `court_quality_stars`, `infrastructure_stars`, `challenge_id`

### Tests (Pest)

1. Evaluation with all 3 opponent dimensions → 200, persisted to `user_ratings`
2. Evaluation missing `fair_play_stars` → 422
3. Approve without ratings → 422
4. Approve with ratings → approval recorded + ratings persisted
5. Player profile shows dimension averages from challenge ratings
6. Place profile shows court + infrastructure averages

---

## Routes summary

```php
// Existing — extend handlers
Route::get('challenges', ...);
Route::post('challenges/{challenge}/evaluation', ...);
Route::post('challenges/{challenge}/result/approve', ...);
Route::get('rankings', ...);
Route::get('players/{player}', ...);
Route::get('places/{place}', ...);
```

## Flutter readiness

The app sends:

- List filters: `status`, `scheduled_from`, `scheduled_to`, `include_history`, `sort`, `radius_km`
- Evaluation/approve: `opponent_ratings[]` with 3 dimensions + `court_quality_stars` / `infrastructure_stars`
- Rankings: `ntrp_level`, `gender`, `format`, `geo`, `state`, `city_id`

Graceful fallback: client-side sort/filter when backend params not yet available.
