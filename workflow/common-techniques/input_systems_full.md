# 🎮 7. Input Systems

## 📌 Scope

How player input is captured and interpreted

### Includes:
- Input buffering  
- Action mapping  
- Device abstraction  

---

## 🔍 Typical sub-problems

- Missed inputs  
- Input lag  
- Conflicting actions  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Input systems should capture intent, not raw hardware state.

That means:
- Separate input reading from game logic  
- Convert inputs into actions or intents  
- Make input time-aware (not just frame-based)  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| Metroid Dread | 2D | Tight input buffering for precision platforming, frame-precise cancel windows, context-insensitive raw input |
| The Legend of Zelda: Breath of the Wild | 3D | Context-sensitive single-button actions, device abstraction, multi-input combination actions |

---

# 🧱 PROBLEM SET

---

# 1. Input Sampling

## 🎯 Goal
Capture input from devices reliably

---

## 🛠️ Techniques

### A. Polling (Per Frame)
```pseudo
input = read_device_state()
```

---

### B. Event-based Input
```pseudo
on_key_pressed(key):
    handle_input(key)
```

---

### C. Hybrid Sampling
```pseudo
events = collect_events()
state = current_device_state()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Polling | Simple | Can miss short inputs |
| Events | Precise | More complex |
| Hybrid | Robust | More systems to manage |

---

## 💥 Failure Cases

- Input missed between frames  
- Multiple inputs in one frame lost  
- Event flooding  

---

## 🔗 Composability Notes

- Feeds:
  - input buffering  
  - intent system  
- Must align with:
  - game loop timing  

---

## 🧩 2D vs 3D

- Same system  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Uses hybrid sampling — continuous actions (aim, move) are polled each frame via analog stick state, while discrete actions (jump, shoot, dodge) are event-based to guarantee no missed presses between frames. The event queue persists for the duration of the frame so that even a very short button press (shorter than one frame) registers correctly. This is especially important for precision techniques like frame-cancel parries.

### 🟦 Godot 4.x
**Node/API:** `Input.get_vector()` / `Input.get_axis()` for polling; `_input(event)` for event-based; use both together in `PlayerInput`
```gdscript
# player_input.gd
class_name PlayerInput
extends Node

var move_direction: Vector2 = Vector2.ZERO
var jump_just_pressed: bool = false
var dodge_just_pressed: bool = false

func _process(_delta: float) -> void:
    # Polling for continuous actions
    move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

    # Reset frame-based flags
    jump_just_pressed = false
    dodge_just_pressed = false

func _input(event: InputEvent) -> void:
    # Event-based for discrete presses (never missed between frames)
    if event.is_action_pressed("jump"):
        jump_just_pressed = true
    if event.is_action_pressed("dodge"):
        dodge_just_pressed = true
```
**Pitfalls:**
- `Input.is_action_just_pressed()` only returns `true` for one frame (the frame the action was pressed). If `_physics_process` runs at a different rate than `_process`, the press can be missed — use event-based (`_input`) for critical inputs.
- `_input` fires before `_physics_process`, so event flags set there are available to physics logic in the same frame.

---

# 2. Input Mapping (Action System)

## 🎯 Goal
Map raw input to game actions

---

## 🛠️ Techniques

### A. Direct Mapping
```pseudo
if key == SPACE:
    jump()
```

---

### B. Action Mapping
```pseudo
if action_pressed("jump"):
    jump()
```

---

### C. Contextual Input Mapping
```pseudo
if context == MENU:
    handle_menu_input()
elif context == GAMEPLAY:
    handle_game_input()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Direct | Simple | Not flexible |
| Action Mapping | Rebindable | Needs setup |
| Contextual | Scalable | More complexity |

---

## 💥 Failure Cases

- Hardcoded inputs  
- Conflicting bindings  
- Wrong context handling  

---

## 🔗 Composability Notes

- Feeds:
  - intent system  
  - state machines  
- Must integrate with:
  - UI systems  
  - gameplay modes  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Context-sensitive mapping — the A button is mapped to "primary action" and resolves differently based on game state: Jump (ground), Climb (near climbable surface), Interact (near NPC/object), Confirm (menu). The mapping is not per-button but per-"slot": each state owns its primary action slot, and the HUD icon updates to show what A will do in the current context. This reduces the control scheme to a small number of buttons while supporting a large action set — a masterclass in input design.

### 🟦 Godot 4.x
**Node/API:** `InputMap` — define actions in Project Settings, remap at runtime
```gdscript
extends Node

# Define action names as constants to avoid typo bugs
const ACTION_JUMP: StringName = &"jump"
const ACTION_INTERACT: StringName = &"interact"
const ACTION_MOVE_LEFT: StringName = &"move_left"

func remap_action(action: StringName, new_event: InputEvent) -> void:
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, new_event)

func save_bindings() -> void:
    # Save current InputMap to a config file for persistence
    var config: ConfigFile = ConfigFile.new()
    for action: StringName in InputMap.get_actions():
        if action.begins_with("ui_"):
            continue  # skip built-in UI actions
        var events: Array[InputEvent] = InputMap.action_get_events(action)
        config.set_value("bindings", action, events)
    config.save("user://keybindings.cfg")
```
**Pitfalls:**
- Define action names as `StringName` constants (`&"jump"`) rather than bare strings (`"jump"`) — `StringName` comparison is O(1) vs `String` comparison O(n).
- Never hardcode `KEY_SPACE` or `JOY_BUTTON_0` in game logic — always go through `InputMap` actions so bindings can be remapped without code changes.

---

# 3. Input Buffering

## 🎯 Goal
Store inputs for a short time to improve responsiveness

---

## 🛠️ Techniques

### A. Simple Buffer
```pseudo
if input_pressed:
    buffer.add(input, time)
```

---

### B. Time-window Execution
```pseudo
if buffered_input and within_time_window:
    execute_action()
```

---

### C. Queue-based Input
```pseudo
queue.push(input)
process_next_input()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Buffer | Prevents missed inputs | Adds hidden logic |
| Time-window | Controlled | Needs tuning |
| Queue | Structured | Can feel delayed |

---

## 💥 Failure Cases

- Inputs triggering too late  
- Multiple buffered inputs firing unexpectedly  
- Buffer interfering with timing-based gameplay  

---

## 🔗 Composability Notes

- Works with:
  - state machines  
  - animation timing  
- Essential for:
  - platformers  
  - combat systems  

---

## 🧩 2D vs 3D

- Same system  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Input buffering is tuned per action: jump buffer = ~8 frames, melee counter = ~4 frames, morph ball = ~6 frames. These per-action windows reflect the mechanical difficulty — the parry counter has the tightest window (hardest move) while jump is the most forgiving. The buffer system stores the timestamp of the last press for each action and consumes it when the game state allows execution. Each action's buffer window is a separate tunable, not a global constant — this is the key architectural lesson.

### 🟦 Godot 4.x
**Node/API:** Per-action timer in `PlayerInput` — no built-in buffering, implement manually
```gdscript
class_name PlayerInput
extends Node

@export var jump_buffer_time: float = 0.133  # 8 frames at 60fps
@export var dodge_buffer_time: float = 0.083  # 5 frames

var _buffers: Dictionary = {}  # StringName -> float (remaining time)

func _process(delta: float) -> void:
    # Decay all buffers
    for action: StringName in _buffers.keys():
        _buffers[action] -= delta
        if _buffers[action] <= 0.0:
            _buffers.erase(action)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        _buffers[&"jump"] = jump_buffer_time
    if event.is_action_pressed("dodge"):
        _buffers[&"dodge"] = dodge_buffer_time

func consume_buffer(action: StringName) -> bool:
    if _buffers.has(action) and _buffers[action] > 0.0:
        _buffers.erase(action)
        return true
    return false

# Usage in state machine:
# if player_input.consume_buffer(&"jump") and is_on_floor():
#     velocity.y = jump_speed
```
**Pitfalls:**
- Consume the buffer immediately on use (`_buffers.erase(action)`) — if you just check it without consuming, the same buffered input fires every frame until the timer expires.
- Buffer windows that are too long (>0.25s) make the game feel "sticky" — the character performs actions the player didn't consciously intend. Tune below 0.2s for most actions.

---

# 4. Input Priority & Conflict Resolution

## 🎯 Goal
Resolve multiple simultaneous inputs

---

## 🛠️ Techniques

### A. Priority Rules
```pseudo
if jump and crouch:
    execute(jump)
```

---

### B. State-based Filtering
```pseudo
if state == JUMP:
    ignore(crouch)
```

---

### C. Input Locking
```pseudo
if action_in_progress:
    ignore_new_inputs()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Priority | Predictable | Hardcoded rules |
| State-based | Context-aware | More logic |
| Locking | Prevents conflicts | Can feel unresponsive |

---

## 💥 Failure Cases

- Input feels ignored  
- Conflicting actions triggering  
- Player loses control  

---

## 🔗 Composability Notes

- Must align with:
  - state machine  
  - animation system  
- Critical for:
  - combat  
  - complex movement  

---

## 🧩 2D vs 3D

- Same logic  

---

### 🎮 Nintendo Reference
**Metroid Dread:** Input conflicts are resolved by the state machine — each state declares which inputs it accepts and which it ignores. While wall-jumping, the movement input is locked for the first 3 frames to prevent the player from immediately redirecting into the wall they just jumped from. This "input lock window" is per-state data, not a global flag. The parry counter has the strictest filter: only the counter button is accepted during the parry window; all other inputs are discarded to prevent accidental early exits.

### 🟦 Godot 4.x
**Node/API:** State-based filtering in `CharacterState` — each state filters input from `PlayerInput`
```gdscript
# State-specific input filtering example
class_name StateWallJump
extends CharacterState

@export var lock_input_frames: int = 3

var _lock_timer: int = 0

func enter(character: CharacterBody3D) -> void:
    _lock_timer = lock_input_frames
    # Apply wall jump velocity immediately
    var input: PlayerInput = character.get_node("PlayerInput") as PlayerInput
    character.velocity.y = character.jump_speed
    character.velocity.x = character.get_wall_normal().x * character.wall_jump_horizontal

func update(character: CharacterBody3D, _delta: float) -> CharacterState:
    if _lock_timer > 0:
        _lock_timer -= 1
        return self  # ignore all directional input for lock_timer frames

    # Normal air movement after lock expires
    var input: PlayerInput = character.get_node("PlayerInput") as PlayerInput
    character.velocity.x = input.move_direction.x * character.max_speed
    return self
```
**Pitfalls:**
- Input locking via a flag in the `PlayerInput` node (`is_locked = true`) leaks state — prefer filtering at the state machine level so the `PlayerInput` node itself remains stateless.
- Never lock ALL input for more than ~0.1s without a visual cue; players assume they're stuck if their inputs silently do nothing.

---

# 5. Input Smoothing & Filtering

## 🎯 Goal
Reduce noise and create smoother input behavior

---

## 🛠️ Techniques

### A. Deadzone
```pseudo
if abs(input) < threshold:
    input = 0
```

---

### B. Smoothing / Interpolation
```pseudo
smoothed = lerp(previous_input, current_input, factor)
```

---

### C. Accumulated Input
```pseudo
input_sum += input * delta
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Deadzone | Removes noise | Reduces sensitivity |
| Smoothing | Stable input | Adds latency |
| Accumulation | Precise control | Complex |

---

## 💥 Failure Cases

- Input lag  
- Over-smoothed controls  
- Loss of responsiveness  

---

## 🔗 Composability Notes

- Used before:
  - intent system  
- Must balance:
  - responsiveness vs stability  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Analog stick input is smoothed with a small deadzone (~15% of the stick range) and a gentle low-pass filter. Camera controls have a larger deadzone (~25%) and more aggressive smoothing to prevent jittery camera movement from stick drift. The deadzone is circular (not square), so diagonal movement feels as responsive as cardinal directions. This two-tier smoothing (movement less smoothed, camera more smoothed) is a common pattern in 3D action games — movement needs responsiveness, camera needs stability.

### 🟦 Godot 4.x
**Node/API:** `Input.get_vector()` has built-in deadzone support; additional smoothing via `lerp`
```gdscript
class_name PlayerInput
extends Node

@export var move_deadzone: float = 0.15
@export var camera_deadzone: float = 0.25
@export var camera_smooth_factor: float = 0.3  # 0 = no smooth, 1 = instant

var move_direction: Vector2 = Vector2.ZERO
var camera_input: Vector2 = Vector2.ZERO
var _raw_camera: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
    # Built-in deadzone handling
    move_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back", move_deadzone)

    # Camera with manual smoothing
    _raw_camera = Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down", camera_deadzone)
    camera_input = camera_input.lerp(_raw_camera, camera_smooth_factor)
```
**Pitfalls:**
- `Input.get_vector()` deadzone is the 4th parameter — it defaults to -1 (uses project settings). Set it explicitly so behavior is predictable regardless of project settings.
- Smoothing camera input with `lerp` is frame-rate dependent — use `lerp(a, b, 1.0 - pow(1.0 - factor, delta * 60.0))` for frame-rate independent smoothing.

---

# 6. Input Timing & Responsiveness

## 🎯 Goal
Ensure input feels immediate and reliable

---

## 🛠️ Techniques

### A. Frame-perfect Input
```pseudo
if input_pressed_this_frame:
    execute()
```

---

### B. Input Windowing
```pseudo
if input within allowed_window:
    execute()
```

---

### C. Latency Compensation
```pseudo
predicted_input = estimate_next_input()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Frame-perfect | Precise | Unforgiving for players (but valid in competitive games) |
| Windowing | Player-friendly | Less strict |
| Compensation | Smooth feel | Can be inaccurate |

---

## 💥 Failure Cases

- Missed inputs  
- Delayed response  
- Inconsistent timing  

---

## 🔗 Composability Notes

- Strongly tied to:
  - game loop timing  
  - animation timing  
- Works with:
  - buffering  
  - state machines  

---

## 🧩 2D vs 3D

- Same principle  

---

### 🎮 Nintendo Reference
**Metroid Dread:** The parry counter is intentionally frame-precise — accepting input only within a 4-frame window before an enemy attack lands. This is tight but deliberate: the challenge of the game is reading enemy attack timing. The surrounding systems (audio cue, flash effect at window open) compensate for the tightness by giving the player reliable cues. The lesson: frame-perfect windows are acceptable when the game teaches the player what to watch for — tight windows without clear cues are just frustrating.

### 🟦 Godot 4.x
**Node/API:** Combine `_input` (event callback) + frame counter for precise windows
```gdscript
extends Node

@export var parry_window_frames: int = 4

var _parry_window_remaining: int = 0
var _parry_succeeded: bool = false

func open_parry_window() -> void:  # called from animation event
    _parry_window_remaining = parry_window_frames
    _parry_succeeded = false

func _physics_process(_delta: float) -> void:
    if _parry_window_remaining > 0:
        _parry_window_remaining -= 1

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("parry") and _parry_window_remaining > 0:
        _parry_succeeded = true
        _parry_window_remaining = 0  # consume window
```
**Pitfalls:**
- Using frame count for timing only works if the physics tick rate is fixed (`Engine.physics_ticks_per_second`). If it varies, 4 frames at 60fps is different from 4 frames at 30fps — use time (seconds) for windows that must be consistent across framerates.
- For very short windows (1–3 frames), verify in the game's real render conditions — a single dropped frame can make a 2-frame window feel inconsistent to players.

---

# 7. Device Abstraction

## 🎯 Goal
Support multiple input devices uniformly

---

## 🛠️ Techniques

### A. Unified Input Layer
```pseudo
move = get_action("move")
```

---

### B. Device-specific Mapping
```pseudo
if device == GAMEPAD:
    use_gamepad_mapping()
```

---

### C. Dynamic Rebinding
```pseudo
bind_key(action, new_key)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Unified | Clean | Abstract layer needed |
| Device-specific | Optimized | More complexity |
| Rebinding | User-friendly | Needs UI + storage |

---

## 💥 Failure Cases

- Inconsistent behavior across devices  
- Broken bindings  
- Device detection issues  

---

## 🔗 Composability Notes

- Must integrate with:
  - input mapping  
  - UI system  
- Enables:
  - accessibility  
  - cross-platform support  

---

## 🧩 2D vs 3D

- Same system  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Seamless controller hot-swapping — the game detects which device was last used and updates HUD button prompts accordingly (Joy-Con vs Pro Controller). The input system is unified via action names; device-specific handling only affects HUD icon rendering. The button prompt system queries the "last active device" Autoload to determine which icon set to display, keeping device awareness isolated to the UI layer. Game logic never branches on controller type.

### 🟦 Godot 4.x
**Node/API:** `Input.get_connected_joypads()`, `Input.joy_connection_changed` signal, `InputEvent.device` property
```gdscript
extends Node

signal active_device_changed(device_type: String)

var _active_device: String = "keyboard"

func _input(event: InputEvent) -> void:
    var new_device: String = _active_device
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        new_device = "gamepad"
    elif event is InputEventKey or event is InputEventMouseButton:
        new_device = "keyboard"

    if new_device != _active_device:
        _active_device = new_device
        active_device_changed.emit(_active_device)

func get_action_icon(action: StringName) -> Texture2D:
    # Return keyboard or gamepad icon based on active device
    if _active_device == "gamepad":
        return _get_gamepad_icon(action)
    return _get_keyboard_icon(action)

func _get_keyboard_icon(_action: StringName) -> Texture2D:
    return null  # placeholder

func _get_gamepad_icon(_action: StringName) -> Texture2D:
    return null  # placeholder
```
**Pitfalls:**
- Godot 4's `Input` system handles keyboard + gamepad through the same `InputMap` action system — you rarely need to branch on device type for game logic, only for HUD icon display.
- `Input.joy_connection_changed` fires when controllers connect/disconnect — handle it to avoid input loss when a controller drops mid-game.

---

# 🧠 FINAL INSIGHT

Input systems are a pipeline:

Device → Raw Input → Mapping → Buffer → Intent → Action

Most bugs come from:
- Mixing input with gameplay logic  
- Not accounting for timing  
- Conflicting input rules  
- Lack of buffering or over-buffering  
