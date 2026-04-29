# VillageConnect

VillageConnect is a Flutter mobile application for digitizing village-level administrative services and improving communication between residents and the Grama Niladhari (GN) office.

The project was developed for the `SE303.3 - Mobile Application Development` module at NSBM Green University Town for the 2025/2026 academic year.

## Purpose

- Reduce manual paperwork and physical visits to GN offices.
- Let residents request GN certificates digitally.
- Let residents track request status from submission to review.
- Improve village communication through official notices and community posts.
- Provide multilingual in-app guidance and chatbot support.

## Main Features

- Resident authentication with NIC-based login.
- First-login account setup for generated accounts.
- Resident and household member management.
- Digital certificate/document request flow.
- GN officer request review, approval, rejection, and additional-information workflow.
- Citizen request tracking and in-app notifications.
- Official notice board and announcements.
- Community posts, jobs/services, complaints, lost and found, and chat.
- Community moderation by authorized users.
- Emergency/incident reporting and incident dashboard.
- Admin dashboard for users, roles, certificates, audit logs, and analytics.
- Multilingual support for English, Sinhala, and Tamil.
- Help/chatbot screen powered by OpenRouter.

## User Roles

- `citizen`: requests services, tracks applications, views notices, and uses community features.
- `admin_resident`: citizen-facing administrative resident role with resident/member creation access.
- `committee`: accesses committee tasks, meetings, polls, moderation, and incident-related flows.
- `gn_officer`: reviews requests, manages citizens, publishes announcements/notices, and responds to incidents.
- `admin`: manages users, roles, certificates, audit logs, analytics, and privileged workflows.

Some permissions are controlled with capability flags as well as roles, such as `canModerateCommunity`, `canManageIncidents`, `canPublishNotices`, and `canAccessAdminDashboard`.

## Tech Stack

- Flutter and Dart
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Riverpod
- GoRouter
- Dio
- Flutter localization with ARB files

## Project Structure

```text
lib/
|-- main.dart                  App bootstrap and Firebase initialization
|-- firebase_options.dart      FlutterFire generated Firebase config
|-- core/
|   |-- config/                API/config constants
|   |-- constants/             App constants and chatbot prompts
|   |-- localization/          Locale provider and copy helpers
|   |-- models/                Firestore data models
|   |-- router/                GoRouter routes and guards
|   |-- services/              Auth, users, notifications, chatbot, approvals
|   |-- theme/                 Design tokens and Material theme
|   `-- utils/                 Validators and small helpers
|-- features/
|   |-- admin/                 Admin dashboards and user management
|   |-- auth/                  Login, first login, resident/member creation
|   |-- chatbot/               In-app AI assistant
|   |-- committee/             Tasks, meetings, polls
|   |-- community/             Feed, moderation, chat, jobs, complaints, lost/found
|   |-- documents/             Certificate requests and tracking
|   |-- emergency/             Emergency alert screen
|   |-- home/                  Citizen shell and home dashboard
|   |-- incidents/             Incident dashboard and details
|   |-- notices/               Notice board and details
|   |-- notifications/         Notification inbox
|   |-- official/              GN officer workflows
|   `-- profile/               Profile and password management
|-- l10n/                      Localization ARB and generated files
`-- shared/widgets/            Reusable VillageConnect UI widgets
```

Additional project context is available in [`overview.md`](overview.md).

## Getting Started

Install dependencies:

```powershell
flutter pub get
```

Run the app:

```powershell
flutter run
```

Run on a specific target:

```powershell
flutter run -d chrome
flutter run -d android
flutter run -d windows
```

Run checks:

```powershell
flutter analyze
flutter test
```

Regenerate localization output after editing ARB files:

```powershell
flutter gen-l10n
```

## Firebase

Firebase configuration is included for the project `village-connect-26949`.

Relevant files:

- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`
- `storage.rules`
- `lib/firebase_options.dart`
- `android/app/google-services.json`

Deploy rules and indexes when needed:

```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Security Notes

- Do not commit real production API keys or service credentials.
- The OpenRouter chatbot configuration currently lives in `lib/core/config/openrouter_secrets.dart`; move secrets to a safer configuration strategy before publishing or production use.
- Firebase Auth user deletion requires backend/admin SDK support; the current app-side admin delete flow can remove Firestore profile data but cannot fully delete Auth accounts.

## Academic Info

- Module: `SE303.3 - Mobile Application Development`
- Institution: NSBM Green University Town
- Academic Year: 2025/2026
- License: Academic use only
