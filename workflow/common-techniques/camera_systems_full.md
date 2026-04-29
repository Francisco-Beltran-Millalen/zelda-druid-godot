# 🎥 9. Camera Systems

## 📌 Scope

How the player sees and perceives the world

### Includes:
- Follow cameras  
- Smoothing and damping  
- Camera collision  
- Framing and composition  

---

## 🔍 Typical sub-problems

- Camera clipping through walls  
- Motion sickness  
- Bad framing / losing the player  
- Camera lag or jitter  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

The camera is not passive—it is an active gameplay system

That means:
- It must prioritize clarity over realism  
- It should anticipate player movement  
- It must never fight player control  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild / Tears of the Kingdom | 3D | Z-targeting lock-on, spring arm collision, free orbit camera, context mode switching |
| Metroid Dread | 2D | Fixed-room camera, cinematic zoom transitions, look-ahead offset, boss arena framing |

---

# 🧱 PROBLEM SET

---

# 1. Follow Camera

## 🎯 Goal
Keep the player in view consistently

---

## 🛠️ Techniques

### A. Direct Follow
```pseudo
camera.position = target.position
```

---

### B. Offset Follow
```pseudo
camera.position = target.position + offset
```

---

### C. Spring Follow
```pseudo
velocity += (target.position - camera.position) * stiffness
camera.position += velocity * delta
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Direct | Precise | Jittery |
| Offset | Stable | Static feel |
| Spring | Smooth | Can overshoot |

---

## 💥 Failure Cases

- Camera jitter  
- Overshooting target  
- Losing player during fast motion  

---

## 🔗 Composability Notes

- Base system for all camera behavior  
- Works with:
  - smoothing  
  - collision  
- Needs coordination with:
  - movement system  

---

## 🧩 2D vs 3D

- 2D: simpler tracking  
- 3D: requires rotation and distance control  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link's camera uses spring follow with a "lag zone" — the camera doesn't follow Link immediately but waits until Link exits a dead zone around the camera's current focus point. This prevents constant micro-jitter while Link idles or makes small adjustments. Only when Link moves beyond the dead zone does the spring pull kick in. The dead zone radius is ~0.5 units in world space, invisible to the player but eliminating the fidgety camera feel common in naive follow implementations.

### 🟦 Godot 4.x
**Node/API:** `Camera2D` with `drag_horizontal_enabled`/`drag_vertical_enabled` and margins; `Camera3D` with `SpringArm3D` + `RemoteTransform3D`
```gdscript
# 2D: Camera2D with drag (built-in dead zone)
# Configure in Inspector: drag_horizontal_enabled = true, drag margins = 0.15

# 3D: SpringArm3D-based follow
extends SpringArm3D

@export var follow_speed: float = 8.0

@onready var target: Node3D = get_parent()  # assumes SpringArm is child of character

func _process(delta: float) -> void:
    # SpringArm handles collision automatically
    # This node follows its parent (the character) by being a child
    # Rotate the arm via player camera input; spring_length sets distance
    pass

# Camera is a child of SpringArm3D — it auto-positions at the end of the arm
# and gets pushed forward if the arm intersects geometry
```
**Pitfalls:**
- `Camera2D` drag margins create a dead zone but the camera still moves linearly once the player exits the zone — combine with `position_smoothing_enabled` for natural easing.
- For 3D, placing `Camera3D` as a child of `SpringArm3D` is the recommended pattern — `SpringArm3D` automatically shortens when geometry is between the character and camera, preventing clipping.

---

# 2. Camera Smoothing & Damping

## 🎯 Goal
Reduce jitter and create smooth motion

---

## 🛠️ Techniques

### A. Linear Interpolation
```pseudo
camera.position = lerp(camera.position, target, smooth_factor)
```

---

### B. Exponential Smoothing
```pseudo
camera.position += (target - camera.position) * (1 - exp(-k * delta))
```

---

### C. Critically Damped Spring
```pseudo
apply_spring_damper(camera, target)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Lerp | Simple | Frame-rate dependent |
| Exponential | Stable, frame-rate independent | Less intuitive to tune |
| Spring | Natural (overshoots slightly, then settles) | Needs tuning |

---

## 💥 Failure Cases

- Camera lag  
- Oversmoothing  
- Input feels delayed  

---

## 🔗 Composability Notes

- Must balance:
  - responsiveness  
  - smoothness  
- Interacts with:
  - input feel  
  - game speed  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Camera smoothing uses critically damped spring behavior (the same as Unity's `SmoothDamp`) — it moves quickly at first and decelerates smoothly without overshooting. The key parameter is the "halflife" (time to cover half the remaining distance): ~0.15s for position tracking, ~0.08s for Z-targeting (tighter, more responsive). The spring approach is preferred over linear lerp because it automatically accounts for framerate variance and produces a natural deceleration curve that feels physical rather than digital.

### 🟦 Godot 4.x
**Node/API:** `Camera2D.position_smoothing_enabled` (built-in) or manual exponential smoothing for `Camera3D`
```gdscript
# 2D: Built-in smoothing
# Camera2D: position_smoothing_enabled = true, position_smoothing_speed = 8.0

# 3D: Frame-rate independent exponential smoothing
extends Camera3D

@export var smooth_speed: float = 8.0  # higher = snappier

var _target_position: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
    # Exponential smoothing — frame-rate independent
    global_position = global_position.lerp(
        _target_position,
        1.0 - exp(-smooth_speed * delta)
    )

func set_target(pos: Vector3) -> void:
    _target_position = pos
```
**Pitfalls:**
- `lerp(a, b, factor * delta)` is frame-rate dependent — at 60fps with factor=8, it behaves differently than at 30fps. Use `lerp(a, b, 1.0 - exp(-factor * delta))` for consistent behavior.
- `Camera2D.position_smoothing_speed` is in units/second — too high (>20) makes it nearly instant, too low (<3) creates noticeable lag.

---

# 3. Camera Collision

## 🎯 Goal
Prevent camera from clipping through geometry

---

## 🛠️ Techniques

### A. Raycast Clamp
```pseudo
hit = raycast(target, camera_position)
if hit:
    camera.position = hit.point
```

---

### B. Sphere Cast
```pseudo
hit = shapecast(sphere, target, camera_position)
```

---

### C. Camera Push Forward
```pseudo
if obstacle_detected:
    move_camera_closer()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Raycast | Simple | Can clip edges |
| Sphere Cast | Robust | More expensive |
| Push | Smooth | May distort framing |

---

## 💥 Failure Cases

- Camera pops  
- Sudden zoom changes  
- Losing intended framing  

---

## 🔗 Composability Notes

- Must integrate with:
  - follow system  
- Needs:
  - collision layers  
- Must not break:
  - player visibility  

---

## 🧩 2D vs 3D

- Mostly a 3D problem  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Camera collision uses sphere cast from Link's position to the desired camera position. When the sphere hits geometry, the camera moves to the hit point plus a small margin (preventing Z-fighting with the wall). The transition is immediate (no smoothing on collision push) but the return to the ideal distance when the obstacle is cleared is smoothed over ~0.3s. This asymmetric timing (fast push, slow return) prevents camera "ping-pong" when the player moves near a wall while still feeling responsive when entering confined spaces.

### 🟦 Godot 4.x
**Node/API:** `SpringArm3D` — handles camera collision automatically without any code
```gdscript
# SpringArm3D is the recommended solution for 3D camera collision in Godot 4.
# It automatically performs a sphere cast from its origin to the end point
# and positions child nodes (Camera3D) at the collision point.

# Setup: Character → SpringArm3D → Camera3D
# SpringArm3D.spring_length = desired camera distance
# SpringArm3D.shape = SphereShape3D (radius = 0.3)
# SpringArm3D.collision_mask = terrain layer

# No code needed — SpringArm3D handles everything automatically.
# For return-to-distance smoothing, use SpringArm3D's built-in margin:
extends SpringArm3D

@export var return_speed: float = 3.0
var _target_length: float

func _ready() -> void:
    _target_length = spring_length

func _process(delta: float) -> void:
    # The SpringArm shortens on collision automatically.
    # This moves it back smoothly after obstacle is cleared:
    spring_length = move_toward(spring_length, _target_length, return_speed * delta)
```
**Pitfalls:**
- `SpringArm3D` collision mask must match the terrain/wall collision layers — if it's set to 0, the spring never shortens.
- Add a minimum `spring_length` (e.g., 0.5) so the camera never teleports into the character when fully compressed by geometry.

---

# 4. Camera Framing & Composition

## 🎯 Goal
Keep important elements visible and readable

---

## 🛠️ Techniques

### A. Dead Zone
```pseudo
if target outside zone:
    move_camera()
```

---

### B. Look-ahead Framing
```pseudo
camera.offset = velocity * factor
```

---

### C. Multi-target Framing
```pseudo
center = average(targets)
camera.position = center
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Dead Zone | Stable | Less reactive |
| Look-ahead | Predictive | Can overshoot |
| Multi-target | Good for multiplayer | Hard to tune |

---

## 💥 Failure Cases

- Player near screen edge  
- Camera oscillation  
- Important objects off-screen  

---

## 🔗 Composability Notes

- Works with:
  - navigation  
  - combat systems  
- Must adapt to:
  - gameplay context  

---

## 🧩 2D vs 3D

- 2D: common technique  
- 3D: harder due to perspective  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Room-based camera framing — each room has a fixed camera that shows a defined portion of the room. The camera doesn't follow Samus freely but snaps between pre-authored camera regions as she moves through the level. This is classic 2D Metroid design: the camera composition is intentional (designed to show threats, exits, or atmosphere), not algorithmic. When Samus enters a new region, the camera transitions via a brief pan rather than a cut, maintaining spatial orientation. The lesson: sometimes fixed, authored camera positions are better than algorithmic follow cameras.

### 🟦 Godot 4.x
**Node/API:** `Camera2D` with `drag` margins for look-ahead; multiple `Camera2D` nodes with `make_current()` for room-based cameras
```gdscript
# Look-ahead for 2D follow camera
extends Camera2D

@export var lookahead_factor: float = 0.15
@export var lookahead_speed: float = 5.0

var _target_offset: Vector2 = Vector2.ZERO

func update_lookahead(player_velocity: Vector2, delta: float) -> void:
    var target: Vector2 = player_velocity.normalized() * player_velocity.length() * lookahead_factor
    _target_offset = _target_offset.lerp(target, lookahead_speed * delta)
    offset = _target_offset

# Room-based camera switching (Metroid style):
# Place a Camera2D in each room area
# When player enters area: $RoomCamera.make_current()
```
**Pitfalls:**
- Look-ahead based on velocity direction causes camera oscillation when the player repeatedly reverses direction — add a minimum velocity threshold before applying look-ahead.
- `Camera2D.make_current()` immediately activates the camera — for smooth room transitions, blend between two cameras using `RemoteTransform2D` weight, or tween the position of one camera to the next region.

---

# 5. Camera Modes & Context Switching

## 🎯 Goal
Adapt camera behavior to different situations

---

## 🛠️ Techniques

### A. Mode Switching
```pseudo
if in_combat:
    camera_mode = COMBAT
```

---

### B. Blend Between Modes
```pseudo
camera = blend(mode_a, mode_b, t)
```

---

### C. State-driven Camera
```pseudo
camera.update(state)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Switching | Clear behavior | Abrupt changes |
| Blending | Smooth | Needs tuning |
| State-driven | Flexible | Complex |

---

## 💥 Failure Cases

- Abrupt transitions  
- Conflicting camera logic  
- Player disorientation  

---

## 🔗 Composability Notes

- Driven by:
  - gameplay state  
- Must sync with:
  - animation  
  - input  
- Needs priority system  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Z-targeting is a distinct camera mode — it locks the camera horizontally to keep both Link and the target visible, and overrides all free-orbit controls. The transition into Z-target mode is instant (frame 1), but the orientation settling takes ~0.2s. The target lock camera calculates a point behind Link that keeps the target in the right third of the screen (leading toward the enemy), not simply centered — this is a film composition technique applied to real-time gameplay. Releasing the lock smoothly returns to free orbit over ~0.3s.

### 🟦 Godot 4.x
**Node/API:** Multiple `Camera3D` nodes with `make_current()`, or a single camera with state-driven `Tween` transitions
```gdscript
extends Node3D

@export var free_camera: Camera3D
@export var lock_camera: Camera3D
@export var transition_duration: float = 0.2

var _locked_target: Node3D = null

func enter_z_target(target: Node3D) -> void:
    _locked_target = target
    lock_camera.make_current()

func exit_z_target() -> void:
    _locked_target = null
    free_camera.make_current()

func _process(_delta: float) -> void:
    if _locked_target and lock_camera.current:
        # Keep lock_camera oriented toward a point between player and target
        var midpoint: Vector3 = (get_parent().global_position + _locked_target.global_position) * 0.5
        lock_camera.look_at(midpoint, Vector3.UP)
```
**Pitfalls:**
- `Camera3D.make_current()` cuts immediately — for smooth transitions, use `Tween` to interpolate `global_position` and `global_rotation` of one camera toward the other before switching.
- When switching camera modes, ensure the new camera's collision mask and spring arm settings are appropriate for the mode (Z-target rooms may need shorter spring arm than open world).

---

# 6. Camera Rotation & Control

## 🎯 Goal
Control how the camera rotates around the player

---

## 🛠️ Techniques

### A. Fixed Angle
```pseudo
camera.rotation = fixed_value
```

---

### B. Player-controlled Camera
```pseudo
camera.rotation += input * sensitivity
```

---

### C. Auto-alignment
```pseudo
camera.rotation = lerp(camera.rotation, target_direction)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Fixed | Stable | Limited control |
| Player-controlled | Freedom | Harder to manage |
| Auto-align | Guided | Can fight player |

---

## 💥 Failure Cases

- Camera fighting player input  
- Sudden rotation snaps  
- Disorientation  

---

## 🔗 Composability Notes

- Must integrate with:
  - input system  
- Interacts with:
  - movement direction  
- Needs smoothing  

---

## 🧩 2D vs 3D

- Mostly 3D  
- Rare in 2D  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Free orbit camera rotates via right stick with horizontal inversion option and two vertical auto-behaviors: (1) gentle auto-correct toward horizontal when Link stands still for >3s (prevents a permanently tilted camera from forgetting), (2) mild forward-lean auto-alignment when Link sprints (camera moves slightly behind). Both auto-behaviors are defeated immediately if the player touches the right stick — player input always has absolute priority. The sensitivity scales with stick deflection (non-linear curve) giving precise control at low deflection and fast sweep at full deflection.

### 🟦 Godot 4.x
**Node/API:** Rotate `SpringArm3D` via camera input — store yaw and pitch separately
```gdscript
extends Node3D  # This node is the camera pivot, parent of SpringArm3D

@export var horizontal_sensitivity: float = 0.005
@export var vertical_sensitivity: float = 0.004
@export var min_pitch_degrees: float = -60.0
@export var max_pitch_degrees: float = 30.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

var _yaw: float = 0.0
var _pitch: float = 0.0

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _yaw -= event.relative.x * horizontal_sensitivity
        _pitch = clamp(_pitch - event.relative.y * vertical_sensitivity,
                       deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
        rotation = Vector3(_pitch, _yaw, 0.0)

func apply_gamepad_camera(cam_input: Vector2, delta: float) -> void:
    _yaw -= cam_input.x * horizontal_sensitivity * delta * 60.0
    _pitch = clamp(_pitch - cam_input.y * vertical_sensitivity * delta * 60.0,
                   deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
    rotation = Vector3(_pitch, _yaw, 0.0)
```
**Pitfalls:**
- Store yaw and pitch as separate floats and apply them as `Vector3(_pitch, _yaw, 0.0)` — using `rotate_y()` and `rotate_x()` in sequence produces gimbal lock at extreme pitch angles.
- Mouse input uses `event.relative` (pixels moved), while gamepad input uses analog axis values — they need different sensitivity multipliers. Expose both as `@export var` for easy tuning.

---

# 7. Camera Jitter & Stability Fixes

## 🎯 Goal
Eliminate visual instability

---

## 🛠️ Techniques

### A. Fixed Update Sync
```pseudo
update_camera_after_physics()
```

---

### B. Position Interpolation
```pseudo
camera.position = interpolate(previous, current)
```

---

### C. Velocity Compensation
```pseudo
camera += target.velocity * delta
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Fixed Sync | Stable | Less flexible |
| Interpolation | Smooth | Adds delay |
| Compensation | Predictive | Can overshoot |

---

## 💥 Failure Cases

- Micro jitter  
- Camera lag  
- Desync with movement  

---

## 🔗 Composability Notes

- Must align with:
  - physics timestep  
  - rendering update  
- Critical for:
  - fast-paced games  

---

## 🧩 2D vs 3D

- Same issue  

---

### 🎮 Nintendo Reference
**Zelda BotW:** The game runs physics at 30Hz and rendering at 60fps. Camera position is interpolated between physics states for the rendering frames, so the camera never jitters at sub-physics step resolution. This interpolation is the primary jitter fix — without it, the camera would visibly "step" at 30Hz even while rendering at 60fps. The camera updates in the "post-physics" step of the game loop (after all entity positions are settled for the frame) to ensure the character is already at its final position before the camera follows.

### 🟦 Godot 4.x
**Node/API:** Camera updates in `_process` (not `_physics_process`); enable `physics/common/physics_interpolation`
```gdscript
extends Camera3D

# KEY RULE: Camera position logic goes in _process(), not _physics_process().
# _process() runs every render frame; _physics_process() runs at fixed physics rate.
# Updating the camera in _process() with a smoothed target produces the best result.

@onready var follow_target: Node3D = get_parent()

@export var smooth_speed: float = 10.0

func _process(delta: float) -> void:
    # Camera follows target smoothly in render loop, not physics loop
    global_position = global_position.lerp(
        follow_target.global_position + Vector3(0.0, 2.0, 5.0),
        1.0 - exp(-smooth_speed * delta)
    )
```
**Pitfalls:**
- Updating `Camera3D.global_position` in `_physics_process` causes jitter at high frame rates because physics ticks at a fixed rate (e.g., 60Hz) but rendering may run at 144Hz — the camera position only updates at physics rate and renders at render rate.
- Enable `physics/common/physics_interpolation` in Project Settings (Godot 4.3+) for automatic interpolation of all physics-driven nodes; this prevents the 30Hz physics / 60fps render jitter automatically.

---

# 🧠 FINAL INSIGHT

The camera is a perception pipeline:

Target → Framing → Smoothing → Collision → Final View

Most bugs come from:
- Camera reacting too late or too aggressively  
- Systems fighting each other (input vs auto-align)  
- Poor prioritization of player visibility  
- Treating camera as passive instead of active  
