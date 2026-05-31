# 05 — Flavors and Per-Environment Builds

Two-flavor minimum: `dev` (your laptop / emulator) and `prod` (the APK on a phone). `staging` is optional. The Flutter side mostly happens via `--dart-define`; the Android side needs `productFlavors` if you want different package IDs, app names, or icons per environment.

## What `env.dart` already gives you

```dart
class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://10.0.2.2:3000',
  );
  static const String flavor = String.fromEnvironment(
    'FLAVOR', defaultValue: 'dev',
  );
  static bool get isProd => flavor == 'prod';
}
```

Adequate for read-only config. Anywhere in the app you want a flavor-dependent value, derive it from `Env.flavor`. Don't sprinkle `String.fromEnvironment` calls around — keep them centralized in `env.dart` so the contract is one file.

## Strategy A: just `--dart-define`, one app installed at a time

The simplest setup. One `applicationId`, one app on the phone, but different builds inject different URLs.

| Flavor | Build command |
|---|---|
| `dev` | `flutter run` (defaults to `dev` and emulator-localhost) |
| `dev`, physical device | `flutter run --dart-define=API_BASE_URL=http://<lan-ip>:3000` |
| `staging` | `flutter build apk --release --dart-define=API_BASE_URL=https://expensy-staging-api.fly.dev --dart-define=FLAVOR=staging` |
| `prod` | `flutter build apk --release --dart-define=API_BASE_URL=https://expensy-api.fly.dev --dart-define=FLAVOR=prod` |

Pros: nothing to change in `build.gradle.kts`.
Cons: only one Expensy at a time on a given phone; if you install staging, prod gets replaced.

For personal use this is usually fine.

## Strategy B: Android `productFlavors`, side-by-side installs

When you want `Expensy (dev)`, `Expensy (staging)`, and `Expensy` to all live on the same phone, you need different application IDs per flavor. Add `productFlavors` to `frontend/android/app/build.gradle.kts` inside `android { }`:

```kotlin
flavorDimensions += "environment"

productFlavors {
    create("dev") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
        resValue("string", "app_name", "Expensy Dev")
    }
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        versionNameSuffix = "-staging"
        resValue("string", "app_name", "Expensy Stage")
    }
    create("prod") {
        dimension = "environment"
        resValue("string", "app_name", "Expensy")
    }
}
```

Then change `AndroidManifest.xml`:
```xml
<application
    android:label="@string/app_name"
    ...>
```

Now:
- `com.expensy.expensy.dev` → "Expensy Dev"
- `com.expensy.expensy.staging` → "Expensy Stage"
- `com.expensy.expensy` → "Expensy"

Build commands:
```powershell
flutter build apk --release --flavor dev `
  --dart-define=API_BASE_URL=http://192.168.1.42:3000 `
  --dart-define=FLAVOR=dev

flutter build apk --release --flavor staging `
  --dart-define=API_BASE_URL=https://expensy-staging-api.fly.dev `
  --dart-define=FLAVOR=staging

flutter build apk --release --flavor prod `
  --dart-define=API_BASE_URL=https://expensy-api.fly.dev `
  --dart-define=FLAVOR=prod
```

Each produces a distinct APK that installs alongside the others. The output paths are:
```
build/app/outputs/flutter-apk/app-dev-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-staging-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-prod-arm64-v8a-release.apk
```

## Per-flavor icons (optional)

To color-shift the icon per flavor so you can tell them apart on the home screen:

```
frontend/android/app/src/dev/res/mipmap-*/ic_launcher.png
frontend/android/app/src/staging/res/mipmap-*/ic_launcher.png
frontend/android/app/src/main/res/mipmap-*/ic_launcher.png   # prod default
```

Gradle picks the source set matching the active flavor and overlays it on `main/`. Easiest way to make these: use `flutter_launcher_icons` once per flavor with different `image_path`s, or do it by hand in any image editor.

## Stitching it together with IDE configurations

VS Code: `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Expensy: dev (emulator)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=API_BASE_URL=http://10.0.2.2:3000",
        "--dart-define=FLAVOR=dev"
      ]
    },
    {
      "name": "Expensy: dev (LAN)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--flavor", "dev",
        "--dart-define=API_BASE_URL=http://192.168.1.42:3000",
        "--dart-define=FLAVOR=dev"
      ]
    },
    {
      "name": "Expensy: prod (release)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "args": [
        "--flavor", "prod",
        "--dart-define=API_BASE_URL=https://expensy-api.fly.dev",
        "--dart-define=FLAVOR=prod"
      ]
    }
  ]
}
```

Android Studio: Run → Edit Configurations → Flutter → set "Build flavor" and "Additional run args" identically.

## Multiple backends, mirrored on Fly

For three flavors you need three backends. Easiest: separate Fly apps + separate Neon branches (Neon has free branching — you get a writable copy of the production schema in seconds).

```powershell
# in backend/, after editing fly.toml to set app = "expensy-staging-api":
fly apps create expensy-staging-api
fly secrets set --app expensy-staging-api `
  DATABASE_URL="postgresql://...staging-pooler..." `
  JWT_ACCESS_SECRET="<different secret>" `
  JWT_REFRESH_SECRET="<different secret>"
fly deploy --app expensy-staging-api --config fly.staging.toml
```

Keep `fly.toml` (prod) and `fly.staging.toml` next to each other in `backend/`. Same image, different config, different DB.

## When NOT to bother with flavors

If you're the only user, skip Strategy B. Just `flutter run` for dev work and `flutter build apk --release --dart-define=API_BASE_URL=https://expensy-api.fly.dev` when you want to update your phone. The complexity payoff arrives at "two real users testing different things" or "I want to ship a beta without breaking my main install."

## Pitfalls

- **`--flavor` without matching Gradle config.** If you pass `--flavor staging` but `productFlavors` doesn't define `staging`, Gradle's error is opaque ("Could not find configuration `stagingDebugRuntimeClasspath`"). Define the flavor first.
- **Forgetting `FLAVOR` in dart-define.** Your app says it's "prod" inside the code (because the default is `dev`, but you might forget to pass it) — Sentry tags wrong, feature flags wrong, etc. Always pass `FLAVOR` when you pass `API_BASE_URL`. Or: make `Env.flavor` derive from `API_BASE_URL` so they can't diverge.
- **Backwards-compat with installed users.** If you launched without a suffix and later add `applicationIdSuffix = ".prod"` to the prod flavor, you've effectively renamed your app — existing installs become "old Expensy" and the new build is a fresh app. Decide before you ship to anyone real.
