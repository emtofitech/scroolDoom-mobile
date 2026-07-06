# DoomScroll — Architecture & Backend Requirements

#todo
Authentication

User registration (email + Google OAuth)
User login / session persistence

App Limits

Browse installed apps list
Set per-app daily limit (in minutes)
Edit or delete an existing limit

Background Tracking
Background service polling app usage every 30 minutes
Breach detection with deduplication (one breach per app per day)

Accountability
Generate partner invite code
Share and accept invite code
Dissolve partnership
Push notification to partner on breach (FCM)
View partner's breach history

Streaks
Daily streak tracking (consecutive clean days)
Longest streak record

Platform Firebase App Id
web 1:372365108449:web:fb250fc2c34714792f83a0
android 1:372365108449:android:c0f6466d459b6dd22f83a0
ios 1:372365108449:ios:e512e4ac8c64b4e02f83a0
windows 1:372365108449:web:f9f92037f417bbc42f83a0

why's the app building with all this info without even knowing who is login in

is the app limits and breaches global and not per useer?

I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): ⏱ [MONITOR] Tick — reading device usage…
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): 📊 [USAGE] Got usage for 5 tracked apps
I/flutter (32445): 📡 [LOCK] Fetching blocked apps…
I/flutter (32445): 📡 [GET] https://doomscroll-aotr.onrender.com/api/v1/limits/blocked
I/flutter (32445): ✅ [200] {"success":true,"data":[]}
I/flutter (32445): ✅ [LOCK] 0 blocked app(s)
I/flutter (32445): ⏱ [MONITOR] No breach for com.lemon.lvoverseas: effective=0s, limit=60s, baseline=473s, total=473s, alreadyReported=false
I/flutter (32445): ⏱ [MONITOR] No breach for com.socialnmobile.dictapps.notepad.color.note: effective=0s, limit=60s, baseline=140s, total=140s, alreadyReported=false
I/flutter (32445): ⏱ [MONITOR] No breach for com.instagram.android: effective=0s, limit=180s, baseline=290s, total=290s, alreadyReported=false
I/flutter (32445): ⏱ [MONITOR] No breach for com.snapchat.android: effective=168s, limit=60s, baseline=0s, total=168s, alreadyReported=true
I/flutter (32445): ⏱ [MONITOR] No breach for com.netflix.mediaclient: effective=0s, limit=60s, baseline=25172s, total=25172s, alreadyReported=false
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): 📡 [GET] https://doomscroll-aotr.onrender.com/api/v1/breaches/me
I/flutter (32445): ✅ [200] {"success":true,"data":[{"id":"6a4bc63479f2e125eeaca407","breachType":"SCREEN_TIME_EXCEEDED","packageName":"com.snapchat.android","appLabel":"Snapchat","limitMinutes":1,"actualMinutes":1,"streakName":null,"missedDays":0,"severity":"LOW","partnerNotified":false,"acknowledged":false,"breachedAt":"2026-07-06T15:13:56.764+00:00"},{"id":"6a4bc16279f2e125eeaca404","breachType":"SCREEN_TIME_EXCEEDED","packageName":"com.netflix.mediaclient","appLabel":"Netflix","limitMinutes":1,"actualMinutes":1,"streakName":null,"missedDays":0,"severity":"LOW","partnerNotified":false,"acknowledged":false,"breachedAt":"2026-07-06T14:53:22.768+00:00"},{"id":"6a4bbd2979f2e125eeaca401","breachType":"SCREEN_TIME_EXCEEDED","packageName":"com.lemon.lvoverseas","appLabel":"CapCut","limitMinutes":1,"actualMinutes":5,"streakName":null,"missedDays":0,"severity":"HIGH","partnerNotified":false,"acknowledged":false,"breachedAt":"2026-07-06T14:35:21.266+00:00"},{"id":"6a4bbcde79f2e125eeaca3ff","breachType":"SCREEN_TIME_EXCEEDED","packag
Running Gradle task 'assembleDebug'... 295.7s
√ Built build\app\outputs\flutter-apk\app-debug.apk
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
I/flutter (32445): 🔍 [FOREGROUND] Native returned: com.android.launcher3
Installing build\app\outputs\flutter-apk\app-debug.apk.

# app-flow

doom-scroll app
user adds app to app limits page and sets a limit e.g 15 mins a day
the app begins to monitor that particular app to see when user exceeds limit, once user exceeds limit, user gets a pop notification on their screen notifiying them that " you have exceeded for limit for (app-name) for today.
then that partcular app is locked ( e.g Instagram was added by user, limit exceeded, IG is locked so user cant access i for the rest of the day).
user can still open and use doomscroll app itself to perform and emerncy unlock of that app or add other apps to app limit.

once user exceeds set limit, user gets nitified, users accountability partner also gets notified.
this breach is recorded on the breaches page of the user

and it is marked as X on the streaks page, (meaning - user broke their streak for that day) , if user doesnt exceed their limit for any app at all that day is marked as check.

user can have 4 apps added to app limit, once one app limit is broken, steak for that day automatically is X.

this is how doomscroll app shptld behave. now examine how it is behaving currently against this behavior. lets know what to change. i will share the API documentation with you to see what have been done , what works and what is left to be implemented

# bug

notification works now. remove lock out screen from showing on doomscroll app. if it cant show outside the app to override the exceeded app, lets looks for another way to lock the app. cos user still have access to the app
