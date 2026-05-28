# PetPal Design System (Organic Modernism)

## Colors
- **Primary**: Desert Bronze (`#C19A6B`). A sophisticated, warm metallic tone used for primary actions and branding.
- **Surface**: Warm Alabaster (`#F9F9F7`). A soft, high-key background that feels more natural than pure white.
- **On-Surface**: Onyx (`#1A1A1A`). High contrast but slightly softened black for optimal readability.
- **Neutrals**: Architectural borders (`#E0E0E0`) and muted text (`#8E8E93`).

## Typography
- **Headings**: Luxury Serif (`Playfair Display`). Used for titles and section headers to convey a premium, editorial feel.
- **Body & Data**: Modern Sans (`IBM Plex Sans Arabic`). Used for all functional text, inputs, and dense data displays for maximum legibility.
- **Hierarchy**: Enforced through scale contrast (≥1.25 ratio) and strategic weight (Semi-Bold for action labels, Medium for body).

## Components & Affordances
- **Radius**: Large, "Luxury Signature" organic curves (`32px`) are the default for cards and primary containers.
- **Tactility**: Heavy reliance on glassmorphism (blurs of 12.0 and opacities around 0.7) for overlays and secondary navigation components.
- **Shadows**: Premium, deep shadows (`AppShadows.premium`) provide depth and separate layered surfaces without the need for heavy borders.
- **Buttons**: Stateful `AppButton` with haptic feedback, scale animations, and a primary gradient variant.

## Spacing & Rhythm
- **Page Margin**: Consistent `24px` gutter.
- **Section Stack**: `32px` vertical separation to allow the design to "breathe".
- **Component Stack**: `12px` to `16px` for grouping related elements.

## Motion Guidelines
- **Curves**: Smooth ease-out-quart/expo curves for transitions.
- **Haptics**: Light impact feedback for tactile confirmation of primary actions.
- **Scale**: Subtle micro-scaling (0.96) on interactive elements to provide a physical "press" sensation.
