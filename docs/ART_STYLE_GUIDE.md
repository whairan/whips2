# ART STYLE GUIDE — Whips: Jungle Math Learning Game

## 1. Visual Identity

**Tagline:** "Noita meets Sony Ericsson Virtual Village — in a living, learnable jungle."

**Core principles:**
1. **Readable above all** — Math moments must be visually calm and uncluttered
2. **Alive and cozy** — Small animations everywhere: swaying leaves, dripping water, blinking eyes
3. **Dense but not noisy** — Layers create depth; contrast creates focus
4. **Progression is visible** — The jungle visually transforms as the player learns

---

## 2. Color Palette

### 2.1 Zone Palettes

Each zone has a dominant palette that shifts across its regions. All zones share the same shadow and highlight families for cohesion.

**Zone 1 — Jungle Edge (Foundations)**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#3A7D44` | Ground foliage, grass |
| Secondary | `#8FBC8F` | Light canopy, ferns |
| Accent | `#FFD700` | Fruit, collectibles, interactive highlights |
| Ground | `#5C4033` | Soil, bark, paths |
| Sky | `#87CEEB` | Visible sky through gaps |
| Shadow | `#1A2E1A` | Deep shadow under canopy |

**Zone 2 — Riverlands (Addition/Subtraction)**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#2E8B57` | Riverside vegetation |
| Secondary | `#4682B4` | River water, pools |
| Accent | `#FF6347` | River flowers, berries |
| Ground | `#6B4226` | Muddy banks, wet stones |
| Water | `#1E90FF` → `#104E8B` | Water gradient, depth |
| Mist | `#B0C4DE` (40% opacity) | River mist |

**Zone 3 — Canopy Works (Multiplication/Division)**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#228B22` | Dense upper canopy |
| Secondary | `#9ACD32` | Sun-hit leaves |
| Accent | `#FF8C00` | Tree platforms, rope bridges |
| Sky Peek | `#F0E68C` | Light through canopy |
| Bark | `#8B4513` | Massive tree trunks |
| Depth | `#0D3B0D` | Far background canopy |

**Zone 4 — Bamboo Fractions Grove**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#90EE90` | Bamboo stalks (lighter green) |
| Secondary | `#6B8E23` | Bamboo leaves |
| Accent | `#DEB887` | Cut bamboo cross-sections, fraction markers |
| Ground | `#D2B48C` | Sandy grove floor |
| Shadow | `#2F4F2F` | Bamboo shadow stripes |

**Zone 5 — Misty Rational Peaks**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#708090` | Stone, cliff faces |
| Secondary | `#4A766E` | Mountain vegetation |
| Accent | `#E0FFFF` | Ice crystals, water drops |
| Mist | `#DCDCDC` (50% opacity) | Thick mountain mist |
| Sky | `#B0C4DE` | Overcast sky |

**Zone 6 — Market Ruins (Decimals/Percents)**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#CD853F` | Sandstone ruins |
| Secondary | `#556B2F` | Overgrown vines on ruins |
| Accent | `#FFD700` | Gold coins, market goods |
| Ground | `#DEB887` | Dusty market floor |
| Stone | `#A0522D` | Ancient carved stone |

**Zone 7 — Night Jungle (Integers/Proportions)**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#0B3D0B` | Dark jungle foliage |
| Secondary | `#191970` | Night sky |
| Accent | `#00FF7F` | Bioluminescent plants, glowing fungi |
| Glow | `#7DF9FF` | Firefly trails, glowing water |
| Moon | `#FFFACD` | Moonlight patches |

**Zone 8 — Temple of Patterns (Prealgebra)**
| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#4A4A4A` | Ancient temple stone |
| Secondary | `#2E8B57` | Temple garden vegetation |
| Accent | `#9370DB` | Rune glow, pattern highlights |
| Gold | `#DAA520` | Temple inlay, sacred geometry |
| Light | `#FFFFF0` | Temple interior light |

### 2.2 UI Palette

| Role | Hex | Usage |
|------|-----|-------|
| UI Background | `#1C1C2E` (90% opacity) | Panels, overlays |
| UI Surface | `#2A2A3E` | Cards, input fields |
| UI Primary | `#4CAF50` | Correct, confirm, progress |
| UI Warning | `#FF9800` | Hints, caution |
| UI Error | `#EF5350` | Gentle incorrect (not harsh red) |
| UI Text | `#F5F5F5` | Primary text |
| UI Text Secondary | `#B0B0B0` | Labels, hints |
| UI Accent | `#64B5F6` | Links, interactive elements |
| Whiteboard BG | `#FAFAFA` | Drawing canvas |
| Whiteboard Grid | `#E0E0E0` | Grid lines |

### 2.3 High Contrast Mode

When high contrast is enabled:
- All UI text gets a 2px dark outline
- UI backgrounds become fully opaque
- Interactive elements get bright borders (`#FFFFFF` 2px)
- Parallax background dims by 30%
- Math task areas get a solid dark background

---

## 3. Parallax Layer System

Every region uses a 5-7 layer parallax stack. Layers are rendered back-to-front.

### 3.1 Standard Layer Stack

| Layer | Z-Index | Scroll Scale | Content | Opacity |
|-------|---------|-------------|---------|---------|
| L0 Sky | -100 | 0.0 | Sky gradient, clouds, sun/moon | 100% |
| L1 Far Background | -80 | 0.1 | Distant mountains or canopy silhouettes | 100% |
| L2 Mid Background | -60 | 0.3 | Medium-distance trees, ruins, landmarks | 100% |
| L3 Near Background | -40 | 0.6 | Close vegetation, large trunks | 100% |
| L4 Playfield | 0 | 1.0 | Tilemap, player, interactables, NPCs | 100% |
| L5 Near Foreground | 20 | 1.2 | Foreground leaves, hanging vines | 60-80% |
| L6 Overlay Canopy | 40 | 1.4 | Top canopy fronds, light filter | 40-60% |
| L7 Atmospheric | 60 | 0.5 | Mist, light rays, particles | 30-50% |

### 3.2 Rules

- **L0-L3**: Static or slow-animated (swaying trees). Never obscure gameplay.
- **L4**: The gameplay layer. All interactables, tiles, and the player live here. Must have clear contrast against L3.
- **L5-L6**: Decorative overlays. Must never cover interactive elements. Use transparency and gaps strategically.
- **L7**: Atmospheric effects. Must be subtle. Disable entirely in reduced-motion mode.

### 3.3 Separation Contrast

To ensure Noita-like readability:
- Playfield (L4) objects use **full saturation and value**
- Background layers (L0-L3) are **desaturated by 20-30%** and **darkened by 10-20%**
- Foreground layers (L5-L6) are **lighter** and **more transparent**
- Interactive objects have a **subtle rim light** (Light2D with small radius) or **1px bright outline**
- Player character has a persistent **subtle glow** or **silhouette shader** to always be visible

---

## 4. Lighting

### 4.1 Light2D Usage

| Light Type | Usage | Color | Energy |
|-----------|-------|-------|--------|
| Ambient | Per-region base lighting | Zone-specific warm/cool | 0.6-0.8 |
| God rays | Canopy light shafts | `#FFF8DC` warm yellow | 0.3-0.5 |
| Point lights | Torches, glowing plants, fireflies | Varies by source | 0.4-0.8 |
| Spot light | Temple interiors, focused areas | `#FFFFF0` white-warm | 0.5-0.7 |
| Interactive highlight | Hover/nearby interactive objects | `#FFD700` gold | 0.2-0.3 |

### 4.2 Normal Mapped Sprites

Key environment sprites (tree trunks, stone surfaces, temple walls) use normal maps for depth:
- Generate normal maps from diffuse sprites using standard tools
- Light2D interacts with normal maps to create dynamic shadows as player/camera moves
- Subtle effect — enhances depth without looking 3D

### 4.3 Day/Night Progression

- Zones 1-6: Daytime with varying canopy density (affects light level)
- Zone 7: Night — ambient light is low, bioluminescent plants and fireflies provide light
- Zone 8: Interior temple — torch-lit with dramatic shadows
- No real-time day/night cycle (fixed per zone for consistency)

---

## 5. Particles & Effects

### 5.1 Ambient Particles

| Particle | Zones | Count | Size | Speed | Behavior |
|----------|-------|-------|------|-------|----------|
| Pollen | 1, 3, 4 | 20-40 | 2-4px | Slow drift | Gentle float upward |
| Mist wisps | 2, 5 | 10-20 | 30-60px | Slow drift | Horizontal flow, fade in/out |
| Fireflies | 7 | 15-30 | 3-5px | Random walk | Glow pulse, wander |
| Dust motes | 6, 8 | 10-20 | 1-3px | Slow fall | Drift in light rays |
| Leaf fall | 1, 3 | 5-10 | 8-12px | Tumble down | Sway side to side, rotate |
| Water drops | 2, 5 | 8-15 | 2-3px | Fast fall | Splash on impact |
| Spores | 4 | 5-10 | 4-6px | Slow rise | Drift from mushrooms |
| Embers | 8 | 5-8 | 2-3px | Slow rise | From torches, glow |

### 5.2 Event Particles

| Event | Effect | Duration |
|-------|--------|----------|
| Correct answer | Green sparkle burst + leaf confetti | 1.5s |
| Level up | Golden spiral + growing vine animation | 2s |
| Region restore | Expanding ring of green particles + fog dissolve | 3s |
| Boss defeated | Large bloom of light + wildlife appears | 4s |
| Eco puzzle solve | Localized effect (water flows, bridge grows, tree blooms) | 2-3s |
| Collectible found | Small golden burst + chime | 1s |
| Hint used | Soft blue glow around hint text | 0.5s |

### 5.3 Reduced Motion Mode

When enabled:
- All ambient particles disabled
- Event particles replaced with simple fade/scale animations
- Parallax scroll disabled (static layers)
- Screen shake disabled
- God rays become a static overlay
- Water is still (no animated shader)
- Leaves don't sway

---

## 6. Sprite Art Guidelines

### 6.1 Resolution and Scale

- **Base tile size**: 16x16 pixels
- **Character sprites**: 16x24 pixels (body), multi-frame animations
- **Interactable sprites**: 16x16 to 32x32 pixels
- **Large landmarks**: 64x64 to 128x128 pixels
- **Pixel density**: 1 game pixel = 3-4 screen pixels at 1080p (320x180 base resolution, scaled up)
- **Rendering**: Nearest-neighbor upscaling (crisp pixels, Noita style)

### 6.2 Character Design

**Player character:**
- Small, expressive, readable silhouette
- 4-direction walk cycle (8 frames each)
- Climb animation (4 frames)
- Swing animation (6 frames)
- Interact animation (4 frames)
- Idle animation (4 frames, breathing + look around)
- Cosmetic slots: hat, back item (tool bag), trail effect
- Must read clearly against ALL zone backgrounds (test each zone)

**NPCs (guide creatures):**
- Friendly jungle animals that give quests and hints
- Each zone has a signature guide animal:
  - Zone 1: Curious monkey
  - Zone 2: Wise frog
  - Zone 3: Bright parrot
  - Zone 4: Gentle panda
  - Zone 5: Mountain goat
  - Zone 6: Market gecko
  - Zone 7: Owl
  - Zone 8: Temple snake (friendly)
- 3-4 frame idle animation, 2-frame talk animation

### 6.3 Interactable Sprites

**Visual language for interactivity:**
- Interactive objects are **slightly brighter** and **more saturated** than background
- On player proximity: **subtle bounce/pulse animation** (2-frame, 0.5s cycle)
- Interact prompt: small icon above object (e.g., hand, eye, gear)
- After interaction/collection: visual change (fruit disappears, door opens, bridge appears)

**Consistent styling:**
- Fruit: 8x8 pixels, bright colors, simple shape (mango=yellow drop, coconut=brown circle, berry=red dot)
- Switches/totems: 16x32, carved stone look, glow on activation
- Doors: 32x32, stone with rune markings, slide/fade open
- Bridges: assembled from 16x8 plank segments
- Trees: multi-tile, trunk 16x32 + canopy 32x32

### 6.4 Tile Art

**Ground tiles:**
- 16x16 base, with auto-tile variants (Wang tiles or Godot terrain sets)
- Each zone has: solid ground, platform edges, slopes, special surface (water, sand, stone)
- Seamless tiling required — edges must match in all 4-neighbor configurations
- Add micro-detail (small grass tufts, pebbles, moss patches) via overlay tiles

**Platform tiles:**
- Wooden platforms, stone ledges, bamboo walkways, vine bridges
- Each has: left cap, middle tile, right cap, single-tile variant
- 2px top highlight for clear edge visibility

---

## 7. UI Clarity Rules

### 7.1 Math Task Presentation

When a math task is active, the visual hierarchy is:

1. **Region dims**: Background layers reduce opacity by 40%, desaturate slightly (shader uniform)
2. **Task panel**: Appears center-screen with solid UI background, rounded corners, subtle shadow
3. **Prompt text**: Large, clear font (minimum 18px equivalent), high contrast
4. **Visual representation**: Below or beside prompt, well-spaced, labeled if needed
5. **Input area**: Clear border, blinking cursor, large touch target
6. **Tool access**: Whiteboard button + manipulative tray visible but not intrusive
7. **Hint button**: Bottom corner, small, labeled "Need a hint?"

**Typography in tasks:**
- Numbers: monospace font for alignment
- Text: clean sans-serif (e.g., Nunito, Open Sans)
- Math symbols: properly rendered (÷ not /, × not *, fractions as stacked bars)
- Minimum line height: 1.5x font size

### 7.2 Whiteboard Overlay

- Appears over the dimmed game with a paper-textured background
- Toolbar at top (horizontal) or left side (vertical, user preference)
- Tool buttons: 32x32, clear icons with text labels below
- Drawing canvas: maximum available space, clean white
- Manipulatives: draggable from tray, visually distinct from drawn content
- Grid: light gray lines at regular intervals, toggleable
- Page navigation: bottom of canvas, dot indicators

### 7.3 HUD (During Gameplay)

Minimal HUD that doesn't compete with the jungle:
- **Top-left**: Current region name (small, fades after 3s)
- **Top-right**: Collectible counter (small icons + count)
- **Bottom-left**: Tool quick-access (small icons, expand on hover)
- **Bottom-right**: Menu button, map button, reference button
- **Health/lives**: None (this is learning, not punitive)
- All HUD elements: semi-transparent when player is nearby, fully visible otherwise

### 7.4 Map View

- Full-screen overlay, scrollable/zoomable
- Regions shown as illustrated landmarks (not abstract nodes)
- Completed regions: full color, animated life
- Available regions: muted color, slight glow border
- Locked regions: dark silhouette behind fog
- Path connections: visible vine/bridge/river paths between regions
- Current location: pulsing marker
- Mastery stars per region: 0-3 stars shown on marker

---

## 8. Animation Guidelines

### 8.1 Timing

| Animation Type | Frame Count | Duration | Easing |
|---------------|-------------|----------|--------|
| Walk cycle | 8 per direction | 0.6s loop | Linear |
| Idle breathe | 4 frames | 2s loop | Ease in-out |
| Climb | 4 frames | 0.4s per step | Linear |
| Interact | 4 frames | 0.5s | Ease out |
| Fruit pickup | 3 frames | 0.3s | Ease out |
| Door open | 6 frames | 0.8s | Ease in-out |
| Bridge grow | 12 frames | 2s | Ease out |
| Fog dissolve | shader | 1.5-3s | Ease in-out |
| Leaf sway | 4 frames | 3s loop | Sine wave |
| Water flow | 4 frames | 1s loop | Linear |

### 8.2 Virtual Village Charm

What makes it feel "cozy and alive":
- **Background animals**: Small birds that fly between trees every 10-20s
- **Ambient movement**: All vegetation has a slow 2-4 frame sway loop
- **Smoke/steam**: Small wisps from hidden water sources
- **Critter spawns**: After region restoration, small animals idle in specific spots (frog on lily pad, bird on branch, butterfly on flower)
- **Weather variations**: Light rain in Zone 2, mist in Zone 5, clear starlight in Zone 7
- **Player idle surprise**: After 5s idle, player character does a unique idle animation (looks around, stretches, inspects a leaf)

---

## 9. Shader Reference

### 9.1 Required Shaders

| Shader | Purpose | Key Parameters |
|--------|---------|---------------|
| `fog_of_war.gdshader` | Map fog reveal | `mask_texture`, `dissolve_threshold`, `edge_color` |
| `region_dim.gdshader` | Dim region during tasks | `dim_amount`, `desaturate_amount` |
| `water.gdshader` | Animated water surface | `wave_speed`, `wave_amplitude`, `color_top`, `color_bottom` |
| `god_rays.gdshader` | Volumetric light shafts | `ray_count`, `ray_angle`, `ray_color`, `ray_intensity` |
| `glow_outline.gdshader` | Interactive object highlight | `outline_color`, `outline_width`, `pulse_speed` |
| `color_blind.gdshader` | Color vision simulation | `mode` (0=none, 1=deut, 2=prot, 3=trit) |
| `silhouette.gdshader` | Player visibility in dark zones | `silhouette_color`, `inner_color` |

### 9.2 Fog of War Shader (Pseudocode)

```glsl
shader_type canvas_item;

uniform sampler2D fog_mask;      // R channel: 0=revealed, 1=hidden
uniform float dissolve_edge = 0.05;
uniform vec4 fog_color : source_color = vec4(0.05, 0.1, 0.05, 1.0);
uniform vec4 edge_glow : source_color = vec4(0.3, 1.0, 0.3, 0.5);

void fragment() {
    float mask = texture(fog_mask, UV).r;
    float edge = smoothstep(0.0, dissolve_edge, mask) - smoothstep(dissolve_edge, dissolve_edge * 2.0, mask);

    vec4 scene = texture(TEXTURE, UV);
    COLOR = mix(scene, fog_color, smoothstep(0.0, dissolve_edge, mask));
    COLOR += edge_glow * edge;  // green glow at fog edge
}
```

---

## 10. Audio Direction (Visual-Adjacent)

While not strictly art, audio supports the visual experience:

| Layer | Content | Volume |
|-------|---------|--------|
| Ambient bed | Jungle sounds (birds, insects, water) per zone | 40-60% |
| Music | Gentle, looping, zone-specific (calm exploration) | 30-50% |
| Task mode music | Simplified, focused version of zone music | 20-40% |
| UI sounds | Click, select, correct, incorrect, page turn | 50-70% |
| Event stingers | Level up, region restore, boss victory | 70-80% |
| Environmental | Water flow, bridge creak, door grind | 40-60% |

**Calm mode audio**: Reduces all volumes by 30%, removes sudden stingers, plays only ambient bed.

---

## 11. Asset Checklist (Per Region)

Each region requires these assets at minimum:

- [ ] 4-6 parallax layer images (per zone style)
- [ ] Ground tileset (auto-tile, 16x16)
- [ ] Platform tileset (caps + middle, 16x16)
- [ ] 8+ interactable sprites with idle and activated states
- [ ] 2+ traversal mechanic sprites (vine, ladder, bridge, etc.)
- [ ] 1 eco-puzzle visual set
- [ ] 1 landmark sprite (32x32 to 128x128)
- [ ] Collectible sprites (3-5 per region)
- [ ] Ambient particle configuration
- [ ] Light2D setup (ambient + point lights)
- [ ] Normal maps for key surfaces (optional early, required for polish)
- [ ] Region map marker illustration
- [ ] Fog of war mask texture
- [ ] Restoration effect sprites/particles

---

## 12. Color Blind Safety

All gameplay-critical information must be conveyed through **shape, pattern, or icon** in addition to color:

| Information | Color Encoding | Shape/Icon Backup |
|------------|---------------|-------------------|
| Correct answer | Green | Checkmark icon + upward motion |
| Incorrect answer | Red-orange | X icon + gentle shake |
| Hint available | Blue | Question mark icon |
| Interactive object | Gold highlight | Bounce animation + icon prompt |
| Mastery level | Green gradient | Star count (0-4 stars) |
| Locked region | Dark | Lock icon overlay |
| Collectible rarity | Color tier | Border pattern (plain/wavy/spiked/ornate) |
