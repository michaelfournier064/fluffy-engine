# Contributing to Fluffy Engine

Thanks for helping build **Fluffy Engine**, a Godot 4 project for **COSC 450: Programming Language Principles and Paradigms**. This guide keeps code, scenes, and assets clean and consistent.

---

## Project Structure

```text
res://
  assets/
    images/
    sounds/
    fonts/
  scenes/            # .tscn scenes (levels, UI, prefabs)
  scripts/           # .gd scripts (gameplay, systems, utils)
  ui/                # themes, reusable UI widgets
  .godot/            # Godot metadata (keep UID cache)
  project.godot
  README.md
  CONTRIBUTING.md
```

- **Scenes** are the primary units of composition.
- **Scripts** mirror scene purpose (e.g., `title_screen.gd` for `TitleScreen.tscn`).
- **UI** contains reusable controls and themes (e.g., `ButtonUtil.gd` helper).

---

## Getting Started

1. **Clone** the repository.
2. **Open in Godot 4.x** (latest stable 4.x recommended).
3. **Run** with **F5**.

### Optional tooling

- **Git LFS** recommended for large binary assets (`assets/images`, `assets/sounds`).

---

## Running & Exporting

- Development: press **F5** in the editor.
- Export builds via **Project → Export** (add presets for your OS if missing).

---

## Tests (optional)

If test scenes/scripts are added (e.g., with GUT or built-in test scenes):

```text
res://tests/...
```

Run tests by opening the test runner scene and pressing **F5**. Keep tests close to the code they cover when possible.

---

## Coding Standards

### GDScript

- **Typed GDScript**: Prefer explicit types.
- **Naming**:
  - Classes/Scenes: `PascalCase` (e.g., `TitleScreen`, `EnemySpawner`).
  - Files: `snake_case.gd` / `TitleScreen.tscn`.
  - Variables/Functions/Signals: `snake_case`.
- **Signals**: Connect in code (preferably in `_ready`) or via the Node panel—be consistent.
- **Connections**:
  - If a node is **instanced fresh** (typical UI/scene): connect without guards.
  - If a node is **persistent** (autoload/singleton) or might reconnect: use  
    `if not signal.is_connected(callback): signal.connect(callback)`.
- **Scene composition**:
  - Favor **composition over inheritance**; make small reusable scenes.
  - Keep UI input unblocked (e.g., set background `TextureRect.mouse_filter = Ignore` or place background as `Sprite2D` under UI `CanvasLayer`).
- **Layout**: Use Containers (`VBoxContainer`, `HBoxContainer`, `MarginContainer`, `AspectRatioContainer`) with **Size Flags** rather than manual anchors.
- **Utilities**: Centralize common UI wiring (e.g., `ButtonUtil`) and audio behaviors.

### Assets

- Place images, audio, and fonts under `assets/`.
- Use clear names; include source/attribution in commit or a top-level `CREDITS.md` if needed.
- Prefer lightweight formats (PNG/JPEG for images, OGG/MP3 for audio as appropriate).

---

## Commit Message Practices

Format:

```text
{type}({area}): {short description}
```

**type**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `build`, `perf`, `style`  
**area**: `ui`, `audio`, `input`, `scene`, `player`, `enemy`, `core`, etc.

### Examples

- `feat(ui): title-screen - add hover/press sounds via ButtonUtil`
- `fix(audio): stop hover sound before playing press sound`
- `refactor(scene): split player into movement + camera`
- `docs: README - add run/export steps`

Keep messages concise, **imperative mood** (e.g., “add”, not “added”).

---

## Branching & Pull Requests

- Branch from `dev` (or `main` if `dev` isn’t used): `feat/ui-title-screen`, `fix/audio-click`.
- Ensure the project **opens and runs** in Godot 4 before submitting.
- **PR checklist**:
  - [ ] Scenes/scripts named and organized as above
  - [ ] No broken references or missing resources
  - [ ] UI input not blocked by backgrounds
  - [ ] Signals connected appropriately (guarded if persistent)
  - [ ] Tests updated/added if applicable
  - [ ] Clear PR title/description (screenshots/gifs welcome)

Assign at least one reviewer.

---

## Git & UIDs

Godot 4 uses **UIDs** in scene/resource files. Keep metadata needed to resolve them:

### .gitignore (essentials)

```text
# Import cache (rebuilds automatically)
.import/
*.import

# Keep .godot UID metadata
!.godot/
!.godot/uid_cache*
```

Do **commit** `.godot/uid_cache*` (and other small metadata), **do not commit** heavy `.import/` caches.

---

## Security & Academic Integrity

- Use only assets/code you have rights to use; credit sources.
- Keep the repo free of credentials or personal data.
- Follow course policies on collaboration and originality.

---

## Questions

Open an issue or start a discussion in the repo. Include:

- Godot version
- OS
- Steps to reproduce (for bugs)
- Scene/script names involved
