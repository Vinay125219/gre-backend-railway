# Phase 2: Project Initialization Commands

> **Run commands in order. Each section must complete before proceeding.**

---

## 1️⃣ Flutter Project Setup

```bash
cd /home/vinay/Music/GREAPP
flutter create --org com.grecoaching --platforms android,web edu_learning_platform
cd edu_learning_platform
```

---

## 2️⃣ Firebase CLI Setup

```bash
# Install Firebase CLI (if needed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure FlutterFire (after creating project in Firebase Console)
flutterfire configure --project=edu-learning-platform

# Initialize Firebase services
firebase init
# Select: Firestore, Functions, Storage, Emulators
```

---

## 3️⃣ Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.3
  hydrated_bloc: ^9.1.2

  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0

  # Routing & DI
  go_router: ^13.2.0
  get_it: ^7.6.4
  injectable: ^2.3.2

  # UI
  flutter_svg: ^2.0.9
  shimmer: ^3.0.0
  google_fonts: ^6.1.0
  lottie: ^3.0.0

  # PDF & Video
  syncfusion_flutter_pdfviewer: ^24.1.0
  youtube_player_flutter: ^8.1.2

  # Charts & Utils
  fl_chart: ^0.66.0
  equatable: ^2.0.5
  dartz: ^0.10.1
  freezed_annotation: ^2.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  injectable_generator: ^2.4.1
  freezed: ^2.4.6
  json_serializable: ^6.7.1
```

```bash
flutter pub get
```

---

## 4️⃣ Folder Structure

```bash
# Core
mkdir -p lib/core/{config,constants,error,extensions,network,theme,utils}
mkdir -p lib/core/widgets/{buttons,cards,dialogs,inputs,loaders,states}

# Auth
mkdir -p lib/features/auth/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,screens,widgets}}

# Student modules
mkdir -p lib/features/student/{dashboard,courses,materials,tests,performance}/{data,domain,presentation/{bloc,screens,widgets}}

# Admin modules
mkdir -p lib/features/admin/{dashboard,students,courses,content,tests,analytics}/presentation/{bloc,screens,widgets}

# Routing & Services
mkdir -p lib/{routing,services/firebase}

# Assets & Tests
mkdir -p assets/{fonts,icons,images,lottie}
mkdir -p test/{core,features,fixtures,mocks}
```

---

## 5️⃣ Verify Setup

```bash
flutter doctor
flutter run -d chrome
```

---

**Next**: Core module implementation (theme, routing, DI)
