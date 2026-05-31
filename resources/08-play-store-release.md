# 08 — Play Store Release (Optional)

You don't need the Play Store. Sideloading covers personal use and small-circle sharing. The Play Store earns its keep when:
- You have more than ~5 users (sideload-update fatigue is real).
- You want auto-updates over Wi-Fi without anyone tapping anything.
- You want crash reports tied to the install via Google Play Console (separate from Sentry).

This guide is the realistic minimum path to "Internal testing" track — the cheapest form of "real" Play Store presence. You can stop there. Going to "Production" / public listing adds review hassles you don't need.

## Costs

- **$25 one-time** developer registration fee. Paid to Google, lifetime, single human account. Worth it if you'll publish anything ever.
- $0/month thereafter.

## Step 1: Register

1. Go to `https://play.google.com/console`.
2. Sign up. Pay $25. Verify your identity (Google asks for a passport/ID for new accounts — required since 2023).
3. Choose "Personal" account type. You can convert to "Organization" later if needed.

The verification can take a few days. Start it now if you think you'll want this later — the wait is the slowest part.

## Step 2: Switch from APK to App Bundle (`.aab`)

The Play Store requires Android App Bundles, not raw APKs. The bundle contains all ABIs and the Play Store generates per-device APKs on download. Smaller installs, same code.

```powershell
cd C:\Dev\projects\Expensy\frontend
flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://expensy-api.fly.dev `
  --dart-define=FLAVOR=prod `
  --dart-define=SENTRY_DSN=<your dsn> `
  --dart-define=APP_RELEASE=expensy@0.1.0+5
```

Output: `build\app\outputs\bundle\release\app-release.aab`.

This single file replaces the three `--split-per-abi` APKs from the sideload flow.

## Step 3: Decide on Play App Signing

The Play Console will prompt: "Use Play App Signing?" Say **yes**. The flow becomes:

- The keystore you generated in `03-app-signing-keystore.md` is now your **upload key** — the key Google uses to confirm uploads are from you.
- Google generates a separate **app signing key** that it holds and uses to re-sign builds for users.
- If your upload key is ever compromised, you can reset it via the Play Console without disrupting users.

You don't have to change anything in `key.properties`. The same keystore signs uploads.

## Step 4: Create the app in the Play Console

Play Console → "Create app":
- Name: `Expensy`
- Default language: English (US)
- App or game: App
- Free or paid: Free
- Declarations: tick the four required boxes (Developer Program Policies, US export laws, etc.)

You're now in the app's dashboard with a giant checklist. The truly required items for an internal-test release are:
1. **Set up your store listing** — name, short description (80 chars), full description (4000), at least 2 phone screenshots, a 512x512 icon, a 1024x500 feature graphic.
2. **App content** declarations:
   - Privacy policy URL (required if you collect any user data — and you do, you have accounts). Host one on GitHub Pages from a `privacy.md` in the repo; see template below.
   - Ads: No.
   - Content rating: complete the questionnaire honestly (no violence, no gambling, etc. — you'll land in "Everyone").
   - Target audience: 18+ (or whichever; don't pick "children" — extra requirements).
   - News app: No.
   - Data safety: declare what you collect (email, financial info) and what you do with it (only used for app function; not shared with third parties; encrypted in transit).
   - Government apps: No.
3. **Pricing & distribution** — Free, select your countries (you can pick just your own).

## Step 5: Internal testing track

This is the magic for small-circle sharing.

Play Console → Release → Testing → Internal testing → Create new release.

- Upload the `.aab`.
- Release notes: a sentence is fine.
- Save → Review → Roll out.

Then the **Testers** tab:
- Create an email list (e.g. "Trusted Testers").
- Add Gmail addresses of you + friends.
- Copy the "Join on Android" URL (looks like `https://play.google.com/apps/internaltest?id=...`).
- Share that URL with testers. They tap it on their phone, accept the invite, and the app appears in their Play Store for normal install. Updates flow automatically.

**Internal testing has no review.** Builds go live for testers within minutes. This is dramatically faster than Production (1–7 day review) and removes the "App not scanned by Play Protect" warning of pure sideloading.

You can keep using Internal testing indefinitely. Up to 100 testers, no review, all the auto-update goodness.

## Step 6: Production (if you ever go further)

If you decide to publish publicly:
1. Play Console → Production → Create new release → same flow as Internal.
2. First-time Production submissions trigger a **manual review** by Google. They run the app, look for policy violations, and either approve or come back with a "App rejected" email pointing at the rule you allegedly broke.
3. Common reasons for rejection on a finance app:
   - No clear privacy policy.
   - "Restricted financial features" without proper disclosure (you're fine — this is your own tracker, not a wallet).
   - Targeting an older API level than required (currently API 35 minimum for new apps; Flutter handles this automatically).
4. After approval, the app is publicly listed at `play.google.com/store/apps/details?id=com.expensy.expensy`.

For a personal-finance tracker that doesn't connect to a bank, Production review is almost always a one-shot pass. The bigger barrier is the privacy policy.

## Privacy policy template

Save as `privacy.md` in the repo, push to a `gh-pages` branch or enable GitHub Pages on `main`/`docs`. URL becomes `https://<you>.github.io/expensy/privacy`.

```markdown
# Expensy Privacy Policy

_Last updated: <date>_

Expensy is a personal expense-tracking app. This policy explains what data
we collect, why, and how it is protected.

## What we collect

- **Account info**: your email address and the name you choose at signup.
- **Financial data you enter**: transaction amounts, category labels, notes,
  budget targets, recurring expense / income rules.
- **Crash diagnostics**: stack traces, app version, device model, and an
  opaque user ID (NOT your email or name) via Sentry. No transaction
  contents are sent to Sentry.

We do NOT collect: bank credentials, real-name identity documents, contacts,
location, or photos.

## How we use it

Only to provide the app's core functionality: storing your transactions,
computing summaries, materializing recurring rules, and showing them back
to you. We do not sell, share, or use your data for advertising.

## Where it's stored

- Backend: PostgreSQL on Neon (EU region), encrypted at rest.
- API: Fly.io, encrypted in transit (HTTPS).
- Mobile cache: locally on your device only.

## Account deletion

Email <you@example.com> and your account and all associated data will be
deleted within 30 days. The Play Store listing also exposes a direct
deletion request link as required by Google.

## Children

Expensy is not directed to children under 13.

## Changes

This policy may be updated. Material changes will be announced in the app.

## Contact

<you@example.com>
```

Hosting on GitHub Pages is free. The Play Console needs only the URL.

## Step 7: Track-aware CI

If you want CI to publish to the Internal track on every tag, add this job to `release.yml` (from `06-ci-cd-github-actions.md`):

```yaml
publish-play:
  needs: build-apk
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: frontend
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with: { flutter-version: '3.27.0', channel: 'stable', cache: true }

    - name: Decode keystore + service account
      run: |
        echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > $HOME/keystore.jks
        echo "${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}" > $HOME/play-sa.json
        cat > android/key.properties <<EOF
        storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}
        keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
        keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
        storeFile=$HOME/keystore.jks
        EOF

    - run: flutter pub get
    - run: |
        flutter build appbundle --release \
          --dart-define=API_BASE_URL=${{ secrets.PROD_API_BASE_URL }} \
          --dart-define=FLAVOR=prod \
          --dart-define=APP_RELEASE=expensy@${{ github.ref_name }}

    - uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
        packageName: com.expensy.expensy
        releaseFiles: frontend/build/app/outputs/bundle/release/app-release.aab
        track: internal
        status: completed
```

`PLAY_SERVICE_ACCOUNT_JSON` comes from: Play Console → Setup → API access → create a service account in Google Cloud, grant it the "Release manager" role in Play Console, download the JSON key, paste it as a secret.

## Pitfalls

- **Wrong upload key.** If you upload a `.aab` signed by a different key than what the Play Console expects, the upload fails with a cryptic error. The upload key shown in the console must match the SHA-1 fingerprint of your keystore (`keytool -list -v -keystore ...`).
- **Forgot to disable Play App Signing.** Once enabled, you can't disable it without contacting support. That's fine — it's the right default — but be intentional about it.
- **Privacy policy URL returns 404.** Play rejects the release. Test the URL in incognito before you submit.
- **Targeting an older API level.** Play raises the floor every year. Currently 35 for new apps and major updates. `flutter build appbundle` uses `flutter.targetSdkVersion`, which tracks the SDK you're on. If you're on an old Flutter SDK, upgrade or set `targetSdk = 35` explicitly in `build.gradle.kts`.
- **Internal testing email list mistakes.** Testers must be added as Gmail addresses they actually use on the phone, AND they must have accepted the invite via the "Join on Android" URL. Not all of "I added them to the list" → "they can install" is automatic.
- **Pulling a release.** Once a release is on the Internal track you can't truly delete it — you can only roll out a new build with `versionCode` higher. Always increment `versionCode` on every upload.

## What ships in the bundle that didn't in the sideload APK

- Per-device APK split (smaller install for the user).
- Auto-updates (Google Play handles them).
- Crash reports in Play Console (less detailed than Sentry but free and always-on).
- Country / device gating if you want it.
- Anonymous install-base metrics.

For a personal app these are nice-to-haves. The fundamental decision is: do you trust Google to be the distribution channel forever? If yes, Play Store. If you ever want to walk away cleanly, sideload + GitHub Releases is a perfectly viable forever-state.
