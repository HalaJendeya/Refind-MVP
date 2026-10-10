# ReFind

ReFind is a personal recall assistant: **save** links, notes, images and documents, then **find** them again with search.

Built with Flutter, GetX and Firebase (Authentication, Cloud Firestore, Storage). Design source: the ReFind Figma file.

## What works

- Splash, 2-page onboarding (remembered after the first time), login, sign up, forgot password (Firebase email), logout
- Session persistence (Firebase keeps you logged in)
- Home with real recent memories, Quick Save (link or text)
- Add Link / Note / Image / Document (images and documents are uploaded to Firebase Storage)
- Library with type filter, intent filter and sorting
- Memory Details: open the original link or file, edit, favorite, archive, delete (with confirmation)
- Favorites, Archived Items
- Search (plain keyword matching, see limitations)
- Profile: edit display name, change password, privacy information, logout

## Project structure

```text
lib/
  main.dart                  starts Firebase, then the GetMaterialApp
  core/
    theme/                   colors + theme (Outfit font, Figma colors)
    routes/                  route names (app_routes) and screens+bindings (app_pages)
    services/                firebase_service (init) and app_binding (long-lived objects)
    utils/                   validators, snackbars, small helpers
  data/
    models/memory_model.dart the Memory class (Dart <-> Firestore)
    services/                auth_service (FirebaseAuth), memory_service (Firestore + Storage)
  features/                  one folder per feature: controller + screens
    auth, splash, onboarding, main (bottom nav), home, library,
    favorites, search, save, memory (shared data controller),
    memory_details, profile
  shared/widgets/            reusable widgets: buttons, text fields, chips, cards,
                             empty/error/loading views, sheets and dialogs
```

## Firebase setup

The Firebase project is **`refind-mvp-81aac`**.

1. **Configuration** was generated with
   `flutterfire configure --project=refind-mvp-81aac --platforms=android,ios`. It created
   `lib/firebase_options.dart`, `firebase.json` and `android/app/google-services.json`.
   `main.dart` starts Firebase with `DefaultFirebaseOptions.currentPlatform`.
2. Registered apps: Android `com.example.refind_mvp`, iOS `com.example.refindMvp`.
   For a release iOS build, also add `GoogleService-Info.plist` (Firebase Console > Project settings >
   your iOS app) to `ios/Runner` in Xcode. It is not needed for the Dart code to start Firebase.
3. In the Firebase Console, turn these on:
   - **Authentication > Sign-in method > Email/Password**
   - **Firestore Database** (create a database)
   - **Storage** (needs the Blaze plan on new projects)
4. **Publish the security rules** from this repo (they are NOT published automatically):
   - Console: Firestore > Rules, paste `firestore.rules`, Publish. Storage > Rules, paste `storage.rules`, Publish.
   - Or with the CLI, after adding `"firestore": {"rules": "firestore.rules"}` and
     `"storage": {"rules": "storage.rules"}` to `firebase.json`:
     `firebase deploy --only firestore:rules,storage --project refind-mvp-81aac`

Data layout: `users/{userId}/memories/{memoryId}` in Firestore and `users/{userId}/memories/{file}` in Storage.

## Run the app

```bash
flutter pub get
flutter run
```

Android needs an emulator or phone. Windows/web are not set up for this project.

## Checks

```bash
dart format .
flutter analyze
flutter test
```

## Limitations (on purpose)

- Search is simple keyword matching on title, note, link, file name, category, intent and tags. It is not AI or semantic search.
- Links are not downloaded: the title starts as the website name and you can edit it. There is no automatic page summary.
- Quick Save is a paste box inside the app. Receiving shares from other apps (Android share sheet) is not implemented.
- Google sign-in, profile photos, themes and extra languages appear in the design but are not implemented; the app says so when tapped.
- No offline editing, notifications, or collaboration.
