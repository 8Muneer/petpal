# Research: Explore Discovery Hub

## Decision: Floating Pill Bottom Navigation
- **Choice**: Custom implementation using a `Positioned` widget inside a `Stack` at the bottom of the `AppScaffold` or a persistent overlay.
- **Rationale**: Flutter's default `BottomNavigationBar` doesn't easily support a floating "pill" look with absolute positioning above the bottom edge. A custom `Container` with `BoxShadow`, `BorderRadius.circular(40)`, and `ClipRRect` for glassmorphism will provide the best aesthetic control.
- **Alternatives**:
  - `FloatingActionButton` + `BottomAppBar`: Too rigid for a 5-item menu.
  - Third-party packages (e.g., `google_nav_bar`): Good, but custom implementation allows for the specific "soft colored circular background" selected state requested.

## Decision: Glassmorphic Overlay Components
- **Choice**: Use `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` inside a `ClipRRect`.
- **Rationale**: This is the standard Flutter approach for real-time glassmorphism. It aligns with the "Organic Modernism" system.
- **Alternatives**:
  - Static semi-transparent images: Low performance cost but doesn't look as premium as real-time blur.

## Decision: Staggered Entrance Animations
- **Choice**: Use `flutter_staggered_animations` or custom `TweenAnimationBuilder` with `AnimationController`.
- **Rationale**: Staggered animations add a "luxury" feel by preventing the UI from feeling static.

## Decision: RTL (Right-to-Left) Handling
- **Choice**: Explicitly use `Directionality(textDirection: TextDirection.rtl, ...)` and `EdgeInsetsDirectional` instead of `EdgeInsets`.
- **Rationale**: Ensures the layout flips correctly for Hebrew/Arabic without manual calculation of left/right.
