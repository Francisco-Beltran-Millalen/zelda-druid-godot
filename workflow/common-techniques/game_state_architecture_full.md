# 🧩 11. Game State & Architecture

## 📌 Scope

How all systems are structured, connected, and managed

### Includes:
- Game states (menu, gameplay, pause)  
- Scene/entity architecture  
- System communication  
- Data flow  

---

## 🔍 Typical sub-problems

- Spaghetti code  
- Tight coupling between systems  
- Hard-to-debug interactions  
- Scaling complexity  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Architecture defines how everything evolves over time

That means:
- Systems must be decoupled but coordinated  
- Data flow must be clear and predictable  
- Structure must support growth and iteration  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| Fire Emblem: Three Houses | Strategy | Turn-phase state machine, combat resolution states, unit/map data flow |
| The Legend of Zelda: Breath of the Wild | 3D | Exploration/combat/puzzle/cutscene state switching, event-driven architecture, modular system design |

---

# 🧱 PROBLEM SET

---

# 1. Game State Management

## 🎯 Goal
Control global game modes

---

## 🛠️ Techniques

### A. Simple State Switch
```pseudo
state = MENU

if start_game:
    state = GAMEPLAY
```

---

### B. State Stack
```pseudo
push_state(PAUSE)
pop_state()
```

---

### C. State Objects
```pseudo
state.update()
state.render()
state.handle_input()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Switch | Simple | Limited |
| Stack | Flexible | More complexity |
| Objects | Scalable | Boilerplate |

---

## 💥 Failure Cases

- State leaks (menu logic in gameplay)  
- Invalid transitions  
- Hidden dependencies  

---

## 🔗 Composability Notes

- Controls:
  - input handling  
  - UI  
  - gameplay systems  
- Must isolate systems per state  

---

## 🧩 2D vs 3D

- Same architecture  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** The game uses a strict turn-phase machine with 5 phases: Player Phase → Enemy Phase → Ally Phase → Environmental Phase → End of Turn. Each phase has its own valid actions — during Enemy Phase, the player cannot input unit commands. The state machine explicitly blocks input at the engine level during non-player phases rather than relying on each system to check "is it my turn?" This "input gating at the state level" is cleaner than per-system turn checks scattered throughout the code.

### 🟦 Godot 4.x
**Node/API:** Autoload singleton for global state + `SceneTree.change_scene_to_file()` for scene transitions
```gdscript
# game_state_manager.gd (Autoload)
class_name GameStateManager
extends Node

enum State { MAIN_MENU, GAMEPLAY, PAUSED, GAME_OVER, CUTSCENE }

signal state_changed(new_state: State)

var current_state: State = State.MAIN_MENU :
    set(value):
        if value == current_state:
            return
        current_state = value
        state_changed.emit(current_state)
        _on_state_changed(current_state)

func _on_state_changed(new_state: State) -> void:
    match new_state:
        State.PAUSED:
            get_tree().paused = true
        State.GAMEPLAY:
            get_tree().paused = false
        State.MAIN_MENU:
            get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func enter_gameplay() -> void:
    current_state = State.GAMEPLAY

func pause() -> void:
    if current_state == State.GAMEPLAY:
        current_state = State.PAUSED
```
**Pitfalls:**
- `get_tree().paused = true` pauses ALL nodes unless they have `process_mode = PROCESS_MODE_ALWAYS` — ensure UI nodes (pause menu, health bar) use `PROCESS_MODE_ALWAYS` so they continue to function while paused.
- Avoid storing scene references or node pointers in the Autoload across scene changes — nodes are freed when the scene changes, leaving the Autoload with dangling references.

---

# 2. Scene / Entity Architecture

## 🎯 Goal
Organize game objects and their behavior

---

## 🛠️ Techniques

### A. Object-Oriented (OOP)
```pseudo
class Player:
    update()
    move()
```

---

### B. Component-based Architecture
```pseudo
entity = [Transform, Physics, Render]
```

---

### C. Entity Component System (ECS)
```pseudo
systems_update(components)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| OOP | Simple | Tight coupling |
| Component | Flexible | Medium complexity |
| ECS | Scalable | Harder to learn |

---

## 💥 Failure Cases

- God objects  
- Duplicate logic  
- Hard dependencies  

---

## 🔗 Composability Notes

- ECS pairs well with:
  - large-scale systems  
- Component systems integrate with:
  - animation  
  - physics  
  - AI  

---

## 🧩 2D vs 3D

- Same structure  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Godot's scene/node architecture is essentially Zelda BotW's approach — every entity is a scene tree of specialized nodes. Link is composed of: MovementController (physics), AnimationController, EquipmentManager, StaminaSystem, CameraTarget, and AudioEmitter — each in its own child node. No single script handles everything. New abilities (Paraglider, Magnesis) are added as additional child nodes without modifying existing ones. This "add capabilities via composition, not modification" pattern is what allows TotK to add the Ultrahand and Fuse systems to Link without rewriting the character system.

### 🟦 Godot 4.x
**Node/API:** Godot's node tree IS component-based — use child nodes for each isolatable concern (the Godot Composition Pattern from this project)
```gdscript
# Godot's node tree structure IS the component system:
# Player (CharacterBody3D)
# ├── PlayerInput (Node) — captures and provides input
# ├── StateMachine (Node) — manages behavior states
# ├── StaminaComponent (Node) — tracks and exposes stamina
# ├── HitboxComponent (Area3D) — receives damage
# ├── AnimationController (Node) — drives AnimationTree
# ├── AudioEmitter (Node) — plays contextual sounds
# └── DebugOverlay (Node) — debug visualization (graybox-4 system)

# Each component is a separate script with a single responsibility.
# Components communicate via signals — never via get_parent() or get_node("../")

# stamina_component.gd example:
class_name StaminaComponent
extends Node

signal stamina_changed(current: float, maximum: float)
signal stamina_depleted()

@export var max_stamina: float = 100.0
var current_stamina: float = max_stamina

func consume(amount: float) -> bool:
    if current_stamina < amount:
        return false
    current_stamina -= amount
    stamina_changed.emit(current_stamina, max_stamina)
    if current_stamina <= 0.0:
        stamina_depleted.emit()
    return true
```
**Pitfalls:**
- Godot is NOT an ECS engine — don't try to separate components into pure data structs and separate systems. Use the scene tree (nodes with their own `_process`) for component behavior.
- The "God object" anti-pattern appears when a character's main script does too much — if a script exceeds ~150 lines, check whether some concern can move to a child component node.

---

# 3. System Communication

## 🎯 Goal
Allow systems to interact without tight coupling

---

## 🛠️ Techniques

### A. Direct Calls
```pseudo
player.take_damage()
```

---

### B. Event System
```pseudo
emit("damage_taken")
```

---

### C. Message Bus
```pseudo
send_message("enemy_spotted")
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Direct | Simple | Coupled |
| Events | Decoupled | Harder to trace |
| Message Bus | Scalable | Complex |

---

## 💥 Failure Cases

- Hidden dependencies  
- Event spam  
- Hard-to-debug flow  

---

## 🔗 Composability Notes

- Events are key for:
  - UI  
  - animation  
  - AI  
- Must maintain clear ownership of data  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Communication between systems uses events almost exclusively. The stamina system doesn't "know about" the climbing system — when climbing starts, it emits "stamina_drain_started" and the stamina system responds. When stamina runs out, it emits "stamina_depleted" and the climbing system (listening) detects the fall. Neither system holds a reference to the other. This decoupling is what allows Nintendo to ship patches that change stamina behavior without touching the climbing code, and vice versa.

### 🟦 Godot 4.x
**Node/API:** Typed signals on nodes; Autoload event bus for game-wide events
```gdscript
# event_bus.gd (Autoload — for truly global events only)
class_name EventBus
extends Node

signal game_paused()
signal game_resumed()
signal enemy_killed(enemy: Node3D, position: Vector3)
signal level_completed()

# For character-level events: use typed signals on the character node directly
# (not the Autoload — Autoload is for events that cross scene boundaries)

# Usage example:
# EventBus.enemy_killed.connect(_on_enemy_killed)
# EventBus.enemy_killed.emit(self, global_position)
```
**Pitfalls:**
- Global Autoload event buses become problematic when overused — every system listening to every event is as bad as tight coupling. Use node-local signals for local events, Autoload only for cross-scene global events.
- Typed signals (`signal damage_taken(amount: float, source: Node3D)`) are strongly preferred over untyped signals — they catch type errors at author time and make the contract explicit.

---

# 4. Data Flow Architecture

## 🎯 Goal
Control how data moves through systems

---

## 🛠️ Techniques

### A. Push-based Updates
```pseudo
on_event():
    update_system()
```

---

### B. Pull-based Updates
```pseudo
data = query_system()
```

---

### C. Unidirectional Flow
```pseudo
input → simulation → render
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Push | Reactive | Hard to track |
| Pull | Clear | Less efficient |
| Unidirectional | Predictable | Rigid |

---

## 💥 Failure Cases

- Circular dependencies  
- Data inconsistency  
- Update order bugs  

---

## 🔗 Composability Notes

- Must align with:
  - game loop  
- Critical for:
  - debugging  
  - determinism  

---

## 🧩 2D vs 3D

- Same structure  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Combat resolution uses unidirectional data flow — the combat calculation phase reads unit stats and produces a `CombatResult` data object (damage dealt, hit/miss, kill flag) without modifying any unit. Only the apply phase then modifies unit state based on the `CombatResult`. This clean separation means: (1) the calculation can be previewed before executing (the in-game "battle forecast" screen reads the exact same calculation), (2) the apply phase is deterministic and can be replayed, and (3) combat modifiers can be injected between calculation and application without touching either phase.

### 🟦 Godot 4.x
**Node/API:** `Resource` objects for immutable data transfer; Autoload for shared mutable state
```gdscript
# Immutable combat result — calculated once, applied once
class_name CombatResult
extends Resource

var attacker: Node3D
var defender: Node3D
var damage_dealt: int = 0
var hit: bool = false
var critical: bool = false
var kills: bool = false

# combat_calculator.gd — reads state, returns CombatResult (no side effects)
static func calculate(attacker: Node3D, defender: Node3D, weapon: WeaponData) -> CombatResult:
    var result: CombatResult = CombatResult.new()
    result.attacker = attacker
    result.defender = defender
    result.hit = _roll_hit(attacker, defender, weapon)
    if result.hit:
        result.damage_dealt = _calculate_damage(attacker, defender, weapon)
        result.kills = _check_kill(defender, result.damage_dealt)
    return result

static func _roll_hit(_a: Node3D, _d: Node3D, _w: WeaponData) -> bool:
    return true  # placeholder

static func _calculate_damage(_a: Node3D, _d: Node3D, _w: WeaponData) -> int:
    return 10  # placeholder

static func _check_kill(_d: Node3D, _dmg: int) -> bool:
    return false  # placeholder
```
**Pitfalls:**
- Static calculation functions that return `Resource` objects (not modifying state) enable battle preview features "for free" — always separate calculation from application when the feature requires a preview.
- `Resource` objects are reference-counted in Godot — returning a new `CombatResult` from a calculation function is cheap; don't pool them unless profiling shows a hotspot.

---

# 5. Update Order & Game Loop

## 🎯 Goal
Ensure systems run in correct sequence

---

## 🛠️ Techniques

### A. Fixed Update Loop
```pseudo
while running:
    update()
    render()
```

---

### B. Fixed + Variable Split
```pseudo
physics_update(fixed_dt)
render_update(variable_dt)
```

---

### C. System Ordering
```pseudo
input → AI → movement → physics → animation → render
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Simple Loop | Easy | Less control |
| Fixed Split | Stable physics | More complexity |
| Ordered Systems | Predictable | Needs discipline |

---

## 💥 Failure Cases

- Order-dependent bugs  
- Jitter  
- Desync between systems  

---

## 🔗 Composability Notes

- One of the MOST critical systems  
- Affects:
  - physics  
  - input  
  - animation  
- Must be consistent  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Turn-based but has a strict update order: (1) input phase (player selects action), (2) validation phase (is action legal?), (3) execution phase (apply action), (4) feedback phase (show animations/effects), (5) state update phase (check win/lose conditions, advance turn). These phases are sequential and non-overlapping — you can never be in execution and validation simultaneously. The result is deterministic, replayable gameplay and clean save state (save can only occur between phases, when the game is in a known stable state).

### 🟦 Godot 4.x
**Node/API:** Godot's built-in update order: `_input` → `_process` → `_physics_process` → rendering. Use `call_deferred` for end-of-frame operations.
```gdscript
# Godot's built-in update order (per frame):
# 1. _input(event)       — input events (keyboard, mouse, controller)
# 2. _process(delta)     — game logic (AI, animation, UI)
# 3. _physics_process(delta) — physics, movement, collision
# 4. Rendering

# For systems that must run AFTER all _physics_process() calls:
# Use Node.PROCESS_PRIORITY to order nodes explicitly
# Higher priority = runs first

extends CharacterBody3D

func _ready() -> void:
    process_priority = 10  # runs before nodes with lower priority

# For things that must happen at end of frame (e.g., after all state settles):
func defer_state_check() -> void:
    call_deferred("_check_win_condition")

func _check_win_condition() -> void:
    pass
```
**Pitfalls:**
- `_process` and `_physics_process` run at different rates — never read physics state (`velocity`, `global_position` from physics) in `_process` without accounting for interpolation; use Godot's physics interpolation feature for smooth visuals.
- `Node.process_priority` orders nodes within the same update callback — use it when two nodes both use `_physics_process` and one must read the other's output.

---

# 6. Modularity & Scalability

## 🎯 Goal
Allow the game to grow without breaking

---

## 🛠️ Techniques

### A. Modular Systems
```pseudo
systems = [movement, combat, AI]
```

---

### B. Plugin Architecture
```pseudo
load_module("combat_system")
```

---

### C. Feature Isolation
```pseudo
feature = self-contained_system()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Modular | Clean | Needs discipline |
| Plugin | Flexible | Overhead |
| Isolation | Safe | Duplication risk |

---

## 💥 Failure Cases

- Tight coupling  
- Feature interdependency  
- Hard-to-remove systems  

---

## 🔗 Composability Notes

- Depends on:
  - communication system  
- Enables:
  - rapid iteration  
  - testing  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda TotK:** The new abilities (Ultrahand, Ascend, Fuse, Recall) were added to a game that was essentially Breath of the Wild. The fact that these could be added without rewriting core systems demonstrates BotW's modularity — each new ability is a self-contained system that communicates with the world via the existing event/physics/collision infrastructure. No existing system was modified to accommodate the new abilities; they simply plug into existing hooks. This is the gold standard for game scalability: new features should be additive, not invasive.

### 🟦 Godot 4.x
**Node/API:** Self-contained feature scenes (`.tscn`) loaded on demand; `preload()` + `instantiate()` for dynamic feature loading
```gdscript
# Each major feature lives in its own scene that can be added/removed
# without touching the base character scene.

# ability_manager.gd
class_name AbilityManager
extends Node

@export var ability_scenes: Array[PackedScene] = []  # set in Inspector

var _abilities: Array[Node] = []

func _ready() -> void:
    for scene: PackedScene in ability_scenes:
        var ability: Node = scene.instantiate()
        add_child(ability)
        _abilities.append(ability)

func add_ability(scene: PackedScene) -> void:
    var ability: Node = scene.instantiate()
    add_child(ability)
    _abilities.append(ability)

func remove_ability(ability_name: StringName) -> void:
    for i: int in range(_abilities.size() - 1, -1, -1):
        if _abilities[i].name == ability_name:
            _abilities[i].queue_free()
            _abilities.remove_at(i)
```
**Pitfalls:**
- `preload()` loads the scene at script compile time (adds to load time); `load()` loads on demand. For optional/large feature scenes, use `load()` or `ResourceLoader.load_threaded_request()`.
- Abilities added as child nodes communicate with the parent character via signals — never `get_parent().stamina -= 10`. Use `StaminaComponent` signals or the parent's typed public API.

---

# 7. Debugging & Tooling

## 🎯 Goal
Understand and control system behavior

---

## 🛠️ Techniques

### A. Logging
```pseudo
log("state changed")
```

---

### B. Debug UI
```pseudo
draw_debug_panel()
```

---

### C. Visualization Tools
```pseudo
draw_collision()
draw_paths()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Logging | Easy | Noisy |
| Debug UI | Clear | Requires setup |
| Visualization | Powerful | Dev cost |

---

## 💥 Failure Cases

- No visibility into systems  
- Hard-to-reproduce bugs  
- Debugging slows development  

---

## 🔗 Composability Notes

- Must be integrated early  
- Essential for:
  - AI  
  - physics  
  - gameplay  

---

## 🧩 2D vs 3D

- Same tools  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** The debug build includes a "game state inspector" overlay — a separate debug camera perspective that shows the full game state: all unit positions, current phase, each unit's remaining action points, territory control flags, and pending events in the queue. This God-view debugger was used to find state bugs that are invisible from the player camera (e.g., a unit with impossible stats, a territory control flag not resetting). The lesson: invest in a debug view that shows the full game state, not just what the player sees.

### 🟦 Godot 4.x
**Node/API:** `DebugManager` (graybox-4 system) + Godot's built-in debugger + `print_debug()`
```gdscript
# debug_overlay.gd — a CanvasLayer always on top, showing key state
class_name DebugOverlay
extends CanvasLayer

@onready var state_label: Label = $StateLabel
@onready var velocity_label: Label = $VelocityLabel

@export var target: CharacterBody3D

func _process(_delta: float) -> void:
    if not OS.is_debug_build():
        visible = false
        return

    if target == null:
        return

    state_label.text = "State: " + _get_state_name()
    velocity_label.text = "Vel: %s | Speed: %.1f" % [
        str(target.velocity.snappedf(0.01)),
        target.velocity.length()
    ]

func _get_state_name() -> String:
    return "unknown"  # override or connect to GameStateManager
```
**Pitfalls:**
- Gate all debug overlays on `OS.is_debug_build()` — shipping with debug UI visible is a common release mistake. The DebugManager from graybox-4 has this gating built-in.
- Godot's built-in Remote Scene Debugger (connect to a running game from the editor) is powerful for inspecting node values live — use it before building custom debug UI.

---

# 🧠 FINAL INSIGHT

Game architecture is the foundation of everything:

Input → Systems → Data Flow → Update Loop → Output

Most bugs come from:
- Poor system separation  
- Unclear data flow  
- Hidden dependencies  
- Inconsistent update order  
