# 🎞️ 6. Animation Systems

## 📌 Scope

How movement and actions are visually represented

### Includes:
- Animation blending  
- State machines / animation graphs  
- Root motion vs in-place animation  
- Inverse kinematics (IK)  

---

## 🔍 Typical sub-problems

- Foot sliding  
- Snapping transitions  
- Mismatch with physics  
- Animation desync  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Animation is not just visual—it is part of the control system.

That means:
- Animation must match gameplay state  
- Motion must feel consistent with visuals  
- Systems must coordinate timing and motion  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild / Tears of the Kingdom | 3D | Locomotion blend trees, IK foot placement, animation events, layering (arm/body split) |
| Metroid Dread | 2D | Frame-perfect cancel windows, hitbox-sync animation events, skeletal 2D animation, mode-swap transitions |

---

# 🧱 PROBLEM SET

---

# 1. Animation State Machines / Graphs

## 🎯 Goal
Control which animation plays based on state

---

## 🛠️ Techniques

### A. Finite Animation State Machine
```pseudo
if state == IDLE:
    play("idle")
elif state == RUN:
    play("run")
elif state == JUMP:
    play("jump")
```

---

### B. Blend Trees
```pseudo
blend_value = speed / max_speed
animation = blend(idle, run, blend_value)
```

---

### C. Animation Graphs
```pseudo
node = graph.evaluate(parameters)
play(node.animation)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| FSM | Simple | Hard transitions |
| Blend Tree | Smooth transitions | Limited logic |
| Graph | Flexible | Complex setup |

---

## 💥 Failure Cases

- State mismatch (running animation while idle)  
- Transition spam  
- Hard snapping between states  

---

## 🔗 Composability Notes

- Driven by:
  - character state machine  
- Must stay synchronized with:
  - movement  
  - physics  
- Often combined with:
  - event systems  

---

## 🧩 2D vs 3D

- Same logic  
- 3D requires more blending dimensions  
- Note: modern 2D games also use skeletal animation (Godot supports `Skeleton2D`) — the blend tree approach applies to 2D as well

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link's locomotion uses a 2D blend tree — speed and direction feed into a blend tree that selects and interpolates between idle, walk, run, and strafe animations. The tree is parameterized so that a speed of 0 plays idle, 0.5 plays walk, and 1.0 plays run with smooth blending between them. There's no hard FSM switch for locomotion — only for mode changes (combat vs exploration). This means Link's movement always looks fluid regardless of input speed.

### 🟦 Godot 4.x
**Node/API:** `AnimationTree` with `AnimationNodeStateMachine` or `AnimationNodeBlendSpace2D`
```gdscript
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _physics_process(_delta: float) -> void:
    var speed_normalized: float = velocity.length() / 6.0  # normalize to 0-1
    anim_tree["parameters/LocomotionBlend/blend_position"] = Vector2(
        velocity.normalized().dot(global_basis.x),  # lateral
        speed_normalized                              # forward
    )
    if not is_on_floor():
        state_machine.travel("Jump")
    elif velocity.length() > 0.1:
        state_machine.travel("Run")
    else:
        state_machine.travel("Idle")
```
**Pitfalls:**
- `AnimationTree` parameters are set via string paths like `"parameters/StateMachine/playback"` — create typed constants for these paths to prevent silent typo bugs.
- `AnimationTree.active` must be `true` for the tree to process; a common bug is forgetting to enable it in `_ready()`.

---

# 2. Animation Blending

## 🎯 Goal
Smooth transitions between animations

---

## 🛠️ Techniques

### A. Linear Interpolation
```pseudo
pose = lerp(pose_a, pose_b, t)
```

---

### B. Crossfade
```pseudo
crossfade(current_anim, next_anim, duration)
```

---

### C. Additive Blending
```pseudo
final_pose = base_pose + additive_pose
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Lerp | Simple | Limited realism |
| Crossfade | Smooth | Timing-sensitive |
| Additive | Flexible | Requires correct setup |

---

## 💥 Failure Cases

- Blending incompatible poses  
- Foot sliding  
- Over-blending → mushy motion  

---

## 🔗 Composability Notes

- Works with:
  - state machines  
  - IK systems  
- Must respect:
  - timing  
  - animation phase  

---

## 🧩 2D vs 3D

- 2D: sprite switching, or skeletal blending via `Skeleton2D` + `AnimationPlayer`  
- 3D: skeletal blending via `AnimationTree`  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Transition blending uses duration tuning per transition pair rather than a global crossfade time. Idle→run: 0.1s (snappy). Run→idle: 0.2s (slight deceleration visual). Combat→death: 0.05s (fast to not delay feel). Jump_land→idle: 0.15s. Each pair has its own carefully tuned blend duration. This per-pair tuning is what makes Link feel responsive during fast inputs and natural during slower transitions — a single global blend time would compromise one or the other.

### 🟦 Godot 4.x
**Node/API:** `AnimationNodeStateMachine` transition settings — `xfade_time` per transition
```gdscript
# In AnimationTree inspector: set per-transition XFade Time values
# Or via code:
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree

func configure_transitions() -> void:
    var state_machine: AnimationNodeStateMachine = anim_tree.tree_root as AnimationNodeStateMachine
    # Get a specific transition and set its blend time
    # Transitions are configured in the AnimationTree editor graphically;
    # tune XFade Time per edge in the StateMachine graph
    pass

# Additive blending: AnimationNodeAdd2 in AnimationTree
# for overlaying a recoil/hit reaction on top of locomotion
```
**Pitfalls:**
- Additive animations require the animation to be authored as "additive" (delta from rest pose, not absolute pose) — applying an absolute animation additively causes extreme distortion.
- Crossfade time that is too long (>0.3s) during combat makes hits feel delayed. Tune fast transitions for responsive actions and slower transitions only for natural state exits.

---

# 3. Root Motion vs In-place Animation

## 🎯 Goal
Determine where motion comes from

---

## 🛠️ Techniques

### A. In-place Animation
```pseudo
position += velocity * delta
animation = play("run_in_place")
```

---

### B. Root Motion
```pseudo
delta_motion = animation.root_delta
position += delta_motion
```

---

### C. Hybrid Approach
```pseudo
position += blend(root_motion, velocity_motion)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| In-place | Full control | Requires syncing |
| Root Motion | Natural movement | Hard to control |
| Hybrid | Flexible | Complex |

---

## 💥 Failure Cases

- Foot sliding (in-place mismatch)  
- Loss of control (root motion)  
- Desync with physics  

---

## 🔗 Composability Notes

- Root motion must integrate with:
  - collision system  
  - navigation  
- In-place relies heavily on:
  - movement controller  

---

## 🧩 2D vs 3D

- 2D: mostly in-place  
- 3D: both approaches common  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link uses in-place animation for all locomotion — position is driven by code, not animation. Root motion is only used for specific one-shot actions: cinematic attacks, climbing transitions, and environmental interactions (mounting a horse). This hybrid approach gives designers full control over movement feel while preserving natural motion for scripted moments. The foot placement IK system then corrects for foot sliding that in-place animation can create on uneven terrain.  
**Metroid Dread:** Samus uses purely in-place animation — the code drives position entirely. This is appropriate for a precision platformer where exact positional control is critical. No root motion is used anywhere, which makes the movement predictable and testable by the physics system without animation interference.

### 🟦 Godot 4.x
**Node/API:** `AnimationMixer.root_motion_track` + `AnimationMixer.get_root_motion_position()`
```gdscript
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree

@export var use_root_motion: bool = false

func _physics_process(_delta: float) -> void:
    if use_root_motion:
        # Apply root motion from animation to actual position
        var root_motion: Vector3 = anim_tree.get_root_motion_position()
        velocity = root_motion / get_physics_process_delta_time()
    # else: velocity is set by movement controller (in-place mode)

    move_and_slide()
```
**Pitfalls:**
- `get_root_motion_position()` returns the delta position for this frame (not cumulative) — apply it by dividing by `delta` to get velocity, then use `move_and_slide()` for collision.
- Root motion bypasses your collision avoidance logic unless you convert it to velocity — never set `global_position` directly from root motion data.

---

# 4. Inverse Kinematics (IK)

## 🎯 Goal
Adjust bones dynamically to match environment

---

## 🛠️ Techniques

### A. Two-bone IK
```pseudo
solve_ik(shoulder, elbow, hand, target)
```

---

### B. Foot Placement IK
```pseudo
foot_target = raycast_to_ground()
apply_ik(foot, foot_target)
```

---

### C. Look-at IK
```pseudo
head.rotation = look_at(target)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Two-bone | Simple, fast | Limited flexibility |
| Foot IK | Ground alignment | Needs stable ground data |
| Look-at | Expressive | Can look unnatural |

---

## 💥 Failure Cases

- Jitter on uneven terrain  
- Foot snapping  
- Overextension of limbs  

---

## 🔗 Composability Notes

- Depends on:
  - collision queries (for ground)  
- Applied after:
  - animation blending  
- Must not fight:
  - root motion  

---

## 🧩 2D vs 3D

- Mostly 3D  
- 2D IK is possible via `SkeletonModification2D` in Godot 4  

---

### 🎮 Nintendo Reference
**Zelda BotW/TotK:** Link uses foot placement IK on all terrain — raycasts from each foot to the ground, and IK adjusts the ankle position to match the surface normal. The pelvis is also adjusted to split the difference between the two feet heights, preventing Link from leaning too far on extreme slopes. The IK is blended based on movement speed: at full run speed the IK weight is ~30% (fast movement masks foot placement differences); at idle it's 100% (foot placement is clearly visible and must be correct).

### 🟦 Godot 4.x
**Node/API:** `SkeletonModification3D` — specifically `SkeletonModificationStack3D` with `SkeletonModification3DLookAt` or `SkeletonModification3DFABRIK`
```gdscript
extends CharacterBody3D

@onready var skeleton: Skeleton3D = $Armature/Skeleton3D
@onready var left_foot_ray: RayCast3D = $LeftFootRay
@onready var right_foot_ray: RayCast3D = $RightFootRay

@export var foot_ik_weight: float = 1.0  # blend 0-1

func _process(_delta: float) -> void:
    _apply_foot_ik()

func _apply_foot_ik() -> void:
    left_foot_ray.force_raycast_update()
    right_foot_ray.force_raycast_update()

    var ik_weight: float = foot_ik_weight * (1.0 - clamp(velocity.length() / 6.0, 0.0, 0.7))

    if left_foot_ray.is_colliding():
        var foot_target: Vector3 = left_foot_ray.get_collision_point()
        # Use SkeletonModificationStack3D or manually set bone pose:
        var bone_idx: int = skeleton.find_bone("LeftFoot")
        var current_pose: Transform3D = skeleton.get_bone_global_pose(bone_idx)
        var target_pose: Transform3D = Transform3D(current_pose.basis, foot_target)
        skeleton.set_bone_global_pose_override(bone_idx, current_pose.interpolate_with(target_pose, ik_weight), ik_weight, true)
```
**Pitfalls:**
- IK must run in `_process` (visual update), not `_physics_process` (physics step) — mixing them causes one-frame visual lag.
- `set_bone_global_pose_override()` with `persistent = true` can lock the bone permanently if not cleared — reset overrides when IK is disabled.

---

# 5. Animation Timing & Events

## 🎯 Goal
Synchronize gameplay with animation

---

## 🛠️ Techniques

### A. Animation Events
```pseudo
on_frame("attack_hit"):
    apply_damage()
```

---

### B. Time-based Triggers
```pseudo
if animation_time > threshold:
    trigger_event()
```

---

### C. State Sync
```pseudo
if animation_finished:
    change_state()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Events | Precise | Hard to maintain |
| Time-based | Simple | Less accurate |
| Sync | Clean | Needs coordination |

---

## 💥 Failure Cases

- Desync between animation and gameplay  
- Missed events  
- Double-trigger bugs  

---

## 🔗 Composability Notes

- Must align with:
  - state machine  
  - hit detection  
- Critical for:
  - combat systems  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Samus's combat animations use frame-precise events for hitbox activation and i-frame windows. Each attack animation has exactly one "hitbox active start" and one "hitbox active end" event, preventing multi-hit bugs. The i-frame window (invulnerability after taking damage) is driven by an animation event on the damage reaction animation — the i-frame starts at the event frame, not at the physics hit frame. This 1–2 frame intentional delay is invisible to the player but prevents "took damage while invulnerable" race conditions.

### 🟦 Godot 4.x
**Node/API:** `AnimationPlayer` "Call Method" tracks for frame-precise events; `animation_finished` signal for state sync
```gdscript
extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

signal attack_hit_frame()
signal attack_finished()

func _ready() -> void:
    anim_player.animation_finished.connect(_on_animation_finished)
    # In AnimationPlayer editor: add a "Call Method" track at the hit frame
    # that calls activate_hitbox() — this is more reliable than checking time

func activate_hitbox() -> void:  # called from AnimationPlayer Method Track
    attack_hit_frame.emit()

func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name == &"Attack":
        attack_finished.emit()
```
**Pitfalls:**
- Use "Call Method" tracks in `AnimationPlayer` for hitbox events — NOT `animation_changed` signal or time comparisons. Method tracks fire at the exact keyframe, not a frame later.
- `AnimationPlayer` method tracks fire even when the animation is sped up or slowed down — if you scale animation speed for feel, verify that event timing still makes sense at the new speed.

---

# 6. Animation Layering

## 🎯 Goal
Combine multiple animations (e.g., run + shoot)

---

## 🛠️ Techniques

### A. Upper/Lower Body Split
```pseudo
lower_body = run_animation
upper_body = shoot_animation
```

---

### B. Masked Blending
```pseudo
apply_mask(animation, body_parts)
```

---

### C. Additive Layers
```pseudo
final_pose += recoil_animation
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Split | Simple | Limited flexibility |
| Masking | Flexible | Setup complexity |
| Additive | Powerful | Needs careful tuning |

---

## 💥 Failure Cases

- Conflicting poses  
- Broken animations  
- Visual artifacts  

---

## 🔗 Composability Notes

- Works with:
  - blending  
  - state machines  
- Requires consistent rig setup  

---

## 🧩 2D vs 3D

- Mostly 3D  
- 2D uses sprite layering or `Skeleton2D` partial pose overrides  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link's combat uses upper/lower body split animation layering — his legs continue locomotion while his upper body plays weapon swing animations. The split point is the pelvis bone: everything above pelvis = combat layer, everything below = movement layer. When Link does a running attack, you see the legs in a running cycle and the arms in the sword swing animation simultaneously. This requires the rig to be designed with the split in mind — the spine twist animation is handled separately to blend the two halves naturally.

### 🟦 Godot 4.x
**Node/API:** `AnimationNodeBlend2` with bone masks, or `AnimationNodeAdd2` for additive layers
```gdscript
# In AnimationTree: create AnimationNodeBlend2 with a bone mask
# Mask = only upper body bones (spine, arms, head)
# Input 0 = locomotion animation
# Input 1 = upper body combat animation
# blend_amount = 1.0 to fully apply upper body layer

extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree

func set_upper_body_action(action_name: StringName) -> void:
    # Switch the upper body state machine to the desired action
    var upper_playback: AnimationNodeStateMachinePlayback = \
        anim_tree["parameters/UpperBodyStateMachine/playback"]
    upper_playback.travel(action_name)

func set_lower_body_locomotion(speed: float) -> void:
    anim_tree["parameters/LocomotionBlend/blend_position"] = speed
```
**Pitfalls:**
- Bone masks in `AnimationNodeBlend2` must be set in the AnimationTree graph editor — there is no GDScript API to set per-bone masks at runtime. Design them at author time.
- When blending upper and lower body, the spine/pelvis bone needs to be assigned to one layer only, or it will conflict and cause unnatural twisting.

---

# 7. Animation & Movement Synchronization

## 🎯 Goal
Ensure visuals match actual movement

---

## 🛠️ Techniques

### A. Speed Matching
```pseudo
animation_speed = velocity.length / max_speed
```

---

### B. Stride Warping
```pseudo
adjust_stride(animation, target_speed)
```

---

### C. Motion Warping
```pseudo
warp_animation_to_target(position)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Speed Match | Simple | Limited accuracy |
| Stride Warp | Natural | Complex |
| Motion Warp | Precise | Expensive |

---

## 💥 Failure Cases

- Foot sliding  
- Overstretching animations  
- Desync during fast motion  

---

## 🔗 Composability Notes

- Critical for:
  - root motion systems  
- Interacts with:
  - navigation  
  - physics  

---

## 🧩 2D vs 3D

- Mostly 3D problem  

---

### 🎮 Nintendo Reference
**Zelda TotK:** Link's locomotion uses speed-matched animation playback — the walk/run cycle is driven at a rate proportional to actual movement speed. At 50% of max speed the animation plays at 0.5× rate, so foot cycle frequency matches the actual stride length. This is combined with foot IK to handle residual mismatch on uneven terrain. The combination of speed-matching + IK eliminates foot sliding without requiring motion warping on every surface — motion warping is reserved for specific cinematic interactions (vault over a wall, dismount from horse).

### 🟦 Godot 4.x
**Node/API:** `AnimationPlayer.speed_scale` or `AnimationTree` parameters for blend position driving animation speed
```gdscript
extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree
@export var max_speed: float = 6.0

func _physics_process(_delta: float) -> void:
    var speed_normalized: float = clamp(velocity.length() / max_speed, 0.0, 1.0)

    # Speed-match: drive blend tree position AND animation playback rate
    anim_tree["parameters/LocomotionBlend/blend_position"] = speed_normalized

    # Scale animation speed to match movement speed (reduces foot sliding)
    # At speed 0: anim rate 0, at max speed: anim rate 1.0
    anim_tree["parameters/TimeScale/scale"] = max(speed_normalized, 0.1)
```
**Pitfalls:**
- Setting `TimeScale/scale` to 0 freezes the animation entirely — use a minimum value (0.05–0.1) to keep the idle breathing animation running.
- Speed matching reduces foot sliding but doesn't eliminate it on uneven terrain — combine with foot IK for best results.

---

# 🧠 FINAL INSIGHT

Animation is a layer between logic and perception:

State → Animation → Blending → IK → Final Pose

Most bugs come from:
- Animation not matching gameplay state  
- Systems running out of sync  
- Mixing root motion and code-driven motion incorrectly  
- Lack of coordination between animation and physics  
