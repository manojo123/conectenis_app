# Google Sign-In — ConecTenis

This guide wires **“Conectar com Google”** on the login screen to `POST /api/auth/social/google` on Laravel.

You need **two places** configured with the **same Google Cloud project**:

| Where | What |
|--------|------|
| **Google Cloud Console** | OAuth clients + SHA-1 (Android) |
| **Laravel `.env`** | `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` (Web client) |
| **Flutter `.env`** | `GOOGLE_OAUTH_WEB_CLIENT_ID` (= same Web client ID) |

`GOOGLE_MAPS_API_KEY` is separate (Maps SDK). Login uses **OAuth**, not the Maps key.

---

## Part 1 — Google Cloud Console

### 1. Create or select a project

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Top bar → select project → **New Project** (e.g. `ConecTenis`).
3. Wait until the project is active.

### 2. OAuth consent screen

1. **APIs & Services** → **OAuth consent screen**.
2. User type: **External** (for testing with any Google account).
3. Fill **App name** (`ConecTenis`), **User support email**, **Developer contact email**.
4. Scopes: add `email`, `profile`, `openid` (often added automatically with Google Sign-In).
5. **Test users**: while in “Testing”, add your Gmail address(es) used to test.
6. Save.

### 3. Create OAuth client — Web (required for API + ID token)

1. **APIs & Services** → **Credentials** → **Create credentials** → **OAuth client ID**.
2. Application type: **Web application**.
3. Name: `ConecTenis Web` (any label).
4. **Authorized redirect URIs** (for Laravel/Socialite if you use browser flows later):
   - `http://localhost/auth/google/callback` (optional for now)
5. **Create** → copy:
   - **Client ID** → use everywhere below as “Web Client ID”
   - **Client secret** → Laravel only

Put in **Laravel** `~/projects/conec/conectenis/.env`:

```env
GOOGLE_CLIENT_ID=123456789-xxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxx
```

Put the **same Client ID** (not the secret) in **Flutter** `.env`:

```env
GOOGLE_OAUTH_WEB_CLIENT_ID=123456789-xxxx.apps.googleusercontent.com
```

### 4. Create OAuth client — Android (required for emulator/device)

1. **Create credentials** → **OAuth client ID** → **Android**.
2. Package name: `com.example.conectenis_app`  
   (must match `applicationId` in `android/app/build.gradle.kts`).
3. **SHA-1 certificate fingerprint** (debug keystore for local dev):

**Windows (PowerShell):**

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the line `SHA1: AA:BB:CC:...` into Google Cloud (no spaces optional; colons are fine).

4. Create.

If SHA-1 is wrong, Google Sign-In fails with generic errors or no ID token.

### 5. Create OAuth client — iOS (only if you test on iPhone)

1. **Create credentials** → **OAuth client ID** → **iOS**.
2. Bundle ID: check `ios/Runner.xcodeproj` (often `com.example.conectenisApp` or similar).
3. Copy **iOS client ID** into Flutter `.env`:

```env
GOOGLE_OAUTH_IOS_CLIENT_ID=123456789-xxxx.apps.googleusercontent.com
```

4. In Xcode / `ios/Runner/Info.plist`, add URL scheme from Google (reversed client ID) if `google_sign_in` asks — see [package docs](https://pub.dev/packages/google_sign_in).

---

## Part 2 — Laravel API

1. Ensure Socialite is installed (`composer require laravel/socialite`).
2. `config/services.php` already has `google` from `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.
3. Run migrations if not done: `sail artisan migrate`.
4. Test endpoint (replace `ID_TOKEN` from a real sign-in):

```bash
curl -X POST http://localhost/api/auth/social/google \
  -H "Content-Type: application/json" \
  -d '{"token":"ID_TOKEN","device_name":"android"}'
```

Expected: `200` with `token`, `user`.

---

## Part 3 — Flutter app

1. Set in `.env`:

```env
API_BASE_URL=http://10.0.2.2/api
USE_MOCK_API=false
GOOGLE_OAUTH_WEB_CLIENT_ID=<same Web Client ID as Laravel GOOGLE_CLIENT_ID>
```

2. **Full restart** (not hot reload):

```powershell
cd C:\conec\conectenis_app
flutter pub get
flutter run
```

3. On login, tap **Conectar com Google** → pick account → app should enter the main flow (or onboarding if new user).

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Snackbar “configure GOOGLE_OAUTH_WEB_CLIENT_ID” | Add Web Client ID to Flutter `.env`, restart app |
| `PlatformException` / sign-in failed on Android | Wrong package name or missing/wrong **SHA-1** on Android OAuth client |
| API 401/422 on `/auth/social/google` | `GOOGLE_CLIENT_ID`/`SECRET` in Laravel; token expired — try again |
| No ID token | `serverClientId` must be **Web** client ID, not Android client ID |
| “Access blocked” on consent screen | Add your Gmail under **Test users** while app is in Testing |
| Works on email login but not Google | `USE_MOCK_API=false` and Sail running |

---

## Checklist

- [ ] OAuth consent screen configured + test user added
- [ ] Web OAuth client → Laravel `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`
- [ ] Same Web Client ID → Flutter `GOOGLE_OAUTH_WEB_CLIENT_ID`
- [ ] Android OAuth client with `com.example.conectenis_app` + debug SHA-1
- [ ] `flutter pub get` + full app restart
- [ ] Sail up, `USE_MOCK_API=false`
