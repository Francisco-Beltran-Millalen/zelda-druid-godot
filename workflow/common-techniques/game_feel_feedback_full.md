# 💥 8. Game Feel & Feedback

## 📌 Scope

How the game feels to the player through feedback and responsiveness

### Includes:
- Screen shake  
- Hit stop (freeze frames)  
- Particles, sound, visual feedback  
- Camera feedback  

---

## 🔍 Typical sub-problems

- Game feels "floaty"  
- Lack of responsiveness  
- Weak or unclear feedback  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Game feel is about perception, not simulation

That means:
- Exaggeration is good  
- Feedback must be immediate and readable  
- Multiple systems must reinforce the same action  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| Metroid Dread | 2D | Hit stop, screen flash, death explosion, i-frame visual flash, tight feedback timing |
| The Legend of Zelda: Breath of the Wild | 3D | Environmental audio response, hit freeze, contextual rumble, particle + sound layering |

---

# 🧱 PROBLEM SET

---

# 1. Input Responsiveness Enhancers

## 🎯 Goal
Make actions feel immediate and forgiving

---

## 🛠️ Techniques

### A. Coyote Time
```pseudo
if time_since_ground < threshold:
    allow_jump()
```

---

### B. Input Buffering
```pseudo
if jump_pressed_recently:
    execute_jump()
```

---

### C. Early/Late Input Windows
```pseudo
if input_within_window:
    accept_action()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Coyote | Forgiving | Less realistic |
| Buffering | Prevents misses | Hidden logic |
| Input Windows | Smooth timing | Needs tuning |

---

## 💥 Failure Cases

- Over-forgiveness → imprecise feel  
- Conflicting buffered actions  
- Unpredictable timing  

---

## 🔗 Composability Notes

- Works with:
  - input system  
  - movement system  
- Must align with:
  - animation timing  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Three forgiveness systems work together: (1) coyote time (~5 frames) for walk-off jumps, (2) jump buffer (~8 frames) for pre-landing jumps, (3) the ledge "magnet" that auto-corrects landing position within ~4 pixels. None of these is visible to the player — they create the feeling that "the game understood what I meant." The precision challenge comes from enemy patterns and obstacles, not from fighting the input system. This is the core philosophy: forgiveness systems should be invisible; difficulty should come from design, not input noise.

### 🟦 Godot 4.x
**Node/API:** Timer variables in `PlayerInput` or `CharacterBody2D` — see movement_locomotion_full.md for full coyote + buffer implementation
```gdscript
# Quick reference — full implementation in movement_locomotion_full.md
extends CharacterBody2D

@export var coyote_time: float = 0.083   # 5 frames at 60fps
@export var jump_buffer_time: float = 0.133  # 8 frames

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

func _physics_process(delta: float) -> void:
    _coyote_timer = coyote_time if is_on_floor() else max(0.0, _coyote_timer - delta)
    _jump_buffer_timer = max(0.0, _jump_buffer_timer - delta)

    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = jump_buffer_time

    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        velocity.y = -jump_speed  # Y is down in 2D
        _coyote_timer = 0.0
        _jump_buffer_timer = 0.0

    move_and_slide()
```
**Pitfalls:**
- Coyote timer must be reset to 0 when a jump is executed — otherwise the player gets a second coyote jump from the first airborne frame.
- Don't apply coyote time if the player jumped off the ledge deliberately (velocity.y < 0 already) — gate it on the player not having initiated a jump.

---

# 2. Hit Stop (Impact Freeze)

## 🎯 Goal
Emphasize impact by briefly pausing the game

---

## 🛠️ Techniques

### A. Global Time Freeze
```pseudo
time_scale = 0
wait(duration)
time_scale = 1
```

---

### B. Localized Freeze
```pseudo
freeze(attacker, duration)
freeze(target, duration)
```

---

### C. Scaled Slow Motion
```pseudo
time_scale = 0.1
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Global Freeze | Strong impact | Affects entire game |
| Local Freeze | Targeted | More complex |
| Slow Motion | Cinematic | Less punchy |

---

## 💥 Failure Cases

- Overuse → annoying feel  
- Breaking physics systems  
- Desync in multiplayer  

---

## 🔗 Composability Notes

- Works with:
  - animation events  
  - combat systems  
- Must not break:
  - physics updates  
  - input timing  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Hit stop is localized — only Samus and the hit enemy freeze for 2–5 frames (depending on hit intensity), while the background and other enemies continue. This is more technically complex than global time scale but avoids the "entire game stutters" feel of global freeze. Counter kills (parry + follow-up) use a slightly longer freeze (6–8 frames) to reward the player. The freeze duration scales with the "importance" of the hit, creating a tactile hierarchy: normal hit < heavy hit < counter kill < boss phase end.

### 🟦 Godot 4.x
**Node/API:** `Engine.time_scale` for global (simple); per-node `process_mode` for localized freeze
```gdscript
# Option A: Global hit stop (simple, good for most cases)
extends Node

func trigger_hit_stop(duration: float) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
    # Note: create_timer(duration, process_always=true) ignores time_scale

# Option B: Localized freeze (attacker + target only)
# On the CharacterBody being frozen:
func freeze_for(duration_seconds: float) -> void:
    process_mode = Node.PROCESS_MODE_DISABLED  # stops _process and _physics_process
    await get_tree().create_timer(duration_seconds, true).timeout  # runs on real time
    process_mode = Node.PROCESS_MODE_INHERIT
```
**Pitfalls:**
- `Engine.time_scale = 0` also freezes `Tween` and `Timer` unless they use `process_always = true`. Always create the resume timer with `process_always = true` (3rd parameter of `create_timer`).
- Localized freeze via `PROCESS_MODE_DISABLED` stops ALL processing including signals — if the frozen node needs to receive a signal during the freeze, handle it in the parent or an external manager.

---

# 3. Screen Shake

## 🎯 Goal
Enhance impact and intensity visually

---

## 🛠️ Techniques

### A. Random Offset Shake
```pseudo
camera.position += random_offset(intensity)
```

---

### B. Noise-based Shake
```pseudo
offset = noise(time) * intensity
```

---

### C. Directional Shake
```pseudo
shake_direction = normalize(hit_direction)
camera += shake_direction * intensity
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Random | Simple | Chaotic |
| Noise | Smooth | Needs tuning |
| Directional | Informative | More logic |

---

## 💥 Failure Cases

- Motion sickness  
- Too much shake → loss of clarity  
- Inconsistent intensity  

---

## 🔗 Composability Notes

- Works with:
  - camera system  
  - combat feedback  
- Should scale with:
  - event importance  

---

## 🧩 2D vs 3D

- Same idea  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Shake uses the trauma model — a "trauma" value is added per impact (0.0–1.0), and it decays over time. Shake intensity is `trauma²` (quadratic decay), meaning strong impacts shake hard at first and taper quickly. Shake is Perlin noise-based (not random) so motion is smooth rather than jerky. The controller rumble is synced to the shake intensity, creating multi-channel reinforcement. A key detail: shake never exceeds a maximum offset that would push the player out of the visible gameplay area.

### 🟦 Godot 4.x
**Node/API:** `Camera3D` or `Camera2D` offset + `FastNoiseLite` for Perlin-based shake
```gdscript
extends Camera3D

@export var trauma_decay: float = 1.5
@export var max_shake_offset: float = 0.15
@export var max_shake_rotation: float = 3.0

var _trauma: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _noise_time: float = 0.0

func _ready() -> void:
    _noise.noise_type = FastNoiseLite.TYPE_PERLIN
    _noise.seed = randi()

func add_trauma(amount: float) -> void:
    _trauma = min(_trauma + amount, 1.0)

func _process(delta: float) -> void:
    _trauma = max(_trauma - trauma_decay * delta, 0.0)
    var shake: float = _trauma * _trauma  # quadratic

    _noise_time += delta * 40.0
    h_offset = max_shake_offset * shake * _noise.get_noise_1d(_noise_time)
    v_offset = max_shake_offset * shake * _noise.get_noise_1d(_noise_time + 100.0)
    rotation_degrees.z = max_shake_rotation * shake * _noise.get_noise_1d(_noise_time + 200.0)
```
**Pitfalls:**
- Add an accessibility option to reduce or disable screen shake — motion sensitivity is common and forced shake is a hard blocker for some players.
- `h_offset` / `v_offset` on `Camera3D` only affect the render target position, not the world position — this is correct for shake (don't move the camera node itself).

---

# 4. Visual Feedback (Particles & Effects)

## 🎯 Goal
Provide immediate visual confirmation of actions

---

## 🛠️ Techniques

### A. Particle Effects
```pseudo
spawn_particles(hit_position)
```

---

### B. Flash / Color Feedback
```pseudo
sprite.color = flash_color
```

---

### C. Trails & Motion Effects
```pseudo
enable_trail(effect)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Particles | Expressive | Performance cost |
| Flash | Clear | Can be overused |
| Trails | Dynamic | Visual clutter |

---

## 💥 Failure Cases

- Too many effects → noise  
- Poor readability  
- Performance drops  

---

## 🔗 Composability Notes

- Must align with:
  - gameplay events  
  - animation timing  
- Combine with:
  - sound  
  - camera effects  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Damage feedback uses a 3-layer visual response: (1) brief white flash on the hurtbox (2 frames), (2) a color shift toward red proportional to remaining health, (3) particle burst at the impact point. Each layer reads at a different distance — the flash is readable from far, the color shift communicates health state at mid-range, and the particles show exact impact location up close. This "readability at multiple distances" is a key principle: don't rely on one effect to communicate everything.

### 🟦 Godot 4.x
**Node/API:** `GPUParticles2D` / `GPUParticles3D` for bursts; `ShaderMaterial` for flashes; `Tween` for color changes
```gdscript
extends CharacterBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var hit_particles: GPUParticles3D = $HitParticles

@export var flash_duration: float = 0.05
@export var flash_color: Color = Color.WHITE

func flash_damage(hit_position: Vector3) -> void:
    # 1. White flash via shader parameter
    var mat: ShaderMaterial = mesh_instance.material_override as ShaderMaterial
    if mat:
        mat.set_shader_parameter("flash_intensity", 1.0)
        var tween: Tween = create_tween()
        tween.tween_method(
            func(v: float) -> void: mat.set_shader_parameter("flash_intensity", v),
            1.0, 0.0, flash_duration
        )

    # 2. Particles at hit position
    hit_particles.global_position = hit_position
    hit_particles.restart()
    hit_particles.emitting = true
```
**Pitfalls:**
- `GPUParticles3D.emitting = true` restarts emission each time it's set — for burst effects, use `restart()` followed by `emitting = true` to ensure a clean burst each call.
- Performance: pooling `GPUParticles3D` nodes (pre-instantiated, enabled/disabled on demand) is significantly cheaper than instancing/freeing them at runtime.

---

# 5. Audio Feedback

## 🎯 Goal
Reinforce actions through sound

---

## 🛠️ Techniques

### A. One-shot Sounds
```pseudo
play_sound("jump")
```

---

### B. Layered Audio
```pseudo
play_sound("impact")
play_sound("crunch")
```

---

### C. Contextual Audio
```pseudo
if surface == METAL:
    play_sound("metal_step")
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| One-shot | Simple | Repetitive |
| Layered | Rich | Needs balancing |
| Contextual | Immersive | More data |

---

## 💥 Failure Cases

- Audio spam  
- Repetition fatigue  
- Mismatch with visuals  

---

## 🔗 Composability Notes

- Must sync with:
  - animation  
  - events  
- Works with:
  - particles  
  - camera feedback  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Footstep audio is contextual — each surface material (grass, stone, wood, water, snow) has its own footstep sound pool. The step sound plays on the animation "foot down" event. Critically, the game randomizes from a pool of 4–6 variations per surface material with pitch randomization (±5%), preventing the "same sound every step" repetition fatigue. The pitch and volume also scale slightly with Link's movement speed, so running sounds more urgent than walking even using the same sound pool.

### 🟦 Godot 4.x
**Node/API:** `AudioStreamPlayer2D` / `AudioStreamPlayer3D` with `AudioStreamRandomizer` for variation
```gdscript
extends Node3D

@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer

@export var footstep_grass: AudioStreamRandomizer
@export var footstep_stone: AudioStreamRandomizer
@export var pitch_variance: float = 0.05

func play_footstep(surface_type: StringName) -> void:
    var stream: AudioStreamRandomizer = _get_stream_for_surface(surface_type)
    if stream:
        footstep_player.stream = stream
        footstep_player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
        footstep_player.play()

func _get_stream_for_surface(surface: StringName) -> AudioStreamRandomizer:
    match surface:
        &"grass": return footstep_grass
        &"stone": return footstep_stone
        _: return footstep_grass
```
**Pitfalls:**
- `AudioStreamRandomizer` (Godot 4.2+) handles random selection from a pool internally — use it instead of manually picking random streams.
- 3D `AudioStreamPlayer3D` attenuates by distance automatically — set `max_distance` to ~10m for footsteps so they don't travel unrealistically far.

---

# 6. Camera Feedback

## 🎯 Goal
Use camera movement to reinforce gameplay

---

## 🛠️ Techniques

### A. Follow Smoothing
```pseudo
camera.position = lerp(camera.position, target, smooth_factor)
```

---

### B. Look-ahead Camera
```pseudo
camera.offset = velocity * lookahead_factor
```

---

### C. Dynamic Framing
```pseudo
adjust_camera_zoom(context)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Smoothing | Stable | Can feel laggy |
| Look-ahead | Predictive | Can overshoot |
| Dynamic | Cinematic | Complex |

---

## 💥 Failure Cases

- Camera lag  
- Overcorrection  
- Motion sickness  

---

## 🔗 Composability Notes

- Works with:
  - movement system  
  - navigation  
- Must not interfere with:
  - player control  

---

## 🧩 2D vs 3D

- 3D requires more careful control  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Camera feedback serves two roles: (1) minor forward lean during sprinting (look-ahead offset of ~15% of run speed), creating urgency, and (2) a brief zoom-out on large hits (landing from height, explosion nearby) that widens the FOV by ~5° for ~0.3s, then returns. The zoom-out provides spatial context at the moment of disorientation. The implementation is subtle enough that most players don't consciously notice it — it just makes landings feel more impactful without feeling like a "camera trick."

### 🟦 Godot 4.x
**Node/API:** `Camera3D` with `fov` animation via `Tween`; `Camera2D` with `offset` and `zoom`
```gdscript
extends Camera3D

@export var base_fov: float = 70.0
@export var sprint_fov: float = 75.0
@export var impact_fov: float = 65.0  # slight zoom-in on land
@export var fov_smooth_speed: float = 8.0

var _target_fov: float = 70.0

func _process(delta: float) -> void:
    fov = lerp(fov, _target_fov, fov_smooth_speed * delta)

func set_sprinting(is_sprinting: bool) -> void:
    _target_fov = sprint_fov if is_sprinting else base_fov

func trigger_impact_zoom(duration: float) -> void:
    _target_fov = impact_fov
    await get_tree().create_timer(duration).timeout
    _target_fov = base_fov
```
**Pitfalls:**
- FOV changes for feel should be subtle (±5°) — large FOV changes (±20°+) cause motion sickness and are immediately noticeable as a "camera trick."
- Smoothing `fov` with `lerp` is frame-rate dependent — use `lerp(fov, target, 1.0 - exp(-speed * delta))` for frame-rate independent exponential smoothing.

---

# 7. Feedback Timing & Layering

## 🎯 Goal
Coordinate multiple feedback systems

---

## 🛠️ Techniques

### A. Event-driven Feedback
```pseudo
on_hit():
    trigger_effects()
```

---

### B. Layered Feedback
```pseudo
play_sound()
spawn_particles()
apply_shake()
```

---

### C. Priority-based Feedback
```pseudo
if strong_hit:
    use_strong_feedback()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Event-driven | Clean | Needs coordination |
| Layered | Rich | Can overload |
| Priority | Clear | Requires tuning |

---

## 💥 Failure Cases

- Too many effects at once  
- Conflicting feedback signals  
- Weak important events  

---

## 🔗 Composability Notes

- Must align across:
  - animation  
  - input  
  - gameplay  
- Feedback should reinforce:
  - player intent  
  - game state  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Every significant event triggers layered feedback across 4 channels simultaneously: hit stop (gameplay time), screen flash (visual), impact sound (audio), and controller rumble (haptic). The timing contract is strict: all 4 must fire within 1 frame of each other, or the player perceives them as "lagging." Boss defeat sequences add a 5th channel: sustained slow-motion (0.3× time scale) that gives the player a moment to appreciate the moment before the cutscene. This "moment of satisfaction" design is intentional — feedback isn't just informational, it's emotional.

### 🟦 Godot 4.x
**Node/API:** Autoload event bus (`FeedbackEvents.gd`) + separate feedback handler nodes
```gdscript
# feedback_events.gd (Autoload)
extends Node

signal hit(position: Vector3, intensity: float)
signal player_died()
signal boss_phase_ended(boss: Node3D)

# feedback_handler.gd (in scene — listens to events, coordinates feedback)
extends Node

@onready var screen_shake: Camera3D = %MainCamera
@onready var audio_player: AudioStreamPlayer = $HitAudio

func _ready() -> void:
    FeedbackEvents.hit.connect(_on_hit)

func _on_hit(position: Vector3, intensity: float) -> void:
    # All feedback triggers in the same frame
    screen_shake.add_trauma(intensity * 0.3)           # 1. camera shake
    audio_player.pitch_scale = 1.0 + (intensity - 1.0) * 0.1
    audio_player.play()                                 # 2. sound
    Input.vibrate_handheld(int(intensity * 50), int(intensity * 80))  # 3. rumble
    # hit stop is triggered on the specific CharacterBody directly
```
**Pitfalls:**
- Coordinate all feedback through a single event (`FeedbackEvents.hit.emit()`) rather than calling each system individually from the gameplay code — this keeps gameplay logic clean and lets feedback systems be added/removed without touching game logic.
- `Input.vibrate_handheld()` only works on mobile/controllers; on desktop it silently does nothing — no guard needed.

---

# 🧠 FINAL INSIGHT

Game feel is a feedback loop:

Input → Action → Feedback → Player Perception → Next Input

Most bugs come from:
- Lack of feedback  
- Delayed feedback  
- Overloading the player with effects  
- Systems not reinforcing each other  
