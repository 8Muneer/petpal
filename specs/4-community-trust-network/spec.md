# Feature Specification: PetPal Community Trust Network

**Status**: Draft
**Branch**: `feature/4-community-trust-network`
**Feature Name**: community-trust-network

## 1. Executive Summary
Transform the Community screen into a high-trust, luxury-themed "Trust Network." This feature focuses on social validation of pet services through "Neighbor Recommendations," a "Trust Karma" system with "Digital Treats," and hyper-local updates. The design follows the Luxury aesthetic with organic curvatures, sophisticated typography (Playfair Display), and glassy interactive components.

## 2. Actors & Personas
- **Pet Owner (User)**: Seeking peace of mind and reliable local advice. They want to see what their neighbors trust and earn recognition for being a helpful member of the community.
- **Service Provider**: Gains visibility through verified neighbor recommendations and high-quality community interactions.

## 3. User Scenarios
- **Scenario 1: Neighborhood Pulse**: A user opens the Trust tab and sees a "Neighborhood Alert" banner about a lost pet nearby. Below, they browse the "Pulse" (Recommendations, Playdates) to see what's happening in their immediate area.
- **Scenario 2: Service Validation**: The user sees a post from a neighbor praising a local walker. The post includes a "Luxury Utility Chip" with a "Book Now" button, allowing the user to instantly book the same walker.
- **Scenario 3: Rewarding Helpfulness**: The user provides a helpful tip on a post and receives a "Digital Treat" from another user. This increases their "Trust Karma" and brings them closer to a "Trusted Neighbor" badge.

## 4. Functional Requirements
- **FR-01: Neighborhood Alert Banner**: A high-visibility (but premium-styled) banner at the top of the feed for urgent alerts (Lost/Found). Navigates to the dedicated Lost & Found screen.
- **FR-02: Pulse Filter Bar**: A horizontal scrollable bar for filtering the feed by 'All', 'Recommendations', 'Expert Tips', 'Playdates', and 'Alerts'.
- **FR-03: Luxury Trust Post**: 
  - Header with User Avatar, Name, Verified Shield (if applicable), and "Trust Karma" count.
  - Location indicator (Neighborhood name or relative distance).
  - High-resolution media area (32px radius).
  - Interaction bar with "Give Treat" (Custom Like) and "Message" icons.
- **FR-04: Utility Recommendation Chip**: A specialized card within a post that links to a Service Listing. Includes service name, rating, neighbor discount info, and a "Book Now" action.
- **FR-05: Trust Karma System**: Logic to track and display "Karma" points earned through "Treats" and helpful contributions.
- **FR-06: Urgent Request Tag**: A distinctive, animated glass tag for posts that require immediate neighbor attention (e.g., last-minute sitter needed).

## 5. Non-Functional Requirements
- **NFR-01: Luxury Aesthetic**: Use the defined Luxury palette (Alabaster, Bronze) and typography (Playfair Display for headers, IBM Plex Sans for body).
- **NFR-02: Hyper-Local Privacy**: Distance and location data must be handled with user-defined privacy levels (e.g., "Brooklyn Heights" instead of exact street address).
- **NFR-03: Interaction Delight**: "Give Treat" action should trigger a subtle, delightful animation (e.g., a bone or heart icon floating up).

## 6. Success Criteria
- [ ] Users can navigate from the community feed to a service booking in under 3 clicks.
- [ ] 100% of community posts utilize the 32px organic radius for media and cards.
- [ ] The "Give Treat" interaction is clearly distinguished from a standard social "Like".
- [ ] Neighborhood alerts are visible within 1 second of feed load.

## 7. Key Entities
- **TrustPost**: Author, Location (Neighborhood), Content, MediaUrl, KarmaPoints, AssociatedService (Optional), IsUrgent (Boolean).
- **UserTrustProfile**: UserID, TotalKarma, Level (e.g., "Helpful Neighbor"), TreatsReceived (Total).
- **ServiceRating**: ProviderID, StarRating (1-5), ReviewCount (Used for utility/booking side).
- **TreatEconomy**: Value (e.g., 5% discount), UsageStatus (Used/Active), Expiry.

## 8. Assumptions & Constraints
- The backend for Karma and Treats is currently pending; UI will use mocked models that are "plug-and-play" for future Firebase integration.
- Ratings are reserved for verified Service Providers to maintain professional utility.
- Neighborhood names will be derived from user-provided location data rather than exact GPS coordinates for privacy.

## 9. Clarifications (Session 2026-04-25)
- **Q1: Karma vs Ratings**: Ratings are kept for Service Providers (Objective Utility). Karma is added for User Profiles (Social Reputation).
- **Q2: Distance Granularity**: Use "Neighborhood Name" (e.g., "Downtown Heights") or "Relative Distance" (e.g., "3 blocks away") to balance hyper-local utility with privacy.
- **Q3: Treat Value**: Treats have a hybrid value—increasing Social Karma while accumulating towards real-world service discounts (Booking Hook).
- **Q4: Daily Limit**: Digital Treats are limited to 3-5 per day per user to prevent inflation and maintain the "Luxury" exclusivity.
