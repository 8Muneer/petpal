# Feature Specification: Sitter Calendar & Availability Redesign

## Overview
Redesign the existing sitter availability management interface into a professional "Mission Control" dashboard. The new interface will utilize a Bento Grid layout to organize a master calendar, service-specific toggles, and a daily capacity slider, matching the "Organic Modernism" aesthetic of the PetPal project.

## User Scenarios

### Scenario 1: Weekly Availability Setup
A sitter wants to set their recurring weekly schedule (e.g., available every Sun-Thu). They use the "Days of the Week" selector to toggle their standard availability.

### Scenario 2: Service-Specific Availability
A sitter is available for Dog Walking all week but only wants to offer Pet Sitting on weekends. They use the Service Toggles to manage these settings independently.

### Scenario 3: Master Calendar Overview
A sitter wants to see an overview of their month, including which days are available, booked, or blocked. They can tap individual dates to override their default weekly availability (e.g., blocking off a specific vacation day).

## Functional Requirements

### FR1: Master Calendar View (Bento Card)
- **FR1.1**: Display a full month view of the current month.
- **FR1.2**: Highlight "Available" days (based on weekly pattern or overrides).
- **FR1.3**: Highlight "Booked" days (where a job is already scheduled).
- **FR1.4**: Highlight "Blocked" days (manually disabled by the sitter).
- **FR1.5**: Support individual date overrides. Sitters can tap any date to toggle its status (Available/Blocked) regardless of their recurring weekly pattern.
- **FR1.6**: Store overrides in a Firestore sub-collection or map (e.g., `dateOverrides: { '2023-10-12': false }`).

### FR2: Service Availability Toggles
- **FR2.1**: Provide independent toggles for "Dog Walking" and "Pet Sitting".
- **FR2.2**: Persist these settings to the user's profile in Firestore.
- **FR2.3**: If a service is toggled OFF, the sitter should not appear in search results for that specific service.


### FR4: Global Availability Toggle
- **FR4.1**: Maintain the existing global "Open for Requests" switch.
- **FR4.2**: If OFF, all other availability settings are bypassed, and the sitter is hidden from all searches.

## Non-Functional Requirements
- **NFR1: Aesthetic Consistency**: Use the "Desert Bronze" palette and glassmorphism tokens.
- **NFR2: Performance**: Calendar transitions and slider updates must be fluid (60fps).
- **NFR3: Localization**: Full Hebrew support for all labels and calendar day/month names.

## Success Criteria
- Sitters can set their weekly availability, capacity, and service toggles in a single screen.
- The UI matches the React prototype provided in the review.
- Data is correctly persisted and reflected in the Service Provider Home Screen's summary.

## Assumptions
- We will reuse the existing `isAvailable` and `availableDays` fields in Firestore.
- New field `dateOverrides` (Map<String, bool>) will be added to the user's document.
- The calendar reflects the weekly recurring pattern combined with date-specific overrides.
