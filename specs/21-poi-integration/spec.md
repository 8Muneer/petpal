# Feature Specification: POI Integration & Display

**Status**: Initial Draft
**Branch**: `21-poi-integration`
**Feature Name**: poi-integration

## 1. Executive Summary

This feature bridges the administrative capability of POI (Point of Interest) creation with the user-facing discovery experience. It ensures that when administrators create or manage POIs (such as Vet Clinics, Dog Parks, and Pet Stores) from the Admin Hub, these locations are seamlessly integrated into the Pet Owner's Home and Explore screens as interactive cards. Clicking on a POI card will navigate the user to a detailed screen displaying specific information about that location.

## Clarifications
### Session 2026-05-13
- Q: Home Screen Display Logic → A: Limited to 10 max in a horizontal list. Includes a "more" button navigating to the explore page to connect with specific POIs.
- Q: POI Detail Map Integration → A: Static visual placeholder with an external "Get Directions" button.

## 2. Actors & Personas

- **System Admin**: Creates and manages POIs from the Admin Hub, providing images, locations, and contact details.
- **Pet Owner (User)**: Discovers POIs via the Home and Explore screens and views their details to make informed decisions for their pets.

## 3. User Scenarios

- **Scenario 1**: An Admin adds a new high-end Vet Clinic via the POI Management screen, uploading an image and setting coordinates.
- **Scenario 2**: A Pet Owner opens the app and sees the newly added Vet Clinic on their Home screen.
- **Scenario 3**: A Pet Owner browses the Explore screen, filters by "Parks", and sees a list of Dog Parks. They click on a specific park card to view its detailed page (address, emergency status, and contact actions).

## 4. Functional Requirements

- **FR-01: Admin POI Persistence**: The system must persist POI data (images, location data, type, and contact info) so it is globally available to all users.
- **FR-02: Home Screen Integration**: The `UserHomeScreen` must fetch and display a curated horizontal list of POIs (maximum 10). It must include a "more" button that navigates the user to the Explore page.
- **FR-03: Explore Screen Integration**: The `ExploreScreen` must display the full directory of POIs, reacting to category filters (Vets, Parks, Stores).
- **FR-04: POI Card Component**: A reusable, aesthetically pleasing card component to display POI summaries.
- **FR-05: POI Detail Screen**: A dedicated screen showing full POI details, a hero image, and contact actions. It will use a static visual placeholder for the map with an external "Get Directions" button.

## 5. Out of Scope

- Real-time GPS distance calculation (can use static sorting or mocked user locations for now).
- User reviews and ratings submission for POIs (read-only for now).

## 6. Success Criteria

- [ ] Admins can successfully create a POI that persists in the database.
- [ ] Created POIs automatically appear on the User Home and Explore screens without an app restart.
- [ ] Clicking a POI card opens a detailed view screen with no layout overflow errors.
- [ ] The UI matches the existing "Organic Modernism" design system.

## 7. Key Entities

- **POI**: `id`, `name`, `type`, `latitude`, `longitude`, `imageUrl`, `address`, `phoneNumber`, `isEmergency`, `rating`, `reviewCount`, `tags`

## 8. Assumptions & Constraints

- Assumes the POI data model and admin repository methods for saving POIs are already functional.
- The UI must strictly follow the "Organic Modernism" aesthetic (glassmorphism, soft curves, tinted neutrals).

## 9. Dependencies

- Firebase Firestore & Storage.
- Existing routing infrastructure for navigation.
