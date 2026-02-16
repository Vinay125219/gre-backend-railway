# Phase 3: Core Implementation Plan

## Deliverables

### 1. Theme System
- `app_colors.dart` - Color palette (EdTech modern)
- `app_text_styles.dart` - Typography (Google Fonts)
- `app_theme.dart` - ThemeData configuration
- `app_spacing.dart` - Consistent spacing

### 2. Dependency Injection
- `injection_container.dart` - GetIt + Injectable setup
- Register all services, repositories, BLoCs

### 3. Router Configuration
- `app_router.dart` - GoRouter with routes
- `route_guards.dart` - Auth & role-based guards
- `route_names.dart` - Named route constants

### 4. Core Utilities
- `failures.dart` - Error handling with Either
- `firebase_paths.dart` - Firestore collection paths
- Base widgets (buttons, cards, inputs)

### 5. Auth Module
- `user_entity.dart` / `user_model.dart`
- `auth_repository.dart` - Firebase Auth wrapper
- `auth_bloc.dart` - Login/logout state
- `login_screen.dart` - UI

---

## Implementation Order

1. Theme system (no dependencies)
2. Core utilities & constants
3. Dependency injection setup
4. Firebase services
5. Auth module (data → domain → presentation)
6. Router with guards
7. App entry point integration
