# MediTrack

A Flutter application for personal and family medicine management. Track your medicines, schedule dosages, scan barcodes, find nearby pharmacies, and coordinate care with family members.

---

## Features

### Medicine Management
- Add, edit, and delete medicines with name, type, category, quantity, notes, and expiry date
- Attach a photo to each medicine (camera or gallery)
- Soft-delete with a recycle bin — restore or permanently remove medicines
- View detailed medicine info and find alternatives from the same category

### Barcode & OCR
- Scan a medicine barcode to auto-fill name, type, category, and dosage
- Photograph a medicine label to extract name, expiry date, and dosage via on-device OCR
- Scanned barcodes are saved to a shared Firestore database for future lookups

### Dosage Scheduling
- Create dosage schedules with custom times and frequency
- Mark individual doses as taken — quantity decrements automatically
- Notify selected family members when a dose is due or taken

### Expiry Tracking
- View all expired medicines in a bottom sheet at a glance
- In-app notifications for medicines expiring within 7 days

### Pharmacy Search
- Locate nearby pharmacies using your device's GPS
- Results show name, address, distance, phone number, and opening hours
- Powered by the OpenStreetMap Overpass API — no API key required

### Family Accounts
- Create a family account and invite members via a one-time token
- Share medicine and dosage visibility across the family
- Remove members or manage invitations from the family settings screen

### In-App Notifications
- Persistent notification feed: dosage reminders, expiry alerts, family updates, low-stock warnings
- Mark individual or all notifications as read

### Data Export
- Export your medicine inventory and profile to a PDF saved in app storage

### Account & Security
- Email/password authentication via Firebase Auth
- Biometric login (fingerprint / face)
- Switch between multiple saved accounts
- Dark mode with persisted theme preference

---

## Tech Stack

| Layer | Library |
|---|---|
| UI framework | Flutter 3.x |
| State management | flutter_bloc / hydrated_bloc |
| Backend / database | Firebase Firestore |
| Authentication | Firebase Auth |
| File storage | Local device storage (path_provider) |
| Barcode scanning | mobile_scanner |
| OCR | google_mlkit_text_recognition |
| Biometrics | local_auth |
| PDF generation | pdf |
| Location | geolocator |
| Pharmacy data | OpenStreetMap Overpass API |
| Secure storage | flutter_secure_storage |

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.7.0`
- Dart `^3.7.0`
- Android SDK with `minSdk 24` / `targetSdk 36` (or Xcode for iOS)
- A Firebase project with the following services enabled:
  - **Authentication** — Email/Password provider
  - **Cloud Firestore** — database in production or test mode
  - **Firebase Storage** *(optional — only needed if cloud image upload is added in future)*

---

## Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd MediTrack
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

The Firebase credential files are intentionally excluded from version control (see `.gitignore`). You must supply them manually.

**Android**

1. Go to the [Firebase Console](https://console.firebase.google.com/) → your project → Project Settings → Your apps.
2. Download `google-services.json`.
3. Place it at `android/app/google-services.json`.

**iOS** *(if building for iOS)*

1. Download `GoogleService-Info.plist` from the same Firebase Console page.
2. Place it at `ios/Runner/GoogleService-Info.plist`.

A `.env.example` file at the project root documents every value found in these files:

```
FIREBASE_PROJECT_NUMBER=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_MOBILESDK_APP_ID=
FIREBASE_API_KEY=
```

### 4. Enable Firebase Authentication

In the Firebase Console → Authentication → Sign-in method, enable **Email/Password**.

### 5. Create Firestore indexes

The app uses compound Firestore queries. If you see index errors in the debug console when running the app, follow the auto-generated link in the error message to create the required index.

---

## Running the App

### Android

Connect a physical device or start an emulator (API level 24+), then:

```bash
flutter run
```

### iOS

```bash
flutter run -d ios
```

### Specific device

```bash
flutter devices          # list connected devices
flutter run -d <device-id>
```

### Release build (Android APK)

```bash
flutter build apk --release
```

---

## Project Structure

```
lib/
├── bloc/               # BLoC state management (dosage, family, image, medicine, theme)
├── model/              # Data models (Medicine, Dosage, FamilyAccount, …)
├── repository/         # Firestore data access layer
├── screens/
│   ├── auth/           # Login, signup, start screen
│   ├── Dosage/         # Add and display dosages
│   ├── family/         # Accept invitation, manage family
│   ├── Medicine/       # Add, display, recycle bin
│   └── main/           # Home, navigation, settings, notifications
├── services/           # Business logic (image, barcode, notifications, pharmacy, …)
├── style/              # App colours
├── widgets/            # Reusable UI components
└── main.dart           # Entry point
```

---

## Permissions

| Permission | Purpose |
|---|---|
| `CAMERA` | Barcode scanning and medicine photo capture |
| `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` | Gallery photo selection |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Biometric login |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | Nearby pharmacy search |
| `INTERNET` | Firebase and Overpass API calls |
