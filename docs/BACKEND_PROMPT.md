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

## 8. Run migrations & tests

- `php artisan migrate`
- Run Pest tests for places (nearby name filter, rate policy, update policy) and user profile `date_of_birth`.

---

**Flutter already handles (no API required for mock):** client-side place name filter when API ignores `name`; self player via auth profile; relative avatar URL resolution via `API_BASE_URL` origin.
