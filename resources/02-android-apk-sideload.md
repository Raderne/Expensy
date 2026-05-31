# 02 — Building and Sideloading the Android APK

This is the "I just want a `.apk` to share with friends, no Play Store" path. If you ever want the Play Store, see `08-play-store-release.md`; this guide is the strictly simpler version.

## Prereqs

- Flutter SDK 3.x installed and on `PATH` (`flutter --version` works).
- Android Studio with the Android SDK and command-line tools (the Flutter installer prompts you for this).
- A signing keystore — covered in detail in `03-app-signing-keystore.md`. **Do that first.** A debug-signed APK can be installed for testing but cannot be updated to a release-signed one without uninstalling, so you want a real keystore from the start.
- Backend deployed somewhere reachable from your phone — see `01-backend-free-hosting.md`. If it's only running on your laptop's `localhost`, you can use `adb reverse` for testing but for sharing it must be on the internet.

## One-time setup

### 1. Bump the application ID (optional but recommended)

`frontend/android/app/build.gradle.kts` currently has:
```kotlin
applicationId = "com.expensy.expensy"
```
That's fine but `com.expensy.expensy` is awkward. Consider `com.<yourhandle>.expensy` (lowercase, dot-separated, ASCII). Change it once and never again — once installed on a phone, the application ID is the app's identity for life. Uninstalling and reinstalling under a new ID loses local data.

### 2. App icon and name

App name lives in `frontend/android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Expensy"
    ...>
```

For an icon set, use `flutter_launcher_icons`:

```yaml
# add to pubspec.yaml dev_dependencies
dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: "ic_launcher"
  ios: false
  image_path: "assets/icon/icon.png"   # 1024×1024 PNG, square, transparent ok
  adaptive_icon_background: "#0E1B4D"  # match your hero gradient
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
  min_sdk_android: 21
```

Then:
```powershell
flutter pub get
dart run flutter_launcher_icons
```

## Build the release APK

From `frontend/`:

```powershell
flutter clean
flutter pub get
flutter build apk --release `
  --dart-define=API_BASE_URL=https://expensy-api.fly.dev `
  --split-per-abi
```

What the flags mean:
- `--dart-define=API_BASE_URL=...` bakes the production base URL into the build. Without this it defaults to `http://10.0.2.2:3000` from `env.dart`, which is the emulator-loopback address — useless on a real phone.
- `--split-per-abi` produces three APKs (arm64-v8a, armeabi-v7a, x86_64) instead of one fat universal APK. Each is ~30% smaller. For a phone in the last ~6 years, `arm64-v8a` is the one you want.

Output:
```
build\app\outputs\flutter-apk\
  app-arm64-v8a-release.apk
  app-armeabi-v7a-release.apk
  app-x86_64-release.apk
```

For sharing, send the **arm64-v8a** APK. If you don't know the recipient's phone, send the universal APK instead — build it without `--split-per-abi`.

## Install on your own phone

### Easiest: via USB and `adb install`

1. On the phone: Settings → About Phone → tap "Build number" seven times → Developer options appears.
2. In Developer options: enable "USB debugging".
3. Plug into your laptop. The phone shows "Allow USB debugging?" — allow.
4. From PowerShell:
   ```powershell
   adb devices                                          # confirm phone is listed
   adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
   ```
   `-r` reinstalls without uninstalling first (preserves data).

### Without a cable: transfer + tap

1. Copy the `.apk` to the phone via Google Drive, email-to-self, USB drag-and-drop, AirDrop-equivalent, whatever.
2. Open the file with the phone's Files app.
3. Android prompts: "Files needs permission to install unknown apps." Tap "Settings" → enable.
4. Tap Install.

This trips the Play Protect scanner the first time. It says "App not scanned" or "Block app." Tap "More details" → "Install anyway." Once Google sees the signature a few times this prompt stops appearing.

## Sharing with a friend

Send them:
1. The `.apk` file (Telegram, WhatsApp, Drive link — anything that preserves the bytes).
2. A one-line instruction: "Open the file, allow install from this source, tap Install. If Google warns, tap 'More details' → 'Install anyway' — it's only because the app isn't on the Play Store."

Better than sending raw files: **GitHub Releases.** Push a tag, attach the APK to the release, share the release URL. Then updates are just "download the new file." If you go this route, see `06-ci-cd-github-actions.md` for an action that builds and attaches the APK on tag push.

## Updates

Sideloaded apps don't auto-update. Your options:

| Strategy | Effort | UX |
|---|---|---|
| Tell friends to redownload manually | Zero | Bad |
| In-app "check for updates" against GitHub Releases API | A weekend | Good |
| Self-host an APK + a tiny update endpoint in your backend | An afternoon | OK |
| Pay $25, put it on the Play Store internal track | $25 + a few hours | Best |

The Play Store internal track (see `08-play-store-release.md`) is by far the smoothest if you go past three or four users. For just you and one or two friends, manual download is fine.

### Sketch of the in-app update checker

```dart
// frontend/lib/core/update/update_checker.dart
class UpdateChecker {
  Future<String?> latestVersionOrNull() async {
    final res = await dio.get<Map<String, dynamic>>(
      'https://api.github.com/repos/<you>/expensy/releases/latest',
    );
    return res.data?['tag_name'] as String?;
  }
}
```

Call it from a Riverpod provider on app start, compare against `PackageInfo.fromPlatform().version`, show a non-blocking banner with a link if a newer tag exists. Don't make it blocking — if GitHub is down your app shouldn't be.

## Verifying the build before shipping

```powershell
# Should report your release signer, not the debug key
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\apksigner.bat" verify --print-certs `
  build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

The output's `Subject:` line should be the CN you used when you generated the keystore in `03-app-signing-keystore.md`, NOT `CN=Android Debug, O=Android, C=US`. If you see "Android Debug" your `key.properties` didn't load — go back and check.

## Sanity checklist before sending the APK

- [ ] `flutter clean && flutter pub get` ran successfully.
- [ ] Built with `--release` (not `--debug` or `--profile`).
- [ ] Built with the production `--dart-define=API_BASE_URL=...`.
- [ ] `apksigner verify --print-certs` shows your release cert.
- [ ] You can install over the previous version on your own phone without `-Uninstall first`.
- [ ] You hit Login, then a dashboard load, then refresh, then add an expense, then close-and-reopen — all on a real phone — and it works.
- [ ] `flutter analyze` and `flutter test` are clean.

## Pitfalls

- **Wrong `API_BASE_URL`.** Easy to forget. App launches, login screen appears, login spins forever — that's this. Check `flutter build` output for `Compiling lib\main.dart for android-arm64`; the dart-define should be in the recent shell history.
- **Mixed signers.** If you build once with the debug key and once with the release key, the second install fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstall first, then install.
- **`INSTALL_FAILED_INSUFFICIENT_STORAGE`** on older phones — not actually about storage. Usually a corrupted APK transfer. Re-copy.
- **HTTPS only.** Android cleartext HTTP is blocked by default in release builds (`usesCleartextTraffic` defaults to false). If your backend isn't on HTTPS, the app silently fails every request. Fly.io gives you HTTPS automatically.
- **Network permission.** Already in the manifest; if not, add `<uses-permission android:name="android.permission.INTERNET" />` to `AndroidManifest.xml`. It's there by default in `flutter create`.
