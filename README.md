# app-comparer
Monorepo for the price comparison application.

Fully vibe coded, do not use as is, it's  proto for me to play, there are a lot of vulnerabilities, this code is not optimized.

This repository contains multiple applications and packages used by the project:

- `apps/client` — Flutter mobile app (Android, iOS, web, desktop skeletons)
- `apps/gateway_server` — Dart server that routes API requests (didnt do)
- `apps/data_server` — Dart server that stores price data and statistics
- `packages/shared_models` — Shared models and drift schema
- `packages/api_contracts` — API requests & responses definitions
- `packages/shared_services` — Shared networking and services

## Developer: Build & Run (Quickstart)

These instructions assume you are on a developer machine with Flutter and the Android SDK installed.
They focus on building and running the mobile `client_price_comparer` application.

### Prerequisites
- Flutter (see https://docs.flutter.dev/get-started/install)
- Android SDK & platform-tools (adb) and a working JDK
- For iOS builds, a macOS machine with Xcode
- Optional: install melos to run workspace scripts (`dart pub global activate melos`)

### Quick workspace setup
```powershell
# From repository root
# Ensure `melos` is installed
dart pub global activate melos

# Fetch dependencies for every package and app
melos run get

# Build code generation artifacts for shared packages & apps
melos run build:shared
melos run build:apps
```

### Local environment (.env)
For local development the client app reads an optional `.env` file placed in `apps/client/.env` with the following keys:

- `SERVER_IP` — IP address of the data server (example: `192.168.18.6`)
- `SERVER_PORT` — Port number used by the data server (example: `8080`)

A sample file is provided at `apps/client/.env.example`. Do NOT commit your real `.env` (it's ignored by `.gitignore`).

To create the `.env` file easily run the helper script:

```powershell
# On Windows
python tools\setup_env.py
# or use the convenience batch
tools\setup_dev.bat
```

The app will fall back to `localhost:8080` when no `.env` is provided.

### Run the client app (debug/hot reload)
```powershell
# From workspace root
# Run the Flutter app using melos from the workspace
melos exec --scope="client_price_comparer" --flutter -- "flutter run -d <device-id>"

# Or from the app directory (uses the flutter tooling directly)
cd apps/client
flutter pub get
flutter run -d <device-id>
```

### Build & install an APK on an Android device
```powershell
# Debug APK (signed with debug key)
cd apps/client
flutter build apk --debug
flutter install
# Or use adb to install a built APK:
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# Release APK (production, consider signing via key.properties)
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk

# Or build an AAB for Play Store:
flutter build appbundle --release
```

### Wireless debugging (connect your Android device over WiFi)
- This project includes `setup_wireless_debug.py` in the repository root to help enable wireless ADB usage.
- Usage: ensure your Android device is connected via USB and USB debugging enabled, then run the script.
```powershell
# From repository root
python .\setup_wireless_debug.py
# The script will walk through enabling tcpip and connecting to your device IP
# It requires adb to be on PATH and a temporarily USB-connected device
```

Note: The helper script prints `melos run run:client` as an example. The workspace includes a `melos` script named `run:client` which starts the app via `flutter run` and can be executed like this:
```powershell
# From repository root
melos run run:client
```

### Tips & Troubleshooting
- Run `flutter doctor` and `flutter devices` to check your environment and connected devices.
- If generated files (drift/json_serializable) are missing, run the build steps above or use `dart run build_runner build --delete-conflicting-outputs` from the package/app directory.
- For consistent builds across packages, make sure `melos run build:shared` is run before launching apps or use `melos run build:apps`.

