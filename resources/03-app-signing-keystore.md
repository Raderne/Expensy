# 03 — Android Signing: Keystore Setup

Every Android app is cryptographically signed. The signature is the app's identity — once installed under a given signer, only updates signed by the **same** key are accepted. Lose the key, lose the ability to update; you'd have to publish under a new application ID and ask users to reinstall.

So this file does two things:
1. Walks you through creating a keystore once, correctly.
2. Wires it into the Gradle build so `flutter build apk --release` uses it.

This is also the section where you make a backup decision — please don't skip it.

## Step 1: Generate the keystore

`keytool` ships with the JDK; Flutter relies on a JDK so you already have it. From PowerShell:

```powershell
$keystorePath = "$env:USERPROFILE\.android\expensy-release.jks"
New-Item -ItemType Directory -Force -Path (Split-Path $keystorePath) | Out-Null

keytool -genkey -v `
  -keystore $keystorePath `
  -alias expensy `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -storetype JKS
```

You'll be prompted for:
- Keystore password (twice). **Write this down**. Use a password manager. If you lose this, the file is a brick.
- Key password (you can press Enter to reuse the keystore password — simpler).
- Distinguished Name fields. They go into the certificate; users will never see them but they're permanent. Fill them honestly:
  ```
  CN: Reda El Marzouki
  OU: (blank or "Personal")
  O: Expensy
  L: <city>
  ST: <state/region>
  C: <2-letter country code, e.g. FR, US, MA>
  ```

10,000-day validity is ~27 years. Don't go shorter — when the cert expires you can't sign updates anymore.

### Verify the keystore

```powershell
keytool -list -v -keystore $keystorePath -alias expensy
```

You should see your `CN=...` and a `SHA256:` fingerprint. The fingerprint is what Google compares against on every install — never changes for the life of this key.

## Step 2: Back it up

This file is irreplaceable. Treat it like the SSH key to your own house.

Minimum:
- **One copy in a password manager** (1Password, Bitwarden — both support file attachments). Drop in: `expensy-release.jks`, the keystore password, the alias, and the key password.
- **One copy on a different physical device** (USB drive in a drawer, encrypted external SSD). Not on the same laptop.

Bad ideas:
- Committing it to git (even private). The history is forever; any future leak burns the key.
- Storing it on Google Drive without a folder password. Plaintext keystore + your gmail password = anyone who phishes you owns your app.
- Trusting only one location. Hardware fails.

If you ever do lose it, your fallback is to publish a new app under a different `applicationId`, ask users to reinstall, and migrate their data (which means a one-shot export endpoint in the API — painful). Just back it up.

## Step 3: Tell Gradle where the keystore is

Create `frontend/android/key.properties` — **NOT committed to git**:

```properties
storePassword=<keystore password from step 1>
keyPassword=<key password (probably same as above)>
keyAlias=expensy
storeFile=C:/Users/<you>/.android/expensy-release.jks
```

Note: use forward slashes in `storeFile` even on Windows — Gradle's properties parser doesn't like backslashes there.

Add it to `.gitignore`:

```powershell
Add-Content C:\Dev\projects\Expensy\.gitignore "`nfrontend/android/key.properties"
```

Or more robustly, edit `frontend/.gitignore` and append:
```
android/key.properties
android/app/upload-keystore.jks
```

## Step 4: Wire it into `build.gradle.kts`

Open `frontend/android/app/build.gradle.kts`. It currently has:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Replace the whole `android { ... }` block contents with:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        FileInputStream(f).use { load(it) }
    }
}

android {
    namespace = "com.expensy.expensy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.expensy.expensy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (rootProject.file("key.properties").exists()) {
                signingConfigs.getByName("release")
            } else {
                // CI without secrets, or a fresh clone — fall back to debug so the build still runs.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

Two important things to notice:
1. **The graceful fallback.** If `key.properties` is missing, Gradle still produces a (debug-signed, unshippable) APK rather than crashing. This matters for fresh clones and CI runs that don't need to ship.
2. **`isMinifyEnabled = true` + `isShrinkResources = true`** turn on R8, the Android code shrinker. Shrinks the APK by ~30% and obfuscates. **If you add Sentry later** (see `04-sentry-crash-reporting.md`), you'll need to upload the R8 mapping file so stack traces remain readable.

## Step 5: ProGuard / R8 rules for Flutter and your libraries

Flutter ships sensible defaults, but a few popular plugins need explicit keep rules. Create `frontend/android/app/proguard-rules.pro`:

```proguard
# Flutter does most of this automatically via the Flutter Gradle Plugin.
# These are belt-and-suspenders for libraries that have caused issues in the wild.

# Reflection-using JSON libraries
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*

# kotlin reflection metadata (Hive/freezed code-gen does not need this,
# but a future package might)
-keep class kotlin.Metadata { *; }

# Don't strip line numbers — keeps stack traces useful in crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

R8 is conservative when it's missing rules — it'll error at build time naming the missing class. If that happens, copy the suggested `-keep` from the build output into this file.

## Step 6: Verify

```powershell
cd C:\Dev\projects\Expensy\frontend
flutter clean
flutter build apk --release `
  --dart-define=API_BASE_URL=https://expensy-api.fly.dev `
  --split-per-abi
```

Then verify the signature:
```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$buildTools = (Get-ChildItem "$sdk\build-tools" | Sort-Object Name -Descending | Select-Object -First 1).FullName
& "$buildTools\apksigner.bat" verify --print-certs `
  C:\Dev\projects\Expensy\frontend\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

The output should include:
```
Signer #1 certificate DN: CN=Reda El Marzouki, ...
```

If it says `CN=Android Debug, O=Android, C=US` then `key.properties` wasn't loaded — re-check the file path, the property names, and that Gradle didn't fall back to the debug branch.

## "Play App Signing" — different feature, also worth knowing about

The above produces a self-signed APK suitable for sideloading. If you ever publish to the Play Store, Google offers **Play App Signing**: you upload your build signed with an *upload* key, and Google re-signs with the *app* key it holds for you. The benefit is that if you lose the upload key, Google can revoke it and let you upload a new one — you only lose the ability to update if Google somehow lost the app key too.

For sideload, Play App Signing doesn't apply. The key you generated above is the only key. See `08-play-store-release.md` for the Play track if you go that way later.

## When to rotate keys

Practically never. Android supports key rotation via APK Signature Scheme v3, but:
- Pre-Android 9 devices ignore the rotation entirely (old key still required to install).
- The mechanism is fiddly.
- The only realistic reason to rotate is compromise (someone exfiltrates your `key.properties` from CI).

Treat the keystore as "generate once, guard for life, never look at again."
