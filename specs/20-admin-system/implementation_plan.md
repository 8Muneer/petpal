# Implementation Plan: Admin Management System

**Status**: Planning
**Branch**: `20-admin-system`
**Feature Name**: admin-system

## 1. Technical Context

This feature implements a specialized Administrative Hub within the existing PetPal Flutter application. It leverages Firebase Authentication roles and Firestore Security Rules to protect administrative data.

- **Frontend**: Flutter (Riverpod for state, GoRouter for admin routes).
- **Backend**: Firebase Firestore (users, pois, verification_requests, community_alerts) and Firebase Storage (POI images, verification documents).
- **Security**: Custom claims or role fields in Firestore used to gate access.

### Technical Constraints
- Must adhere to "Organic Modernism" design system.
- Must ensure zero leakage of admin-only data to regular users.
- RTL support (Hebrew) for all administrative forms.

## 2. Constitution Check

The plan must comply with the PetPal Constitution:
- [ ] Premium "Organic Modernism" aesthetic for Admin Hub.
- [ ] Security-first approach for role-based access.
- [ ] Maintain standard Riverpod patterns for data fetching.

## 3. Proposed Changes

### [Component] Core Security & Roles
- **[MODIFY] [firebase.json](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/firebase.json)**: Add security rules for `admin` role validation.
- **[MODIFY] [firestore.rules](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/firestore.rules)**: Restrict write access to `pois` and `users` roles to `request.auth.token.admin == true` or checking the `role` field in the user document.

### [Component] Admin Interface (UI)
- **[NEW] [lib/features/admin/presentation/screens/admin_hub_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/lib/features/admin/presentation/screens/admin_hub_screen.dart)**: The main entry point for the Admin Dashboard (Bento-style metrics).
- **[NEW] [lib/features/admin/presentation/widgets/admin_navigation_rail.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/lib/features/admin/presentation/widgets/admin_navigation_rail.dart)**: Navigation sidebar for desktop/tablet views.
- **[NEW] [lib/features/admin/presentation/screens/poi_management_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/lib/features/admin/presentation/screens/poi_management_screen.dart)**: List and editor for Parks, Vets, and Stores.
- **[NEW] [lib/features/admin/presentation/screens/sitter_verification_screen.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/lib/features/admin/presentation/screens/sitter_verification_screen.dart)**: Reviewing and approving sitter applications.

### [Component] Domain & Data Model
- **[MODIFY] [lib/features/explore/domain/entities/poi_model.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/lib/features/explore/domain/entities/poi_model.dart)**: Ensure all fields are editable and serializable for the admin form.
- **[NEW] [lib/features/admin/domain/entities/admin_stats.dart](file:///c:/Users/NumanSh/OneDrive/Desktop/projects/college projects/petpal/project/petpal/lib/features/admin/domain/entities/admin_stats.dart)**: Model for dashboard metrics.

## 4. Execution Phases

### Phase 1: Foundation & Security
- Implement the `admin` role in Firestore user profiles.
- Secure Firestore rules.
- Set up Admin-only routes in the app router.

### Phase 2: POI Management (MVP)
- Build the POI Editor with map picker support.
- Implement Firebase Storage upload for POI images.
- Replace mock fallback data in `poi_repository_impl.dart` with live Firestore calls.

### Phase 3: Sitter & Content Moderation
- Build the Sitter Verification list and detail view.
- Implement the Report/Moderation queue for community content.

### Phase 4: Polish & Dashboard
- Finalize the Bento-style Metrics Dashboard.
- Apply `frontend-design` and `normalize` skills for a premium finish.

## 5. Verification Plan

### Automated Tests
- Integration tests for router gating (verify non-admins can't reach `/admin`).
- Security rules testing via Firebase Emulator.

### Manual Verification
- Log in as an Admin and create a new Dog Park; verify it appears on the Home screen.
- Log in as a regular User and attempt to navigate to `/admin`; verify redirection to Home.
- Test Sitter Verification flow: Verify a sitter and check for the badge on their profile.
