# Specification: Explore Filtering System

## Overview
**Feature Name**: Explore Filtering System
**Description**: Implementation of a robust, high-end filtering mechanism for the Explore Discovery Hub. This system enables Pet Owners to narrow down sitters based on specific criteria and allows Service Providers to filter through available job requests, ensuring a boutique and efficient matching experience.

## User Scenarios
### 1. Pet Owner Filtering
- **Opening Filters**: The owner taps the "Filter" icon in the Explore header. A premium Modal Bottom Sheet slides up.
- **Selecting Criteria**: The owner selects a price range using a slider, chooses a minimum rating (e.g., 4+ stars), and selects pet types they need help with.
- **Applying**: Upon clicking "Apply", the Explore list updates instantly with staggered animations to show only matching sitters.
- **Clearing**: The owner can clear all filters to return to the full list.

### 2. Service Provider (Sitter) Filtering
- **Filtering Jobs**: The sitter opens the filter sheet to narrow down public requests.
- **Criteria**: Filters by area/distance, pet type (e.g., only "Big Dogs"), and date range.
- **Success**: The sitter finds a job that matches their availability and expertise.

## Functional Requirements
### 1. Filter Interface (Modal Bottom Sheet)
- **Visuals**: 32px top-corner radius, white background with glassmorphic elements.
- **Layout**: RTL-first, generous padding (24px).
- **Header**: "סינון" (Filter) title on the right, "נקה הכל" (Clear All) button on the left.

### 2. Filter Categories (Pet Owner)
- **Price Range**: A custom dual-thumb slider for min/max hourly rate.
- **Rating**: Selection chips for "כל הדירוגים" (All), "4+ כוכבים", "4.5+ כוכבים".
- **Pet Types**: Multi-select chips for Dogs, Cats, Birds, etc.
- **Service Type**: Selection for "טיול כלבים" (Walking), "פנסיון" (Sitting).

### 3. Application Logic
- **State Management**: Filters are managed via Riverpod (`marketplaceFiltersProvider`).
- **Interaction**: Intentional - User clicks a large "Show [X] Results" button at the bottom of the filter sheet.
- **Visual Feedback**: Subtle Indicator - A small golden dot on the "Filter" icon in the header when filters are active.

## Clarifications (Session 2026-05-06)
- Q: What are the specific filter categories for Pet Owners? → A: Option A (Essential Boutique: Price, Rating, Service Type, and Pet Species).
- Q: Should filters be applied instantly or only after clicking 'Apply'? → A: Option B (Intentional: User clicks a large "Show [X] Results" button).
- Q: How should active filters be displayed on the main Explore screen? → A: Option A (Subtle Indicator: A small golden dot on the "Filter" icon).

## Non-Functional / Quality Attributes
- **Responsiveness**: Filter sheet must be height-adaptive based on content.
- **Animations**: Smooth slide-up transition for the sheet; list items must re-animate (staggered) when filters are applied.
- **UX**: Haptic feedback on slider adjustments and chip selections.

## Success Criteria
- Pet Owners can narrow down a list of 50+ sitters to a specific subset in under 10 seconds.
- Sitters can filter jobs by pet type and area.
- Filter state is accurately reflected in the results count (e.g., "3 זמינים").

## Assumptions
- The existing `marketplaceFiltersProvider` will be extended to support the new UI categories.
- Backend/Mock data supports querying by these new filter dimensions.
