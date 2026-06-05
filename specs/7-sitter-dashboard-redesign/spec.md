# Sitter Dashboard & Bookings Redesign

## Goal
Redesign the Service Provider (Sitter) experience to focus on professional booking management, real-time job tracking, and neighborhood awareness. The UI follows the "Organic Modernism" aesthetic and provides a "Mission Control" feel for active sittings.

## User Scenarios
1. **Sitter managing active job**: A sitter can see exactly how much time has passed, follow a care checklist (Food, Walk, Meds), and send photo updates.
2. **Sitter receiving requests**: A sitter can see new requests with urgency timers and pet-specific personality tags to make quick decisions.

## Functional Requirements
- **Bottom Navigation**: Consolidated to 5 tabs (Home, Calendar, Bookings, Chat, Community).
- **Bookings Tab**:
    - Segmented control for "Requests", "Active", and "History".
    - **Active Sitting Card**:
        - Real-time ticking timer.
        - Care Checklist with persistent state.
        - Progress bar based on checklist completion.
        - Quick actions: Photo Update, Chat.
    - **Requests Grid**:
        - Cards with urgency countdown timers.
        - Pet personality tags (Friendly, Trained, etc.).
        - Service type and price clearly displayed.
- **Localization**: Full Hebrew support for all professional labels.

## Success Criteria
- Sitter can complete care tasks with one tap.
- Active sitting status is clearly visible at a glance.
- Request response time improved via urgency visual cues.

## Assumptions
- "Mutual Neighbors" and "Karma" gamification are excluded from this specific workflow.
- Checklist tasks are standard but allow for customization in future updates.
