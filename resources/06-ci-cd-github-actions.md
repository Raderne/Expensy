# 06 — CI/CD with GitHub Actions

What you want:
- Every push and PR runs the backend tests, the frontend analyzer, and the frontend tests.
- Tags like `v0.1.5` trigger a release build and upload an APK as a GitHub Release asset.
- Optional: every push to `main` redeploys the backend to Fly.

Free for private repos: 2,000 GitHub Actions minutes / month. A full Expensy run is ~3 min, so you'd burn ~600 minutes in a heavy month — well under the cap.

## File layout

Workflows live in `.github/workflows/`. Each file is one workflow. We'll create three:

```
.github/workflows/
  backend.yml         # lint + test backend on push/PR touching backend/**
  frontend.yml        # analyze + test frontend on push/PR touching frontend/**
  release.yml         # build & publish APK + redeploy API on tag push
```

## 1. Backend lint + test

`.github/workflows/backend.yml`:

```yaml
name: backend
on:
  pull_request:
    paths: ['backend/**', '.github/workflows/backend.yml']
  push:
    branches: [main]
    paths: ['backend/**', '.github/workflows/backend.yml']
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: expensy_test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 10
    env:
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/expensy_test?schema=public
      JWT_ACCESS_SECRET: ci_access_secret_at_least_32_characters_xx
      JWT_REFRESH_SECRET: ci_refresh_secret_at_least_32_characters_x
      JWT_ACCESS_TTL: 15m
      JWT_REFRESH_TTL: 30d
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - run: npm ci
      - run: npx prisma migrate deploy
      - run: npx prisma db seed
      - run: npm run lint
      - run: npx tsc --noEmit
      - run: npm test
```

Notes:
- The Postgres service container gives Vitest a real DB instead of mocks. If you only want unit-level tests, drop the service block; Vitest currently passes without it because most repositories are mocked. But once you start writing integration tests (see `07-integration-tests-testcontainers.md`) you'll want it.
- `npm ci` is strictly stricter than `npm install` — it requires `package-lock.json` to match `package.json` exactly. Use it in CI.

## 2. Frontend analyze + test

`.github/workflows/frontend.yml`:

```yaml
name: frontend
on:
  pull_request:
    paths: ['frontend/**', '.github/workflows/frontend.yml']
  push:
    branches: [main]
    paths: ['frontend/**', '.github/workflows/frontend.yml']
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'        # match your dev SDK
          channel: 'stable'
          cache: true

      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage

      # Optional: report coverage to a free service
      - uses: codecov/codecov-action@v5
        if: always()
        with:
          files: frontend/coverage/lcov.info
          flags: frontend
```

Tip: `dart format --set-exit-if-changed .` makes formatting violations fail CI. Pair with a pre-commit hook locally so you don't bounce off CI for whitespace.

## 3. Tagged release: build APK, redeploy backend

`.github/workflows/release.yml`:

```yaml
name: release
on:
  push:
    tags: ['v*.*.*']
  workflow_dispatch:
    inputs:
      tag:
        description: 'Tag to release as (e.g. v0.1.5)'
        required: true

permissions:
  contents: write   # required to upload release assets

jobs:
  build-apk:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'
          cache: true

      - run: flutter pub get

      # Materialize the keystore from a base64 secret.
      - name: Decode keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > $HOME/keystore.jks
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=$HOME/keystore.jks
          EOF

      - name: Build APK
        run: |
          flutter build apk --release \
            --dart-define=API_BASE_URL=${{ secrets.PROD_API_BASE_URL }} \
            --dart-define=FLAVOR=prod \
            --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN_MOBILE }} \
            --dart-define=APP_RELEASE=expensy@${{ github.ref_name }} \
            --split-per-abi

      - name: Upload Sentry mapping
        if: secrets.SENTRY_AUTH_TOKEN != ''
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
        run: flutter pub run sentry_dart_plugin --release expensy@${{ github.ref_name }}

      - name: Rename for upload
        run: |
          cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
             expensy-${{ github.ref_name }}-arm64-v8a.apk

      - name: Create GitHub Release with APK
        uses: softprops/action-gh-release@v2
        with:
          files: frontend/expensy-*.apk
          generate_release_notes: true

  deploy-api:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Required GitHub secrets

Settings → Secrets and variables → Actions → New repository secret:

| Secret | What it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\<you>\.android\expensy-release.jks"))` |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | `expensy` (from step 1 of `03-app-signing-keystore.md`) |
| `PROD_API_BASE_URL` | e.g. `https://expensy-api.fly.dev` |
| `SENTRY_DSN_MOBILE` | DSN for `expensy-mobile` project |
| `SENTRY_AUTH_TOKEN` | Token with `project:releases` scope |
| `FLY_API_TOKEN` | `fly tokens create deploy` |

## Generating the base64 keystore

Once, from PowerShell:

```powershell
$bytes = [IO.File]::ReadAllBytes("$env:USERPROFILE\.android\expensy-release.jks")
[Convert]::ToBase64String($bytes) | Set-Clipboard
```

Paste into the `ANDROID_KEYSTORE_BASE64` secret. The keystore stays on your laptop; GitHub holds an encrypted copy.

## Branch protection (worth setting up)

Settings → Branches → Add rule for `main`:
- Require status checks to pass before merging: `backend / test`, `frontend / test`.
- Require branches to be up to date before merging.
- Don't allow bypass.

For a personal project even with one maintainer this stops "I'll just push to main quickly" mistakes from breaking the deploy pipeline.

## Cutting a release

Local workflow:

```powershell
# bump the version in pubspec.yaml first: 0.1.0+1 → 0.1.1+2
git commit -am "release: 0.1.1"
git tag v0.1.1
git push origin main --tags
```

GitHub Actions picks up the tag, runs `release.yml`, attaches the APK to the new release, and (if `deploy-api` is enabled) ships the API. The whole pipeline takes ~7–10 min.

## Pitfalls

- **Cache busting.** `subosito/flutter-action@v2` caches the Flutter SDK. If a sub-dep upgrade needs a different SDK, bump `flutter-version` here AND on your laptop in lockstep, otherwise CI compiles with one SDK and you compile with another.
- **Secrets in logs.** GitHub auto-masks values stored as secrets, but if you `echo` a secret into a file the file's contents are still visible if you `cat` them. Never `cat` `android/key.properties`.
- **`secrets.X` is empty.** Setting a secret in the wrong scope (environment vs repository vs organization) is a frequent footgun. The repo-level "Actions secrets" tab is the right place.
- **Tag triggers don't run on the same workflow file modifications.** If you edit `release.yml` and tag in the same push, the tag uses the OLD workflow file. Push the workflow change first, then tag.
- **`secrets.SENTRY_AUTH_TOKEN != ''`** — GitHub Actions doesn't allow that expression directly in `if:` in older runners; if it fails, use `if: ${{ secrets.SENTRY_AUTH_TOKEN != '' }}` syntax.
