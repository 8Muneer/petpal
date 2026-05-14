# PetPal: Sitter & Provider Experience (The Jericho Professional)

This document details the dedicated interface and components for **Sitters** and **Service Providers**, focusing on high-efficiency management tools wrapped in the Jericho luxury aesthetic.

---

## 1. Provider Dashboard (`service_provider_home_screen.dart`)
*Goal: A high-level overview of business performance and immediate tasks.*

### Suggested Components:
- **Jericho Earnings Card**: 
  - A Desert Bronze card (`#C19A6B`) with a subtle glass overlay showing "Total Earnings" and "Pending Payouts".
  - **Interaction**: Tap to view detailed financial analytics.
- **"Next Up" Booking Pill**: 
  - A prominent, floating pill at the top showing the very next appointment (Pet Name, Time, Service Type).
- **Activity Heatmap**: 
  - A minimalist grid showing booking density over the last 30 days, using shades of Alabaster and Bronze.
- **Quick Action Floating Menu**: 
  - An organic-shaped "+" button that expands to show: "Add Service", "Set Out-of-Office", "Blast Update to Clients".

---

## 2. Booking & Request Management (`bookings_screen.dart`)
*Goal: Seamless handling of incoming requests and active schedules.*

### Suggested Components:
- **Glass Segmented Control**: 
  - A custom tab bar for "Requests", "Active", and "History" with a 20px blur background.
- **Jericho Request Card**:
  - **Top Row**: Pet Avatar (circular, 48px) + Owner Name.
  - **Body**: Service Type, Date Range, and "Proposed Price" in bold Bronze.
  - **Action Bar**: Two high-contrast buttons—"Review Details" (White Glass) and "Quick Accept" (Bronze).
- **Active Sitting Timer**: 
  - For active sessions, a live counter showing how long the sitting has been in progress, with a "Send Photo Update" shortcut.

---

## 3. Availability & Scheduling (`availability_screen.dart`)
*Goal: Elegant control over time and capacity.*

### Suggested Components:
- **Jericho Master Calendar**: 
  - A full-screen interactive calendar with custom markers for booked vs. available slots.
  - **Style**: Playfair Display for the month name, IBM Plex Sans for the numbers.
- **Time Slot Chips**: 
  - Morning, Afternoon, and Evening chips that the sitter can toggle on/off with a smooth haptic transition.
- **"Organic" Capacity Slider**: 
  - A slider to set how many pets can be cared for simultaneously, using a custom bronze thumb.

---

## 4. Service Configuration (`service_settings_screen.dart`)
*Goal: Defining the professional offering.*

### Suggested Components:
- **Service Type Editor**: 
  - Cards for each service (Sitting, Walking, Training) with toggles to enable/disable.
- **Price Architecture Row**: 
  - Input fields with the Jericho border style for "Base Rate", "Extra Pet Fee", and "Holiday Surcharge".
- **Radius-Organic Image Uploader**: 
  - A large area with 32px corners for the sitter to upload "Work Gallery" photos (showing their space or past happy pets).

---

## 5. Client & Pet Intelligence (`sitting_request_detail_screen.dart`)
*Goal: Deep context on the pet being cared for.*

### Suggested Components:
- **Pet Bio Card**: 
  - A 32px radius card with a large photo, breed info, and a "Vibe Check" (Temperament tags like "Energetic", "Quiet", "Friendly").
- **Medical & Instruction Accordion**: 
  - Expandable sections for "Feeding Schedule", "Emergency Contact", and "Special Medical Needs".
- **Direct Link Chat Bar**: 
  - A persistent bottom bar to message the owner instantly without leaving the detail page.

---

## 6. Sitter Professional Profile (`profile_screen.dart`)
*Goal: Building trust and showcasing excellence.*

### Suggested Components:
- **Trust Badge Grid**: 
  - Icons for "Verified ID", "5.0 Rating", "Repeat Clients", and "Pet First Aid Certified".
- **Client Testimonial Scroller**: 
  - A horizontal scroll of Playfair Display quotes from happy pet owners.
- **Jericho Portfolio Grid**: 
  - A staggered grid of high-quality photos from past sittings.
