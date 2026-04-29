# 🧲 2. Collision Detection & Queries

## 📌 Scope

Detecting if/when things touch or overlap

### Includes:
- Raycasts, shapecasts  
- Overlaps  
- Hit detection  
- Line of sight  

---

## ❗ Why separate from physics

This is about querying the world, not resolving it.

You are asking:
"What is there?"
NOT:
"What should happen?"

---

## 🔍 Typical sub-problems

- Ground checks  
- Wall detection  
- Hitboxes vs hurtboxes  
- Visibility checks  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Detection should be stateless, deterministic, and query-based

That means:
- No side effects  
- Same input → same result  
- Independent from movement logic  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild | 3D | Interaction sphere raycasts, line of sight for stealth/enemies |
| Metroid Dread | 2D | Precise hitbox/hurtbox separation, i-frames, tight ground detection |

---

# 🧱 PROBLEM SET

---

# 1. Raycasting (Line Queries)

## 🎯 Goal
Detect intersections along a line

---

## 🛠️ Techniques

### A. Single Raycast
```pseudo
hit = raycast(origin, direction, max_distance)
if hit:
    point = hit.position
    normal = hit.normal
```

---

### B. Multi-ray Sampling
```pseudo
hits = []
for dir in directions:
    hits.append(raycast(origin, dir))

result = aggregate(hits)
```

---

### C. Layer / Mask Filtering
```pseudo
hit = raycast(origin, dir, mask=GROUND_LAYER)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Single Ray | Fast, simple | Limited coverage |
| Multi-ray | More robust | More expensive |
| Layer Mask | Precise filtering | Requires setup discipline |

---

## 💥 Failure Cases

- Thin objects missed (tunneling-like effect)  
- Starting inside collider → no hit  
- Precision errors at long distances  
- Missing fast-moving targets  

---

## 🔗 Composability Notes

- Used by:
  - ground detection  
  - line of sight  
  - aiming systems  
- Often combined with shape casts for robustness  
- Must be consistent with collision layers used in physics  

---

## 🧩 2D vs 3D

- 2D: simpler, fewer rays needed  
- 3D: often requires multiple rays or spread  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link's interaction system uses a forward-facing sphere cast (not a single ray) that samples multiple points around the reticle. When the player holds a button, a cone of raycasts fans out from Link's perspective — the closest interactable that hits any ray is highlighted. This prevents the common frustration of "I'm looking right at it but can't interact" by widening the hit window beyond a hairline ray.

### 🟦 Godot 4.x
**Node/API:** `RayCast3D` node (continuous) or `PhysicsDirectSpaceState3D.intersect_ray()` (one-shot)
```gdscript
extends Node3D

@export var ray_length: float = 10.0
@export var interaction_layer: int = 2  # bit index

func _physics_process(_delta: float) -> void:
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        global_position,
        global_position + -global_basis.z * ray_length
    )
    query.collision_mask = 1 << interaction_layer
    query.exclude = [self]
    var result: Dictionary = space.intersect_ray(query)
    if not result.is_empty():
        var hit_point: Vector3 = result["position"]
        var hit_normal: Vector3 = result["normal"]
```
**Pitfalls:**
- `RayCast3D` node caches its result until the next physics frame — use `force_raycast_update()` if you need a fresh result mid-frame.
- `intersect_ray()` called outside `_physics_process` may query stale physics state; always call it in `_physics_process` or `_physics_process`-adjacent callbacks.

---

# 2. Shape Casting (Swept Volumes)

## 🎯 Goal
Detect collisions over a volume along a path

---

## 🛠️ Techniques

### A. Capsule Cast
```pseudo
hit = shapecast(capsule, direction, distance)
```

---

### B. Box Cast
```pseudo
hit = shapecast(box, direction, distance)
```

---

### C. Continuous Sweep
```pseudo
hit = sweep_shape(shape, from, to)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Capsule | Good for characters | Limited shapes |
| Box | Predictable | Can snag on edges |
| Sweep | Accurate | Expensive |

---

## 💥 Failure Cases

- Starting inside geometry → undefined results  
- Edge grazing → unstable normals  
- Performance spikes with many casts  

---

## 🔗 Composability Notes

- Often replaces multiple raycasts  
- Works closely with movement prediction  
- Required for:
  - robust grounding  
  - ledge detection  

---

## 🧩 2D vs 3D

- 2D: box/circle casts  
- 3D: capsule is dominant  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus's ground detection uses a capsule cast centered on her feet rather than a single downward ray. This prevents the classic "one foot off the edge" false-negative — the capsule catches the platform even when Samus is standing near its edge with only part of her foot collider over solid ground. The capsule radius is slightly smaller than her visual foot width, creating a subtle forgiveness margin.

### 🟦 Godot 4.x
**Node/API:** `ShapeCast3D` node or `PhysicsDirectSpaceState3D.intersect_shape()`
```gdscript
extends CharacterBody3D

@onready var shape_cast: ShapeCast3D = $GroundProbe  # child ShapeCast3D node

func _physics_process(_delta: float) -> void:
    shape_cast.force_shapecast_update()
    if shape_cast.is_colliding():
        var hit_normal: Vector3 = shape_cast.get_collision_normal(0)
        var hit_point: Vector3 = shape_cast.get_collision_point(0)
        # Use hit_normal for slope checks
```
**Pitfalls:**
- `ShapeCast3D` reports the first collision only by default; call `get_collision_count()` and iterate if you need all hits.
- A shape cast starting inside geometry returns no hit — position the shape just above the character's feet, not at ground level.

---

# 3. Overlap Queries (Volume Checks)

## 🎯 Goal
Detect what is inside a region

---

## 🛠️ Techniques

### A. Sphere / Circle Overlap
```pseudo
colliders = overlap_sphere(center, radius)
```

---

### B. Box Overlap
```pseudo
colliders = overlap_box(center, size)
```

---

### C. Trigger Volumes
```pseudo
on_enter(collider):
    handle_event()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Sphere | Cheap | Imprecise |
| Box | Flexible | Orientation issues |
| Triggers | Event-driven | Less control |

---

## 💥 Failure Cases

- Missing fast objects between frames  
- Multiple triggers firing unexpectedly  
- Large volumes causing performance issues  

---

## 🔗 Composability Notes

- Used for:
  - area detection  
  - combat hitboxes  
  - pickups  
- Often combined with state machines  

---

## 🧩 2D vs 3D

- Same concept  
- 3D requires rotation handling  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemy detection uses a layered overlap system — a large outer sphere for "awareness" range (enemy alert), a medium sphere for combat engagement range, and a small inner sphere for "very close" reactions like backstabs. Each sphere is a separate `Area` volume with different collision layers. This lets designers tune enemy awareness without touching combat logic, because each concern lives in its own isolated volume.

### 🟦 Godot 4.x
**Node/API:** `Area2D` / `Area3D` with `body_entered` / `body_exited` signals, or `PhysicsDirectSpaceState3D.intersect_shape()`
```gdscript
extends Area3D

signal enemy_entered(enemy: Node3D)

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("enemy"):
        enemy_entered.emit(body)

# For manual overlap query (one-shot, no node needed):
func check_overlap_at(pos: Vector3, radius: float) -> Array[Node3D]:
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var shape: SphereShape3D = SphereShape3D.new()
    shape.radius = radius
    var params: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), pos)
    var hits: Array[Dictionary] = space.intersect_shape(params)
    var result: Array[Node3D] = []
    for hit: Dictionary in hits:
        result.append(hit["collider"] as Node3D)
    return result
```
**Pitfalls:**
- `Area3D.body_entered` fires once on entry — if you need continuous overlap, use a timer or poll `get_overlapping_bodies()` each frame.
- Monitoring must be enabled on `Area3D` (`monitoring = true`) or the signals never fire.

---

# 4. Hit Detection (Combat / Interaction)

## 🎯 Goal
Determine if an attack or interaction hits a target

---

## 🛠️ Techniques

### A. Hitbox vs Hurtbox
```pseudo
if overlap(hitbox, hurtbox):
    apply_damage()
```

---

### B. Frame-based Activation
```pseudo
if animation_frame in active_frames:
    enable_hitbox()
```

---

### C. Swept Hit Detection
```pseudo
hit = sweep(hitbox, previous_pos, current_pos)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Overlap | Simple | Can miss fast hits |
| Frame-based | Precise timing | Animation dependent |
| Sweep | Accurate | Expensive |

---

## 💥 Failure Cases

- Missed hits due to low framerate  
- Double hits in one frame  
- Desync with animation  

---

## 🔗 Composability Notes

- Requires:
  - overlap queries  
  - animation system  
- Interacts with:
  - networking  
  - state machines  

---

## 🧩 2D vs 3D

- Same logic  
- 3D adds directional complexity  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus's hitbox (hurtbox for receiving damage) is significantly smaller than her sprite — roughly 60% of her visual width. Her attack hitboxes are activated on exact animation frames via animation events, and each hit within a single attack combo can only register once per target (a per-target invulnerability flag per attack swing). This prevents multi-hit bugs where a single swing registers multiple times on a stationary enemy.  
**Zelda BotW:** Weapon swing detection uses an arc-shaped swept hitbox following the blade's arc, not a static box. This matches the visual swing and means the hit registers at the point where the blade "crosses" the enemy — giving precise, readable results that match what the player sees.

### 🟦 Godot 4.x
**Node/API:** `Area2D` / `Area3D` for hitboxes — enable/disable via `monitoring` and `monitorable` properties
```gdscript
extends Node3D

@onready var hitbox: Area3D = $HitboxArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _already_hit: Array[Node3D] = []

func _ready() -> void:
    hitbox.monitoring = false
    hitbox.body_entered.connect(_on_hitbox_body_entered)

func activate_hitbox() -> void:  # called from AnimationPlayer track callback
    _already_hit.clear()
    hitbox.monitoring = true

func deactivate_hitbox() -> void:  # called from AnimationPlayer track callback
    hitbox.monitoring = false

func _on_hitbox_body_entered(body: Node3D) -> void:
    if body in _already_hit:
        return
    if body.has_method("take_damage"):
        _already_hit.append(body)
        body.take_damage(10)
```
**Pitfalls:**
- Use AnimationPlayer's "Call Method" track (not signals) to activate/deactivate hitboxes — it fires at the exact frame, while signal-based approaches can fire a frame late.
- Separate the hitbox (what you deal damage with) and hurtbox (what you receive damage on) into different `Area3D` nodes on different collision layers; otherwise an attacker's hitbox hits its own hurtbox.

---

# 5. Line of Sight (Visibility)

## 🎯 Goal
Determine if one entity can "see" another

---

## 🛠️ Techniques

### A. Direct Raycast
```pseudo
hit = raycast(eye, target)
visible = (hit == target)
```

---

### B. Multi-point Visibility
```pseudo
points = target.get_visibility_points()
visible = any(raycast(eye, p) for p in points)
```

---

### C. Cone Check + Raycast
```pseudo
if angle_to_target < fov:
    visible = raycast_clear()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Single Ray | Fast | Easily blocked |
| Multi-point | Robust | Expensive |
| Cone + Ray | Realistic | More logic |

---

## 💥 Failure Cases

- Partial occlusion issues  
- Thin obstacles not detected  
- Flickering visibility  

---

## 🔗 Composability Notes

- Combines:
  - raycasting  
  - angle checks  
- Used by:
  - AI systems  
  - stealth mechanics  

---

## 🧩 2D vs 3D

- 2D: simpler geometry  
- 3D: occlusion is more complex  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemy vision uses a cone-check followed by a multi-point raycast. The cone angle and range differ by enemy type (`@export var` equivalents in the game data). Key detail: the raycast checks three points on Link's body (feet, torso, head) — if any point is visible, the enemy can see him. Crouching reduces the hit chance because it lowers Link, making the head and torso points harder to reach around obstacles. The Sheikah Sensor (enemy detection icon) visualizes the cone in real-time, which is essentially a debug tool shipped as a gameplay feature.

### 🟦 Godot 4.x
**Node/API:** `RayCast3D` node on the enemy's "eyes" + angle check via `dot()` or `angle_to()`
```gdscript
extends Node3D

@export var fov_angle_degrees: float = 90.0
@export var sight_range: float = 20.0
@onready var eye_ray: RayCast3D = $EyeRayCast

func can_see(target: Node3D) -> bool:
    var to_target: Vector3 = (target.global_position - global_position)
    if to_target.length() > sight_range:
        return false
    var angle: float = rad_to_deg(global_basis.z.angle_to(to_target.normalized()))
    if angle > fov_angle_degrees * 0.5:
        return false
    eye_ray.target_position = eye_ray.to_local(target.global_position)
    eye_ray.force_raycast_update()
    if eye_ray.is_colliding():
        return eye_ray.get_collider() == target
    return true
```
**Pitfalls:**
- Check `fov_angle_degrees * 0.5` (half-angle) — FOV of 90° means 45° to either side of forward, not 90° to one side.
- `RayCast3D.target_position` is in local space; use `to_local()` to convert a world-space target, or use `PhysicsDirectSpaceState3D.intersect_ray()` instead for world-space queries.

---

# 6. Spatial Filtering & Layers

## 🎯 Goal
Limit what queries can detect

---

## 🛠️ Techniques

### A. Collision Layers
```pseudo
raycast(mask=ENEMY_LAYER)
```

---

### B. Tag Filtering
```pseudo
if collider.tag == "enemy":
```

---

### C. Query Groups
```pseudo
overlap(group="interactable")
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Layers | Fast, engine-level | Limited slots |
| Tags | Flexible | String-based errors |
| Groups | Organized | Requires discipline |

---

## 💥 Failure Cases

- Incorrect filtering → missing hits  
- Overlapping layers → unintended interactions  
- Hard-to-debug filtering logic  

---

## 🔗 Composability Notes

- Critical for ALL queries  
- Must align with:
  - physics system  
  - gameplay logic  

---

## 🧩 2D vs 3D

- Same system  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Uses a strict collision layer convention — terrain, props, enemies, player, water, and interactables each live on separate layers. Enemy raycasts only check the terrain and player layers (not other enemies), which prevents enemies from blocking each other's line-of-sight queries and saves performance. Interactable objects have a dedicated detection layer that is only queried when the player presses the interact button — not every frame — reducing constant raycasting overhead.

### 🟦 Godot 4.x
**Node/API:** `collision_layer` and `collision_mask` bitmasks — use named constants via `ProjectSettings`
```gdscript
# In project settings > Layer Names, name your layers:
# Layer 1 = "world", Layer 2 = "player", Layer 3 = "enemy", Layer 4 = "interactable"

extends Node3D

const LAYER_WORLD: int = 1       # bit 0
const LAYER_PLAYER: int = 2      # bit 1
const LAYER_ENEMY: int = 4       # bit 2
const LAYER_INTERACT: int = 8    # bit 3

func raycast_for_enemy_vision() -> Dictionary:
    var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        global_position,
        global_position + global_basis.z * 20.0
    )
    query.collision_mask = LAYER_WORLD | LAYER_PLAYER  # only check terrain + player
    return space.intersect_ray(query)
```
**Pitfalls:**
- Godot 4 has 32 collision layers. Establish a naming convention in Project Settings early — once objects are placed, changing layer assignments is painful.
- `collision_layer` = what layer this object IS on. `collision_mask` = what layers this object DETECTS. They are independent bitmasks; a common mistake is setting one but not both.

---

# 🧠 FINAL INSIGHT

Collision detection is not one tool—it is a toolkit of queries:

Raycast → ShapeCast → Overlap → Filter → Interpret

Most bugs come from:
- Wrong query type used  
- Missing edge cases (thin objects, fast movement)  
- Inconsistent filtering  
- Mixing detection with resolution  
