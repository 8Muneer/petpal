# PetPal Sitter: UI/UX Planning for Home and Bookings Screens 🐾

This document outlines recommendations for redesigning the Service Provider (Sitter) experience in PetPal, focusing on the **Organic Modernism** aesthetic and user flow optimization.

---

## 🗺️ Navigation Structure Changes (Bottom Navigation)
To create a cleaner and more focused interface, we reduced the 7 tabs to 5 key areas:

1. **Home**: Mission Control for daily management, availability status, and earnings.
2. **Calendar**: Schedule management, time-off, and future booking overview.
3. **Bookings**: Centralized hub for all incoming requests and confirmed appointments (Unified Walks, Sitting, and other services).
4. **Chat**: Direct communication with pet owners.
5. **Community**: "Trust Network" feed updates and Lost & Found alerts.

---

## 🏠 HOMEPAGE - "Service Provider Mission Control"

The Home screen should convey **confidence, professionalism, and tranquility**. We will use glassmorphism elements and earthy tones (Bronze/Slate).

### Recommended Components:
1. **Immersive Hero Section**:
   - High-quality background image that changes based on the time of day (Morning/Evening).
   - Personalized greeting: "Good morning, [Name] 🌿 Your business looks great today."
   - A prominent but elegantly designed availability switch to toggle "Off-duty" mode instantly.

2. **Earnings & Insights Card**:
   - Instead of a simple list, use a raised Luxury card showing: "Weekly Revenue," "Current Rating," and "Remaining Work Hours."
   - Use a subtle Sparkline graph to show growth trends.

3. **Live Job Tracker**:
   - If a sitter is currently on a job, this is the most critical component.
   - A floating card with a live timer, pet photo, and quick actions for "End Job" or "Send Photo Update to Owner."

4. **Quick Actions**:
   - A row of styled Pill buttons: "Post Community Update," "Quick Message Last Client," "Add New Service."

---

## 📅 BOOKINGS Screen - "Workflow Management"

This screen must be **highly functional, clean, and free of cognitive load**.

### Recommended Components:
1. **Internal Tabbed View**:
   - **Requests**: New incoming inquiries awaiting approval.
   - **Upcoming**: Confirmed appointments in the calendar.
   - **History**: Archive of completed jobs.

2. **Luxury Request Cards**:
   - Visual emphasis on the **pet's photo**.
   - Quick details: "Dog • 2 km away • ₪90".
   - "Compatibility" tags: e.g., "Returning Neighbor" or "Fits your schedule."
   - Clear action buttons: "Accept" (soft green) and "Decline" (textured gray).

3. **Expanded Task Details**:
   - Tapping a booking opens a clean screen with "Care Instructions" (Food, Meds, Keys).
   - Quick shortcuts for Navigation (Google Maps/Waze) and Chat with the owner.

4. **Integrated Service Management**:
   - At the bottom, quick access to edit rates and services (Walks/Sitting) without diving deep into settings.

---

## ✨ Design Aesthetics
- **Typography**: Use heavy weights for headings (Bold/Black) and wide letter spacing for secondary text.
- **Color Palette**: Use `AppColors.primary` (Bronze) for positive actions and `AppColors.surfaceDark` for deep backgrounds.
- **Motion**: Smooth transitions (Fade & Slide) between tabs for a premium app feel.

> [!TIP]
> Add a "Neighborhood Pulse" component on the Home screen—a graph showing when there is high demand in your area to encourage the sitter to open availability.
