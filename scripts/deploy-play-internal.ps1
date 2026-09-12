<#
.SYNOPSIS
    Builds a release App Bundle and uploads it to Google Play via Gradle Play Publisher.

.DESCRIPTION
    Wraps `flutter build appbundle` + `gradlew publishReleaseBundle`. The AAB that
    Flutter produces is uploaded as-is (Gradle does not rebuild it).

    ONE-TIME SETUP (see scripts/README-play-deploy.md for the full walkthrough):
      1. Play Console > Setup > API access -- link a Google Cloud project.
      2. Google Cloud > IAM > Service Accounts -- create one, download its JSON key.
      3. Play Console > Users and permissions -- invite the service-account email,
         grant "Release to testing tracks" + access to br.com.conectenis.app.
      4. Point to the JSON key with one of:
           - android/key.properties:  playServiceAccountJson=C:/path/to/key.json
           - env var:                 PLAY_SERVICE_ACCOUNT_JSON=C:/path/to/key.json
           - or drop it at:           android/play-service-account.json
      5. The very first upload for a new app must be done manually in the console.

.PARAMETER Track
    Play track to release to. Default: internal. (alpha | beta | production also valid.)

.PARAMETER ReleaseNotes
    Optional release-notes text. Written to
    android/app/src/main/play/release-notes/<Track>/pt-BR.txt before upload.

.PARAMETER Draft
    Upload as a draft release (needs manual rollout in the console) instead of
    rolling out immediately.

.PARAMETER SkipBuild
    Skip `flutter build appbundle` and upload the AAB already in build/.

.PARAMETER Promote
    Do not build or upload. Promote the release already on the track (e.g. a draft
    left by an earlier -Draft run) to a completed rollout.

.EXAMPLE
    ./scripts/deploy-play-internal.ps1

.EXAMPLE
    ./scripts/deploy-play-internal.ps1 -ReleaseNotes "Correcoes no mapa e ranking."
#>
[CmdletBinding()]
param(
    [string]$Track = "internal",
    [string]$ReleaseNotes,
    [switch]$Draft,
    [switch]$SkipBuild,
    [switch]$Promote
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

# gradlew needs Java. Outside VS Code it is usually not on PATH -- fall back to the
# JDK bundled with Android Studio (same one .vscode/settings.json points at).
if (-not $env:JAVA_HOME -and -not (Get-Command java -ErrorAction SilentlyContinue)) {
    $studioJbr = "C:/Program Files/Android/Android Studio/jbr"
    if (Test-Path $studioJbr) { $env:JAVA_HOME = $studioJbr }
    else { throw "Java not found. Set JAVA_HOME to a JDK 17+." }
}

$aabDir  = Join-Path $repoRoot "build/app/outputs/bundle/release"
$aabPath = Join-Path $aabDir "app-release.aab"

Write-Host "==> ConecTenis -> Google Play ($Track track)" -ForegroundColor Cyan

if ($Promote) {
    Write-Host "==> Promoting existing $Track release to a completed rollout" -ForegroundColor Cyan
    Push-Location (Join-Path $repoRoot "android")
    try {
        & ".\gradlew.bat" promoteReleaseArtifact `
            --from-track $Track --promote-track $Track `
            --release-status completed --no-daemon
        if ($LASTEXITCODE -ne 0) { throw "gradlew promoteReleaseArtifact failed ($LASTEXITCODE)" }
    }
    finally {
        Pop-Location
    }
    Write-Host "==> Done. Check Play Console > Testing > Internal testing." -ForegroundColor Green
    return
}

if ($ReleaseNotes) {
    $notesDir = Join-Path $repoRoot "android/app/src/main/play/release-notes/$Track"
    New-Item -ItemType Directory -Force -Path $notesDir | Out-Null
    $trimmed = $ReleaseNotes.Substring(0, [Math]::Min(500, $ReleaseNotes.Length))
    Set-Content -Path (Join-Path $notesDir "pt-BR.txt") -Value $trimmed -Encoding utf8
    Write-Host "    release notes -> android/app/src/main/play/release-notes/$Track/pt-BR.txt"
}

if (-not $SkipBuild) {
    Write-Host "==> flutter build appbundle --release" -ForegroundColor Cyan
    & flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build failed ($LASTEXITCODE)" }
}

if (-not (Test-Path $aabPath)) {
    throw "AAB not found at $aabPath. Run without -SkipBuild."
}
$sizeMb = (Get-Item $aabPath).Length / 1MB
Write-Host ("    artifact: {0} ({1:N1} MB)" -f $aabPath, $sizeMb)

$gradleArgs = @(
    "publishReleaseBundle"
    "-Pplay.track=$Track"
    "-Pplay.artifactDir=$aabDir"
    "--no-daemon"
)
if ($Draft) { $gradleArgs += @("--release-status", "draft") }

Write-Host "==> gradlew $($gradleArgs -join ' ')" -ForegroundColor Cyan
Push-Location (Join-Path $repoRoot "android")
try {
    & ".\gradlew.bat" @gradleArgs
    if ($LASTEXITCODE -ne 0) { throw "gradlew publishReleaseBundle failed ($LASTEXITCODE)" }
}
finally {
    Pop-Location
}

Write-Host "==> Done. Check Play Console > Testing > Internal testing." -ForegroundColor Green
