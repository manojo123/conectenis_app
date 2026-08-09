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

### 4. Create OAuth clients — Android (required for emulator/device)

> ⚠️ The app's package was renamed to **`br.com.conectenis.app`** (ago/2026).
> Android OAuth clients registered for the old `com.example.conectenis_app`
> stop working after the rename — Google Sign-In then fails with
> `ApiException: 10` (DEVELOPER_ERROR).

Each Android OAuth client is one **(package name, SHA-1)** pair, so create
**two** clients — one per keystore:

1. **Create credentials** → **OAuth client ID** → **Android**.
2. Package name: `br.com.conectenis.app`
   (must match `applicationId` in `android/app/build.gradle.kts`).
3. **SHA-1 certificate fingerprint**:

| Build | Keystore | SHA-1 (this machine, ago/2026) |
|---|---|---|
| `flutter run` (debug) | `%USERPROFILE%\.android\debug.keystore` | `E7:90:E6:3A:AD:0E:7C:A3:64:5F:B2:A0:27:23:3B:E3:53:E2:BB:70` |
| Release APK (testers) | `C:/Users/Jorge Moura/conectenis-upload.jks` | `FF:27:B2:81:BF:34:5C:0F:E4:DF:D0:00:AF:11:07:71:7F:9B:02:E4` |

To regenerate the fingerprints:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android
```

4. Create both clients. Changes can take a few minutes to propagate.

If the package or SHA-1 is wrong, Google Sign-In fails with
`PlatformException(sign_in_failed, ...ApiException: 10...)`.

> If the **Maps** key is restricted by app (package + SHA-1), update those
> restrictions with the same pairs — otherwise map tiles stop rendering in
> release builds.

### 5. OAuth client — iOS (done, ago/2026)

So iPhone users can also sign in with Google (this is independent of "Sign
in with Apple" — Apple's own provider is a separate, unrelated feature).

Configured:

| Item | Value |
|---|---|
| Bundle ID | `com.example.conectenisApp` (from `ios/Runner.xcodeproj` — **not yet renamed** to match Android's `br.com.conectenis.app`; if/when it is, this client's Bundle ID must be updated too, same pitfall as the Android package rename) |
| iOS client ID | `454816636572-v0j15vebq6n70co4bekneqh0i25gjln2.apps.googleusercontent.com` |

Set in Flutter `.env`:

```env
GOOGLE_OAUTH_IOS_CLIENT_ID=454816636572-v0j15vebq6n70co4bekneqh0i25gjln2.apps.googleusercontent.com
```

`ios/Runner/Info.plist` has the required reversed-client-ID URL scheme
(`com.googleusercontent.apps.454816636572-v0j15vebq6n70co4bekneqh0i25gjln2`)
added as a second `CFBundleURLTypes` entry, alongside the existing
`conectenis://` deep-link scheme — `google_sign_in` needs this to receive
the auth redirect on iOS. No Xcode step needed unless the Bundle ID changes.

To create a new one (e.g. after a Bundle ID rename): **Create credentials**
→ **OAuth client ID** → **iOS** → paste the Bundle ID → update `.env` and
the `Info.plist` scheme with the new client ID.

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

3. On login, tap **Conectar com Google** → pick account → app receives token immediately (RN01.1). Router then shows:
   - `/legal-acceptance` if terms not accepted
   - `/onboarding` if profile incomplete
   - main shell otherwise

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| Snackbar “configure GOOGLE_OAUTH_WEB_CLIENT_ID” | Add Web Client ID to Flutter `.env`, restart app |
| `PlatformException` / sign-in failed on Android | Wrong package name or missing/wrong **SHA-1** on Android OAuth client |
| `ApiException: 10` (DEVELOPER_ERROR) | Android OAuth client doesn't match the installed APK — register `br.com.conectenis.app` with the debug **and** upload SHA-1s (section 4) |
| API 401/422 on `/auth/social/google` | `GOOGLE_CLIENT_ID`/`SECRET` in Laravel; token expired — try again |
| No ID token | `serverClientId` must be **Web** client ID, not Android client ID |
| “Access blocked” on consent screen | Add your Gmail under **Test users** while app is in Testing |
| Works on email login but not Google | `USE_MOCK_API=false` and Sail running |

---

## Checklist

- [ ] OAuth consent screen configured + test user added
- [ ] Web OAuth client → Laravel `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`
- [ ] Same Web Client ID → Flutter `GOOGLE_OAUTH_WEB_CLIENT_ID`
- [ ] Android OAuth clients with `br.com.conectenis.app` + debug SHA-1 **and** upload SHA-1
- [ ] `flutter pub get` + full app restart
- [ ] Sail up, `USE_MOCK_API=false`
