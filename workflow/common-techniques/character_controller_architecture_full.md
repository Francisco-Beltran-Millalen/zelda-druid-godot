# 🧍 4. Character Controller Architecture

## 📌 Scope

How you structure player/NPC movement systems

### Includes:
- Kinematic vs rigidbody controllers  
- State machines (idle/run/jump)  
- Input abstraction  
- Motion composition  

---

## ❗ Why separate

This is design architecture, not a specific mechanic.

You are deciding:
"How do all systems connect and flow together?"

NOT:
"How does jumping work?"

---

## 🔍 Typical sub-problems

- Mixing physics and control  
- State explosion  
- Reusable controllers  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

A character controller is a pipeline of decisions → motion → correction

That means:
- Input → Intent → State → Movement → Collision → Adjustment  
- Systems must be decoupled but coordinated  
- Architecture defines maintainability and scalability  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild / Tears of the Kingdom | 3D | Hierarchical state machine (normal/climb/swim/combat/glide), input abstraction |
| Metroid Dread | 2D | Mode-based controller swap (standard/morph ball), modular ability states |

---

# 🧱 PROBLEM SET

---

# 1. Kinematic vs Rigidbody Controllers

## 🎯 Goal
Choose how movement is fundamentally driven

---

## 🛠️ Techniques

### A. Kinematic Controller
```pseudo
velocity = compute_velocity(input)
position += velocity * delta
resolve_collisions()
```

---

### B. Rigidbody Controller
```pseudo
apply_force(input_force)
physics_engine_simulates()
```

---

### C. Hybrid Controller
```pseudo
velocity = controlled_input + physics_velocity
apply_constraints()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Kinematic | Full control, predictable | Must implement everything |
| Rigidbody | Realistic, built-in physics | Hard to control precisely |
| Hybrid | Flexible | Complex, easy to break |

---

## 💥 Failure Cases

- Rigidbody: uncontrollable bouncing  
- Kinematic: unnatural interactions  
- Hybrid: conflicting forces  

---

## 🔗 Composability Notes

- Kinematic pairs well with:
  - custom collision resolution  
  - game feel systems  
- Rigidbody pairs with:
  - physics-heavy gameplay  
- Hybrid requires strict separation of concerns  

---

## 🧩 2D vs 3D

- Same concepts  
- 3D increases instability in rigidbody systems  
- **In Godot 4:** Use `CharacterBody3D` (kinematic) for player characters — `RigidBody3D` is not recommended for player control due to imprecise physics interactions

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link uses a kinematic controller for all ground movement, swimming, climbing, and combat — the engine never delegates motion to physics simulation for the player character. Physics applies only to props and ragdolls. This is a deliberate game feel choice: kinematic gives designers precise control over Link's responsiveness without fighting simulation forces. The Climbing mechanic (which could be rigidbody) is entirely code-driven: a custom gravity vector plus per-frame raycast surface queries.  
**Metroid Dread:** Samus is also kinematic. The Morph Ball is a second kinematic configuration (spherical collision shape, different gravity, different movement constants) rather than a different physics body type. Switching between Samus and Morph Ball is a state transition, not a physics body swap.

### 🟦 Godot 4.x
**Node/API:** `CharacterBody3D` for all player/NPC characters — kinematic by default, full control
```gdscript
# CharacterBody3D is the standard for player controllers in Godot 4.
# RigidBody3D is for physics props only.
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_speed: float = 10.0
@export var gravity: float = 30.0

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var move_dir: Vector3 = (basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
    velocity.x = move_dir.x * speed
    velocity.z = move_dir.z * speed

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_speed

    move_and_slide()
```
**Pitfalls:**
- `RigidBody3D` for player characters causes precision loss, uncontrollable bouncing on slopes, and multiplayer prediction problems. Use `CharacterBody3D` exclusively for controllable characters.
- Mixing `RigidBody3D` and `CharacterBody3D` for the same entity (hybrid approach) is fragile in Godot 4 — if you need physics interactions (e.g., the player can push boxes), use `move_and_collide()` and apply impulses to adjacent `RigidBody3D` objects manually.

---

# 2. State Machines (Movement States)

## 🎯 Goal
Control behavior based on current state

---

## 🛠️ Techniques

### A. Finite State Machine (FSM)
```pseudo
state = IDLE

if input.move:
    state = RUN
if input.jump:
    state = JUMP
```

---

### B. Hierarchical State Machine
```pseudo
state = GROUND
substate = RUN
```

---

### C. Data-driven States
```pseudo
state = config[current_state]
execute(state.logic)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| FSM | Simple | State explosion |
| Hierarchical | Scalable | More complex |
| Data-driven | Flexible | Harder to debug |

---

## 💥 Failure Cases

- State explosion (too many states)  
- Invalid transitions  
- Hidden coupling between states  

---

## 🔗 Composability Notes

- Drives:
  - animation  
  - movement logic  
- Must remain independent from:
  - physics system  
- Often combined with:
  - event systems  

---

## 🧩 2D vs 3D

- Same structure  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link has a hierarchical state machine — a top-level "locomotion mode" (ground/swim/climb/glide/combat/cutscene) with sub-states within each. The transition graph is carefully curated: not every state can transition to every other. For example, climbing → combat is only possible via a wall-jump-to-attack chain; you can't directly switch. This gate design prevents animation and physics conflicts by ensuring only valid transitions occur. TotK expanded this with Ascend and Ultrahand as additional locomotion modes using the same hierarchical framework.

### 🟦 Godot 4.x
**Node/API:** Resource-based `State` pattern — each state is a `Resource` or inner class with `enter()`, `exit()`, `update()` methods
```gdscript
# state.gd (base class)
class_name CharacterState
extends Resource

func enter(_character: CharacterBody3D) -> void:
    pass

func exit(_character: CharacterBody3D) -> void:
    pass

func update(_character: CharacterBody3D, _delta: float) -> CharacterState:
    return self  # return a different state to transition

# state_machine.gd (on the CharacterBody3D)
extends CharacterBody3D

@export var initial_state: CharacterState

var _current_state: CharacterState

func _ready() -> void:
    _current_state = initial_state
    _current_state.enter(self)

func _physics_process(delta: float) -> void:
    var next_state: CharacterState = _current_state.update(self, delta)
    if next_state != _current_state:
        _current_state.exit(self)
        _current_state = next_state
        _current_state.enter(self)
```
**Pitfalls:**
- Avoid `match` / `if-else` chains for states in the same script — they become unmanageable past 3–4 states. Use the Resource pattern above from the start.
- States should NOT reach into each other or the controller directly. Pass the `CharacterBody3D` reference in, and let the state read/write only via defined methods.

---

# 3. Input Abstraction

## 🎯 Goal
Decouple input source from movement logic

---

## 🛠️ Techniques

### A. Input Mapping
```pseudo
move = get_input("move_axis")
jump = get_input("jump")
```

---

### B. Command Pattern
```pseudo
command = input_to_command(input)
execute(command)
```

---

### C. Intent System
```pseudo
intent.direction = input_vector
intent.jump = pressed
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Mapping | Simple | Limited flexibility |
| Command | Decoupled | More boilerplate |
| Intent | Clean design | Requires structure |

---

## 💥 Failure Cases

- Input tied directly to movement  
- Hardcoded controls  
- Multiplayer input conflicts  

---

## 🔗 Composability Notes

- Feeds:
  - state machine  
  - movement system  
- Enables:
  - AI reuse  
  - network input  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Context-sensitive inputs — the A button does different things depending on the current locomotion mode: jump (ground), grab (climbing), dive (swimming), open (interact). The input isn't wired to specific actions; it's wired to the current state's "primary action slot." This is a context-mapping pattern: input abstraction + state machine together route the same button to different behavior, eliminating "wrong button" confusion while keeping the control scheme simple.

### 🟦 Godot 4.x
**Node/API:** `PlayerInput` child node (this project's Composition Pattern) — character controller never reads `Input` directly
```gdscript
# player_input.gd — child node of CharacterBody3D
class_name PlayerInput
extends Node

@export var jump_buffer_time: float = 0.12

var move_direction: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_buffered: bool = false

var _jump_buffer_timer: float = 0.0

func _process(delta: float) -> void:
    move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    jump_pressed = Input.is_action_just_pressed("jump")

    if jump_pressed:
        _jump_buffer_timer = jump_buffer_time
    if _jump_buffer_timer > 0.0:
        _jump_buffer_timer -= delta
        jump_buffered = true
    else:
        jump_buffered = false

# character_body.gd reads from PlayerInput only:
# @onready var player_input: PlayerInput = $PlayerInput
# velocity.x = player_input.move_direction.x * speed
```
**Pitfalls:**
- Character scripts that read `Input` directly cannot be driven by AI or replayed via network — always route through the `PlayerInput` child node.
- `PlayerInput` should also work for AI-controlled characters: an AI controller sets `move_direction` and `jump_pressed` the same way the hardware input does, enabling identical behavior.

---

# 4. Motion Composition

## 🎯 Goal
Combine multiple motion influences into one result

---

## 🛠️ Techniques

### A. Additive Composition
```pseudo
velocity = base + jump + external_forces
```

---

### B. Priority-based Composition
```pseudo
if stunned:
    velocity = stun_motion
else:
    velocity = player_motion
```

---

### C. Layered Motion
```pseudo
velocity = combine_layers([
    input_layer,
    physics_layer,
    animation_layer
])
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Additive | Simple | Can conflict |
| Priority | Clear control | Less flexible |
| Layered | Scalable | Complex |

---

## 💥 Failure Cases

- Forces cancel each other  
- Unexpected overrides  
- Hard-to-debug interactions  

---

## 🔗 Composability Notes

- Central to controller design  
- Must integrate with:
  - physics  
  - animation  
- Needs clear priority rules  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Link's velocity is composed additively: base horizontal movement + gravity + knockback + wind + conveyor forces. Each source writes to its own velocity component. The composition rule is additive for all effects except knockback — knockback uses priority composition (it overrides input velocity completely during the stun duration). This "additive except for overrides" pattern keeps most interactions predictable while allowing special cases to take full control.

### 🟦 Godot 4.x
**Node/API:** Additive velocity composition in `_physics_process` — separate components per concern
```gdscript
extends CharacterBody3D

# Velocity components — each system writes its own component
var _movement_velocity: Vector3 = Vector3.ZERO  # from input/state
var _external_velocity: Vector3 = Vector3.ZERO  # knockback, wind, conveyor
var _gravity_velocity: Vector3 = Vector3.ZERO

@export var gravity: float = 30.0
@export var external_decay: float = 10.0  # external forces fade over time

func _physics_process(delta: float) -> void:
    # Gravity
    if not is_on_floor():
        _gravity_velocity.y -= gravity * delta
    else:
        _gravity_velocity.y = 0.0

    # Decay external forces
    _external_velocity = _external_velocity.move_toward(Vector3.ZERO, external_decay * delta)

    # Compose final velocity
    velocity = _movement_velocity + _gravity_velocity + _external_velocity
    move_and_slide()

func apply_knockback(force: Vector3) -> void:
    _external_velocity = force  # priority override of external component
```
**Pitfalls:**
- Writing directly to `velocity` from multiple systems causes ordering-dependent bugs — use separate component variables and compose once per frame.
- `_external_velocity` should decay using `move_toward()` not `*= 0.9` — the latter is frame-rate dependent.

---

# 5. Separation of Concerns

## 🎯 Goal
Avoid tightly coupled systems

---

## 🛠️ Techniques

### A. System Separation
```pseudo
input → intent → movement → physics → animation
```

---

### B. Data-oriented Design
```pseudo
components = [position, velocity, state]
systems_update(components)
```

---

### C. Event-driven Architecture
```pseudo
emit("jump_started")
on_event("jump_started", handler)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Separation | Maintainable | More structure |
| Data-oriented | Scalable | Harder to learn |
| Event-driven | Decoupled | Debug complexity |

---

## 💥 Failure Cases

- Spaghetti dependencies  
- Hidden side effects  
- Systems tightly coupled  

---

## 🔗 Composability Notes

- Foundation for:
  - reusable controllers  
  - multiplayer  
- Enables testing and iteration  

---

## 🧩 2D vs 3D

- Same architecture  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Each major system (movement, combat, inventory, quest) communicates via events rather than direct calls. The combat system doesn't "know about" the stamina system — when a spin attack is initiated, it emits a "stamina consumed" event and the stamina system responds. This is why the game can layer systems like temperature (reduces stamina recovery) onto base mechanics without the temperature system needing any combat code. The separation is what makes the emergent gameplay possible.

### 🟦 Godot 4.x
**Node/API:** Typed signals for all cross-node communication; Autoload event bus for global events
```gdscript
# character.gd — defines typed signals instead of direct calls
extends CharacterBody3D

signal health_changed(new_health: int, delta: int)
signal state_changed(new_state: CharacterState)
signal died()

var health: int = 100 :
    set(value):
        var delta: int = value - health
        health = value
        health_changed.emit(health, delta)
        if health <= 0:
            died.emit()

# Another system connects to these signals — never calls health directly:
# character.health_changed.connect(_on_health_changed)
```
**Pitfalls:**
- "Godot Composition Rule": if a script would reference a sibling or parent node by path (`get_node("../../UI/HealthBar")`), that's a violation — communicate via signals or Autoload instead.
- Autoload singletons are appropriate for truly global events (game paused, level loaded). Per-character events should be typed signals on the character, not routed through an Autoload.

---

# 6. Reusable Controller Design

## 🎯 Goal
Create controllers that work across multiple characters

---

## 🛠️ Techniques

### A. Parameterized Controllers
```pseudo
speed = config.speed
jump_force = config.jump_force
```

---

### B. Modular Components
```pseudo
controller = [movement_module, jump_module, climb_module]
```

---

### C. Behavior Composition
```pseudo
abilities = [run, jump, dash]
apply(abilities)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Parameterized | Easy reuse | Limited flexibility |
| Modular | Flexible | Integration complexity |
| Behavior-based | Scalable | Hard to debug |

---

## 💥 Failure Cases

- Over-generalization  
- Too many configuration options  
- Inconsistent behavior across entities  

---

## 🔗 Composability Notes

- Depends on:
  - separation of concerns  
- Interacts with:
  - state machines  
  - motion composition  

---

## 🧩 2D vs 3D

- Same design  

---

### 🎮 Nintendo Reference
**Metroid Dread:** All enemies and bosses share the same base entity framework as Samus — they all have CharacterController, StateMachine, HitboxComponent, and AnimationController components, with different configurations and state implementations. Boss EMMI robots have the same architecture as regular enemies; what makes them different is their state machine logic and ability set, not a special code path. This shared architecture is why new enemy types can be added without touching core systems.

### 🟦 Godot 4.x
**Node/API:** `@export var` for all tunables, shared base scene with overridable child nodes
```gdscript
# character_base.gd — shared by player, enemies, NPCs
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var jump_speed: float = 10.0
@export var gravity: float = 30.0
@export var initial_state: CharacterState  # swap this per character type

@onready var state_machine: Node = $StateMachine
@onready var hitbox: Area3D = $HitboxComponent

# Enemies use the same script with different @export values and initial_state
# No code change needed for new character types — only data
```
**Pitfalls:**
- Export all tunable values with `@export var` — never hardcode movement constants. A character's "speed = 5.0" must be visible in the Inspector so designers can tune without touching code.
- Avoid "base class with giant conditional" design. Use composition (different `initial_state`, different child nodes) to create variation, not `if entity_type == PLAYER`.

---

# 🧠 FINAL INSIGHT

A character controller is not a single system—it is an architecture:

Input → Intent → State → Motion → Collision → Resolution → Final Transform

Most bugs come from:
- Systems doing too many things  
- Poor separation of concerns  
- Conflicting motion sources  
- State mismanagement  
