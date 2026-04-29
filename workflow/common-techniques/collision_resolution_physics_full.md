# ⚖️ 3. Collision Resolution & Physics Response

## 📌 Scope

What happens AFTER a collision is detected

### Includes:
- Sliding along walls  
- Bounce, friction  
- Penetration correction  
- Rigidbody physics  

---

## ❗ Key distinction

- Detection = "did we hit?"  
- Resolution = "what do we do about it?"  

---

## 🔍 Typical sub-problems

- Jittering  
- Sticking to walls  
- Tunneling fixes (CCD)  
- Stable stacking  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Resolution is about producing stable, believable motion under constraints

That means:
- No interpenetration (or minimal)  
- Stable over time (no jitter/explosions)  
- Predictable and controllable  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild | 3D | Slope/ledge correction, stable stacking (physics objects), friction |
| Metroid Dread | 2D | Wall sliding, ledge magnetism, penetration correction for tight hitboxes |

---

# 🧱 PROBLEM SET

---

# 1. Penetration Resolution (Depenetration)

## 🎯 Goal
Resolve overlapping objects by pushing them apart

---

## 🛠️ Techniques

### A. Minimum Translation Vector (MTV)
```pseudo
mtv = compute_penetration_vector(a, b)
position += mtv
```

---

### B. Iterative Depenetration
```pseudo
for i in range(iterations):
    if overlapping:
        position += compute_mtv()
```

---

### C. Position Projection
```pseudo
position = project_out_of_collision(position)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| MTV | Direct, fast | Can cause jitter |
| Iterative | More stable | More expensive |
| Projection | Clean result | Requires robust math |

---

## 💥 Failure Cases

- Oscillation between surfaces  
- Deep penetration → large correction → "teleport"  
- Stacked objects exploding  

---

## 🔗 Composability Notes

- Must run before velocity resolution  
- Works with:
  - sliding  
  - stacking  
- Too aggressive correction breaks movement feel  

---

## 🧩 2D vs 3D

- Same concept  
- 3D introduces more axes → more instability  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Tight corridors require precise penetration resolution — Samus's collision shape is a narrow capsule, and the game uses iterative depenetration to ensure she never clips into geometry even in pixel-perfect tight passages. The key design choice: Samus's collision shape is slightly smaller than her visual sprite, so depenetration corrections never cause visible "teleport" pops. This margin between visual and physics is a standard practice in precision platformers.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D.move_and_slide()` handles depenetration automatically via Jolt Physics (default in Godot 4.6). For manual depenetration use `KinematicCollision3D`.
```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
    # move_and_slide() automatically resolves penetration via Jolt's solver
    move_and_slide()

    # Manual: if you need to inspect the collision result
    for i: int in range(get_slide_collision_count()):
        var col: KinematicCollision3D = get_slide_collision(i)
        var depth: float = col.get_depth()
        var normal: Vector3 = col.get_normal()
        # depth and normal are available for custom response
```
**Pitfalls:**
- Jolt Physics (default in Godot 4.6) handles depenetration more stably than the old GodotPhysics engine — avoid overriding `move_and_slide()` with manual MTV corrections unless you have a specific reason.
- If an object starts inside geometry (e.g., placed by a level designer), `move_and_slide()` will push it out in an undefined direction; validate spawn positions.

---

# 2. Sliding Response

## 🎯 Goal
Allow movement along surfaces instead of stopping

---

## 🛠️ Techniques

### A. Velocity Projection
```pseudo
velocity = project_on_plane(velocity, collision_normal)
```

---

### B. Remove Normal Component
```pseudo
velocity -= dot(velocity, normal) * normal
```

---

### C. Sequential Collision Resolution
```pseudo
for collision in collisions:
    velocity = adjust_velocity(velocity, collision.normal)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Projection | Smooth | Needs stable normals |
| Remove Component | Precise | Can feel rigid |
| Sequential | Handles multiple hits | Order-dependent bugs |

---

## 💥 Failure Cases

- Corner trapping (multiple normals)  
- Infinite sliding loops  
- Loss of speed  

---

## 🔗 Composability Notes

- Depends on detection normals  
- Must follow depenetration  
- Interacts with:
  - slope handling  
  - step offset  

---

## 🧩 2D vs 3D

- Same principle  
- 3D has more multi-surface cases  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus slides along walls with a custom friction curve — contact doesn't stop her momentum but redirects it along the wall surface with a slight speed reduction (~10%). Corners use sequential resolution: when Samus hits a convex corner, both normals are resolved sequentially (not averaged), which prevents her from "sticking" at corner seams. This is why Samus feels smooth traversing complex geometry.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D.move_and_slide()` — uses up to `max_slides` sequential resolutions (default: 4)
```gdscript
extends CharacterBody3D

# move_and_slide() handles sliding automatically.
# To manually slide a velocity vector against a normal:
func slide_velocity(vel: Vector3, surface_normal: Vector3) -> Vector3:
    return vel.slide(surface_normal)  # Vector3.slide() is built-in

func _physics_process(_delta: float) -> void:
    # After move_and_slide(), check each collision for custom response
    move_and_slide()
    for i: int in range(get_slide_collision_count()):
        var col: KinematicCollision3D = get_slide_collision(i)
        if col.get_normal().dot(Vector3.UP) < 0.1:
            # Wall collision — could apply wall-slide logic here
            pass
```
**Pitfalls:**
- `move_and_slide()` runs up to `max_slides` iterations internally; reducing this below 4 causes corner-trapping. Increase it (to 6–8) only in very complex geometry environments.
- `Vector3.slide(normal)` removes the component along the normal; `Vector3.project(normal)` gives you only the component along the normal. Common confusion.

---

# 3. Bounce & Restitution

## 🎯 Goal
Simulate bouncing behavior after collision

---

## 🛠️ Techniques

### A. Reflection Vector
```pseudo
velocity = reflect(velocity, normal) * restitution
```

---

### B. Restitution Coefficient
```pseudo
velocity *= bounce_factor
```

---

### C. Conditional Bounce
```pseudo
if impact_speed > threshold:
    apply_bounce()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Reflection | Realistic | Needs correct normals |
| Restitution | Simple | Less accurate |
| Conditional | Controlled | Less physical |

---

## 💥 Failure Cases

- Infinite bouncing  
- Energy gain due to numeric error  
- Micro-bounces on flat surfaces  

---

## 🔗 Composability Notes

- Interacts with:
  - friction  
  - velocity clamping  
- Often disabled for character controllers  

---

## 🧩 2D vs 3D

- Same math  
- 3D adds angular effects  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Physics-enabled props (barrels, crates) use conditional bounce — objects only bounce if impact speed exceeds a threshold, otherwise they just stop. Below the threshold, restitution is set to 0.1, preventing the infinite micro-bounce problem on flat stone floors. The threshold is tuned per object material (wood bounces less than metal), so barrels feel different from pots. Character controllers (Link, enemies) have bounce completely disabled — all collisions are resolved as slides.

### 🟦 Godot 4.x
**Node/API:** `RigidBody3D` with `PhysicsMaterial` — set `bounce` property (0.0–1.0)
```gdscript
extends RigidBody3D

@export var bounce_threshold_speed: float = 5.0

func _ready() -> void:
    var mat: PhysicsMaterial = PhysicsMaterial.new()
    mat.bounce = 0.4
    mat.friction = 0.6
    physics_material_override = mat

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # Conditional bounce: disable bounce on slow impacts
    if state.linear_velocity.length() < bounce_threshold_speed:
        physics_material_override.bounce = 0.0
    else:
        physics_material_override.bounce = 0.4
```
**Pitfalls:**
- `PhysicsMaterial.bounce` is combined between two objects by the engine (max or average depending on settings) — setting bounce on one object may not override the other.
- Avoid bounce on `CharacterBody3D` entirely; use `RigidBody3D` only for non-player physics objects.

---

# 4. Friction & Damping

## 🎯 Goal
Reduce motion over time or on contact

---

## 🛠️ Techniques

### A. Linear Damping
```pseudo
velocity *= (1 - damping * delta)
```

---

### B. Surface Friction
```pseudo
velocity -= friction * normal_component
```

---

### C. Coulomb Friction Approximation
```pseudo
friction_force = clamp(force, max_friction)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Damping | Simple | Not physically accurate |
| Surface Friction | Context-aware | Needs tuning |
| Coulomb | Realistic | More complex |

---

## 💥 Failure Cases

- Objects never fully stop  
- Overdamping → sticky movement  
- Sliding on flat surfaces  

---

## 🔗 Composability Notes

- Works with:
  - sliding  
  - stacking  
- Must be applied after collision resolution  

---

## 🧩 2D vs 3D

- Same principles  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Surface friction varies by material — ice surfaces have near-zero friction (Link slides when sprinting), stone is standard, wet grass after rain slightly reduces friction. This is implemented via per-material friction coefficients applied to the player's horizontal velocity each frame. The result makes the world feel "physical" without the player needing to read tooltips — the behavior communicates material properties directly.

### 🟦 Godot 4.x
**Node/API:** `PhysicsMaterial.friction` on `StaticBody3D` surfaces, or manual deceleration in `CharacterBody3D`
```gdscript
extends CharacterBody3D

@export var ground_friction: float = 20.0
@export var ice_friction: float = 1.0   # nearly no deceleration

var _current_friction: float = 20.0

func _physics_process(delta: float) -> void:
    if is_on_floor():
        # Check surface material via groups or metadata
        var floor_col: KinematicCollision3D = move_and_collide(Vector3.DOWN * 0.1, true)
        if floor_col and floor_col.get_collider():
            var surface: Node = floor_col.get_collider() as Node
            _current_friction = ice_friction if surface.is_in_group("ice") else ground_friction

        if Input.get_vector("move_left", "move_right", "move_forward", "move_back") == Vector2.ZERO:
            velocity.x = move_toward(velocity.x, 0.0, _current_friction * delta)
            velocity.z = move_toward(velocity.z, 0.0, _current_friction * delta)

    move_and_slide()
```
**Pitfalls:**
- Frame-rate independent friction: use `velocity *= pow(1.0 - friction_factor, delta)` or `move_toward()`, never `velocity *= constant` (frame-rate dependent).
- `PhysicsMaterial.friction` on `StaticBody3D` only affects `RigidBody3D` interactions — it does NOT affect `CharacterBody3D` which manages its own deceleration.

---

# 5. Continuous Collision Detection (CCD)

## 🎯 Goal
Prevent fast objects from passing through surfaces

---

## 🛠️ Techniques

### A. Swept Collision
```pseudo
hit = sweep(shape, previous_pos, next_pos)
```

---

### B. Substepping
```pseudo
for step in steps:
    simulate_small_step()
```

---

### C. Time of Impact (TOI)
```pseudo
toi = compute_time_of_impact(a, b)
position = interpolate_to(toi)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Sweep | Accurate | Expensive |
| Substep | Simple | Cost increases fast |
| TOI | Precise | Complex |

---

## 💥 Failure Cases

- Missed collisions at extreme speeds  
- Performance spikes  
- Numerical instability  

---

## 🔗 Composability Notes

- Requires:
  - detection system  
- Interacts with:
  - physics timestep  
  - resolution order  

---

## 🧩 2D vs 3D

- Same approach  
- 3D more expensive  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus's charged beam projectiles travel at high speed, but tunneling is prevented not by CCD but by limiting projectile speed to a maximum safe velocity per physics tick — at 60fps, the max speed is set so the projectile moves no more than ~80% of the thinnest wall in the level per frame. This "speed cap + tick rate" approach avoids the performance cost of CCD while guaranteeing no tunneling as long as level geometry meets a minimum thickness rule (enforced in the level editor).

### 🟦 Godot 4.x
**Node/API:** `RigidBody3D.continuous_cd = true` (Jolt Physics in Godot 4.6 has built-in CCD)
```gdscript
extends RigidBody3D

func _ready() -> void:
    # Enable CCD for fast-moving projectiles or small bodies
    continuous_cd = true
    # Jolt Physics (default in Godot 4.6) handles CCD at engine level
    # For CharacterBody3D (kinematic), use move_and_collide() which sweeps:
    pass

# CharacterBody3D alternative: use move_and_collide() for swept test
func sweep_move(delta: Vector3) -> KinematicCollision3D:
    return move_and_collide(delta)
```
**Pitfalls:**
- CCD only applies to `RigidBody3D` in Godot 4 — `CharacterBody3D.move_and_slide()` already sweeps per-frame, so CCD is not needed for character controllers.
- In Jolt (Godot 4.6), CCD is more robust than in GodotPhysics; if upgrading a project from 4.5, re-test fast projectile behavior.

---

# 6. Stable Stacking

## 🎯 Goal
Keep objects resting on each other without jitter

---

## 🛠️ Techniques

### A. Constraint Solvers
```pseudo
solve_constraints(bodies)
```

---

### B. Iterative Solver (Gauss-Seidel)
```pseudo
for i in iterations:
    resolve_contacts()
```

---

### C. Sleep States
```pseudo
if velocity < threshold:
    set_sleeping()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Solver | Stable | Complex |
| Iterative | Practical | Needs tuning |
| Sleep | Performance boost | Can freeze incorrectly |

---

## 💥 Failure Cases

- Jittering stacks  
- Objects sinking  
- Exploding stacks  

---

## 🔗 Composability Notes

- Requires:
  - penetration resolution  
  - friction  
- Highly dependent on:
  - timestep consistency  

---

## 🧩 2D vs 3D

- 3D significantly harder  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Physics stacking (boxes, logs, rocks) uses sleep states aggressively — objects go to sleep within ~0.5s of coming to rest. Stacked structures that would be unstable in a full rigid-body sim are stabilized via a "stack joint" system where touching static objects gain increased friction and reduced restitution. This prevents the classic "stack of crates slowly explodes" problem while still allowing the player to disturb stacks intentionally with explosions or direct hits.

### 🟦 Godot 4.x
**Node/API:** `RigidBody3D.can_sleep = true` (default) — Jolt Physics auto-sleeps at rest
```gdscript
extends RigidBody3D

func _ready() -> void:
    can_sleep = true
    # Jolt (Godot 4.6) handles stacking significantly better than GodotPhysics
    # Increase solver iterations for complex stacks in Project Settings:
    # physics/3d/jolt/solver/velocity_iterations (default: 10)
    # physics/3d/jolt/solver/position_iterations (default: 2)

func wake_up_stack() -> void:
    # Force wake neighboring bodies on impact
    sleeping = false
```
**Pitfalls:**
- Jolt Physics (Godot 4.6) has much better stacking stability than GodotPhysics — if you see jitter, first check if you're using Jolt (Project Settings > Physics > 3D > Physics Engine).
- Objects that sleep too quickly can cause "frozen mid-air" bugs — tune `RigidBody3D.sleep_threshold` if objects stop before fully settling.

---

# 7. Jittering & Stability Fixes

## 🎯 Goal
Eliminate unstable micro-movements

---

## 🛠️ Techniques

### A. Velocity Threshold Clamp
```pseudo
if abs(velocity) < epsilon:
    velocity = 0
```

---

### B. Positional Correction Bias
```pseudo
position += correction * bias
```

---

### C. Fixed Timestep
```pseudo
simulate(dt_fixed)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Clamp | Simple | Can hide real issues |
| Bias | Stabilizes | Can drift |
| Fixed Timestep | Consistent | Less flexible |

---

## 💥 Failure Cases

- Visible snapping  
- Energy loss  
- Hidden bugs masked  

---

## 🔗 Composability Notes

- Works across ALL physics systems  
- Essential for:
  - stacking  
  - resting contacts  

---

## 🧩 2D vs 3D

- Same idea  
- 3D amplifies instability  

---

### 🎮 Nintendo Reference
**Zelda BotW:** The physics engine runs at a fixed 30Hz (even when rendering at 60fps), and physics interpolation is used for smooth visual presentation. This fixed timestep is the primary jitter fix — by keeping physics consistent regardless of rendering framerate, all instability issues are reproducible and easier to fix. The game also uses a micro-velocity threshold: rigid bodies with velocity below ~0.01 units/frame have their velocity zeroed, preventing the "vibrating at rest" bug common in Euler-integrated physics.

### 🟦 Godot 4.x
**Node/API:** `Engine.physics_ticks_per_second` (default: 60), `ProjectSettings` physics timestep
```gdscript
# In Project Settings > Physics:
# physics/common/physics_ticks_per_second = 60
# physics/common/physics_interpolation = true (Godot 4.3+)

extends RigidBody3D

const VELOCITY_SLEEP_THRESHOLD: float = 0.01

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # Manual micro-velocity clamp (usually handled by Jolt's sleep system)
    if state.linear_velocity.length() < VELOCITY_SLEEP_THRESHOLD and is_on_floor():
        state.linear_velocity = Vector3.ZERO
```
**Pitfalls:**
- Physics interpolation (`physics/common/physics_interpolation = true`) is the right fix for visual jitter caused by framerate mismatch — don't try to fix it by increasing `physics_ticks_per_second`.
- Running physics at >120Hz in Godot significantly increases CPU cost; for stable stacking, tuning Jolt solver iterations is more effective than raising the tick rate.

---

# 🧠 FINAL INSIGHT

Collision resolution is a pipeline of corrections:

Detect → Depenetrate → Adjust Velocity → Apply Forces → Stabilize

Most bugs come from:
- Wrong order of operations  
- Missing iterations  
- Systems fighting each other  
- Numerical instability  
