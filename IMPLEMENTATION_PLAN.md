# EDU Learning Platform - Phase 1: Foundation & Planning

> **Project Type**: Production-ready GRE Coaching EdTech Platform  
> **Platform**: Android (primary), Web-ready architecture  
> **Stack**: Flutter + Firebase (Auth, Firestore, Storage, Cloud Functions)  
> **Auth**: Firebase Authentication (Email/Password, Phone OTP)

---

## 1️⃣ Full Folder Structure Tree

```
edu_learning_platform/
├── android/                          # Android native configuration
├── ios/                              # iOS native configuration (future)
├── web/                              # Web build configuration
├── assets/
│   ├── fonts/                        # Custom typography (Outfit, Inter)
│   ├── icons/                        # Custom SVG/PNG icons
│   ├── images/                       # Static images, illustrations
│   └── lottie/                       # Loading/success/error animations
├── lib/
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # MaterialApp configuration
│   ├── injection_container.dart      # Dependency injection setup
│   │
│   ├── core/                         # Shared application core
│   │   ├── config/
│   │   ├── constants/
│   │   ├── error/
│   │   ├── extensions/
│   │   ├── network/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── features/                     # Feature modules (vertical slices)
│   │   ├── auth/                     # Authentication module
│   │   ├── student/                  # Student domain features
│   │   │   ├── dashboard/
│   │   │   ├── courses/
│   │   │   ├── materials/
│   │   │   ├── tests/
│   │   │   └── performance/
│   │   └── admin/                    # Admin domain features
│   │       ├── dashboard/
│   │       ├── students/
│   │       ├── courses/
│   │       ├── content/
│   │       ├── tests/
│   │       └── analytics/
│   │
│   ├── routing/                      # Navigation layer
│   └── services/                     # Firebase & external services
│
├── test/                             # Test directory
├── integration_test/
├── pubspec.yaml
├── firestore.rules
├── storage.rules
└── README.md
```

---

## 2️⃣ Recommended Dependencies

| Category | Package | Purpose |
|----------|---------|---------|
| **State** | `flutter_bloc` | BLoC pattern state management |
| **Firebase** | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Backend services |
| **Routing** | `go_router` | Declarative navigation with guards |
| **DI** | `get_it`, `injectable` | Dependency injection |
| **UI** | `flutter_svg`, `shimmer`, `lottie`, `google_fonts` | Design system |
| **PDF/Video** | `syncfusion_flutter_pdfviewer`, `youtube_player_flutter` | Content viewers |
| **Charts** | `fl_chart`, `percent_indicator` | Analytics visualization |
| **Utils** | `equatable`, `dartz`, `freezed` | Functional programming helpers |

---

## 3️⃣ Architecture Overview

### User Roles
- **Admin**: Full access to content, tests, students, analytics
- **Student**: Read courses/materials, attempt tests, view performance

### Role Enforcement
- UI Level: Conditional widget rendering
- Router: GoRouter redirect guards
- Backend: Firestore security rules

### Data Flow
```
UI → BLoC Event → Use Case → Repository → DataSource → Firebase
                                    ↓
UI ← BLoC State ← Entity ← Model ←─┘
```

---

## 4️⃣ Key Modules

### Student Module
- Dashboard with performance snapshot
- Enrolled courses & materials (PDF, video, notes)
- Timer-based mock tests with auto-submission
- Test history with accuracy & section analysis

### Admin Module
- Create/manage students and assign courses
- Upload PDFs, add video links, create notes
- Create MCQ/MSQ tests with sections
- Monitor student participation & performance

### Exam Engine
- Question types: MCQ, MSQ, NAT (extendable)
- Timer with auto-submit via Cloud Function
- Instant result calculation with section breakdown

---

## 5️⃣ Firestore Collections

```
users/{uid}           → role, email, displayName
students/{id}         → userId, assignedCourses, metadata
courses/{id}          → title, sections, published
materials/{id}        → courseId, type, url, published
tests/{id}            → duration, totalMarks, published
  └── questions/{id}  → type, options, correctAnswer
test_attempts/{id}    → testId, studentId, answers, result
```

---

## 6️⃣ Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Firestore read costs | Pagination, caching, composite indexes |
| PDF storage costs | Compress before upload |
| Real-time listener overload | Use read-once where appropriate |
| Security | Firestore rules + Cloud Functions for admin ops |

---

**Status**: Phase 1 Complete ✅
