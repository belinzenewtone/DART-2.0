# update

App update checking and install prompt.

Sources:
- Supabase `app_updates` table (preferred)
- `APP_UPDATE_*` Dart define fallback

Android:
- Supports APK in-app update flow through `ota_update`.

Other platforms:
- Falls back to opening update website URL.
