# Whips: Jungle Math

An educational math adventure game built in **Godot 4.3** that teaches foundational through pre-algebra mathematics (grades K-6) through an immersive 2.5D jungle environment.

Players explore 55 interconnected jungle regions across 8 themed zones, solving math puzzles that progressively restore a decaying jungle ecosystem. The game features an adaptive mastery-based learning system, whiteboard drawing tools, interactive manipulatives, and a fog-of-war map.

## Quick Start

### Prerequisites

- [Godot 4.3+](https://godotengine.org/download) (standard edition)
- Python 3.10+ (for content tools)

### Running the Game

```bash
# Open in Godot editor
godot --editor --path godot_project

# Or run directly
godot --path godot_project
```

### Content Pipeline

Content is authored as JSON in `content/` and built to Godot-readable resources:

```bash
# Validate all content
python tools/content_validator.py --all

# Build content to godot_project/resources/generated/
python tools/build_content.py

# Watch for changes and rebuild automatically
python tools/build_content.py --watch
```

### Running Tests

```bash
pip install jsonschema pytest
python -m pytest tests/ -v
```

## Project Structure

```
whips-jungle-math/
├── godot_project/              # Godot 4.3 project
│   ├── project.godot           # Project config (1280x720, GL Compatibility)
│   ├── scenes/                 # Scene files (.tscn)
│   │   ├── core/               # Main scene
│   │   ├── menus/              # Title screen, profile select
│   │   ├── map/                # Jungle map with fog of war
│   │   ├── regions/            # Region base template
│   │   └── whiteboard/         # Drawing overlay
│   ├── scripts/                # GDScript source (31 files)
│   │   ├── core/               # GameManager, SceneManager, SaveSystem,
│   │   │                       # ContentLoader, SettingsManager (autoloads)
│   │   ├── player/             # Character controller, state machine
│   │   ├── regions/            # RegionManager, interactables (FruitTree,
│   │   │                       # RopeBridge, ClimbableSurface, Collectible, etc.)
│   │   ├── math/               # TaskManager — grading, hints, mastery tracking
│   │   ├── whiteboard/         # Drawing canvas, undo/redo
│   │   ├── toolkit/            # Manipulatives (counters, number line, etc.)
│   │   ├── map/                # Jungle map controller, fog of war
│   │   ├── ui/                 # HUD, task UI overlay
│   │   ├── mini_games/         # Mini-game templates
│   │   ├── rewards/            # Reward tracking
│   │   └── reference/          # In-game reference library
│   ├── assets/                 # Art, audio, fonts, shaders (placeholder)
│   └── resources/generated/    # Built content (from JSON)
├── content/                    # Content authoring (JSON)
│   ├── schemas/                # JSON schemas (7 schemas)
│   ├── zones/                  # Zone definitions
│   ├── levels/                 # Level definitions
│   ├── tasks/                  # Task banks
│   ├── reference_pages/        # Reference content
│   └── dialogues/              # NPC dialogue trees
├── tools/                      # Python build tools
│   ├── content_validator.py    # Schema validation + lint rules
│   └── build_content.py        # JSON to Godot resource compiler
├── tests/                      # Automated tests
│   └── test_content_validator.py
└── docs/                       # Design documentation
    ├── ARCHITECTURE.md         # Technical architecture
    ├── ART_STYLE_GUIDE.md      # Visual style, palettes, shaders
    └── CURRICULUM_AND_MAP.md   # Full 55-level curriculum
```

## Game Controls

| Action          | Key            |
|-----------------|----------------|
| Move            | WASD / Arrows  |
| Jump            | Space          |
| Interact        | E              |
| Whiteboard      | Q              |
| Map             | M              |
| Reference       | R              |
| Back / Pause    | ESC            |

## Architecture

### Core Systems (Autoloaded Singletons)

- **GameManager** — Global state, profile management, mastery tracking, unlock progression
- **SceneManager** — Scene transitions with fade effects, region routing
- **SaveSystem** — JSON-based save/load with version migration
- **ContentLoader** — Loads content JSON, hot-reload support
- **SettingsManager** — Accessibility, audio, gameplay settings

### Gameplay Loop

```
Title Screen → Profile Select → Jungle Map → Select Region
    → Region loads with interactables spawned from JSON
    → Warmup diagnostic task auto-starts
    → Quest progression: warmup → teach → practice → apply → boss
    → Correct answers → mastery tracking → eco-puzzle restoration
    → Region complete → rewards unlocked → adjacent regions revealed
    → Return to map
```

### Data-Driven Content

All game content is defined in JSON with schema validation:

- **Zones** define theme, palette, guide animal, ambient settings
- **Levels** define interactables, quest line, eco-puzzle, rewards, connections
- **Tasks** define prompt, answer, hints (4 levels), solution approaches, grading rules
- **Reference pages** provide topic explanations, examples, common pitfalls

### Mastery Model

Five skill levels with spaced repetition:

| Level | Name        | Requirement                                |
|-------|-------------|--------------------------------------------|
| 0     | New         | Not yet attempted                          |
| 1     | Introduced  | 1 attempt                                  |
| 2     | Practiced   | 3 correct answers                          |
| 3     | Proficient  | 5 correct, 3 streak, difficulty >= 2       |
| 4     | Mastered    | 5 streak at proficient level               |

### Eco-Puzzle System

Each region has an eco-puzzle linking math tasks to environmental restoration — solving a counting task grows a vine bridge, completing equations activates a water wheel, etc. This provides tangible, visual feedback for mathematical progress.

## Current Status

### Implemented (MVP Foundation)

- All core game systems (5 autoloaded singletons)
- Player controller with full state machine (idle, walk, jump, fall, climb, interact)
- Task system with answer validation, hints, mastery tracking
- Dynamic interactable spawning from level JSON
- Region lifecycle (load, quest progression, eco-puzzle, restoration, rewards)
- Whiteboard drawing tool with undo/redo, multi-page, grid
- Manipulative toolkit framework (counter seeds, number line, etc.)
- Jungle map with fog of war and region markers
- Save/load system with migration support
- Content pipeline with schema validation and build tools
- Accessibility settings (high contrast, reduced motion, calm mode, color-blind)

### Zone 1 Content (Playable)

- **3 levels** with full quest lines and task banks:
  - Level 01: Counting to 20 (10 tasks)
  - Level 02: Comparing Numbers (9 tasks)
  - Level 03: Place Value — Ones & Tens (9 tasks)
- **10 reference pages** covering counting, comparison, place value, and beyond
- **1 zone definition** with palette, guide animal (Kiko the monkey), ambient settings

### Designed but Not Yet Implemented

- Levels 4-55 (full curriculum designed in `docs/CURRICULUM_AND_MAP.md`)
- Art assets (sprites, tilesets, shaders — directory structure ready)
- Audio (ambient, music, SFX — settings system ready)
- Mini-game implementations (8 templates defined)
- NPC dialogue system (schema ready, no content authored)
- Advanced traversal abilities (vine swing, water walk, cloud step, etc.)
- Cosmetic reward system

## Content Authoring

### Adding a New Level

1. Create `content/levels/level_XX_topic.json` following the level schema
2. Create `content/tasks/level_XX_tasks.json` with task bank (array of tasks)
3. Create reference pages in `content/reference_pages/`
4. Add the level to the zone definition
5. Run `python tools/content_validator.py content/levels/level_XX_topic.json` to validate
6. Run `python tools/build_content.py` to build

### Task Structure

Each task requires:
- **prompt** — The question presented to the player
- **answer** — The correct answer (number, string, array, or "variable" for boss tasks)
- **hints** — 1-4 progressive hints from gentle to explicit
- **explanation** — Shown after correct answer
- **skill_tags** — Which skills this task assesses
- **difficulty** — 1-5 scale for adaptive difficulty

### Validation Commands

```bash
# Validate everything
python tools/content_validator.py --all

# Check region connectivity (all levels reachable from level_01)
python tools/content_validator.py --check-graph

# Check reward balance (no duplicate unlocks)
python tools/content_validator.py --check-balance

# Check skill coverage (each skill has enough tasks)
python tools/content_validator.py --check-coverage
```

## Curriculum Overview

| Zone | Theme                    | Levels | Topics                                    |
|------|--------------------------|--------|-------------------------------------------|
| 1    | Jungle Edge              | 1-6    | Counting, comparing, place value, patterns, addition, subtraction concepts |
| 2    | Riverlands               | 7-14   | Addition & subtraction facts and algorithms |
| 3    | Canopy Works             | 15-24  | Multiplication & division                 |
| 4    | Bamboo Fractions Grove   | 25-33  | Fraction concepts and operations          |
| 5    | Misty Rational Peaks     | 34-38  | Decimal concepts and operations           |
| 6    | Market Ruins             | 39-44  | Percents, ratios, proportions             |
| 7    | Night Jungle             | 45-50  | Integers and coordinate plane             |
| 8    | Temple of Patterns       | 51-55  | Prealgebra — expressions, equations, functions |

See `docs/CURRICULUM_AND_MAP.md` for the full 55-level breakdown with landmarks, rewards, and skill tags.

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — Technical architecture, system design, performance targets
- [`docs/ART_STYLE_GUIDE.md`](docs/ART_STYLE_GUIDE.md) — Visual style, zone palettes, shader specs, animation timing
- [`docs/CURRICULUM_AND_MAP.md`](docs/CURRICULUM_AND_MAP.md) — Complete 55-level curriculum with mastery rules and reward graph

## License

All rights reserved.
