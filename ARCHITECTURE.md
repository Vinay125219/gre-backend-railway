# EDU Learning Platform - Architecture

> Project: GRE Coaching Institute App  
> Current Mode: Flutter + Local Mock Data  
> Target Backend: Railway-hosted API

## Folder Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── error/
│   ├── mock/              # In-memory shared data for mock mode
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── student/
│   │   ├── dashboard/
│   │   ├── courses/
│   │   ├── materials/
│   │   ├── tests/
│   │   └── performance/
│   └── admin/
│       ├── dashboard/
│       ├── students/
│       ├── courses/
│       ├── content/
│       ├── tests/
│       └── analytics/
├── routing/
└── injection_container.dart
```

## Current Data Strategy

- All repositories use `MockDatabase` (shared in-memory state).
- No external backend calls are active.
- App remains fully navigable for UI and flow validation.

## Planned Migration Strategy (Railway)

1. Introduce backend API client + config (`API_BASE_URL`).
2. Implement backend endpoints on Railway.
3. Replace mock repositories one feature at a time.
4. Keep UI/BLoC contracts stable while swapping data layer.

## Key Dependencies

| Category | Packages |
|----------|----------|
| State | `flutter_bloc`, `equatable` |
| Routing | `go_router` |
| DI | `get_it` |
| UI | `shimmer`, `google_fonts`, `flutter_animate` |
| Media | `syncfusion_flutter_pdfviewer`, `youtube_player_flutter`, `video_player` |
| Charts | `fl_chart` |
| Utilities | `dartz`, `intl`, `shared_preferences`, `file_picker` |

## Roles

- Admin: manage students, courses, content, tests, analytics
- Student: access courses/content, take tests, track performance
