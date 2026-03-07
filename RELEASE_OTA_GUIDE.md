# Android Production APK + OTA Guide

This project already includes OTA prompt/install logic through:
- Supabase `app_updates` table
- `ota_update` plugin for Android APK updates

## 1) One-time release signing setup

Generate a keystore (run once on your machine):

```powershell
keytool -genkeypair -v -keystore C:\Users\BELINZE NEWTONE\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` from `android/key.properties.example` and fill your values.

`android/key.properties` is already gitignored in `android/.gitignore`.

## 2) Build production APK

Use your Supabase runtime values:

```powershell
cd C:\Users\BELINZE NEWTONE\Documents\Playground\DART-2.0
C:\flutter\bin\flutter.bat clean
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat build apk --release --dart-define=SUPABASE_URL=https://sjapmklwyibqvatssctw.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_1PTKefse6HZdZtEq0lnbmA_G7s_aQ34
```

Output file:

`build\app\outputs\flutter-apk\app-release.apk`

## 3) Upload APK to HTTPS host

Upload `app-release.apk` to a stable HTTPS URL (Supabase Storage, CDN, server, etc.).

## 4) Publish OTA update metadata in Supabase

```sql
update public.app_updates
set active = false
where active = true;

insert into public.app_updates (
  active,
  latest_version,
  min_supported_version,
  force_update,
  title,
  message,
  notes,
  apk_url,
  website_url,
  updated_at
) values (
  true,
  '1.0.1',
  '1.0.0',
  false,
  'Update BELTECH App',
  'A newer update is available. Please update now.',
  array['New features added', 'Performance improvements', 'Bug fixes'],
  'https://YOUR_DOMAIN/app-release.apk',
  'https://YOUR_DOMAIN/download',
  now()
);
```

## 5) Rules for OTA to work

- Keep same `applicationId`.
- Keep same signing key.
- Increase version every release in `pubspec.yaml` (`versionName+versionCode`).
- APK URL must be downloadable over HTTPS.
- User confirms install on Android.

