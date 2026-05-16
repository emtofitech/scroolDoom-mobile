# DoomScroll — App Limits Feature Plan

## What's Needed to Make App Limits Fully Functional

### 1. 📦 Flutter Package — Installed Apps Discovery

You need a package to list all apps installed on the user's phone. Best option:

- [`installed_apps`](https://pub.dev/packages/installed_apps) or [`device_apps`](https://pub.dev/packages/device_apps) — gives you package name (`com.instagram.android`), app name, and app icon.

> ⚠️ **iOS limitation**: Apple doesn't allow querying installed apps. This feature will be **Android-only**. On iOS you'd need a fallback — either a manual text input or a pre-populated list of popular social apps.

---

### 2. 🔑 Auth Token on Every Request

All four endpoints (`GET`, `POST`, `PUT`, `DELETE`) are likely **authenticated**. The `ApiClient` already supports a `token` param — we need to read it from `TokenStorage` before every limits API call. A `LimitsService` will handle this automatically.

---

### 3. 📋 Things the API Specs Don't Tell Us (Questions for Backend Dev)

| Question | Why it matters |
|---|---|
| **What `appId` format does the backend expect?** e.g. `com.instagram.android` (Android package name)? | Must match what the installed apps package gives us |
| **Does `DELETE /api/v1/limits/{appId}` return a response body?** | Need to know for success/error handling |
| **Does `PUT` return the updated limit object?** | Same — need to know the response shape |
| **Is `todayUsageSeconds` tracked server-side or device-side?** | If device-side, you need a **usage stats** package like [`app_usage`](https://pub.dev/packages/app_usage) + Android `UsageStatsManager` permission |
| **Are there any rate limits on these endpoints?** | Affects how we debounce slider/chip changes |

---

### 4. 📱 Android Permission — `QUERY_ALL_PACKAGES`

To list installed apps on Android 11+, you need this in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

> Google Play may flag this — you'll need to justify it in your Play Console listing.

---

### 5. 🏗️ New Files to Create

| File | Purpose |
|---|---|
| `core/models/limit_models.dart` | `AppLimit` model matching the API response |
| `core/services/limits_service.dart` | `getAll()`, `create()`, `update()`, `delete()` |
| Updated `api_endpoints.dart` | Add the limits endpoints (with `{appId}` interpolation) |
| Updated `app_limits.dart` | Replace hardcoded data with API calls, installed app picker |

---

### 6. 🎯 UX Decisions Needed

1. **Chip options** — Fixed set for all apps (e.g. `15m, 30m, 1h, 2h, 3h, 4h`) or keep different chips per app?

2. **"Add App" bottom sheet** — Should it:
   - Show **all** installed apps, or filter out system apps (Settings, Phone, Camera, etc.)?
   - Show the app's **real icon** from the device?
   - Have a **search bar** to filter?

3. **Duplicate prevention** — If the user already tracks Instagram, should it be hidden from the picker or show an "Already tracked" badge?

4. **Offline/loading states** — Shimmer skeleton while limits load from the API, or a simple spinner?

---

## API Endpoints Reference

### POST `/api/v1/limits` — Create a new limit

**Request:**
```json
{
  "appId": "com.example.game",
  "dailyLimitSeconds": 3600
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "appId": "string",
    "dailyLimitSeconds": 0,
    "isActive": true,
    "todayUsageSeconds": 0
  }
}
```

### GET `/api/v1/limits` — Get all limits

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "appId": "string",
      "dailyLimitSeconds": 0,
      "isActive": true,
      "todayUsageSeconds": 0
    }
  ]
}
```

### PUT `/api/v1/limits/{appId}` — Update a limit

**Request:**
```json
{
  "dailyLimitSeconds": 7200,
  "isActive": true
}
```

### DELETE `/api/v1/limits/{appId}` — Remove a limit


What's Needed to Make App Limits Fully Functional
1. 📦 Flutter Package — Installed Apps Discovery
You need a package to list all apps installed on the user's phone. Best option:

installed_apps or device_apps — gives you package name (com.instagram.android), app name, and app icon.
⚠️ iOS limitation: Apple doesn't allow querying installed apps. This feature will be Android-only. On iOS you'd need a fallback — either a manual text input or a pre-populated list of popular social apps.

2. 🔑 Auth Token on Every Request
All four endpoints (GET, POST, PUT, DELETE) are likely authenticated. The ApiClient already supports a token param — we need to read it from TokenStorage before every limits API call. I'll build a LimitsService that handles this automatically.

3. 📋 Things the API Specs Don't Tell Us (Questions for Your Backend Dev)
Question	Why it matters
What appId format does the backend expect? e.g. com.instagram.android (Android package name)?	Must match what the installed apps package gives us
Does DELETE /api/v1/limits/{appId} return a response body?	Need to know for success/error handling
Does PUT return the updated limit object?	Same — need to know the response shape
Is todayUsageSeconds tracked server-side or device-side?	If device-side, you need a usage stats package like app_usage + Android UsageStatsManager permission
Are there any rate limits on these endpoints?	Affects how we debounce slider/chip changes
4. 📱 Android Permission — QUERY_ALL_PACKAGES
To list installed apps on Android 11+, you need this in AndroidManifest.xml:

xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
Google Play may flag this — you'll need to justify it in your Play Console listing.

5. 🏗️ New Files I'll Create
File	Purpose
core/models/limit_models.dart	AppLimit model matching the API response
core/services/limits_service.dart	getAll(), create(), update(), delete()
Updated api_endpoints.dart	Add the limits endpoints (with {appId} interpolation)
Updated app_limits.dart	Replace hardcoded data with API calls, installed app picker
6. 🎯 UX Decisions Needed From You
Chip options — You mentioned "options up to 4hrs, add 3h and 4h". Do you want a fixed set for all apps (e.g. 15m, 30m, 1h, 2h, 3h, 4h) or keep different chips per app?

"Add App" bottom sheet — Should it:

Show all installed apps, or filter out system apps (Settings, Phone, Camera, etc.)?
Show the app's real icon from the device?
Have a search bar to filter?
Duplicate prevention — If the user already tracks Instagram, should it be hidden from the picker or show a "Already tracked" badge?

Offline/loading states — Want a shimmer skeleton while limits load from the API, or a simple spinner?

Once you answer those UX questions (or tell me to just make the calls), I'll build the whole thing end-to-end.

1:09 AM
put this response in a rea