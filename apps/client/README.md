# client_price_comparer

A Flutter mobile app used for price comparison (Android & iOS). This app depends on shared workspace packages and uses `melos` to orchestrate workspace scripts.

## Quick Start (Android)

The recommended workflow is to use the workspace's `melos` scripts from the repository root. Melos ensures shared dependencies are prepared and code generation is run in the right order.

```powershell
# From repository root
melos run get         # fetch dependencies for all packages and apps
melos run build:shared
melos run build:apps

# Run the client with flutter on a connected Android device
melos exec --scope="client_price_comparer" --flutter -- "flutter run -d <device-id>"
```

### Build APK
```powershell
cd apps/client
flutter build apk --debug
flutter install

# For production-ready builds (use keystore & key.properties for signing):
flutter build apk --release
```

### Wireless debugging
To set your Android device for wireless ADB debugging, use the helper script in the repo root:
```powershell
python .\setup_wireless_debug.py
```
You can start the app using the dedicated `melos` script from the workspace root:
```powershell
melos run run:client
```

### iOS
To build for iOS you must use a macOS machine with Xcode. Use `flutter build ipa` or open `ios/Runner.xcworkspace` in Xcode and configure code signing.

### Troubleshooting
- If code generation artifacts are missing: `melos run build:apps` or run `flutter pub run build_runner build --delete-conflicting-outputs` in packages that use build_runner.
- Ensure the correct device is selected with `flutter devices`.

For details and workspace-level scripts, check the project root `README.md` and `melos.yaml`.
