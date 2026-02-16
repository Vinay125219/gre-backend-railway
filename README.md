# EDU Learning Platform

Flutter client for a GRE coaching platform.

## Current State

- Legacy PHP backend integration has been removed.
- The app is running in **local mock mode** (in-memory data only).
- Project is now cleaned and ready for Railway backend integration.

## Run The App (Mock Mode)

```bash
flutter pub get
flutter run
```

## Demo Login

- Admin: `admin@test.com`
- Student: `student@test.com`
- Password: any value with 6+ characters (example: `admin123`)

## Railway + GitHub Setup

Follow the beginner step-by-step guide:

- `docs/RAILWAY_GITHUB_SETUP.md`

That guide covers:

1. Creating and pushing your GitHub repository.
2. Connecting Railway to GitHub.
3. Configuring variables and public domain.
4. Preparing this Flutter app for Railway API URL integration.
