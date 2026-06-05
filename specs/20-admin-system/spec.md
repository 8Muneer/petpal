# Feature Specification: Admin Management System

**Status**: Initial Draft
**Branch**: `20-admin-system`
**Feature Name**: admin-system

## 1. Executive Summary

PetPal currently lacks a centralized administration interface. All Point of Interest (POI) data and sitter verifications are handled manually or through mock fallbacks. This feature implements a comprehensive **Admin Management System** that allows authorized users to manage the entire platform. The system will support user management, content moderation (sitters and community alerts), and platform configuration (managing Parks, Vets, and Pet Stores).

## 2. Actors & Personas

- **System Admin**: A specialized user role with elevated permissions. They need a secure dashboard to monitor platform health and take administrative actions.
- **Service Provider (Sitter)**: Their profile and listings are subject to Admin verification and moderation.
- **Community User**: Their posts and alerts are subject to Admin moderation to ensure safety and quality.

## 3. User Scenarios

- **Scenario 1: Sitter Verification**: A new sitter registers on the platform. The Admin reviews their submitted credentials and profile details from the Admin Dashboard and marks them as "Verified," enabling the premium "Verified" badge on their profile.
- **Scenario 2: Managing Local Places**: The Admin adds a new high-end veterinary clinic to the platform. They input the name, address, location, and upload a premium image. This clinic then appears in the Home and Explore sections for all users.
- **Scenario 3: Community Moderation**: A user reports an inappropriate alert in the community feed. The Admin reviews the alert from the moderation queue and decides to dismiss it or delete it from the platform.
- **Scenario 4: User Oversight**: The Admin searches for a specific user to review their activity or update their account status (e.g., granting special badges or handling reports).

## 4. Functional Requirements

### A. Admin Authentication & Role Management
- **FR-01: Admin Role**: Implement a specific `role` field in the user profile (Firestore `users` collection) to distinguish between `owner`, `sitter`, and `admin`.
- **FR-02: Restricted Access**: Ensure that administrative screens and API calls (Firestore rules) are only accessible to users with the `admin` role. Access is managed through a unified login flow with role-based redirection.
- **FR-03: SuperAdmin Access**: All administrative users have full system access (SuperAdmin). Granular permission levels are not required for the initial version.

### B. User & Sitter Management
- **FR-04: User Directory**: A searchable list of all registered users with the ability to view detailed profiles.
- **FR-05: Sitter Verification Workflow**: A dedicated interface to review pending sitter applications and approve/reject them.
- **FR-06: Karma Management**: Ability for admins to manually adjust user Karma points in special cases (e.g., rewards for exceptional community service).

### C. Content Moderation
- **FR-07: Community Alert Moderation**: A queue of all active community alerts with the ability to delete or mark as "Resolved."
- **FR-08: Reported Content Queue**: A centralized list of items (posts, comments, profiles) reported by users for review.

### D. POI (Places) Management
- **FR-09: POI Editor**: A form to create and edit Points of Interest (Parks, Vets, Stores) with fields for name, type, location (lat/lng), rating, tags, and images.
- **FR-10: POI Image Upload**: Integration with Firebase Storage to upload and manage photos for local places.
- **FR-11: Emergency Status Toggle**: Ability to mark specific POIs (like Vets) as "Emergency" services to trigger special UI badges.

### E. Admin Dashboard (UI)
- **FR-12: High-Level Metrics**: A dashboard displaying platform stats (total users, active sitters, pending verifications, recent alerts).
- **FR-13: Integrated Admin Hub**: The admin interface is built as a dedicated section within the existing mobile application, accessible only to authenticated admins. It follows the "Organic Modernism" design system with a specialized dashboard layout.

## 5. Out of Scope
- Automated AI-based content moderation.
- Financial reporting and payment processing administration.
- System-wide maintenance mode toggle.
- Advanced analytics (e.g., user retention cohorts).

## 6. Success Criteria
- [ ] Only users with the `admin` role can access the Admin Dashboard.
- [ ] Admins can create, update, and delete POI data that immediately reflects on the Home/Explore screens.
- [ ] Sitter verification status can be toggled from the dashboard, correctly updating the UI badges for users.
- [ ] Community alerts can be moderated (removed) by an admin.
- [ ] Dashboard provides accurate counts of total users and pending tasks.
- [ ] The interface is responsive and follows the PetPal design system.

## 7. Key Entities
- **Admin**: `id`, `name`, `role`, `permissions`
- **VerificationRequest**: `id`, `userId`, `documents`, `status` (pending, approved, rejected), `timestamp`

## 8. Assumptions & Constraints
- The system will use the existing Firebase/Firestore backend.
- Administrative actions will be logged for audit purposes (internal logging).
- The "Organic Modernism" design language is maintained for the admin UI.

## 9. Dependencies
- Firebase Authentication and Firestore Security Rules.
- Feature 18 (Discovery Hub) — for POI data structures.
- Feature 12 (Feedback & Ratings) — for sitter metrics.

## 10. Clarifications

### Session 2026-05-13
- Q1: Should the Admin use a unified login or separate? → A: Unified Login (role-based redirection).
- Q2: Permission granularity? → A: Single Level (SuperAdmin only).
- Q3: Where should the dashboard live? → A: Integrated (In-App Dashboard).
