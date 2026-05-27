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
