# Implementation Plan - Sitter Dashboard Redesign

## Technical Context
- **Architecture**: Clean Architecture with Riverpod for state management.
- **Theme**: Organic Modernism (Desert Bronze palette, Glassmorphism).
- **State Management**: Using `StateNotifierProvider` to track the active sitting session and checklist.

## Proposed Changes

### Domain Layer
- [NEW] `lib/features/bookings/domain/entities/care_task.dart`: Entity for care tasks (Food, Walk, Meds).

### Presentation Layer
- [NEW] `lib/features/bookings/presentation/providers/sitter_dashboard_state.dart`: State notifier for active sitting sessions.
- [MODIFY] `lib/features/home/presentation/screens/service_provider_home_screen.dart`: Update to include the 5-tab navigation and the new Bookings tab content.
- [NEW] `lib/features/bookings/presentation/widgets/active_sitting_card.dart`: High-end card for live job tracking.
- [NEW] `lib/features/bookings/presentation/widgets/sitter_request_card.dart`: Updated request card with urgency timers.

## Verification Plan
### Automated Tests
- Unit tests for `SitterDashboardNotifier` state transitions.
- Widget tests for the ticking timer logic.

### Manual Verification
- Verify the timer ticks in real-time.
- Verify checklist state persists when switching tabs.
- Verify RTL alignment in Hebrew for all new components.
