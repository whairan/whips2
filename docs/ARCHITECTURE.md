# ARCHITECTURE.md — Whips: Jungle Math Learning Game

## 1. Engine Choice: Godot 4.3+

**Why Godot 4:**
- Native 2D pipeline with TileMapLayer, parallax layers, Light2D, Y-sort, and normal-mapped sprites — ideal for the 2.5D jungle aesthetic
- Built-in UI system (Control nodes) for the whiteboard overlay, toolkit HUD, and menus without a separate UI framework
- GDScript for fast iteration; C# available for performance-critical systems (mastery model, task generation)
- Scene instancing maps directly to the "region package" model — each level is a scene tree
- Custom editor plugins (EditorPlugin, EditorInspectorPlugin) support the authoring pipeline
- Resource system (.tres/.res) for data-driven content with hot-reload via `ResourceLoader.load()` with cache invalidation
- Open source, no royalties, small binary

**Rendering approach:**
- CanvasLayer stack for parallax depth (background → mid-ground → playfield → foreground canopy → UI)
- Light2D with normal maps for volumetric jungle feel
- GPUParticles2D for mist, fireflies, pollen, light rays
- Shader-based fog of war on the map view (mask texture + dissolve shader)

---

## 2. Project Structure

```
whips/
├── docs/
│   ├── ARCHITECTURE.md          # this file
│   ├── ART_STYLE_GUIDE.md
│   └── CURRICULUM_AND_MAP.md
├── tools/
│   ├── content_validator.py     # schema validation + lint
│   ├── task_generator.py        # parameterized task generation
│   └── build_content.py         # compile content → Godot resources
├── content/
│   ├── schemas/                 # JSON schemas
│   │   ├── zone.schema.json
│   │   ├── level.schema.json
│   │   ├── task.schema.json
│   │   ├── interactable.schema.json
│   │   ├── reward.schema.json
│   │   ├── dialogue.schema.json
│   │   └── reference_page.schema.json
│   ├── zones/                   # zone definition files
│   │   ├── zone_1_jungle_edge.json
│   │   ├── zone_2_riverlands.json
│   │   └── ...
│   ├── levels/                  # per-level content
│   │   ├── level_01_counting.json
│   │   ├── level_02_number_sense.json
│   │   └── ...
│   ├── tasks/                   # task bank per topic
│   ├── reference_pages/         # codex content
│   └── dialogues/               # NPC dialogue trees
├── godot_project/
│   ├── project.godot
│   ├── addons/
│   │   ├── region_builder/      # editor plugin: region authoring
│   │   ├── task_editor/         # editor plugin: task trigger wiring
│   │   └── content_hot_reload/  # editor plugin: watch content/ → reload
│   ├── assets/
│   │   ├── sprites/
│   │   │   ├── player/
│   │   │   ├── interactables/
│   │   │   ├── environments/
│   │   │   ├── ui/
│   │   │   └── effects/
│   │   ├── tilesets/
│   │   ├── shaders/
│   │   ├── audio/
│   │   └── fonts/
│   ├── scenes/
│   │   ├── core/
│   │   │   ├── main.tscn                 # root: manages scene transitions
│   │   │   ├── game_manager.tscn         # autoload: global state
│   │   │   └── transition_screen.tscn
│   │   ├── menus/
│   │   │   ├── title_screen.tscn
│   │   │   ├── profile_select.tscn
│   │   │   └── settings.tscn
│   │   ├── map/
│   │   │   └── jungle_map.tscn           # full 55-region overview
│   │   ├── regions/
│   │   │   ├── region_base.tscn          # base region scene
│   │   │   ├── zone_1/
│   │   │   │   ├── region_01_counting.tscn
│   │   │   │   ├── region_02_number_sense.tscn
│   │   │   │   └── ...
│   │   │   └── ...
│   │   ├── puzzles/
│   │   │   ├── puzzle_overlay.tscn        # task presentation layer
│   │   │   └── mini_games/
│   │   │       ├── fruit_count_harvest.tscn
│   │   │       ├── vine_jump_number_line.tscn
│   │   │       ├── totem_array_builder.tscn
│   │   │       ├── river_split_share.tscn
│   │   │       ├── bamboo_fraction_craft.tscn
│   │   │       ├── jungle_market_barter.tscn
│   │   │       ├── temple_balance_altar.tscn
│   │   │       └── pattern_trail.tscn
│   │   ├── whiteboard/
│   │   │   └── whiteboard_overlay.tscn
│   │   ├── toolkit/
│   │   │   └── tool_tray.tscn
│   │   └── reference/
│   │       └── reference_library.tscn
│   ├── scripts/
│   │   ├── core/
│   │   │   ├── game_manager.gd           # global state, save/load
│   │   │   ├── scene_manager.gd          # transitions between scenes
│   │   │   ├── save_system.gd            # profile persistence
│   │   │   ├── settings_manager.gd       # accessibility, audio, display
│   │   │   └── content_loader.gd         # data-driven content loading
│   │   ├── player/
│   │   │   ├── player_controller.gd      # movement, climbing, interaction
│   │   │   ├── player_state_machine.gd   # idle, walk, climb, swing, interact
│   │   │   └── player_inventory.gd       # fruit, collectibles, tools
│   │   ├── regions/
│   │   │   ├── region_manager.gd         # load/unload region, state tracking
│   │   │   ├── region_restore.gd         # fog clearing, vegetation growth
│   │   │   ├── interactable_base.gd      # base class for all interactables
│   │   │   ├── climbable_surface.gd
│   │   │   ├── swing_point.gd
│   │   │   ├── pushable_block.gd
│   │   │   ├── fruit_tree.gd
│   │   │   ├── water_control.gd
│   │   │   ├── switch_totem.gd
│   │   │   ├── rune_door.gd
│   │   │   ├── rope_bridge.gd
│   │   │   ├── moving_platform.gd
│   │   │   └── eco_puzzle.gd
│   │   ├── math/
│   │   │   ├── task_manager.gd           # task selection, presentation, grading
│   │   │   ├── task_generator.gd         # parameterized task creation
│   │   │   ├── mastery_model.gd          # skill tracking, spaced repetition
│   │   │   ├── hint_engine.gd            # layered hints
│   │   │   └── feedback_engine.gd        # gentle explanations
│   │   ├── whiteboard/
│   │   │   ├── whiteboard_controller.gd  # canvas management
│   │   │   ├── drawing_tool.gd           # pencil, eraser logic
│   │   │   ├── stamp_tool.gd             # shape stamps
│   │   │   └── undo_redo_manager.gd
│   │   ├── toolkit/
│   │   │   ├── tool_tray_controller.gd
│   │   │   ├── manipulative_base.gd
│   │   │   ├── counter_seeds.gd
│   │   │   ├── fraction_bamboo.gd
│   │   │   ├── algebra_tablets.gd
│   │   │   ├── number_line_vine.gd
│   │   │   ├── ruler_tool.gd
│   │   │   └── protractor_tool.gd
│   │   ├── map/
│   │   │   ├── jungle_map_controller.gd
│   │   │   └── fog_of_war.gd
│   │   ├── rewards/
│   │   │   ├── reward_manager.gd
│   │   │   ├── unlock_tracker.gd
│   │   │   └── collectible.gd
│   │   ├── reference/
│   │   │   ├── reference_library.gd
│   │   │   └── reference_page.gd
│   │   ├── ui/
│   │   │   ├── hud.gd
│   │   │   ├── dialogue_box.gd
│   │   │   ├── task_ui.gd
│   │   │   └── accessibility.gd
│   │   └── mini_games/
│   │       ├── mini_game_base.gd
│   │       ├── fruit_count_harvest.gd
│   │       ├── vine_jump_number_line.gd
│   │       ├── totem_array_builder.gd
│   │       ├── river_split_share.gd
│   │       ├── bamboo_fraction_craft.gd
│   │       ├── jungle_market_barter.gd
│   │       ├── temple_balance_altar.gd
│   │       └── pattern_trail.gd
│   └── resources/
│       ├── themes/
│       │   └── jungle_theme.tres
│       └── generated/                    # compiled content from tools/
└── tests/
    ├── test_task_generation.py
    ├── test_mastery_model.py
    ├── test_content_validator.py
    ├── test_save_migration.py
    └── test_schemas.py
```

---

## 3. Core Systems

### 3.1 Scene & State System

**Scene graph:**
```
Main (main.tscn)
├── SceneManager          # handles transitions
├── GameManager (autoload)
│   ├── SaveSystem
│   ├── SettingsManager
│   ├── ContentLoader
│   ├── MasteryModel
│   ├── RewardManager
│   └── UnlockTracker
├── CurrentScene           # swapped by SceneManager
│   └── (title_screen | profile_select | jungle_map | region_XX | ...)
├── OverlayLayer           # always on top
│   ├── WhiteboardOverlay  # toggle with hotkey
│   ├── ToolTray
│   ├── PuzzleOverlay      # task presentation
│   ├── DialogueBox
│   └── HUD
└── TransitionScreen       # fade/wipe between scenes
```

**State transitions:**
```
┌──────────┐    ┌───────────────┐    ┌─────────────┐
│  Title   │───>│ Profile Select│───>│  Jungle Map │
│  Screen  │    │               │    │             │
└──────────┘    └───────────────┘    └──────┬──────┘
                                            │
                                     select region
                                            │
                                     ┌──────▼──────┐
                                     │   Region    │
                                     │  (Level)    │◄────────────┐
                                     └──────┬──────┘             │
                                            │                    │
                                   interact with                 │
                                   math trigger                  │
                                            │                    │
                                     ┌──────▼──────┐             │
                                     │   Puzzle    │  complete   │
                                     │  Overlay    │─────────────┘
                                     └──────┬──────┘
                                            │
                                     open whiteboard
                                     (any time)
                                            │
                                     ┌──────▼──────┐
                                     │ Whiteboard  │
                                     │  Overlay    │
                                     └─────────────┘
```

**Overlay rules:**
- Whiteboard can open from ANY state (region, puzzle, map)
- Tool tray is always accessible when whiteboard or puzzle is open
- Reference library opens as a full overlay from HUD button or puzzle hint
- Puzzle overlay dims the region background (shader uniform)
- Multiple overlays can stack: region → puzzle → whiteboard

### 3.2 Jungle Region System

Each region is a Godot scene that inherits from `region_base.tscn`.

**Region scene structure:**
```
RegionBase
├── ParallaxBackground
│   ├── Layer0_Sky           (scroll_scale: 0.0)
│   ├── Layer1_FarTrees      (scroll_scale: 0.2)
│   ├── Layer2_MidCanopy     (scroll_scale: 0.5)
│   └── Layer3_Mist          (scroll_scale: 0.3)
├── YSortWorld
│   ├── TileMapLayer_Ground
│   ├── TileMapLayer_Platforms
│   ├── Player
│   ├── Interactables        (group: all interactive objects)
│   │   ├── FruitTree_1
│   │   ├── Vine_1
│   │   ├── RopeBridge_1
│   │   ├── SwitchTotem_1
│   │   ├── RuneDoor_1
│   │   ├── WaterWheel_1
│   │   ├── PushableStone_1
│   │   └── ClimbableTree_1
│   ├── TraversalElements
│   │   ├── SwingPoint_1
│   │   ├── MovingPlatform_1
│   │   └── Ladder_1
│   ├── Collectibles
│   ├── NPCs
│   └── EcoPuzzleTriggers
├── FogOfWarMask             (sprite/shader — cleared on restore)
├── RestorationEffects       (particles, growing vines, etc.)
├── Light2D_Ambient
├── Light2D_Rays             (godray shader)
└── RegionManager            (script: loads region data, manages state)
```

**Region data (JSON → Resource):**
```json
{
  "region_id": "region_01",
  "zone": "zone_1_jungle_edge",
  "topic": "counting_to_20",
  "skill_tags": ["count_objects", "count_sequence", "count_from_n"],
  "landmark": "The First Clearing",
  "environment": {
    "tilemap": "res://assets/tilesets/zone_1_ground.tres",
    "parallax_layers": ["sky_dawn", "far_trees_green", "mid_ferns", "mist_light"],
    "ambient_color": "#2D5A27",
    "light_rays": true,
    "particles": ["pollen", "fireflies_subtle"]
  },
  "interactables": [
    {"type": "fruit_tree", "id": "ft_1", "position": [200, 400], "fruit_type": "mango", "count_range": [1, 10]},
    {"type": "climbable_tree", "id": "ct_1", "position": [500, 350]},
    {"type": "vine", "id": "v_1", "position": [350, 200], "swing": true},
    {"type": "switch_totem", "id": "st_1", "position": [700, 400], "triggers": "rune_door_1"},
    {"type": "rune_door", "id": "rd_1", "position": [800, 400], "required_task": "task_count_5"},
    {"type": "pushable_stone", "id": "ps_1", "position": [600, 450]},
    {"type": "water_wheel", "id": "ww_1", "position": [900, 350]},
    {"type": "rope_bridge", "id": "rb_1", "position": [400, 300], "state": "broken"}
  ],
  "traversal": ["climbable_tree", "vine_swing", "rope_bridge"],
  "eco_puzzle": {
    "id": "eco_01",
    "description": "Count the seeds to grow the bridge vine",
    "task_ref": "task_count_bridge",
    "on_solve": {"action": "restore", "target": "rb_1", "effect": "vine_grow"}
  },
  "quest_line": {
    "warmup": "task_diagnostic_count",
    "teach": ["task_teach_count_objects", "task_teach_count_sequence"],
    "practice": ["task_practice_count_1", "task_practice_count_2", "task_practice_count_3"],
    "apply": ["task_apply_fruit_count", "task_apply_eco_bridge"],
    "boss": "task_boss_counting_mastery"
  },
  "rewards": {
    "tool_unlock": "counter_seeds",
    "traversal_unlock": null,
    "jungle_restore": "clearing_bloom",
    "reference_pages": ["ref_counting_basics", "ref_number_names"],
    "collectibles": ["golden_seed_1", "golden_seed_2", "golden_seed_3"]
  },
  "connections": {
    "north": null,
    "south": null,
    "east": "region_02",
    "west": null
  },
  "restore_states": {
    "fog_cleared": false,
    "vegetation_grown": false,
    "bridge_rebuilt": false,
    "wildlife_spawned": false,
    "landmark_activated": false
  }
}
```

### 3.3 Interactables & Traversal

**Base class hierarchy:**
```
Node2D
└── InteractableBase (interactable_base.gd)
    ├── properties: interact_radius, prompt_text, is_active, region_state_key
    ├── signals: interacted, state_changed
    ├── methods: _on_player_nearby(), activate(), deactivate()
    │
    ├── FruitTree         → harvests fruit (math count task trigger)
    ├── ClimbableSurface  → player attaches, moves vertically
    ├── SwingPoint        → pendulum physics, player grabs
    ├── RopeBridge        → walkable when intact, collapses/rebuilds
    ├── PushableBlock     → physics-driven, snaps to grid
    ├── WaterControl      → dam/wheel, affects water level
    ├── SwitchTotem       → toggle, triggers linked objects
    ├── RuneDoor          → opens when task completed
    ├── MovingPlatform    → path-following platform
    └── Collectible       → pickup, adds to inventory
```

**Traversal mechanics (reusable components):**

| Mechanic | Implementation | Player State |
|----------|---------------|--------------|
| Climb | `ClimbableSurface` + raycasts on tree/vine/ladder | `climb` state: up/down/dismount |
| Swing | `SwingPoint` + PinJoint2D pendulum | `swing` state: momentum + release |
| Jump pad | `Area2D` with velocity impulse | `airborne` state |
| Moving platform | `AnimatableBody2D` on Path2D | `idle`/`walk` on platform |
| Rope bridge | `StaticBody2D` segments, rebuild animation | normal `walk` |
| Zip vine | `Path2D` + `PathFollow2D`, player rides | `zip` state |
| Floating log | `RigidBody2D` on water, player balances | `walk` with sway |
| Ladder | `ClimbableSurface` variant, vertical only | `climb` state |

### 3.4 Math Task System

**Task model:**
```json
{
  "task_id": "task_count_fruit_3",
  "topic": "counting_to_20",
  "skill_tags": ["count_objects"],
  "difficulty": 2,
  "type": "interactive",
  "representations": ["visual", "symbolic"],
  "prompt": "How many mangoes are on this tree?",
  "visual": {
    "type": "fruit_tree_display",
    "params": {"fruit": "mango", "count": 7, "arrangement": "scattered"}
  },
  "input_type": "number_entry",
  "answer": 7,
  "accept_equivalent": [],
  "solution_approaches": [
    {"method": "count_one_by_one", "hint": "Tap each mango as you count"},
    {"method": "group_and_count", "hint": "Group them by twos or threes first"}
  ],
  "hints": [
    {"level": 1, "text": "Try tapping each fruit to count it"},
    {"level": 2, "text": "Start from the left side and work right"},
    {"level": 3, "text": "There are more than 5. Count carefully from 1."}
  ],
  "explanation": "There are 7 mangoes on the tree. Counting each one: 1, 2, 3, 4, 5, 6, 7.",
  "on_correct": {"trigger": "eco_puzzle_progress", "target": "eco_01"},
  "on_incorrect": {"feedback": "gentle_retry", "offer_hint": true},
  "whiteboard_enabled": true,
  "tools_available": ["counter_seeds"],
  "tags": ["curated"],
  "generator_params": null
}
```

**Task flow:**
```
Trigger (interactable/NPC/quest)
  → TaskManager.start_task(task_id)
    → PuzzleOverlay opens (region dims)
      → Task rendered (visual + prompt)
      → Player works (whiteboard, tools, input)
      → Submit answer
        → Grade (exact match, equivalent check, partial credit)
          → Correct: feedback + reward + env change
          → Incorrect: gentle feedback + hint offer + retry
    → PuzzleOverlay closes
  → MasteryModel.record(skill_tags, result)
  → RegionManager.check_quest_progress()
```

**Task generation (parameterized):**
```gdscript
# task_generator.gd
func generate_counting_task(min_val: int, max_val: int, context: String) -> TaskData:
    var count = randi_range(min_val, max_val)
    var task = TaskData.new()
    task.prompt = "Count the %s" % context
    task.answer = count
    task.visual = {"type": "object_scatter", "count": count, "object": context}
    task.difficulty = _calculate_difficulty(count)
    return task
```

### 3.5 Whiteboard & Toolkit System

**Whiteboard architecture:**
```
WhiteboardOverlay (CanvasLayer, z_index: 100)
├── Background (semi-transparent)
├── CanvasContainer
│   ├── DrawingCanvas (SubViewport + Sprite2D)
│   │   └── multi-layer rendering:
│   │       Layer 0: grid (optional)
│   │       Layer 1: user drawing
│   │       Layer 2: stamps/shapes
│   │       Layer 3: manipulatives
│   ├── PageIndicator (1/n pages)
│   └── ManipulativeLayer (draggable objects on canvas)
├── Toolbar
│   ├── PencilButton (colors: black, red, blue, green)
│   ├── EraserButton (size slider)
│   ├── SelectButton (lasso select, move)
│   ├── UndoButton
│   ├── RedoButton
│   ├── ClearPageButton
│   ├── NewPageButton
│   ├── GridToggle
│   └── CloseButton
└── ManipulativeTray (drag out onto canvas)
    ├── CounterSeeds
    ├── FractionBamboo
    ├── AlgebraTablets
    ├── NumberLineVine
    ├── RulerTool
    └── ProtractorTool
```

**Drawing implementation:**
- `SubViewport` with `ImageTexture` for rasterized drawing
- Bresenham line drawing between input points for smooth strokes
- Undo/redo via command pattern: each stroke/erase/stamp is a `DrawCommand`
- Pages stored as `Array[Image]`, switchable
- Board state serialized to save file per task attempt

**Manipulatives:**
- Each manipulative is a `Control` node that can be dragged from tray onto canvas
- On canvas, manipulatives are interactive: fraction bamboo can be split/joined, counters grouped, number line scrolled
- Manipulatives have a "jungle item" visual style (seeds, bamboo, carved stone) but clear mathematical function
- Snap-to-grid option when grid is enabled

### 3.6 Mastery & Adaptive System

**Mastery model (spaced repetition + skill tracking):**
```gdscript
# mastery_model.gd
class SkillRecord:
    var skill_tag: String
    var level: int          # 0=new, 1=introduced, 2=practiced, 3=proficient, 4=mastered
    var correct_streak: int
    var total_attempts: int
    var total_correct: int
    var last_attempt_time: int
    var next_review_time: int
    var difficulty_rating: float  # running average difficulty of tasks attempted

func record_attempt(skill_tag: String, correct: bool, difficulty: int):
    var record = get_or_create(skill_tag)
    record.total_attempts += 1
    if correct:
        record.total_correct += 1
        record.correct_streak += 1
        _maybe_level_up(record)
    else:
        record.correct_streak = 0
        _maybe_level_down(record)
    record.last_attempt_time = Time.get_unix_time_from_system()
    record.next_review_time = _calculate_next_review(record)
    save()

func get_mastery_level(skill_tag: String) -> int:
    return get_or_create(skill_tag).level

func get_due_for_review() -> Array[String]:
    # returns skill tags that are due for spaced review
    ...
```

**Level-up thresholds:**
| Level | Name | Requirement |
|-------|------|------------|
| 0 | New | No attempts |
| 1 | Introduced | Attempted warmup |
| 2 | Practiced | 3+ correct in practice |
| 3 | Proficient | 5+ correct, streak of 3 at difficulty ≥ 2 |
| 4 | Mastered | Boss challenge passed, streak of 5 |

**Hint engine (layered):**
- Level 1: Gentle nudge ("Think about what counting means")
- Level 2: Strategy hint ("Try grouping them by fives")
- Level 3: Partial reveal ("The answer is between 5 and 10")
- Level 4: Worked example (step-by-step with explanation)
- Player chooses when to request hints — never forced

### 3.7 Reward & Progression System

**Reward categories and implementation:**

| Category | Examples | Implementation |
|----------|----------|---------------|
| Skill mastery | Level up badge per skill | MasteryModel tracks, HUD shows |
| Jungle restore | Fog clears, vines grow, waterfall starts | Region shader uniforms + particle toggle |
| Traversal unlock | Vine swing, canopy climb, zip vine | Player ability flags |
| Tool unlock | Ruler, fraction bamboo, algebra tablets | ToolTray availability flags |
| Reference pages | Codex entries | ReferenceLibrary unlock flags |
| Cosmetics | Player skins, hat, trail effects | Player cosmetic slots |
| Collectibles | Golden seeds, ancient runes, rare butterflies | Inventory + collection UI |

**Progression gates:**
- Regions unlock based on adjacent region completion (graph-based, not linear)
- Some regions require specific traversal abilities (vine swing to reach canopy zone)
- Boss challenges gate region "restoration" but not forward progress — player can skip and return
- Practice arena always available for any unlocked topic

### 3.8 Global Jungle Map

**Implementation:**
```
JungleMap (scene)
├── MapCamera (Camera2D, zoomable, pannable)
├── MapBackground (full jungle illustration, large texture)
├── FogOfWarLayer (SubViewport + shader)
│   └── FogMask (Image: white = hidden, black = revealed)
├── RegionMarkers (55 clickable nodes)
│   ├── RegionMarker_01 (position, icon, label, state)
│   ├── RegionMarker_02
│   └── ...
├── PathConnections (Line2D between connected regions)
├── WildlifeSpawns (animated animals on revealed areas)
├── WaterfallEffects (particles on restored landmarks)
└── MapUI
    ├── ZoneLabels
    ├── LegendPanel
    └── MasteryOverview
```

**Fog of war:**
- Shader-based: a mask texture where each pixel represents map visibility
- Completing a region: circular reveal centered on region, dissolve animation
- Adjacent regions become "shadowed" (partially visible, clickable)
- Fully hidden regions show only as dark silhouettes

**End-game reveal:**
- When all 55 regions complete: cinematic pan across entire map
- All fog dissolves in a cascade
- Wildlife, waterfalls, glowing plants all activate
- Music builds to a crescendo
- "Mastery Tour" mode unlocks: free-roam the full map, revisit any region

---

## 4. Content Pipeline

### 4.1 Authoring flow

```
Content Author (JSON/YAML files in content/)
    │
    ▼
Validator (tools/content_validator.py)
    │  checks: schema compliance, answer validity,
    │  region connectivity, reward balance, skill coverage
    ▼
Build Tool (tools/build_content.py)
    │  compiles JSON → Godot Resource files (.tres)
    │  copies to godot_project/resources/generated/
    ▼
Hot Reload (addons/content_hot_reload/)
    │  watches content/ directory
    │  on change: re-validate → re-build → reload in editor
    ▼
Godot Editor (runtime)
    └─ ContentLoader.gd reads .tres resources
```

### 4.2 Validator rules

- **Schema compliance**: all required fields present, correct types
- **Answer validity**: every task has a valid answer, no division by zero, no negative results where inappropriate
- **Region connectivity**: every region is reachable from region_01 via connections graph
- **Reward balance**: no duplicate unlocks, all tools unlocked by level 30, all traversal by level 40
- **Skill coverage**: every skill tag has at least 10 practice tasks and 1 boss task
- **Difficulty curve**: tasks within a level increase in difficulty, bosses are hardest
- **Reference completeness**: every topic has at least 1 reference page

### 4.3 Hot reload (dev mode)

```gdscript
# content_hot_reload.gd (EditorPlugin)
func _ready():
    var watcher = FileSystemWatcher.new()
    watcher.watch("res://../../content/")
    watcher.file_changed.connect(_on_content_changed)

func _on_content_changed(path: String):
    # 1. Run validator
    var result = OS.execute("python3", ["../../tools/content_validator.py", path])
    if result.exit_code != 0:
        push_warning("Content validation failed: %s" % result.output)
        return
    # 2. Rebuild resource
    OS.execute("python3", ["../../tools/build_content.py", path])
    # 3. Reload in editor
    EditorInterface.get_resource_filesystem().scan()
    print("Content hot-reloaded: %s" % path)
```

---

## 5. Save System

**Save file structure:**
```json
{
  "version": 3,
  "profile": {
    "name": "Explorer",
    "created": "2026-01-15T10:30:00Z",
    "play_time_seconds": 14400
  },
  "mastery": {
    "count_objects": {"level": 4, "streak": 7, "attempts": 23, "correct": 21},
    "count_sequence": {"level": 3, "streak": 4, "attempts": 15, "correct": 12}
  },
  "regions": {
    "region_01": {"completed": true, "restored": true, "collectibles": ["gs_1", "gs_2"]},
    "region_02": {"completed": true, "restored": false, "collectibles": ["gs_3"]},
    "region_03": {"completed": false, "restored": false, "collectibles": []}
  },
  "unlocks": {
    "tools": ["counter_seeds", "ruler"],
    "traversal": ["vine_swing"],
    "reference_pages": ["ref_counting_basics", "ref_number_names", "ref_addition_intro"],
    "cosmetics": ["leaf_hat"]
  },
  "inventory": {
    "fruits": {"mango": 5, "coconut": 2},
    "collectibles": ["gs_1", "gs_2", "gs_3", "rune_alpha"]
  },
  "settings": {
    "hint_level": "normal",
    "difficulty": "adaptive",
    "accessibility": {
      "high_contrast": false,
      "reduced_motion": false,
      "calm_mode": false,
      "color_blind_mode": "none",
      "font_size": "medium"
    }
  },
  "whiteboard_states": {}
}
```

**Save migration:**
- Each save file has a `version` field
- `SaveSystem` contains migration functions: `_migrate_v1_to_v2()`, `_migrate_v2_to_v3()`, etc.
- Migrations run sequentially on load if version is old
- Automated tests verify all migration paths

---

## 6. Accessibility

| Feature | Implementation |
|---------|---------------|
| High contrast text | Theme override: bold fonts, dark outlines, increased contrast |
| Reduced motion | Global flag: disables particles, parallax, screen shake; uses simple fades |
| Calm mode | Removes timers, reduces visual noise, softer audio |
| Color-blind modes | Shader: deuteranopia, protanopia, tritanopia simulation + icon differentiation |
| Font sizing | 3 sizes (S/M/L), all UI uses theme font size reference |
| Input flexibility | Keyboard, mouse, gamepad, touch (future) all supported |
| Screen reader hints | Control nodes have `tooltip_text` for accessibility |

---

## 7. Performance Targets

| Metric | Target |
|--------|--------|
| FPS (region gameplay) | 60 FPS stable on mid-range hardware |
| FPS (map view, all 55 markers) | 60 FPS |
| Whiteboard input latency | < 16ms (1 frame) |
| Scene transition time | < 500ms |
| Save/load time | < 100ms |
| Memory (single region) | < 200MB |
| Memory (map view) | < 300MB |
| Content hot-reload | < 2s |

---

## 8. Migration Plan from Python Prototype

Since no Python prototype exists in the workspace, this serves as a forward migration plan for any existing Python prototype logic:

| Python Component | Godot Equivalent | Migration Strategy |
|-----------------|-------------------|-------------------|
| Task bank (Python dicts/JSON) | `content/tasks/*.json` → Godot Resources | Export Python data to JSON, validate with schema, build to .tres |
| Mastery tracking (Python) | `mastery_model.gd` | Port algorithm to GDScript, verify with unit tests |
| UI (Tkinter/Pygame/terminal) | Godot Control nodes + scenes | Rebuild from scratch in Godot (no UI code reuse) |
| Task generator (Python) | `task_generator.gd` + `tools/task_generator.py` | Keep Python version for batch generation, port core logic to GDScript for runtime |
| Save data (Python pickle/JSON) | Godot JSON save system | Write migration script: Python save → Godot JSON format |

**Migration steps:**
1. Export all task data from Python prototype to JSON matching the content schema
2. Run validator on exported data, fix any issues
3. Port mastery algorithm to GDScript, write comparison tests
4. Rebuild all UI in Godot (no code reuse — different paradigm)
5. Write save file converter if existing saves need to carry over
6. Validate with parallel testing: run same tasks in both systems, compare results

---

## 9. Testing Strategy

### Automated (Python — tools/tests/)
- Content schema validation
- Task generation correctness (answers are valid)
- Mastery model progression (level up/down thresholds)
- Save migration paths
- Region connectivity graph (all regions reachable)
- Reward balance checks

### Automated (Godot — GUT framework)
- Whiteboard undo/redo operations
- Player state machine transitions
- Interactable trigger/response
- Region restore state changes
- Task grading logic
- Save/load round-trip

### Manual / Playtest
- Region feel and interactable polish
- Whiteboard drawing quality
- Hint and feedback tone
- Difficulty progression
- Accessibility modes
- Performance profiling

---

## 10. MVP Scope

The MVP proves the core jungle vision with 3 levels:

| Component | MVP Scope |
|-----------|-----------|
| Regions | 3 connected regions (Levels 1-3 from Zone 1) |
| Map | Mini map with 3 regions + fog of war |
| Player | Walk, climb, interact, collect |
| Interactables | 8+ per region (fruit trees, vines, totems, doors, bridges, stones, wheels, climbable trees) |
| Traversal | Climb + vine swing |
| Eco puzzles | 1 per region (math → environment change) |
| Math tasks | 15-20 curated tasks across 3 topics |
| Whiteboard | Pencil, eraser, undo/redo, grid, multi-page |
| Toolkit | 6 manipulatives (counter seeds, fraction bamboo, algebra tablets, number line vine, ruler, protractor) |
| Mastery | Basic skill tracking + level up |
| Hints | 3-layer hints |
| Rewards | Tool unlock, jungle restore effect, reference pages |
| Reference | 10 codex pages |
| Save/Load | Profile create/select, auto-save |
| Settings | High contrast, reduced motion, calm mode |
| Parallax | 4-layer parallax per region |
| Particles | Mist, pollen, fireflies |
| Audio | Ambient jungle + UI sounds (placeholder) |

---

## 11. Roadmap Beyond MVP

| Milestone | Regions | Key Additions |
|-----------|---------|---------------|
| MVP | 1-3 | Core systems, 3 regions, whiteboard, toolkit |
| Alpha | 1-14 | Zones 1-2 complete, all mini-games for counting/addition/subtraction |
| Beta | 1-33 | Zones 1-4 complete, fractions, full mastery model, practice arena |
| Release Candidate | 1-50 | Zones 1-7, decimals/percents/integers, end-game map reveal |
| 1.0 | 1-55 | All zones, prealgebra, mastery tour, polish, full audio |
| Post-launch | 55+ | Community levels, additional topics, multiplayer practice |
