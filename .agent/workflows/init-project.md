---
description: 
---

### 2. The Initialization Workflow (The "Kickoff")
**File Location:** `.agent/workflows/init_project.md`
**Command:** `/init-project`

This replaces the "Your Task" section of the prompt. It guides the agent through the one-time setup process.

```markdown
# Initialize Jericho Villa Project

**Description:** Bootstraps the project foundation, git, and core layers based on provided specs.

**Steps:**
1.  **Analyze Requirements:**
    - Read the attached `UI,UX.txt` and `database_schema.txt` (if provided in context).
    - Extract Design Tokens (Colors, Radius, Shadows) and Schema definitions.

2.  **Setup Foundation:**
    - Initialize Git repo (`git init`).
    - Create `pubspec.yaml` with dependencies (riverpod, freezed, etc.).
    - Generate the `lib/core/` directory structure (Theme, Colors, Failure Classes).
    - **Wait for user confirmation.**

3.  **Implement Domain & Data (Feature 1):**
    - Generate Entities, Repositories, and Models for the `Auth` feature.
    - Run build_runner if necessary.
    - **Wait for user confirmation.**

4.  **Build UI (Feature 1):**
    - strictly apply the "200-Line Rule" from the Rules file.
    - **Wait for user confirmation.**