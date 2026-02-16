# EDU Learning Platform - Feature Verification Checklist

Use this checklist to verify all features work on **Chrome (Web)** and **Android (App)**.

| ✅ = Pass | ❌ = Fail | ⚠️ = Partial | ➖ = Not Tested |

**Last Updated:** January 13, 2026

---

## 1. Authentication

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Splash screen loads | ✅ | ➖ | Animated logo and loading state |
| Login form displays | ✅ | ➖ | Email/password fields rendered |
| Email validation | ✅ | ➖ | Form validation works |
| Password validation | ✅ | ➖ | Form validation works |
| Login with valid credentials | ✅ | ➖ | admin@greapp.com / Admin@123456 |
| Login error handling (wrong password) | ➖ | ➖ | |
| "Remember me" checkbox | ➖ | ➖ | |
| Forgot password dialog | ➖ | ➖ | |
| Admin redirect after login | ✅ | ➖ | Redirects to /admin/dashboard |
| Student redirect after login | ➖ | ➖ | |
| Logout functionality | ✅ | ➖ | Successfully clears session |
| Session persistence | ✅ | ➖ | Session remembered on refresh |

---

## 2. Student Dashboard

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Dashboard loads successfully | | | |
| Welcome card with greeting | | | |
| User name displays correctly | | | |
| My Courses section | | | |
| Course cards display | | | |
| Upcoming Tests section | | | |
| Test cards display | | | |
| Performance stats display | | | |
| Pull-to-refresh | | | |
| Bottom navigation bar | | | |
| Navigate to Courses | | | |
| Navigate to Tests | | | |
| Navigate to Performance | | | |
| Notifications icon | | | |
| Profile menu | | | |

---

## 3. Student - Courses

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Courses list loads | | | |
| Search courses | | | |
| Course card displays title | | | |
| Course card shows description | | | |
| Course card shows material count | | | |
| Course card shows test count | | | |
| Section chips (Verbal/Quant/AW) | | | |
| Empty state when no courses | | | |
| Error state with retry | | | |
| Navigate to course details | | | |

---

## 4. Student - Course Details

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Course details load | | | |
| Course title/description | | | |
| Materials tab | | | |
| Tests tab | | | |
| Material list displays | | | |
| Test list displays | | | |
| Open PDF material | | | |
| Open Video material | | | |
| Start test from course | | | |

---

## 5. Student - Materials

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| **PDF Viewer** | | | |
| PDF loads correctly | | | |
| Page navigation | | | |
| Zoom in/out | | | |
| **Video Player** | | | |
| Video loads correctly | | | |
| Play/Pause | | | |
| Seek functionality | | | |
| Fullscreen mode | | | |

---

## 6. Student - Test Taking

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Test loads with questions | | | |
| Timer displays | | | |
| Progress bar | | | |
| Question navigation (prev/next) | | | |
| Question palette | | | |
| **MCQ Questions** | | | |
| Single option selection | | | |
| Option deselection | | | |
| **MSQ Questions** | | | |
| Multiple options selection | | | |
| **NAT Questions** | | | |
| Numeric input field | | | |
| Mark for review | | | |
| Clear response | | | |
| Submit test dialog | | | |
| Test submission | | | |

---

## 7. Student - Performance

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Performance screen loads | | | |
| Verbal accuracy display | | | |
| Quant accuracy display | | | |
| Total tests attempted | | | |
| Improvement trend | | | |
| Performance charts | | | |

---

## 8. Admin Dashboard

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Dashboard loads successfully | | | |
| Students count stat card | | | |
| Courses count stat card | | | |
| Tests count stat card | | | |
| Materials count stat card | | | |
| Quick Actions section | | | |
| Add Student button | | | |
| Add Course button | | | |
| Add Test button | | | |
| Recent Activity section | | | |
| Database status section | | | |
| Bottom navigation | | | |
| Navigate to Students | | | |
| Navigate to Courses | | | |
| Navigate to Tests | | | |
| Navigate to Analytics | | | |
| Logout functionality | | | |

---

## 9. Admin - Students Management

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Students list loads | | | |
| Search students | | | |
| Student card displays info | | | |
| Add new student | | | |
| Edit student | | | |
| Delete student | | | |
| Student creation form validation | | | |
| Save student | | | |

---

## 10. Admin - Course Management

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Course list loads | | | |
| Create new course | | | |
| Edit course | | | |
| Delete course | | | |
| Course form - title | | | |
| Course form - description | | | |
| Course form - sections (Verbal/Quant/AW) | | | |
| Publish/Unpublish course | | | |
| Save course | | | |

---

## 11. Admin - Content Management

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Content list loads | | | |
| Add PDF material | | | |
| Add Video material | | | |
| Edit material | | | |
| Delete material | | | |
| Assign material to course | | | |
| File upload (if applicable) | | | |

---

## 12. Admin - Test Management

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Tests list loads | | | |
| Create new test | | | |
| Edit test | | | |
| Delete test | | | |
| Test form - title | | | |
| Test form - description | | | |
| Test form - duration | | | |
| Test form - assign to course | | | |
| Add MCQ question | | | |
| Add MSQ question | | | |
| Add NAT question | | | |
| Question with options | | | |
| Set correct answer | | | |
| Add explanation | | | |
| Set marks/negative marks | | | |
| Publish/Unpublish test | | | |
| Save test | | | |

---

## 13. Admin - Analytics

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| Analytics dashboard loads | | | |
| Student performance charts | | | |
| Course completion stats | | | |
| Test attempt stats | | | |

---

## 14. Cross-Platform & Backend Readiness

| Feature | Chrome | Android | Notes |
|---------|--------|---------|-------|
| App runs in local mock mode | ✅ | ✅ | Backend integration intentionally disabled |
| Railway backend URL configured | ➖ | ➖ | Add after Railway deploy |
| Data syncs across platforms | ➖ | ➖ | |
| Session persistence | ✅ | ➖ | Using localStorage on web |
| Responsive UI on different sizes | ➖ | ➖ | |
| Loading states (shimmer) | ➖ | ➖ | |
| Error handling & retry | ✅ | ➖ | 401 errors handled gracefully |
| Network error handling | ➖ | ➖ | |

---

## Testing Commands

```bash
# Run on Android
flutter run

# Run on Chrome (Web)
flutter run -d chrome

# Build APK
flutter build apk --release

# Build Web
flutter build web --release
```

---

## Railway Backend Verification (After Deploy)

```bash
# Replace with your deployed Railway backend URL
curl -i https://<YOUR-RAILWAY-APP>.up.railway.app/health
```
