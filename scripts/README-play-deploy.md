# Automated Google Play deploys

`scripts/deploy-play-internal.ps1` builds a release App Bundle and uploads it to a
Google Play track (default: **internal testing**) using
[Gradle Play Publisher](https://github.com/Triple-T/gradle-play-publisher) (GPP
`3.11.0`, wired into `android/settings.gradle.kts` + `android/app/build.gradle.kts`).

## One-time setup

### 1. Link a Google Cloud project

Play Console → **Setup → API access** → *Link a Google Cloud project* (create one
if needed). Accept the API terms.

### 2. Create a service account

In the Cloud project: **IAM & Admin → Service Accounts → Create service account**.
No Cloud roles needed. Open it → **Keys → Add key → JSON** → download the file.

### 3. Grant it Play access

Play Console → **Users & permissions → Invite new users** → paste the service
account email (`…@….iam.gserviceaccount.com`).

- Account permissions: **Release to testing tracks** (and *Manage testing track
  releases*). Add *Release to production* only if you'll deploy production too.
- App permissions: add **ConecTenis** (`br.com.conectenis.app`).

Propagation can take a few minutes to ~24h the first time.

### 4. Point the build at the key

Pick one (all are git-ignored):

| Method | How |
| --- | --- |
| `key.properties` | add `playServiceAccountJson=C:/Users/you/conectenis-play.json` to `android/key.properties` |
| Env var | set `PLAY_SERVICE_ACCOUNT_JSON=C:/Users/you/conectenis-play.json` |
| Default path | save the file as `android/play-service-account.json` |

### 5. First upload

Already done manually for this app. (The Play API cannot create the first release
of a brand-new app or app version on a track that has never been used.)

## Usage

```powershell
# Build + upload to internal testing, roll out immediately
./scripts/deploy-play-internal.ps1

# With release notes (pt-BR, written to the GPP release-notes file)
./scripts/deploy-play-internal.ps1 -ReleaseNotes "Correções no mapa e no ranking."

# Upload as a draft (review/submit manually in the console)
./scripts/deploy-play-internal.ps1 -Draft

# Re-upload the last build without rebuilding
./scripts/deploy-play-internal.ps1 -SkipBuild

# Different track
./scripts/deploy-play-internal.ps1 -Track beta
```

## Bump the version first

Play rejects an AAB whose `versionCode` already exists. Increment the build number
in `pubspec.yaml` (`version: 1.0.1+2` → `1.0.2+3`) before deploying.

## Notes

- The script runs `flutter build appbundle --release`, then
  `gradlew publishReleaseBundle -Pplay.artifactDir=…` so the exact AAB Flutter
  produced is what gets uploaded.
- Signing still comes from `android/key.properties` (upload key). Play App Signing
  re-signs on Google's side.
- Direct Gradle tasks also work: `cd android && ./gradlew publishReleaseBundle`
  (rebuilds the AAB via Gradle), `./gradlew bootstrap` (pull current listing),
  `./gradlew promoteArtifact --from-track internal --promote-track beta`.
- To move this to CI later, the same GPP config works from a GitHub Actions job —
  add the keystore and service-account JSON as encrypted secrets.
