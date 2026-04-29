# 🧱 1. Movement & Locomotion

## 📌 Scope

Anything related to how entities move through space.

### Includes:
- Walking, running, jumping  
- Stairs, slopes, ledges  
- Air control  
- Acceleration / deceleration  
- Root motion vs code-driven motion  

---

## ❗ Why it's its own category

Movement is not physics—it's player-facing behavior design.  
You are not simulating reality; you are designing control + feel.

---

## 🔍 Typical sub-problems

- Stair stepping  
- Slope handling  
- Momentum vs responsiveness  
- Ground detection  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Movement systems are usually kinematic + assisted by queries.

That means:
- You decide the velocity  
- You query the world  
- You adjust the result  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild / Tears of the Kingdom | 3D | Slope handling, stair stepping, momentum, moving platforms |
| Metroid Dread | 2D | Ground detection, jumping, air control, wall sliding, coyote time |

---

# 🧱 PROBLEM SET

---

# 1. Ground Detection

## 🎯 Goal
Determine if the character is "grounded" and what the ground is.

---

## 🛠️ Techniques

### A. Single Raycast
```pseudo
is_grounded = raycast(origin, down, distance)
ground_normal = hit.normal
```

### B. Multi-ray / Foot Probes
```pseudo
hits = [
  raycast(left_foot),
  raycast(center),
  raycast(right_foot)
]
is_grounded = any(hits)
```

### C. Shape Cast (Capsule / Box)
```pseudo
is_grounded = shapecast(collider, down)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Single Ray | Fast, simple | Fails on edges |
| Multi-ray | More stable | More complexity |
| Shape Cast | Most accurate | Expensive |

---

## 💥 Failure Cases

- Edge of platform → ray misses → "fake falling"  
- Fast movement → ground skipped  
- Uneven terrain → jittering normals  

---

## 🔗 Composability Notes

- Combine with slope handling (uses ground normal)  
- Combine with coyote time for better feel  
- Must run before movement resolution  

---

## 🧩 2D vs 3D

- 2D: Usually 1–3 rays downward  
- 3D: Capsule or multi-ray is strongly preferred  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus uses multi-point ground detection to feed precise normals into her landing pose system. The ground state is sampled every frame with near-zero tolerance — there is no "grace window" for grounding itself; that forgiveness is handled separately via coyote time (~5–6 frames), keeping detection and forgiveness concerns cleanly separated.  
**Zelda BotW:** Link's ground probes detect slope angle independently of movement blocking — slopes below ~45° feed into normal movement, slopes above that silently switch to the climbing state. The probe is a capsule cast centered on the character's base, not a single foot ray, which prevents edge-wobble on uneven terrain.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody2D` / `CharacterBody3D` — `is_on_floor()`, `get_floor_normal()`, `floor_snap_length`
```gdscript
extends CharacterBody3D

@export var gravity: float = 30.0
@export var floor_snap: float = 0.3

func _physics_process(delta: float) -> void:
    floor_snap_length = floor_snap
    if not is_on_floor():
        velocity.y -= gravity * delta
    move_and_slide()
    var ground_normal: Vector3 = get_floor_normal()
    # ground_normal is Vector3.UP when flat, tilted on slopes
```
**Pitfalls:**
- `is_on_floor()` returns stale data until after `move_and_slide()` — always call move first.
- `floor_snap_length` only applies when moving downward; set it to 0 when jumping or it will suppress the launch.

---

# 2. Stair Stepping

## 🎯 Goal
Allow smooth traversal over small vertical obstacles

---

## 🛠️ Techniques

### A. Step Offset (Lift + Forward)
```pseudo
if collide_forward():
    if obstacle_height < step_height:
        position.y += step_height
        move_forward()
```

---

### B. Invisible Ramp Approximation
- Replace stairs with slope collider

---

### C. Raycast Snap to Ground
```pseudo
target_y = raycast(down)
position.y = lerp(position.y, target_y, snap_speed)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Step Offset | Accurate | Complex, edge cases |
| Ramp | Stable, cheap | Not physically correct |
| Snap | Smooth | Can feel floaty |

---

## 💥 Failure Cases

- Step too high → character "blocks"  
- Rapid step sequences → jitter  
- Snap → causes foot sliding illusion  
- Offset → can clip into ceilings  

---

## 🔗 Composability Notes

- Must integrate with collision resolution  
- Strong interaction with ground detection  
- Often combined with slope logic  
- Snap + gravity can conflict (fighting forces)  

---

## 🧩 2D vs 3D

- 2D: Often unnecessary (tilemaps handle it)  
- 3D: Critical problem (stairs are everywhere)  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link never visibly "steps" over individual stairs — stairs in the game world use invisible ramp geometry rather than discrete steps. This sidesteps the step-offset problem entirely: the visual stairs are decorative meshes, while the collision shape is a single smooth incline. When a true step is unavoidable (dungeon puzzles), the game uses a height-snap approach combined with a short animation.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D.move_and_slide()` with `floor_max_angle` and `max_slides`
```gdscript
extends CharacterBody3D

@export var step_height: float = 0.35  # max stair height to auto-step
@export var floor_max_angle_deg: float = 45.0

func _ready() -> void:
    floor_max_angle = deg_to_rad(floor_max_angle_deg)

func _physics_process(delta: float) -> void:
    move_and_slide()
    # Godot's CharacterBody3D handles step-up automatically via
    # floor_max_angle + internal sweep; no manual lift needed for small steps.
    # For taller steps, use a downward raycast after forward movement and
    # teleport up if obstacle_height < step_height.
```
**Pitfalls:**
- `move_and_slide()` handles small steps automatically on `CharacterBody3D`; implementing manual step logic on top often causes double-stepping.
- Invisible ramp colliders (simple `ConvexPolygonShape3D`) are often the right solution over complex step logic.

---

# 3. Slope Handling

## 🎯 Goal
Move smoothly across inclined surfaces

---

## 🛠️ Techniques

### A. Velocity Projection
```pseudo
velocity = project_on_plane(velocity, ground_normal)
```

---

### B. Max Slope Angle Clamp
```pseudo
if angle_between(normal, up) > max_slope:
    block_or_slide()
```

---

### C. Stick-to-Ground Force
```pseudo
velocity += ground_normal * stick_force
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Projection | Natural | Depends on stable normals |
| Angle Clamp | Simple | Hard cutoff, feels artificial |
| Stick Force | Prevents bouncing | Can feel "magnetic" |

---

## 💥 Failure Cases

- Crest of slope → character becomes airborne  
- Sharp edges → unstable normals  
- Downhill acceleration bugs  

---

## 🔗 Composability Notes

- Requires ground detection normals  
- Conflicts with jump logic if not gated  
- Works with friction / acceleration tuning  

---

## 🧩 2D vs 3D

- 2D: Usually angle-based logic  
- 3D: Requires vector projection  

---

### 🎮 Nintendo Reference
**Zelda BotW/TotK:** Slopes up to ~45° are walkable with full speed; above that, movement slows and eventually triggers climbing mode. The transition uses ground normal angle, not geometry tags — any surface with the right normal just works. This means the entire overworld works without any hand-authored "this is a slope" markers, which is a key lesson: derive walkability from physics normals, not from level metadata.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D.floor_max_angle`, `up_direction`, `velocity.slide()`
```gdscript
extends CharacterBody3D

@export var max_slope_degrees: float = 45.0

func _ready() -> void:
    floor_max_angle = deg_to_rad(max_slope_degrees)
    up_direction = Vector3.UP

func _physics_process(delta: float) -> void:
    if is_on_floor():
        # Project velocity onto the slope plane to prevent downhill acceleration
        var floor_normal: Vector3 = get_floor_normal()
        velocity = velocity.slide(floor_normal)  # removes component into floor
    move_and_slide()
```
**Pitfalls:**
- Setting `floor_max_angle` too high causes the character to "walk" up near-vertical walls — test with geometry at 50°, 60°, 80°.
- `floor_snap_length` must be set so the character stays grounded on the downward side of slopes; without it, the character briefly becomes airborne at the top.

---

# 4. Jumping & Gravity

## 🎯 Goal
Control vertical movement and responsiveness

---

## 🛠️ Techniques

### A. Basic Gravity
```pseudo
velocity.y -= gravity * delta
```

---

### B. Coyote Time
```pseudo
if time_since_ground < threshold:
    allow_jump()
```

---

### C. Jump Buffering
```pseudo
if jump_pressed_recently:
    queue_jump()
```

---

### D. Variable Jump Height
```pseudo
if jump_released_early:
    velocity.y *= 0.5
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Gravity | Simple | Feels stiff alone |
| Coyote | Forgiving | Less realistic |
| Buffer | Responsive | Hidden complexity |
| Variable Jump | Expressive | Needs tuning |

---

## 💥 Failure Cases

- Double jump bugs from bad state tracking  
- Jump during slope transitions  
- Gravity fighting ground snapping  

---

## 🔗 Composability Notes

- Strong interaction with ground detection  
- Must override stick-to-ground forces  
- Buffer + coyote together = best feel combo  

---

## 🧩 2D vs 3D

- Same concepts  
- 3D adds directional jump influence  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus has heavier gravity on descent than ascent — the downward gravity multiplier (~2×) creates a punchy, deliberate jump arc. Variable jump height is implemented via early-release dampening: releasing the button early multiplies upward velocity by ~0.5. Coyote time is ~5 frames (0.083s at 60fps) and jump buffer is ~8 frames. These exact values contribute to Dread's reputation for tight, precise platforming.  
**Zelda BotW:** Link's jump is a short burst with a flat arc — gravity is moderate and consistent. There is no variable jump height; jumps feel predictable. This deliberate design choice makes traversal feel stable in a large 3D world where the player needs to judge jump distances reliably.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody2D` / `CharacterBody3D`, `Engine.time_scale` not needed — use gravity multipliers
```gdscript
extends CharacterBody2D

@export var jump_speed: float = 500.0
@export var gravity_up: float = 1200.0
@export var gravity_down: float = 2400.0  # heavier fall
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var variable_jump_dampen: float = 0.5

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

func _physics_process(delta: float) -> void:
    if is_on_floor():
        _coyote_timer = coyote_time
    else:
        _coyote_timer -= delta
        var g: float = gravity_down if velocity.y > 0.0 else gravity_up
        velocity.y += g * delta

    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = jump_buffer_time
    else:
        _jump_buffer_timer -= delta

    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        velocity.y = -jump_speed
        _coyote_timer = 0.0
        _jump_buffer_timer = 0.0

    if Input.is_action_just_released("jump") and velocity.y < 0.0:
        velocity.y *= variable_jump_dampen

    move_and_slide()
```
**Pitfalls:**
- In Godot 2D, `y` is positive downward; jump velocity is negative. Confusing sign conventions are the #1 source of gravity bugs.
- Never use `Engine.time_scale` for variable jump — it affects the entire game. Use per-character gravity multipliers instead.

---

# 5. Air Control

## 🎯 Goal
Control movement while airborne

---

## 🛠️ Techniques

### A. Reduced Acceleration
```pseudo
velocity += input * air_control_factor
```

---

### B. Directional Influence Clamp
```pseudo
velocity = clamp_direction_change(velocity, max_angle)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Reduced Control | Predictable | Can feel stiff |
| Full Control | Responsive | Unrealistic |

---

## 💥 Failure Cases

- Mid-air direction snapping  
- Overpowered air strafing  

---

## 🔗 Composability Notes

- Uses same system as ground movement  
- Must ignore friction models  
- Interacts with jump arcs  

---

## 🧩 2D vs 3D

- 2D: Horizontal only  
- 3D: Full vector control  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus has meaningful air control — she can reach full horizontal speed mid-air but with ~60% of the ground acceleration rate. Critically, she preserves momentum from the last ground direction during the first few frames of the jump, giving a "committed" feel to directional jumps. Wall jumping fully resets her air control state, enabling advanced traversal patterns like wall-kick chains.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody2D` / `CharacterBody3D` — separate acceleration constants for ground vs air
```gdscript
extends CharacterBody2D

@export var max_speed: float = 300.0
@export var ground_accel: float = 2000.0
@export var air_accel: float = 1200.0   # 60% of ground
@export var air_friction: float = 0.0   # no friction in air

func _physics_process(delta: float) -> void:
    var input_dir: float = Input.get_axis("move_left", "move_right")
    var accel: float = ground_accel if is_on_floor() else air_accel
    var target_x: float = input_dir * max_speed

    if input_dir != 0.0:
        velocity.x = move_toward(velocity.x, target_x, accel * delta)
    elif is_on_floor():
        velocity.x = move_toward(velocity.x, 0.0, ground_accel * delta)
    # In air: no friction — momentum is preserved

    move_and_slide()
```
**Pitfalls:**
- Adding friction in the air is the most common cause of "floaty" feeling — when the player releases the stick mid-air and the character decelerates, it undermines jump momentum.
- Applying the full `ground_accel` in air makes the character feel like it's running on air; reduce it to 40–70% of ground.

---

# 6. Wall Sliding & Collision Response (Movement-side)

## 🎯 Goal
Prevent hard stops when hitting walls

---

## 🛠️ Techniques

### A. Slide Along Surface
```pseudo
velocity = project_on_plane(velocity, wall_normal)
```

---

### B. Cancel Into Wall
```pseudo
velocity = remove_component(velocity, wall_normal)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Sliding | Smooth | Can feel slippery |
| Cancel | Precise | Feels rigid |

---

## 💥 Failure Cases

- Corner trapping  
- Oscillation between surfaces  
- Loss of control in tight spaces  

---

## 🔗 Composability Notes

- Depends on collision detection normals  
- Must run after movement intent  
- Interacts with step offset logic  

---

## 🧩 2D vs 3D

- Same concept  
- 3D has more edge cases (corners, edges)  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Wall sliding is a core mechanic — Samus grabs walls automatically on contact while airborne, decelerating via a custom friction curve (fast at first, then slow). Wall jumping requires pressing jump within a tight timing window after grabbing. There's a "wall magnetism" range: if Samus is within a few pixels of a wall, she auto-snaps to it, preventing frustrating near-misses. This is the key lesson: make the "grab" happen at a wider radius than the visual contact.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody2D.is_on_wall()`, `get_wall_normal()`, `is_on_wall_only()`
```gdscript
extends CharacterBody2D

@export var wall_slide_gravity: float = 400.0  # slower fall while wall-sliding
@export var wall_jump_speed: float = 500.0
@export var wall_jump_horizontal: float = 350.0

var _is_wall_sliding: bool = false

func _physics_process(delta: float) -> void:
    _is_wall_sliding = is_on_wall() and not is_on_floor() and velocity.y > 0.0

    if _is_wall_sliding:
        velocity.y = min(velocity.y + wall_slide_gravity * delta, wall_slide_gravity)

    if Input.is_action_just_pressed("jump") and _is_wall_sliding:
        var wall_normal: Vector2 = get_wall_normal()
        velocity.y = -wall_jump_speed
        velocity.x = wall_normal.x * wall_jump_horizontal

    move_and_slide()
```
**Pitfalls:**
- `get_wall_normal()` returns the normal of the LAST wall hit, not the current wall — verify `is_on_wall()` is true before using it.
- `move_and_slide()` already performs wall sliding internally; if you add extra projection on top, the character will slide at double rate.

---

# 7. Momentum vs Responsiveness

## 🎯 Goal
Balance realism vs control

---

## 🛠️ Techniques

### A. Acceleration Model
```pseudo
velocity = lerp(current_velocity, target_velocity, accel * delta)
```

---

### B. Instant Velocity (Arcade)
```pseudo
velocity = input_direction * max_speed
```

---

### C. Hybrid Model
- Instant direction change  
- Gradual speed change  

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Acceleration | Realistic | Sluggish |
| Instant | Responsive | Unrealistic |
| Hybrid | Balanced | More tuning |

---

## 💥 Failure Cases

- Input feels laggy  
- Over-snappy movement  
- Inconsistent speed on slopes  

---

## 🔗 Composability Notes

- Affects ALL movement systems  
- Interacts with:
  - slope handling  
  - air control  
  - animation  

---

## 🧩 2D vs 3D

- Same logic  
- 3D requires direction smoothing  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link uses the hybrid model — direction changes are near-instant but speed builds up over ~0.2s. This makes Link feel snappy and responsive (critical in a large open world where the player makes many small directional corrections) while still having enough momentum feel to make running through Hyrule feel weighty. The turn animation plays at the same time but is purely cosmetic — it never delays the actual movement.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D` — `move_toward()` for speed, instant direction
```gdscript
extends CharacterBody3D

@export var max_speed: float = 6.0
@export var acceleration: float = 20.0
@export var deceleration: float = 30.0  # faster stop than start

func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction: Vector3 = (basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

    if direction != Vector3.ZERO:
        velocity.x = move_toward(velocity.x, direction.x * max_speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * max_speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

    move_and_slide()
```
**Pitfalls:**
- `lerp()` on velocity is frame-rate dependent; use `move_toward()` or multiply by `delta` for consistent acceleration across framerates.
- Make deceleration (stopping) faster than acceleration (starting) — this is the most impactful single tweak for "responsiveness" feel.

---

# 8. Moving Platforms

## 🎯 Goal
Keep character stable on moving surfaces

---

## 🛠️ Techniques

### A. Add Platform Velocity
```pseudo
velocity += platform.velocity
```

---

### B. Parent to Platform
```pseudo
character.parent = platform
```

---

### C. Relative Motion Tracking
```pseudo
position += platform.delta_movement
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Velocity Add | Flexible | Drift issues |
| Parenting | Simple | Breaks physics |
| Relative Motion | Accurate | Complex |

---

## 💥 Failure Cases

- Sliding off platform  
- Desync on fast platforms  
- Jump inherits wrong velocity  

---

## 🔗 Composability Notes

- Requires ground detection  
- Interacts with:
  - jumping  
  - slope handling  
- Parenting conflicts with physics systems  

---

## 🧩 2D vs 3D

- Same concept  
- 3D rotation adds complexity  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Moving platforms use velocity inheritance — Link adopts the platform's velocity vector while grounded. When Link jumps off a moving platform, that velocity is added to his jump velocity (standard physics-engine momentum), which enables gameplay — players can use a moving platform's speed as a "launch pad." Rotating platforms use relative motion tracking to avoid physics conflicts: Link's position updates with the platform's angular delta each frame, independent of the physics step.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D.get_floor_velocity()` — built-in platform velocity tracking
```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
    if is_on_floor():
        # Godot 4: get_floor_velocity() returns the velocity of the surface below us
        var platform_vel: Vector3 = get_floor_velocity()
        # Add platform velocity so the character moves with it
        velocity.x += platform_vel.x
        velocity.z += platform_vel.z
        # Optionally: pass horizontal platform speed into jump on launch

    move_and_slide()
```
**Pitfalls:**
- `get_floor_velocity()` is only valid when `is_on_floor()` returns true — cache it before the jump starts if you want to inherit launch velocity.
- Parenting a `CharacterBody3D` to a moving `AnimatableBody3D` works for simple linear platforms; for rotating platforms it often breaks physics — use velocity tracking instead.

---

# 🧠 FINAL INSIGHT

Movement is not one system—it is a composition of systems:

Input → Intent → Velocity → Collision Query → Adjustment → Final Motion

Most bugs come from:
- Systems running in wrong order  
- Systems fighting each other  
- Missing state transitions  
