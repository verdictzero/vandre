# Flatland Walker - Claude Code Implementation Plan

## Project Overview

**Goal:** Build a lightweight 2.5D infinite walking simulator in Godot 4.5, targeting Pi Zero 2 W performance.

**Core Features:**
- Infinite flat terrain with chunk-based streaming
- Y-axis billboard sprites for vegetation/objects
- Concentric background rings (trees, hills, mountains)
- Layered scrolling clouds
- Fog blending foreground into background
- Fake day/night cycle via color grading
- Completely unlit rendering pipeline

---

## Phase 1: Project Foundation

### Task 1.1: Create Project Structure

Create the Godot 4.5 project with optimized settings for Pi Zero 2 W.

**Files to create:**
- `project.godot` - Configure for Compatibility renderer, disable all expensive features
- `default_env.tres` - Minimal environment with fog settings

**Project settings to configure:**
- Renderer: Compatibility (OpenGL ES 3.0)
- Disable: SDFGI, SSAO, SSR, glow, volumetric fog
- Physics: Disable 3D physics entirely if possible
- Display: 640x480 or 800x600 default resolution
- Vsync: Enabled, target 30 FPS

**Global shader uniforms to register:**
- `sky_color_top` (Color)
- `sky_color_horizon` (Color)
- `fog_color` (Color)
- `ambient_tint` (Color)
- `time_of_day` (float)

---

### Task 1.2: Create Core Shaders

**File:** `shaders/unlit_terrain.gdshader`
- Spatial shader, render_mode unshaded
- Sample albedo texture
- Apply ambient_tint global uniform
- Apply distance fog using fog_color global uniform
- Fog should start at ~60 units, fully fogged at ~96 units

**File:** `shaders/billboard_y.gdshader`
- Spatial shader, render_mode unshaded, cull_disabled
- Y-axis billboard rotation in vertex shader (rotate to face camera, Y-axis only)
- Alpha cutoff at 0.5 for transparency
- Apply ambient_tint global uniform
- Apply distance fog matching terrain shader

**File:** `shaders/background_ring.gdshader`
- Spatial shader, render_mode unshaded, cull_disabled
- UV scrolling for optional horizontal animation
- Pre-baked fog amount uniform (0.0-1.0)
- Apply ambient_tint global uniform
- Blend with fog_color based on fog amount

**File:** `shaders/sky_gradient.gdshader`
- Spatial shader, render_mode unshaded, cull_front, depth_draw_never
- Gradient from sky_color_horizon (bottom) to sky_color_top (top)
- No fog application

**File:** `shaders/clouds.gdshader`
- Spatial shader, render_mode unshaded, blend_mix, depth_draw_never
- UV scrolling with scroll_speed uniform
- Opacity uniform for layer depth
- Tint clouds with sky_color_horizon

---

### Task 1.3: Create Placeholder Textures

Generate simple placeholder textures for initial testing. These should be small (64x64 or 128x128) PNG files.

**Files to create:**
- `assets/textures/terrain/grass_placeholder.png` - Simple green/brown grass pattern
- `assets/textures/sprites/tree_placeholder.png` - Simple tree silhouette with transparency
- `assets/textures/sprites/bush_placeholder.png` - Bush silhouette with transparency
- `assets/textures/backgrounds/treeline_placeholder.png` - Horizontal treeline silhouette (seamless)
- `assets/textures/backgrounds/hills_placeholder.png` - Rolling hills silhouette (seamless)
- `assets/textures/backgrounds/mountains_placeholder.png` - Mountain range silhouette (seamless)
- `assets/textures/sky/clouds_placeholder.png` - Soft cloud shapes with transparency (seamless horizontal)

---

## Phase 2: Player Controller

### Task 2.1: Create Player Scene

**File:** `scenes/player/player.tscn`
- Root: CharacterBody3D (or Node3D if no physics needed)
- Child: Camera3D at eye height (~1.7 units)
- No collision shape initially (add later if needed)

**File:** `scripts/player/player_controller.gd`

**Functionality:**
- Simple first-person movement (WASD or arrow keys)
- Mouse look (horizontal and vertical with clamping)
- Fixed Y position (always at ground level + eye height)
- Movement speed: ~5 units/second
- No jumping, no gravity calculations
- Expose movement_speed and mouse_sensitivity as exports

**Input actions to define in project.godot:**
- move_forward, move_backward, move_left, move_right
- Optional: toggle_run for faster movement

---

## Phase 3: Chunk System

### Task 3.1: Create Terrain Chunk

**File:** `scenes/world/chunk.tscn`
- Root: Node3D named "Chunk"
- Child: MeshInstance3D for terrain plane
- Plane mesh: 64x64 units, 1 segment (just a quad)
- Material: ShaderMaterial using unlit_terrain.gdshader

**File:** `scripts/world/chunk.gd`

**Functionality:**
- `chunk_coord: Vector2i` - Grid coordinate of this chunk
- `initialize(coord: Vector2i)` - Set position, seed RNG, spawn vegetation
- `activate()` - Show and enable processing
- `deactivate()` - Hide and disable processing, clear vegetation
- Uses chunk_coord for deterministic random seed

---

### Task 3.2: Create Vegetation Spawner

**File:** `scripts/world/vegetation_spawner.gd`

**Functionality:**
- Static/autoload class for spawning vegetation in chunks
- `spawn_vegetation(chunk: Node3D, coord: Vector2i, count: int)`
- Use seeded RandomNumberGenerator based on chunk coord
- Spawn billboard sprites at random positions within chunk bounds
- Return array of spawned nodes for later cleanup
- Vegetation types: trees (sparse), bushes (medium), grass tufts (dense)

---

### Task 3.3: Create Chunk Manager

**File:** `scenes/world/chunk_manager.tscn`
- Root: Node3D named "ChunkManager"
- Will dynamically create/manage chunk instances

**File:** `scripts/world/chunk_manager.gd`

**Functionality:**
- `CHUNK_SIZE = 64.0` constant
- `VIEW_DISTANCE = 1` (3x3 grid = 9 chunks)
- `chunk_pool: Array[Node3D]` - Pool of reusable chunk instances
- `active_chunks: Dictionary` - Maps Vector2i coord to chunk node
- Track player reference
- Each frame: calculate player's current chunk coord
- When player chunk changes: update_chunks()
- `update_chunks()`: determine needed coords, deactivate old chunks (return to pool), activate new chunks (from pool or create)
- `world_to_chunk(pos: Vector3) -> Vector2i` helper function
- `get_or_create_chunk() -> Node3D` helper function

---

### Task 3.4: Create Billboard Sprite Scene

**File:** `scenes/world/billboard_sprite.tscn`
- Root: MeshInstance3D
- QuadMesh facing +Z, size 2x2 (adjustable)
- ShaderMaterial using billboard_y.gdshader
- Texture uniform exposed

**File:** `scripts/world/billboard_sprite.gd` (minimal)
- Export texture variable to set sprite appearance
- Export scale variable for size variation

---

## Phase 4: Background Environment

### Task 4.1: Create Sky Dome

**File:** `scenes/environment/sky_dome.tscn`
- Root: MeshInstance3D
- Sphere or hemisphere mesh, large radius (500+ units)
- Normals inverted (or use cull_front in shader)
- ShaderMaterial using sky_gradient.gdshader

---

### Task 4.2: Create Background Ring Component

**File:** `scenes/environment/background_ring.tscn`
- Root: MeshInstance3D named "BackgroundRing"
- Cylinder mesh, open top/bottom, normals facing inward
- ShaderMaterial using background_ring.gdshader
- Configurable radius, height, texture, fog_amount, scroll_speed

**File:** `scripts/environment/background_ring.gd`

**Exports:**
- radius: float
- height: float
- texture: Texture2D
- fog_amount: float (0.0-1.0)
- scroll_speed: float (0.0 for static)
- y_offset: float (vertical position)

**_ready():**
- Generate cylinder mesh procedurally OR use pre-made mesh
- Apply material with exported parameters

---

### Task 4.3: Create Background Rings Container

**File:** `scenes/environment/background_rings.tscn`
- Root: Node3D named "BackgroundRings"
- Children: Multiple BackgroundRing instances configured as:

| Ring | Radius | Height | Fog Amount | Y Offset | Texture |
|------|--------|--------|------------|----------|---------|
| Vegetation | 100 | 15 | 0.3 | 0 | treeline |
| Hills | 180 | 30 | 0.5 | -5 | hills |
| Mountains | 350 | 80 | 0.7 | -10 | mountains |

- This entire node parents to player (moves with player)

---

### Task 4.4: Create Cloud Layers

**File:** `scenes/environment/cloud_layers.tscn`
- Root: Node3D named "CloudLayers"
- Children: 3 BackgroundRing instances configured for clouds:

| Layer | Radius | Height | Y Offset | Scroll Speed | Opacity |
|-------|--------|--------|----------|--------------|---------|
| Low | 400 | 40 | 50 | 0.02 | 0.6 |
| Mid | 450 | 50 | 80 | 0.01 | 0.4 |
| High | 500 | 60 | 120 | 0.005 | 0.3 |

- Uses clouds.gdshader instead of background_ring.gdshader
- Parents to player (moves with player)

---

## Phase 5: Day/Night Cycle

### Task 5.1: Create Day/Night Controller

**File:** `scenes/environment/day_night_controller.tscn`
- Root: Node named "DayNightController"

**File:** `scripts/environment/day_night_controller.gd`

**Exports:**
- day_length_seconds: float = 600.0 (10 min full cycle)
- starting_hour: float = 8.0
- paused: bool = false

**Properties:**
- current_time: float (0.0-24.0)

**Color data structure:**
Define colors for key times of day (5:00, 8:00, 12:00, 18:00, 21:00):
- sky_color_top
- sky_color_horizon
- fog_color
- ambient_tint

**_process(delta):**
- Advance current_time based on day_length_seconds
- Wrap at 24.0
- Interpolate colors between time keyframes (use smoothstep)
- Set global shader uniforms via RenderingServer.global_shader_parameter_set()

**Helper functions:**
- `get_interpolated_colors(time: float) -> Dictionary`
- `set_time(hour: float)` - Jump to specific time
- `get_time_string() -> String` - Format as "HH:MM" for debug

---

## Phase 6: Main Scene Assembly

### Task 6.1: Create Main Scene

**File:** `scenes/main.tscn`

**Structure:**
```
Main (Node3D)
├── Player (instance of player.tscn)
│   ├── Camera3D
│   ├── BackgroundRings (instance, moves with player)
│   ├── CloudLayers (instance, moves with player)
│   └── SkyDome (instance, moves with player)
├── ChunkManager (instance of chunk_manager.tscn)
├── DayNightController (instance)
└── UI (CanvasLayer)
    └── DebugLabel (Label) - optional, shows FPS/time/chunk
```

**File:** `scripts/main.gd`

**Functionality:**
- Get references to Player and ChunkManager
- Pass player reference to ChunkManager on ready
- Optional: debug UI showing FPS, current time, player chunk coord

---

## Phase 7: Polish and Optimization

### Task 7.1: Implement MultiMesh for Vegetation

Optimize vegetation rendering by batching identical sprites.

**Modify:** `scripts/world/chunk.gd`
- Instead of individual billboard nodes, use MultiMeshInstance3D
- One MultiMesh per vegetation type per chunk
- Significantly reduces draw calls

---

### Task 7.2: Add Distance-Based Vegetation LOD

**Modify:** `scripts/world/chunk.gd` or create `scripts/world/vegetation_lod.gd`

**Functionality:**
- Track distance from player to chunk center
- At far distance: reduce visible vegetation count
- At very far distance: hide small vegetation (grass), show only trees
- Smooth fade using alpha or scale

---

### Task 7.3: Create Debug/Testing Tools

**File:** `scripts/debug/debug_overlay.gd`

**Functionality:**
- Toggle with F3 or backtick key
- Display: FPS, chunk coord, time of day, memory usage
- Buttons/keys to: skip time forward, change weather (future), teleport

---

## Phase 8: Weather System (Future)

### Task 8.1: Create Weather Controller

**File:** `scripts/environment/weather_controller.gd`

**Weather states:** CLEAR, OVERCAST, FOG, RAIN

**Each state modifies:**
- Fog density (adjust fog start/end distances)
- Cloud opacity
- Ambient tint darkness
- Optional rain layer

---

### Task 8.2: Create Rain Effect Layer

**File:** `scenes/environment/rain_layer.tscn`

- Cylinder with downward-scrolling rain texture
- Very fast UV scroll
- Semi-transparent
- Only visible during RAIN weather

---

## Implementation Order Summary

Execute tasks in this order for incremental, testable progress:

1. **Phase 1.1** - Project structure and settings
2. **Phase 1.2** - Core shaders
3. **Phase 1.3** - Placeholder textures
4. **Phase 2.1** - Player controller (test: can walk around infinite flat plane)
5. **Phase 3.4** - Billboard sprite scene
6. **Phase 3.1** - Single terrain chunk
7. **Phase 3.2** - Vegetation spawner
8. **Phase 3.3** - Chunk manager (test: infinite terrain works)
9. **Phase 4.1** - Sky dome
10. **Phase 5.1** - Day/night controller (test: sky color changes)
11. **Phase 4.2** - Background ring component
12. **Phase 4.3** - All background rings (test: layered environment visible)
13. **Phase 4.4** - Cloud layers (test: clouds scroll)
14. **Phase 6.1** - Main scene assembly
15. **Phase 7.1** - MultiMesh optimization
16. **Phase 7.2** - Vegetation LOD
17. **Phase 7.3** - Debug tools
18. **Phase 8** - Weather (optional/future)

---

## Testing Checkpoints

After each phase, verify:

| Phase | Test |
|-------|------|
| 2 | Player can move and look around on a static plane |
| 3 | Walking generates/destroys chunks seamlessly, vegetation appears |
| 4 | Background rings visible, create depth illusion |
| 5 | Sky and fog colors shift over time |
| 6 | Full scene runs at 30+ FPS on Pi 5 |
| 7 | Optimizations improve performance, ready for Pi Zero 2 W test |

---

## Technical Reference

### Shader Code Snippets

#### Y-Axis Billboard (vertex shader)
```glsl
void vertex() {
    vec3 cam_pos = (inverse(VIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz;
    vec3 to_cam = cam_pos - MODEL_MATRIX[3].xyz;
    to_cam.y = 0.0;
    to_cam = normalize(to_cam);
    
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = cross(up, to_cam);
    
    VERTEX = right * VERTEX.x + up * VERTEX.y + to_cam * VERTEX.z;
}
```

#### Distance Fog (fragment shader)
```glsl
float fog_start = 60.0;
float fog_end = 96.0;
float depth = length(VERTEX);
float fog_factor = smoothstep(fog_start, fog_end, depth);
ALBEDO = mix(ALBEDO, fog_color, fog_factor);
```

#### UV Scrolling (fragment shader)
```glsl
vec2 uv = UV;
uv.x += TIME * scroll_speed;
vec4 col = texture(albedo, uv);
```

---

### Performance Budget

| Resource | Budget |
|----------|--------|
| Draw calls | < 50 |
| Triangles | < 10,000 |
| Textures in VRAM | < 16 MB |
| RAM usage | < 256 MB |
| Target FPS | 30 stable |

---

### Chunk System Diagram

```
Chunk Grid (player at center, 3x3 active):

┌───────┬───────┬───────┐
│ -1,-1 │  0,-1 │  1,-1 │
├───────┼───────┼───────┤
│ -1, 0 │ [P]   │  1, 0 │  [P] = Player's chunk
├───────┼───────┼───────┤
│ -1, 1 │  0, 1 │  1, 1 │
└───────┴───────┴───────┘

Each chunk = 64x64 units
Total active area = 192x192 units
```

---

### Background Layer Stack (side view)

```
                Height
                  │
           120u   │  ════════════════════  High clouds
            80u   │  ════════════════════  Mid clouds  
            50u   │  ════════════════════  Low clouds
                  │
            40u   │  ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲  Mountains (fog: 0.7)
            20u   │  ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿  Hills (fog: 0.5)
            10u   │  🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲  Treeline (fog: 0.3)
             0u   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  Terrain chunks
                  └────────────────────────────► Radius
                      100   180   350   500
```

---

## Notes for Implementation

- **Always test on Pi 5 first**, then verify on Pi Zero 2 W
- **Keep textures small** - 64x64 to 256x256 max
- **Use shared materials** - never duplicate materials per instance
- **Profile regularly** - use Godot's built-in profiler and monitor
- **Chunk transitions must be seamless** - no popping or visible loading
- **Fog is critical** - it hides the draw distance limit, tune carefully
- **Background rings parent to player** - they move with the player to maintain illusion
- **Deterministic spawning** - use chunk coordinates as seeds for reproducible worlds
