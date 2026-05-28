# Feature Specification: Discovery Hub & Community Alerts

**Status**: Draft
**Branch**: `18-discovery-hub`
**Feature Name**: discovery-hub

## 1. Executive Summary
The "Discovery Hub" transforms PetPal into a comprehensive utility for pet owners by centralizing the discovery of essential local services and safety information. This feature integrates location-based searching for dog parks, pet stores, and veterinary clinics (including emergency facilities with specialized ratings) into the existing Explore screen. Additionally, it enhances the Community Feed with a structured "Forum" management system, a "Picture of the Day" engagement feature, and a high-priority "Safety Alerts" system for critical warnings like poison, recalls, and wildlife threats.

## 2. Actors & Personas
- **Pet Owner (Searcher)**: Needs to quickly find the nearest dog park or pet store, and critically, the nearest emergency vet during a crisis.
- **Pet Owner (Social)**: Wants to share advice, join outings, and engage with the community through galleries and the "Picture of the Day".
- **Sitter/Provider**: Benefits from community recommendations and alerts regarding local hazards.
- **System/Admin**: Responsible for curating or aggregating safety warnings and "Picture of the Day".

## 3. User Scenarios
- **Scenario 1: Late-Night Emergency**: It's 2:00 AM, and a pet has ingested something toxic. The owner opens PetPal, goes to the Explore screen, and instantly sees a red "Emergency Vet" card with the closest 24/7 clinic and its rating.
- **Scenario 2: Weekend Outing**: An owner wants to find a new place to play. They filter the Explore screen for "Dog Parks" and find a park 3km away with 4.5 stars and recent comments mentioning a functioning water fountain.
- **Scenario 3: Community Engagement**: A user browses the "Forums" and filters by "Advice" to find tips on leash training. They then contribute a photo to the "Gallery by Topic" (e.g., #SunsetWalks) and check if their pet was selected as the "Picture of the Day".
- **Scenario 4: Staying Safe**: A push notification alerts an owner that a "Poison Warning" has been issued for their local neighborhood park, allowing them to avoid the area.

## 4. Functional Requirements

### A. Location Discovery (Explore Screen & Home Integration)
- **FR-01: Essential Services Map/List**: Integrate three new categories as top-level tabs in the Explore screen: `Dog Parks`, `Pet Stores`, and `Vets`.
- **FR-02: Home Screen Surface**: Display high-priority lists (e.g., "Closest Emergency Vets" and "Top Rated Parks Near You") directly on the User Home screen for instant access.
- **FR-03: Emergency Vet Priority**: Emergency clinics must be highlighted with a "Urgent/24-7" badge and high-contrast (Red/Emergency) UI treatment.
- **FR-04: Provider Ratings & Reviews**: Extend the existing review system to Vets and Pet Stores, allowing users to see detailed ratings.
- **FR-05: Distance-Based Sorting**: All discovery results must show distance from the user's current or selected location.
- **FR-06: Mini-Map Snapshots**: Discovery list cards should include a small static map snapshot showing the relative location of the service/park.

### B. Forums & Community Management
- **FR-07: Structured Categories**: Refine the community pulse bar to explicitly support: `Outings` (Events), `Advice`, `Recommendations`, and `General`.
- **FR-08: Gallery by Topic**: Implement hashtag-based or folder-based photo galleries (e.g., #HikingDogs, #CatNap) within the community section.
- **FR-09: Picture of the Day**: A featured pet photo selected automatically based on the highest "Treat" (like) count from the previous 24 hours, displayed prominently at the top of the Community Feed.

### C. Safety Alerts & Notifications
- **FR-10: High-Priority Warnings**: Implement specific alert types in the Neighborhood Alert Banner: `Poison`, `Food Recalls`, `Rabies Alert`, and `Wild Animals`.
- **FR-11: Notification System**: Users must receive push notifications for:
  - New community "Matches" (e.g., a playdate match or a service match).
  - High-priority safety warnings in their area.
- **FR-12: Match Notifications**: Notification triggered when a sitter's availability/preferences perfectly match a public job request.

## 5. Non-Functional Requirements
- **NFR-01: Location Latency**: Location-based results should load in under 2 seconds.
- **NFR-02: Alert Urgency**: Safety alerts must be visually distinct and use high-contrast accessibility standards.
- **NFR-03: Localization**: All category labels and alert types must be professionally localized in Hebrew.

## 6. Success Criteria
- [ ] Users can find the nearest Emergency Vet in under 3 taps from the Home screen.
- [ ] Explore screen successfully displays 4 categories (Sitters, Parks, Vets, Stores) as main tabs.
- [ ] Home screen displays a "Nearby Essentials" list with at least 2 categories.
- [ ] Community Feed includes a functional "Picture of the Day" section based on popularity.
- [ ] Push notifications are delivered for local safety alerts.
- [ ] Users can filter forum posts by "Advice" or "Outings" with zero lag.

## 7. Key Entities (Firestore Structure)
- **POI (Point of Interest)**: `id`, `name`, `type` (Park/Vet/Store), `isEmergency` (bool), `location` (geopoint), `rating`, `reviewCount`.
- **GalleryPost**: `id`, `imageUrl`, `topic` (string/hashtag), `timestamp`.
- **Alert**: `id`, `type` (Poison/Recalls/Rabies/Wildlife), `title`, `content`, `location`, `priority` (High/Med).

## 8. Assumptions & Constraints
- We assume access to a location-based POI database (or a curated demo dataset).
- We assume push notification infrastructure (Firebase Cloud Messaging) is configured.

## 9. Clarifications
### Session 2026-05-10
- **Q1: Discovery Interface Structure** → **A**: Main Tabs (Option A) + Home Screen Integration.
- **Q2: Picture of the Day Selection** → **A**: Top "Treats" (Option A) - Automated engagement.
- **Q3: Visualization Strategy** → **A**: List with Mini-Map (Option C) - Enhanced cards with location context.
