# PetPal: Use Cases & Feature Specification

This document outlines the core functional requirements, user interactions, and feature sets of the PetPal platform.

---

## 1. User Roles & Actors

| Role | Description |
| :--- | :--- |
| **Pet Owner** | Primary user seeking services for their pets and managing pet profiles. |
| **Service Provider** | Professionals (Walkers, Sitters, Trainers) offering services and managing their business. |
| **Community Member** | General users participating in the feed and helping with Lost & Found efforts. |


---

## 2. Core Use Cases

### A. Service Discovery & Booking
- **UC-01: Search for Services**: Owners search for providers based on service type (Walk, Sit, Train), location, and pet type.
- **UC-02: Check Availability**: Owners view a provider's real-time calendar to find matching slots.
- **UC-03: Request Booking**: Owners send a booking request with specific pet details and time slots.
- **UC-04: Accept/Decline Booking**: Providers review requests and manage their schedule.

### B. Service Management (Provider Side)
- **UC-05: List Service**: Providers create listings with pricing, service descriptions, and requirements.
- **UC-06: Set Availability**: Providers define their working hours and "off" days.
- **UC-07: Track Earnings**: Providers view financial analytics and completed job history.

### C. Community & Social
- **UC-08: Share Updates**: Users post photos and messages ("hi everyone") to the community feed.
- **UC-09: Interact with Posts**: Users like and comment on community updates.
- **UC-10: Real-time Chat**: Owners and Providers communicate regarding active or upcoming bookings.

### D. Emergency (Lost & Found)
- **UC-11: Report Lost Pet**: Owners upload a photo and location of their lost pet.
- **UC-12: Report Found Pet**: Community members report sightings of found pets.
- **UC-13: AI Image Matching**: The system automatically cross-references lost and found pet photos to suggest potential matches.

---

## 3. Feature Set

### 🛠️ Core Infrastructure
- **Role-Based Access Control (RBAC)**: Secure authentication and personalized dashboards for Owners vs. Providers.
- **Real-time Synchronization**: Powered by Firebase for instant messaging and booking updates.
- **Push Notifications**: Context-aware alerts for booking approvals, new messages, and urgent Lost & Found matches.

### 🐕 Pet Management
- **Digital Pet Profiles**: Store photos, breed information, medical records, and temperament notes.
- **Service History**: A log of all past walks, sittings, and medical updates for each pet.

### 📅 Smart Scheduling
- **Dynamic Calendar**: A high-end visual calendar for providers to manage multiple concurrent bookings.
- **Conflict Resolution**: Logic to prevent overbooking and manage overlap between different service types.

### 🧠 AI & Advanced Tech
- **AI Visual Matching**: Computer Vision model to identify pet breeds and match facial/fur patterns in Lost & Found posts.
- **Location Tracking**: (Optional/Premium) Real-time GPS tracking during active dog walks.

### 💎 Jericho Premium UI (Vibe)
- **Luxury Aesthetic**: Fully implemented design tokens (Desert Bronze, Warm Alabaster).
- **Glassmorphism**: Elegant use of backdrop blurs and semi-transparent layers for a modern feel.
- **Parallax Interactions**: Immersive transitions and high-quality visual feedback.
