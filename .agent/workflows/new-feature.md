---
description: 
---

# Build New Feature

**Description:** Implements a new feature following the Clean Architecture strict order.

**Steps:**
1.  **Git Branching:**
    - Ask the user for the feature name (e.g., `villa-listing`).
    - Create a new branch `feature/villa-listing`.

2.  **Domain Layer:**
    - Create Entities, UseCases, and Repository Interfaces (Pure Dart).
    - Verify no Flutter dependencies are imported.

3.  **Data Layer:**
    - Create Models (Freezed) and Repository Implementations.
    - Implement Firestore Data Sources.

4.  **Presentation Layer:**
    - Create Riverpod Providers.
    - Build Screens and Widgets (Applying the 200-line split rule).

5.  **Commit:**
    - Suggest `git add .` and `git commit -m "feat: implemented [feature] layer"`.