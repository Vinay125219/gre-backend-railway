# EDUApp - Complete Testing Guide

## 📱 Application Overview

**App Name:** EDUApp  
**Version:** 1.0.0  
**APK Location:** `~/Desktop/EDUApp.apk`  
**Firebase Project:** `voice-notes-cdcf0`

---

## 🔧 Firebase Backend Setup

### Step 1: Access Firebase Console
```
URL: https://console.firebase.google.com/project/voice-notes-cdcf0
```

### Step 2: Enable Authentication
1. Go to **Authentication → Sign-in method**
2. Enable **Email/Password** provider
3. Create test accounts:
   | Role | Email | Password |
   |------|-------|----------|
   | Admin | admin@eduapp.com | Admin@123 |
   | Student | student@eduapp.com | Student@123 |

### Step 3: Setup Firestore Users Collection
Create documents in `users` collection matching the Firebase Auth UIDs:

**Admin User Document:**
```json
{
  "id": "<auth-uid>",
  "email": "admin@eduapp.com",
  "displayName": "Admin User",
  "role": "admin",
  "createdAt": "2026-01-10T00:00:00Z",
  "isActive": true
}
```

**Student User Document:**
```json
{
  "id": "<auth-uid>",
  "email": "student@eduapp.com",
  "displayName": "Test Student",
  "role": "student",
  "createdAt": "2026-01-10T00:00:00Z",
  "isActive": true
}
```

---

## 📋 Test Scenarios

### 1. Authentication Tests

#### Test 1.1: Student Login
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Install and launch EDUApp.apk | Splash screen with logo appears |
| 2 | Wait for loading | Login screen displays |
| 3 | Enter: student@eduapp.com / Student@123 | Fields accept input |
| 4 | Tap "Sign In" button | Loading spinner appears |
| 5 | Wait for authentication | **Student Dashboard** appears with bottom navigation |
| 6 | Verify bottom tabs | Shows: Courses, Tests, Performance, Profile |

#### Test 1.2: Admin Login
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Logout if logged in | Returns to login screen |
| 2 | Enter: admin@eduapp.com / Admin@123 | Fields accept input |
| 3 | Tap "Sign In" button | Loading spinner appears |
| 4 | Wait for authentication | **Admin Console** appears |
| 5 | Verify admin navigation | Shows: Courses, Tests, Students, Content, Analytics |

#### Test 1.3: Invalid Credentials
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter wrong email/password | Fields accept input |
| 2 | Tap "Sign In" | Error message displays (e.g., "Invalid credentials") |

#### Test 1.4: Logout
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Go to Profile tab | Profile screen displays |
| 2 | Tap "Logout" button | Confirmation dialog appears |
| 3 | Confirm logout | Returns to login screen |

---

### 2. Admin Features Tests

#### Test 2.1: Create Course
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as admin | Admin console appears |
| 2 | Tap "Courses" tab | Course list screen |
| 3 | Tap "+" button | Course creation form |
| 4 | Enter course details:<br>- Title: "GRE Verbal Master"<br>- Description: "Complete verbal prep"<br>- Section: Verbal Reasoning | All fields accept input |
| 5 | Tap "Save" | Success message, returns to list |
| 6 | Verify course in list | New course card appears |

#### Test 2.2: Create Test
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Tests" tab | Test management screen |
| 2 | Tap "Create Test" button | Test creation form |
| 3 | Enter test details:<br>- Title: "Verbal Practice 1"<br>- Duration: 30 mins<br>- Course: Select created course | All fields accept input |
| 4 | Add questions using "Add Question" button | Question form appears |
| 5 | Create MCQ:<br>- Question: "Select synonym of PRUDENT"<br>- Options: Careful, Reckless, Hasty, Bold<br>- Correct: Careful | Fields accept input |
| 6 | Save question | Question added to list |
| 7 | Tap "Save Test" | Success message, test saved |
| 8 | Toggle "Publish" | Test becomes available to students |

#### Test 2.3: Upload Content (Material)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Content" tab | Content management screen |
| 2 | Tap "Add Content" button | Upload dialog with tabs (PDF/Video/Notes) |
| 3 | Select PDF tab, enter details | Form accepts input |
| 4 | Tap "Choose PDF" button | File picker opens |
| 5 | Select a PDF file | File name displayed |
| 6 | Tap "Add" | Upload starts, progress shown |
| 7 | Verify in content list | New PDF appears in list |

#### Test 2.4: View Content URL
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Find uploaded content in list | Content card visible |
| 2 | Tap ⋮ menu → "View" | Opens content URL in external browser |

#### Test 2.5: Manage Students
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Students" tab | Student list screen |
| 2 | View student cards | Shows student names and emails |
| 3 | Tap "Add Student" | Student creation form |

#### Test 2.6: View Analytics
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Analytics" tab | Analytics dashboard |
| 2 | View charts and stats | Shows test performance charts |

---

### 3. Student Features Tests

#### Test 3.1: View Courses
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Login as student | Student dashboard |
| 2 | Tap "Courses" tab | My Courses list |
| 3 | View enrolled courses | Course cards with thumbnails |
| 4 | Tap on a course | Course details screen |

#### Test 3.2: Search Courses
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On Courses screen, tap search icon | Search field appears in app bar |
| 2 | Type "Verbal" | Courses filter to matching results |
| 3 | Clear search (tap X) | All courses shown again |

#### Test 3.3: Pull to Refresh Courses
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | On Courses screen, pull down | Refresh indicator appears |
| 2 | Wait for refresh | List updates with latest data |

#### Test 3.4: Take a Test
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Tests" tab | Available tests list |
| 2 | Tap on a published test | Test info screen |
| 3 | Tap "Start Test" | Timer starts, first question displays |
| 4 | Answer a question (tap option) | Option highlights as selected |
| 5 | Tap "Next" arrow | Next question appears, question counter updates |
| 6 | Tap "Mark for Review" | Question flagged (yellow indicator) |
| 7 | Navigate using question palette | Jump to specific question |
| 8 | Tap "Submit Test" | Confirmation dialog |
| 9 | Confirm submission | Results screen shows score and accuracy |

#### Test 3.5: View PDF Material
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open a course with PDFs | Course materials list |
| 2 | Tap on a PDF material | PDF viewer opens |
| 3 | Navigate pages (arrows/page input) | Pages change, counter updates |
| 4 | Tap bookmark icon | "Bookmarked page X" message |
| 5 | Close and reopen PDF | **Resumes from last page** (progress saved) |
| 6 | Tap share icon | Share sheet opens with PDF URL |

#### Test 3.6: Watch Video Material
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open a course with videos | Course materials list |
| 2 | Tap on a video | Video player opens |
| 3 | Play video, pause at 2 minutes | Video pauses |
| 4 | Close video player | Returns to materials |
| 5 | Reopen same video | **"Resuming from 2m 0s"** message, video seeks to position |

#### Test 3.7: Performance Dashboard
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Performance" tab | Performance dashboard |
| 2 | View overall stats | Accuracy %, Tests taken, Trend shown |
| 3 | View accuracy trend chart | Line chart with test scores |
| 4 | View section breakdown | Progress bars for Verbal, Quant, AWA |
| 5 | Tap date filter button (calendar icon) | Date range picker opens |
| 6 | Select date range (e.g., last 7 days) | "Filtering: [dates]" message appears |
| 7 | View recent tests | Test cards with scores |
| 8 | View strengths/weaknesses | Topics listed in green/red cards |

---

### 4. Dark Theme Test

#### Test 4.1: Verify Dark Mode (if enabled)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set device to dark mode in settings | System dark mode active |
| 2 | Launch EDUApp | App uses dark color scheme |
| 3 | Verify backgrounds are dark (#0F172A) | Dark surfaces visible |
| 4 | Verify text is light colored | Text readable on dark background |
| 5 | Verify buttons and cards styled correctly | Primary colors (blue) pop on dark |

---

### 5. Error Handling Tests

#### Test 5.1: Course Load Error Retry
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Disable internet on device | No connectivity |
| 2 | Open Courses tab | Error message displays |
| 3 | Verify "Try Again" button visible | Button present |
| 4 | Re-enable internet | Connectivity restored |
| 5 | Tap "Try Again" | Courses load successfully |

---

## 🔥 Firestore Test Data Templates

Add these to your Firestore database for testing:

### Course Document (`courses` collection)
```json
{
  "id": "course-001",
  "title": "GRE Verbal Mastery",
  "description": "Complete GRE verbal reasoning preparation with practice",
  "sections": ["Verbal Reasoning"],
  "thumbnailUrl": null,
  "published": true,
  "materialCount": 5,
  "testCount": 2,
  "createdAt": "2026-01-10T00:00:00Z"
}
```

### Test Document (`tests` collection)
```json
{
  "id": "test-001",
  "courseId": "course-001",
  "title": "Verbal Practice Test 1",
  "description": "20 questions covering Text Completion and Sentence Equivalence",
  "section": "verbal",
  "duration": 30,
  "totalQuestions": 20,
  "totalMarks": 40,
  "published": true,
  "shuffleQuestions": false,
  "showResults": true,
  "createdAt": "2026-01-10T00:00:00Z"
}
```

### Question Document (`tests/{testId}/questions` subcollection)
```json
{
  "id": "q-001",
  "testId": "test-001",
  "orderIndex": 0,
  "type": "mcq",
  "question": "Select the word most similar in meaning to PRUDENT",
  "options": ["Careful", "Reckless", "Hasty", "Bold"],
  "correctAnswer": "Careful",
  "explanation": "Prudent means showing care and thought for the future.",
  "marks": 2,
  "negativeMarks": 0
}
```

### Enrollment Document (`enrollments` collection)
```json
{
  "id": "enrollment-001",
  "studentId": "<student-auth-uid>",
  "courseId": "course-001",
  "enrolledAt": "2026-01-10T00:00:00Z"
}
```

---

## ✅ Testing Checklist

### Pre-Testing Setup
- [ ] APK installed on test device (EDUApp.apk from Desktop)
- [ ] Firebase project accessible
- [ ] Test user accounts created in Firebase Auth
- [ ] User documents created in Firestore `users` collection
- [ ] At least 1 course created in `courses` collection
- [ ] At least 1 test with questions created
- [ ] Student enrolled in at least 1 course

### Authentication Tests
- [ ] Student login successful
- [ ] Admin login successful
- [ ] Invalid credentials show error
- [ ] Logout works correctly

### Admin Features
- [ ] Can view/create/edit courses
- [ ] Can create tests with questions
- [ ] Can publish/unpublish tests
- [ ] Can upload PDF/Video content
- [ ] Can view content URL in browser
- [ ] Can manage students
- [ ] Can view analytics

### Student Features
- [ ] Can view enrolled courses
- [ ] Course search works
- [ ] Pull to refresh works
- [ ] Error retry button works
- [ ] Can take published tests
- [ ] Test timer works
- [ ] Can submit test and see results
- [ ] PDF viewer shows pages correctly
- [ ] PDF bookmark saves page
- [ ] PDF progress resumes on reopen
- [ ] PDF share opens share sheet
- [ ] Video player plays videos
- [ ] Video progress resumes on reopen
- [ ] Performance dashboard shows data
- [ ] Date filter picker works
- [ ] Strengths/weaknesses displayed

### UI/Theme
- [ ] Dark mode displays correctly (if system dark mode)
- [ ] All text is readable
- [ ] Buttons are properly styled
- [ ] Cards have correct shadows/borders

---

## 🐛 Troubleshooting

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| "User not found" after login | User document missing in Firestore | Create user doc with matching UID in `users` collection |
| Blank screen after login | Role field missing or incorrect | Ensure `role: "admin"` or `role: "student"` exists in user doc |
| "Permission denied" | Firestore rules too restrictive | Use test mode rules or deploy proper rules |
| Courses not showing for student | No enrollments | Create enrollment document linking student to course |
| Tests not showing | Tests not published | Set `published: true` in test document |
| PDF won't open | Invalid URL | Ensure URL is accessible and CORS-enabled |
| Video won't play | Not a valid YouTube URL | Use proper YouTube video URL |

---

## 📞 Support

For issues during testing, check:
1. Firebase Console → Authentication → Users (verify accounts)
2. Firebase Console → Firestore → Data (verify documents)
3. `flutter logs` for runtime errors
4. Device logcat for Android-specific issues

---

*Last Updated: January 10, 2026*
