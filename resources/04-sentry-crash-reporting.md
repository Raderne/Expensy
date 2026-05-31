# 04 — Crash Reporting with Sentry

Without crash reporting you only learn about a bug when a friend remembers to tell you about it. Sentry's free tier gives you 5,000 errors and 10,000 performance events per month — more than enough for a personal app with a handful of users.

This guide wires Sentry into both the Flutter app (release builds only, with R8 mapping upload) and the Node backend.

## Step 0: Create the Sentry project

1. Sign up at `https://sentry.io` (free, GitHub auth).
2. Create an organization. Personal-tier orgs are fine.
3. Create **two projects**:
   - `expensy-mobile` (platform: Flutter).
   - `expensy-api` (platform: Node).
4. From each project's "Settings → Client Keys (DSN)" page, copy the DSN. They look like:
   ```
   https://abc123@o1234.ingest.sentry.io/567890
   ```
5. From "Settings → Auth Tokens" generate a token with the scopes `project:releases` and `org:read`. You'll need this for source-map / mapping uploads from CI.

Store the DSNs and the auth token in your password manager. The mobile DSN is "public" (it ships in the APK and Sentry's quota is enforced server-side) but the auth token is **not** — never commit it.

---

## Flutter integration

### 1. Add the package

`frontend/pubspec.yaml`:
```yaml
dependencies:
  sentry_flutter: ^9.1.0
```

```powershell
cd C:\Dev\projects\Expensy\frontend
flutter pub get
```

### 2. Read the DSN from `--dart-define`

Edit `frontend/lib/config/env.dart`:

```dart
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// Empty string means "no Sentry" — used in dev so we don't pollute the
  /// production project with stack traces from `flutter run`.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static bool get isProd => flavor == 'prod';
  static bool get sentryEnabled => sentryDsn.isNotEmpty;
}
```

### 3. Wire it into `main()`

`frontend/lib/main.dart` — wrap `runApp` in `SentryFlutter.init` only when the DSN is present:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // existing Hive setup ...
  HttpCache cache;
  try {
    cache = await HiveHttpCache.open();
  } catch (_) {
    cache = InMemoryHttpCache();
  }

  Future<void> bootstrap() async {
    runApp(
      ProviderScope(
        overrides: [httpCacheProvider.overrideWithValue(cache)],
        child: const ExpensyApp(),
      ),
    );
  }

  if (Env.sentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        options.environment = Env.flavor;            // 'dev' / 'staging' / 'prod'
        options.release = const String.fromEnvironment('APP_RELEASE',
            defaultValue: 'expensy@dev');             // e.g. expensy@0.1.0+5
        options.tracesSampleRate = Env.isProd ? 0.10 : 1.0;
        options.attachScreenshot = false;             // PII — keep off for personal finance
        options.attachViewHierarchy = false;
        options.sendDefaultPii = false;
        options.debug = !Env.isProd;
      },
      appRunner: bootstrap,
    );
  } else {
    await bootstrap();
  }
}
```

Notes:
- `release` ties stack traces to a specific build. The format is `<app-slug>@<version>+<build>`. Get a sensible default at build time: `--dart-define=APP_RELEASE=expensy@0.1.0+5`.
- `tracesSampleRate` 0.10 in prod = 10% of requests get performance tracing. Bump or drop to taste; this is what controls the "performance" quota.
- `sendDefaultPii: false` makes Sentry strip IP addresses, usernames, etc. For a personal-finance app, leave it off.

### 4. Capture user info (without PII)

When the user logs in, tag the Sentry scope with a stable, **non-identifying** ID so you can group crashes per user without leaking who they are:

```dart
// frontend/lib/features/auth/application/auth_controller.dart
import 'package:sentry_flutter/sentry_flutter.dart';

// after a successful login / token refresh:
await Sentry.configureScope((scope) {
  scope.setUser(SentryUser(id: user.id)); // user.id is a CUID — opaque
});

// on logout:
await Sentry.configureScope((scope) => scope.setUser(null));
```

User-visible names, emails, and phone numbers do NOT belong here. Just the opaque ID.

### 5. Upload R8 mapping files

When you turned on `isMinifyEnabled` in `03-app-signing-keystore.md`, Gradle started shrinking and renaming classes. Without uploading the mapping, every stack trace looks like:

```
a.b.c.d(SourceFile:7)
```

Useless. Install the Sentry CLI and the Flutter Sentry plugin:

```powershell
# global CLI
npm install -g @sentry/cli
```

`frontend/pubspec.yaml`:
```yaml
dev_dependencies:
  sentry_dart_plugin: ^3.1.0

sentry:
  upload_debug_symbols: true
  upload_source_maps: true
  upload_sources: false
  project: expensy-mobile
  org: <your-org-slug>
  # auth_token is read from SENTRY_AUTH_TOKEN env var; do NOT inline it
  release: <will be set via env var or CLI>
```

Then after every release build:

```powershell
$env:SENTRY_AUTH_TOKEN = "<token from Sentry>"
flutter pub run sentry_dart_plugin --release "expensy@0.1.0+5"
```

In CI (see `06-ci-cd-github-actions.md`) this lives in a `runs-on: ubuntu-latest` job step that fires after `flutter build apk --release`.

### 6. Test the integration

Add a temporary "crash me" button somewhere unreachable in normal use, like long-pressing the app version in Profile:

```dart
GestureDetector(
  onLongPress: () => throw StateError('Sentry test crash'),
  child: Text('v0.1.0+5', style: AppTextStyles.mutedSmall),
)
```

Crash the app, wait a minute, refresh the Sentry dashboard. You should see the event in `expensy-mobile`. Once verified, **delete the test crash button**.

---

## Backend integration

### 1. Add the package

`backend/package.json`:
```powershell
cd C:\Dev\projects\Expensy\backend
npm install @sentry/node @sentry/profiling-node
```

### 2. Initialize before everything

`backend/src/instrument.ts` (new — must be imported FIRST):

```ts
import * as Sentry from '@sentry/node';
import { nodeProfilingIntegration } from '@sentry/profiling-node';

const dsn = process.env.SENTRY_DSN;
if (dsn) {
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV ?? 'development',
    release: process.env.SENTRY_RELEASE,    // e.g. expensy-api@<git-sha>
    integrations: [nodeProfilingIntegration()],
    tracesSampleRate: 0.1,
    profilesSampleRate: 0.1,
    sendDefaultPii: false,
    beforeSend(event) {
      // Belt-and-suspenders: scrub any field that looks like a token or password.
      if (event.request?.headers) {
        delete event.request.headers.authorization;
        delete event.request.headers.cookie;
      }
      return event;
    },
  });
}
```

`backend/src/index.ts` — the **very first** import:

```ts
import './instrument.js';   // must be first; pulls in Sentry before anything imports it
import { app } from './app.js';
// ... rest unchanged
```

`backend/src/app.ts` — add the error handler after your other middleware:

```ts
import * as Sentry from '@sentry/node';
// ... existing setup
Sentry.setupExpressErrorHandler(app);
// then your final error-formatting middleware
app.use(errorHandler);
```

Order matters: Sentry's handler must be added **after** all routes and **before** your final error middleware. `setupExpressErrorHandler` is a no-op when there's no DSN.

### 3. Tag userId on requests

In `backend/src/middleware/auth.ts` (or wherever `req.userId` is populated):

```ts
import * as Sentry from '@sentry/node';

// after you've verified the JWT and set req.userId:
Sentry.getCurrentScope().setUser({ id: req.userId });
```

Same rule as on mobile: opaque IDs only.

### 4. Set Fly secrets

```powershell
fly secrets set `
  SENTRY_DSN="https://...@o....ingest.sentry.io/..." `
  SENTRY_RELEASE="expensy-api@$(git rev-parse --short HEAD)"
```

The `SENTRY_RELEASE` is set fresh on every deploy by your CI (or your local `fly deploy` command).

### 5. Source-map upload (optional but recommended)

Backend is TypeScript, so prod stack traces point at `dist/...js` lines. Upload source maps to get them back to `.ts`:

```powershell
$env:SENTRY_AUTH_TOKEN = "..."
sentry-cli releases new "expensy-api@$(git rev-parse --short HEAD)"
sentry-cli releases files "expensy-api@$(git rev-parse --short HEAD)" upload-sourcemaps ./dist
sentry-cli releases finalize "expensy-api@$(git rev-parse --short HEAD)"
```

Wire into CI; not worth doing by hand.

---

## What to alert on

In Sentry, go to your project → Alerts → Create Alert.

Sensible defaults for a personal app:
1. **Any new issue type, ever, in `prod`** → email yourself.
2. **Error rate > 5% over 1 hour** → email yourself.
3. **A single issue affects > 3 users** → email yourself.

Don't set up Slack/PagerDuty. The email firehose for a project this small is fine and easy to mute when you're heads-down.

---

## What NOT to send to Sentry

This is a finance app. Be paranoid about:
- Transaction notes (free-text, can contain anything).
- Email addresses.
- Names.
- Amounts (less obviously sensitive, but still — a leaked amount + a leaked email is a vector).

The Sentry SDKs respect a `beforeSend` hook. Use it. If you ever start logging request bodies for debugging, scrub them in `beforeSend` before they leave the process. Example:

```ts
beforeSend(event) {
  if (event.request?.data && typeof event.request.data === 'object') {
    delete (event.request.data as any).note;
    delete (event.request.data as any).email;
    delete (event.request.data as any).password;
  }
  return event;
}
```

And on Flutter:
```dart
options.beforeSend = (event, hint) async {
  // Strip the body of any captured HTTP breadcrumb
  event.breadcrumbs?.removeWhere((b) => b.category == 'http' && b.data?['url']?.toString().contains('/transactions') == true);
  return event;
};
```

---

## Cost guardrails

- Sentry's free plan caps at 5k errors + 10k performance events per month. If you're not sampling, a single mis-handled error in a loop can blow through that in a day.
- Set `tracesSampleRate` low in prod (0.05 to 0.10).
- In Sentry's project settings → "Spike Protection," turn it on (free, on by default).
- Set up a per-project monthly cap so you don't accidentally upgrade to a paid plan.

---

## Pitfalls

- **DSN in the wrong project.** Easy to swap `expensy-mobile` and `expensy-api` DSNs. Check the project name in the first few events.
- **Forgot to upload mapping files.** Stack traces will be `a.b.c.d` forever until you upload. Re-run the upload for any past release — Sentry retroactively symbolicates.
- **Old releases keep emitting.** If you remove a build from circulation, its events keep coming until everyone updates. Filter by release in the Sentry UI.
- **`sendDefaultPii: true`** sneaks in via a copy-pasted example. Always set it `false` for this app.
