# BloodSenz Starter — Flutter + Firebase

This starter is an early prototype scaffold, not a production-ready medical application. It uses Firebase directly from Flutter for authentication, private report-file storage, and report metadata. MongoDB and the Express metadata API have been removed.

## Architecture
- **Flutter**: sign-in/registration, dashboard, report upload and report list.
- **Firebase Authentication**: email/password identity.
- **Cloud Firestore**: per-user report metadata and status.
- **Firebase Cloud Storage**: private PDF/image files.
- **OCR/AI processing**: intentionally not implemented yet. Add a trusted server-side processor or Cloud Functions later; do not let the mobile client write trusted AI/clinical analysis fields.

## Data model
Report metadata is stored at `users/{uid}/reports/{reportId}`:
- `id`, `ownerUid`, `storagePath`
- `originalFileName`, `contentType`, `sizeBytes`
- `status` (client upload initially sets `uploaded`)
- `createdAt`, `updatedAt`

The original file is stored at `users/{uid}/reports/{reportId}/{filename}` in Cloud Storage. Do not store PDF/image bytes in Firestore.

## Firebase setup
1. Create a Firebase project at the Firebase console.
2. In **Authentication → Sign-in method**, enable **Email/Password**.
3. Create a **Cloud Firestore** database.
4. Create/enable **Cloud Storage**.
5. Install Flutter and make sure `flutter doctor` reports no blocking setup errors.
6. From `flutter_app`, create a Flutter platform project if needed, or copy these source files into an existing Flutter project.
7. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
8. Configure the Firebase apps:
   ```bash
   flutterfire configure
   ```
   This should generate `lib/firebase_options.dart`. The checked-in `lib/firebase_options.dart.example` is only a placeholder; never replace it with invented Firebase IDs or keys.
9. Apply `firestore.rules` in **Firestore Database → Rules**.
10. Apply `firebase_storage.rules` in **Storage → Rules**.
11. From `flutter_app`, run:
   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```

If starting from scratch, run `flutter create bloodsenz` in a separate working folder and merge the provided `pubspec.yaml` and `lib/` into that project. Do not overwrite platform folders in an existing working project without backing them up.

## Current prototype behavior
1. User registers or signs in using Firebase Authentication.
2. User selects a PDF, JPG, JPEG, or PNG up to 15 MB.
3. App uploads the file to the user's private Storage path.
4. App saves the metadata document in the user's Firestore subcollection.
5. Dashboard streams that user's reports and allows deleting a report.

If metadata creation fails after upload, the app attempts to delete the uploaded file. Deletion is best-effort; production should add a cleanup workflow for orphaned files.

## Security and privacy notes
- Firestore rules restrict access to each authenticated user's own report documents.
- Storage rules restrict access to the authenticated user's own files and limit size/type.
- Client-created metadata is limited to upload fields. Firestore updates are disabled in these rules; a trusted backend should later own OCR/AI results and processing status transitions.
- Rules are a starting point, not a substitute for security review. Test them in the Firebase Emulator Suite before storing real health records.
- Avoid uploading real patient data during development. Use synthetic/sample reports.
- Do not put service-account credentials in Flutter or commit them to source control.
- The current extension/content-type checks are not full file-content malware validation.
- BloodSenz is not a diagnostic system. Preserve lab-provided values, units, and reference intervals; let users review OCR results, and direct medical concerns to qualified clinicians.

## Suggested next milestones
1. Configure Firebase and verify registration/sign-in.
2. Upload a sample PDF/image and confirm metadata appears in Firestore.
3. Test cross-user access is denied using the Firebase Emulator Suite.
4. Add robust report deletion/retry handling.
5. Add OCR extraction and a review/correction screen.
6. Add plain-language explanations with safety guardrails and a longitudinal timeline.
7. Before deployment, add privacy notice, consent, retention/deletion controls, monitoring, rate limiting where appropriate, and a security review.
# BloodSenz
