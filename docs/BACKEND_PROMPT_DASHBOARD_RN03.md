# Laravel API — Dashboard de Engajamento (RN03)

Use this prompt in the **conectenis** Laravel project Cursor instance. The Flutter app consumes these endpoints when `USE_MOCK_API=false`.

## 1. `GET /api/dashboard/matchmaking`

**Purpose:** RN03.1 — count discoverable players at the **exact same NTRP** as the authenticated user within a configurable radius.

**Query params:**
- `radius_km` — required, integer, one of `5`, `10`, `25` (validate enum)

**Logic:**
- Use authenticated user's `latitude`, `longitude`, `ntrp_rating` from DB (not query params).
- Reuse `User::scopeDiscoverable()` and Haversine distance from nearby players logic.
- Filter: `ntrp_rating = user.ntrp_rating` (exact match, not range).
- Exclude current user.
- Return count only (no player list).

**Response (unwrapped JSON):**
```json
{
  "count": 3,
  "radius_km": 10,
  "ntrp_rating": 3.5,
  "has_matches": true
}
```

**Edge cases:**
- User missing lat/lng → `422` with Portuguese message.
- User missing `ntrp_rating` → `422`.
- `has_matches` = `count > 0`.

**Optional:** cache result 60–120s per user+radius key.

## 2. `GET /api/dashboard/stats`

**Purpose:** RN03.2 — consolidated user stats for the home infographic panel.

**Response (unwrapped JSON):**
```json
{
  "tennis_level": { "ntrp_rating": 3.5 },
  "record": {
    "wins": 12,
    "losses": 5,
    "matches_played": 17,
    "win_rate": 0.706
  },
  "ranking": {
    "local": {
      "scope": "home",
      "city_id": 42,
      "city_name": "Jundiaí",
      "state": "SP",
      "rank": 7,
      "total_players": 120,
      "points": 80
    },
    "general": {
      "scope": "played",
      "state": "SP",
      "rank": 45,
      "total_players": 500,
      "points": 80
    }
  }
}
```

**Field definitions:**
- `tennis_level.ntrp_rating` — from authenticated user.
- `record.wins` / `record.losses` / `record.matches_played` — derive from completed challenge evaluations where user participated (include singles and doubles via `winner_user_id` / `winner_team`). **Losses must be computed** (currently not stored).
- `record.win_rate` — `wins / matches_played` rounded to 3 decimals; `0` when `matches_played = 0`.
- `ranking.local` — user's position in **home city** leaderboard (`RankingScope::Home`, user's `home_city_id`). Include `rank`, `total_players`, `points`, city metadata. If user has no `home_city_id` or no stats row, return `rank: null`, `total_players: 0`.
- `ranking.general` — user's position in **state-wide** leaderboard using `RankingScope::Played` aggregated across all cities in user's `state` (product decision: "Ranking Geral" = state-wide). Same null-safe behavior.

**Rank calculation:** position = 1 + count of players with higher `points`, then higher `wins` (same ordering as existing `GET /rankings`).

## 3. Tests

Add `tests/Feature/Api/DashboardApiTest.php`:
- Matchmaking: same NTRP counted, different NTRP excluded, radius respected, self excluded.
- Stats: wins/losses/win_rate correct after seeded evaluations; local and state ranks correct; unranked user returns null ranks.

## 4. Docs

Update `docs/API.md` with both endpoints.

Follow existing patterns in `routes/api.php`, `PlayerController`, `RankingService`. Add Pest feature tests.
