# Sitter Marketplace & Booking Flow

## Goal
Connect the pet owner's ordering flow and the sitter's service posting flow into a cohesive Marketplace. This enables owners to discover sitters based on specific rules and requirements, while allowing sitters to present their services professionally to the community.

## User Scenarios
1. **Pet Owner Finding a Sitter**: A pet owner needs a sitter for a specific period. They navigate to the Marketplace, apply filters (rules), and find a sitter that matches their criteria. They then send a booking request.
2. **Sitter Listing their Service**: A user wants to earn money sitting pets. They go to "Mission Control", post their service listing with their rates, experience, and specific rules (e.g., "no large dogs").
3. **Connecting Request to Sitter**: A pet owner creates a "Public Request" for a job. Sitters in the area can see this request and apply for it.

## Functional Requirements
- **Marketplace Entry**:
    - "Find a Sitter" button on User Home Screen (Discovery chips or a dedicated section).
    - "Post My Service" button on Service Provider Home Screen (Quick actions).
- **Owner Ordering Flow**:
    - **Specific Rules**: Ability for owners to add rules like "No other pets", "Must stay at my home", "Twice a day feeding". These are **Hard Filters**: Owners only see sitters who explicitly support their rules.
    - **Sitter Discovery**: A searchable/filterable list of Sitters. This is integrated into the **User Home Screen** (discovery chips/scrollers) and also available via a **Dedicated Tab** in the navigation.
- **Sitter Posting Flow**:
    - **Profile/Service Card**: Sitters can set their "Bio", "Price", "Location", and "Available Days".
    - **Rules/Constraints**: Sitters can specify what types of pets they accept.
- **Connection Logic**:
    - **Booking Model**: Owners can either book a specific sitter directly OR post a general "Public Job" request for sitters to apply to.
    - **Sitter Profile Detail**: Clicking a sitter card opens a premium detail screen with a parallax hero image, quick stats, bio, service tags, and an availability calendar.

## Success Criteria
- Pet owners can browse and filter sitters by their specific rules.
- Sitters can list their services and rules clearly.
- Owners can seamlessly navigate between direct booking and posting public jobs.
- The Sitter Profile screen provides a premium, "wow" experience with all necessary info for booking.

## Assumptions
- The design system (Organic Modernism) is already defined and components like `AppCard` and `GlassCard` are available.
- Basic authentication and profile management are in place.
- The user can toggle between "Owner" and "Sitter" roles or the app handles both roles for a single user.

## Terminology
- **Marketplace**: The centralized area where sitters are listed and requests are shown.
- **Rules**: Specific constraints or requirements set by either owners or sitters.
- **Service Provider**: A user acting as a sitter.
