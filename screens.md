# PetPal: Screen & Component Map (Jericho Design System)

This document maps all screens in the PetPal app to their required components, maintaining the "Luxury Jericho" aesthetic across the entire user experience.

---

## 1. Authentication & Onboarding
*Goal: Create a high-end first impression using warm surfaces and organic shapes.*

### Onboarding Screen (`onboarding_screen.dart`)
- **Jericho Hero Slider**: High-quality pet photography with smooth parallax transitions.
- **Glass Onboarding Card**: A fixed bottom card with `radius-organic (32px)` and `BackdropFilter` (blur: 20).
- **Primary CTA Button**: Desert Bronze button with gold text/icons.
- **Paginator Dots**: Minimalist dots, with the active one in Desert Bronze.

### Login & Signup Screens (`login_screen.dart`, `signup_screen.dart`)
- **Header Serif Text**: "Welcome to PetPal" in `Playfair Display`.
- **Organic Input Fields**: Input boxes with `radius: 16px` and subtle `1px solid #E0E0E0` borders.
- **Auth Glass Card**: The main form container with a subtle shadow and warm surface color.
- **Social Login Buttons**: Minimalist white chips with brand icons.

---

## 2. Home & Discovery (Main Navigation)
*Goal: Showcase services and updates in a curated, magazine-style layout.*

### User Home Screen (`user_home_screen.dart`)
- **Parallax Hero Header**: Large pet image with a floating glass search bar.
- **Discovery Chips**: Horizontal row of white category chips (Dogs, Cats, etc.).
- **"Top Rated" Service Scroller**: Horizontal list of **Premium Service Cards** (220px height, glass rating pill).
- **"Recently Watched" Scroller**: Horizontal list of **Structured Tiles** (140px width).
- **Community Snapshot**: Large white cards (32px corners) with user profiles and pet photos.

### Service Provider Home Screen (`service_provider_home_screen.dart`)
- **Earnings Summary Card**: Desert Bronze card with glass highlights.
- **Active Bookings List**: Vertical list of tiles showing upcoming pet appointments.
- **Quick Action Grid**: Icons for "Add Service", "Update Availability", and "Analytics".

---

## 3. Community Feed & Lost and Found
*Goal: Clean, social-focused layouts with high visual emphasis on pet photos.*

### Feed Screen (`feed_screen.dart`)
- **Community Update Card**: (Component #5 from design.md) - 32px corner radius, user profile row, large media area.
- **Post Interaction Bar**: Minimalist icons (Heart, Comment, Share) in `color-on-surface`.
- **Floating Create Button**: Floating Desert Bronze button with a "+" icon.

### Lost & Found Feed (`lost_found_feed_screen.dart`)
- **Urgent Status Pill**: Red glass pill overlay on post images for "LOST" items.
- **Location Chip**: Small chip with a map icon showing where the pet was last seen.
- **Grid Layout**: Two-column grid of pet photos with 24px corner radius.

---

## 4. Messaging & Communication
*Goal: Intimate, clear, and responsive chat interface.*

### Chat List Screen (`chat_list_screen.dart`)
- **Chat Avatar Row**: 60px circular avatars with online status indicators.
- **Message Preview Tile**: Horizontal row with bold name and truncated message text.
- **Search Header**: Minimalist glass search bar.

### Chat Screen (`chat_screen.dart`)
- **Chat Header**: User avatar, name, and "Active Now" status in `Playfair Display` (smaller size).
- **Message Bubbles**: 
  - Sent: Desert Bronze bubbles with 20px radius (0px on bottom-right).
  - Received: Warm Alabaster bubbles with 20px radius (0px on bottom-left).
- **Input Action Bar**: Glass-styled input field with attachment and emoji icons.

---

## 5. Profile & Management
*Goal: Structured, easy-to-navigate dashboard for users and providers.*

### Profile Screen (`profile_screen.dart`)
- **Profile Hero**: Circular avatar (120px) centered over a Warm Alabaster background.
- **Stat Row**: Horizontal list of "Followers", "Posts", and "Reviews" with bold numbers.
- **Navigation List**: Clean vertical list of settings (Edit Profile, Bookings, Security) with Chevron icons.

### Bookings Screen (`bookings_screen.dart`)
- **Booking Status Tabs**: Segmented control with "Upcoming", "Completed", and "Cancelled".
- **Service Detail Tile**: Horizontal tile showing service type, pet name, and price in Desert Bronze.

---

## 6. Service Specifics (Walking & Sitting)
*Goal: Functional forms and detail pages that feel premium and trustworthy.*

### Request Detail Screens (`walk_request_detail_screen.dart`, etc.)
- **Service Summary Header**: Large image of the pet involved with a glass overlay.
- **Detail Grid**: Information grid showing Time, Date, Duration, and Price.
- **Action Bottom Bar**: Sticky button bar with "Accept" (Bronze) or "Decline" (Transparent) options.

### Creation Forms (`create_walk_request_screen.dart`, etc.)
- **Step Indicator**: Minimalist progress bar at the top.
- **Styled Forms**: Large input fields, date pickers, and pet selection chips using the Jericho radius and border tokens.
