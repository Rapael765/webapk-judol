# judol

Aplikasi pembungkus yang membuka https://mantra88.com di dalam WebView.
Dibuat dengan alat Web ke APK di aplikasi Fix Merah.

- `lib/main.dart` : seluruh kode app (alamat situs di `kAppUrl`, izin di `kPerms`)
- `android/app/src/main/AndroidManifest.xml` : daftar izin Android

Build:
    flutter pub get
    flutter build apk --release
