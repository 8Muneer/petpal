# 🐾 PetPal — Pet Care Marketplace

PetPal is a Hebrew-first (RTL) mobile marketplace that connects pet owners with trusted service providers — dog walkers, pet sitters — and wraps the whole pet-care experience in one app: community feed, lost & found with AI photo matching, pet-friendly places to explore, real-time chat, reviews, and a full admin console.

Built with **Flutter** on a **Firebase** backend (Firestore, Auth, Storage, Cloud Functions, FCM), with **Gemini AI** powering lost-pet photo matching and moderation triage.

---

## ✨ Feature Highlights

### For pet owners
- **Service marketplace** — browse walkers & sitters, filter by price/location, view provider profiles with ratings
- **Requests & offers** — post a walk/sitting request, receive provider offers, accept or refuse each one
- **Bookings with a real lifecycle** — pending → accepted → awaiting confirmation → completed, with two-sided completion confirmation, cancellation, and dispute paths
- **Reviews** — rate a provider only after a genuinely completed booking (enforced server-side)
- **My Pets** — pet profiles with photos that plug into requests
- **Lost & Found + AI matching** — report a lost/found pet; a Cloud Function pipeline pre-filters candidates and asks **Gemini** to compare photos, attaching scored matches to the post
- **Community feed** — posts, likes, comments
- **Explore** — curated pet-friendly places (dog parks, vets, stores) with emergency badges
- **Chat** — real-time messaging between owners and providers
- **Push notifications** — server-generated (FCM) for every booking lifecycle event

### For service providers
- Provider dashboard with incoming requests, applications, and booking management
- Service listings (walking / sitting) with pricing and availability
- Verification flow reviewed by admins

### Admin console
- Dashboard with live stats, user directory, sitter verification queue
- **AI-assisted moderation** — reports are triaged by Gemini (severity / category / suggested action) via a Cloud Function; the admin always makes the final call
- POI (places) management, global alerts, role management with audit trail

---

## 🔐 Security Model (the short version)

Security is enforced **server-side**, not in the UI:

- **Roles**: `petOwner` / `serviceProvider` / `admin`. Role changes go exclusively through the `setUserRole` Cloud Function — audited in `admin_audit`, protected against demoting the last admin, mirrored to custom auth claims. No client write path can escalate a role.
- **Firestore rules**: owner-only updates on requests, participant-only chat, allow-listed interaction fields on posts (`likes`, `commentCount`), booking status machine validated transition-by-transition, review creation requires a completed booking owned by the reviewer.
- **Ratings can't be forged**: rating aggregates are written only by the `onReviewWrite` Cloud Function.
- **Demo seeding is admin-only**: every `isMock` branch in the rules additionally requires an admin caller.
- **Storage rules**: per-user path scoping, image-only uploads, 10MB cap, admin custom-claim gate on POI images.
- **AI keys never ship in the app**: all Gemini calls (matching, comparison, triage) run inside Cloud Functions using a server-side key.

Rules and functions are covered by emulator test suites (see Testing below).

---

## 🏗️ Architecture

```
lib/
├── core/            # theme (design tokens), router, shared widgets, utils, services
├── features/        # feature-first, each with clean-architecture layers:
│   ├── auth/        #   data / domain / presentation
│   ├── booking/
│   ├── walks/  sitting/  applications/
│   ├── feed/  lost_and_found/  explore/
│   ├── messaging/  notifications/  reviews/
│   ├── pets/  profile/
│   └── admin/
└── main.dart / app.dart
functions/           # Cloud Functions (booking notifications, AI pipelines,
                     # role management, scheduled jobs) + emulator test suites
```

- **State management**: Riverpod
- **Routing**: go_router with auth + role-based redirects
- **Design system**: token-based theme (`core/theme/app_theme.dart`) — deep-teal palette, Frank Ruhl Libre display + Heebo body (both Hebrew-capable, bundled offline)
- **RTL**: app-wide Hebrew locale; every surface renders right-to-left

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.2
- A Firebase project (Blaze plan for Cloud Functions)
- Node.js 22 + Firebase CLI (for functions & rules)

### Run the app
```bash
flutter pub get
flutter run
```

### Deploy backend
```bash
# Rules + indexes
firebase deploy --only firestore,storage

# Functions (set the Gemini key first)
# functions/.env: GEMINI_KEY=<your key>
firebase deploy --only functions
```

### Demo data
Sign in with an **admin** account → Profile → the seed buttons in the app bar generate/clear realistic demo data (users, pets, services, requests, bookings, reviews). Seeding is intentionally blocked for non-admin users, both in the UI and in the security rules.

---

## 🧪 Testing

```bash
# Dart unit tests
flutter test

# Firestore rules / Storage rules / Cloud Functions (emulator; needs JDK 21+)
cd functions
npm test
```

The rules suites assert the security model above — privilege-escalation guards, owner-only updates, moderation access, audit-trail immutability, upload constraints.

---

## 📄 License

Academic project. Fonts (Heebo, Frank Ruhl Libre) are used under the SIL Open Font License; licenses are registered in-app and bundled in `assets/google_fonts/`.
