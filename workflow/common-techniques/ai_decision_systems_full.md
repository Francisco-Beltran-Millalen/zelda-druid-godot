# 🧠 10. AI Decision Systems

## 📌 Scope

How entities decide what to do

### Includes:
- Finite State Machines (FSM)  
- Behavior Trees  
- Utility AI  

---

## 🔍 Typical sub-problems

- Predictable behavior  
- State bugs  
- Performance issues  
- Hard-to-scale logic  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

AI is about decision-making under constraints, not intelligence

That means:
- Simplicity often beats complexity  
- Behavior must be predictable but not trivial  
- Systems must scale with content  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild | 3D | Patrol → alert → combat FSM, group coordination, perception systems |
| Fire Emblem: Three Houses | Strategy | Utility AI for turn-based combat decisions, attack priority scoring, positioning |

---

# 🧱 PROBLEM SET

---

# 1. Finite State Machines (FSM)

## 🎯 Goal
Define behavior as discrete states with transitions

---

## 🛠️ Techniques

### A. Simple FSM
```pseudo
state = IDLE

if see_enemy:
    state = CHASE
elif health_low:
    state = FLEE
```

---

### B. State with Transitions
```pseudo
if state == CHASE and lost_enemy:
    state = SEARCH
```

---

### C. State Objects
```pseudo
state.update()
state.on_enter()
state.on_exit()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Simple FSM | Easy to implement | Not scalable |
| Transition-based | More control | Complex transitions |
| State objects | Modular | More boilerplate |

---

## 💥 Failure Cases

- State explosion  
- Transition bugs  
- Hard-to-debug behavior  

---

## 🔗 Composability Notes

- Works with:
  - animation  
  - navigation  
- Often combined with:
  - event systems  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Bokoblin enemies use a 5-state FSM: Patrol → Alert → Investigate → Combat → Flee. Transitions are asymmetric — going from Patrol to Combat requires seeing the player for 2 consecutive seconds (avoids false triggers), while returning from Combat to Patrol requires losing sight for 10 seconds (prevents instant de-aggro). The Fight/Flee decision within Combat is made by a simple health threshold — below 25% health, the Bokoblin runs to the alarm horn and tries to call reinforcements. This single health-based branch creates emergent behavior (now the player must prioritize killing weak enemies to prevent reinforcement calls) from a very simple state machine.

### 🟦 Godot 4.x
**Node/API:** Resource-based `State` pattern — reuse the same architecture as character controllers
```gdscript
# enemy_state.gd (base)
class_name EnemyState
extends Resource

func enter(_enemy: Node3D) -> void:
    pass

func exit(_enemy: Node3D) -> void:
    pass

func update(_enemy: Node3D, _delta: float) -> EnemyState:
    return self  # return a different state to transition

# state_patrol.gd
class_name StatePatrol
extends EnemyState

@export var patrol_speed: float = 2.0
@export var alert_sight_time: float = 2.0  # must see player for this long to transition

var _sight_timer: float = 0.0

func update(enemy: Node3D, delta: float) -> EnemyState:
    var perception: EnemyPerception = enemy.get_node("Perception") as EnemyPerception
    if perception.can_see_player():
        _sight_timer += delta
        if _sight_timer >= alert_sight_time:
            return enemy.state_combat  # transition to combat
    else:
        _sight_timer = 0.0
    return self
```
**Pitfalls:**
- State objects should be `Resource` subclasses, not `Node` subclasses — they can then be shared/duplicated efficiently and don't need to live in the scene tree.
- Keep transitions out of the state objects themselves — return the new state from `update()` and let the state machine handle the actual transition. States should not know about each other.

---

# 2. Behavior Trees

## 🎯 Goal
Structure behavior hierarchically

---

## 🛠️ Techniques

### A. Selector Node
```pseudo
for child in children:
    if child.succeeds():
        return success
```

---

### B. Sequence Node
```pseudo
for child in children:
    if child.fails():
        return failure
```

---

### C. Action Node
```pseudo
move_to(target)
attack()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Behavior Tree | Modular, designer-friendly | Harder to debug than FSM |
| Selector/Sequence | Structured | Verbose for simple behaviors |
| Action Nodes | Flexible | Needs good design upfront |

---

## 💥 Failure Cases

- Infinite loops  
- Poor priority ordering  
- Hard-to-track execution flow  

---

## 🔗 Composability Notes

- Integrates with:
  - navigation  
  - animation  
- Often uses:
  - blackboard system  

---

## 🧩 2D vs 3D

- Same structure  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Guardian enemies (large robotic enemies) use behavior tree-like hierarchical logic rather than a flat FSM. Their behavior has clear priority levels: (1) avoid lethal damage (dodge/deflect priority), (2) chase if target is fleeing, (3) execute attack sequence if in range. The priority ordering is visible — a Guardian with low health raises a "shield" sub-behavior that overrides attacking, creating a defensive phase. The game's custom AI system resembles a priority selector: it evaluates conditions from highest priority down and executes the first valid behavior. This produces adaptive behavior from composable, readable rules.

### 🟦 Godot 4.x
**Node/API:** No built-in Behavior Tree in Godot 4 — use the **Beehave** GDExtension addon, or implement a simple priority selector manually
```gdscript
# Simple priority selector (no addon needed for basic BT patterns)
extends Node3D

@onready var perception: Node3D = $Perception
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# Priority-ordered behavior evaluation — highest priority first
func _physics_process(_delta: float) -> void:
    if _try_avoid_damage():
        return
    if _try_attack():
        return
    if _try_chase():
        return
    _do_patrol()

func _try_avoid_damage() -> bool:
    if perception.incoming_threat_detected():
        _execute_dodge()
        return true
    return false

func _try_attack() -> bool:
    if perception.player_in_attack_range():
        _execute_attack()
        return true
    return false

func _try_chase() -> bool:
    if perception.player_visible():
        nav_agent.target_position = perception.last_known_player_position
        return true
    return false

func _do_patrol() -> void:
    nav_agent.target_position = _get_next_patrol_point()
```
**Pitfalls:**
- Behavior Trees are more complex to implement and debug than FSMs — only use them when you have >7–8 states with complex priority interactions. For most enemies, a well-structured FSM is simpler and more maintainable.
- Without a visual debugger (which BT addons provide), BT execution flow is hard to trace in plain code. If you roll your own, add logging at each node evaluation.

---

# 3. Utility AI

## 🎯 Goal
Choose actions based on scoring

---

## 🛠️ Techniques

### A. Score-based Decision
```pseudo
score_attack = evaluate_attack()
score_flee = evaluate_flee()

action = max(score_attack, score_flee)
```

---

### B. Weighted Factors
```pseudo
score = health_weight * health + distance_weight * distance
```

---

### C. Curve-based Evaluation
```pseudo
score = curve(distance_to_target)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Utility AI | Dynamic, emergent behavior | Hard to tune without good tooling |
| Weighted | Flexible | Needs balancing |
| Curves | Smooth decisions | Complex setup |

---

## 💥 Failure Cases

- Unstable decisions (flip-flopping) — add hysteresis  
- Poor tuning → bad behavior  
- Hard-to-debug scoring  

---

## 🔗 Composability Notes

- Often replaces FSM transitions  
- Works well with:
  - perception systems  
- Needs:
  - cooldowns or hysteresis  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Enemy unit turn decisions use a multi-factor scoring system — the "best action" is the attack + target combination with the highest score across four factors: (1) expected damage dealt, (2) expected damage taken (negative), (3) distance to advance the front line, (4) kill potential (strong bonus for securing kills). Each factor has a weight tunable per enemy class (aggressive classes weight kill potential more; defensive classes weight damage taken reduction more). This produces varied, context-appropriate AI behavior from a single scoring function, which is the core advantage of Utility AI over FSMs in turn-based games.

### 🟦 Godot 4.x
**Node/API:** `Dictionary[StringName, float]` score map with cooldown tracking
```gdscript
extends Node3D

@export var attack_weight: float = 1.0
@export var defense_weight: float = 0.8
@export var advance_weight: float = 0.5
@export var kill_bonus: float = 2.0
@export var hysteresis: float = 0.1  # must beat current action by this margin to switch

var _current_action: StringName = &"idle"
var _action_cooldowns: Dictionary = {}

func choose_action(targets: Array[Node3D]) -> StringName:
    var scores: Dictionary = {}
    scores[&"attack"] = _score_attack(targets)
    scores[&"defend"] = _score_defend()
    scores[&"advance"] = _score_advance()

    var best_action: StringName = &"idle"
    var best_score: float = -INF
    for action: StringName in scores:
        var score: float = scores[action]
        if action == _current_action:
            score += hysteresis  # bias toward staying in current action
        if score > best_score and not _is_on_cooldown(action):
            best_score = score
            best_action = action

    _current_action = best_action
    return best_action

func _score_attack(targets: Array[Node3D]) -> float:
    if targets.is_empty():
        return 0.0
    var best_target: Node3D = targets[0]
    var expected_damage: float = _estimate_damage(best_target)
    var will_kill: bool = _can_kill(best_target)
    return expected_damage * attack_weight + (kill_bonus if will_kill else 0.0)

func _score_defend() -> float:
    return 0.0  # placeholder

func _score_advance() -> float:
    return 0.0  # placeholder

func _estimate_damage(_target: Node3D) -> float:
    return 0.0  # placeholder

func _can_kill(_target: Node3D) -> bool:
    return false  # placeholder

func _is_on_cooldown(action: StringName) -> bool:
    return _action_cooldowns.get(action, 0.0) > 0.0
```
**Pitfalls:**
- Without hysteresis (a bias toward the current action), Utility AI flip-flops between two equally-scored actions every frame. The `hysteresis` constant (0.05–0.2) prevents this.
- Utility AI is difficult to balance without tooling that shows scores in real-time. Build a debug overlay early that prints the score for each action — it pays for itself immediately.

---

# 4. Perception Systems

## 🎯 Goal
Provide AI with information about the world

---

## 🛠️ Techniques

### A. Vision Check
```pseudo
if raycast_to_target and within_fov:
    see_enemy = true
```

---

### B. Distance Check
```pseudo
if distance_to(target) < threshold:
    in_range = true
```

---

### C. Event Perception
```pseudo
on_noise_heard():
    investigate()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Vision | Realistic | Expensive |
| Distance | Simple | Less accurate |
| Events | Efficient | Needs triggers |

---

## 💥 Failure Cases

- AI sees through walls  
- Detection too sensitive  
- Missed detections  

---

## 🔗 Composability Notes

- Feeds:
  - FSM  
  - behavior tree  
  - utility AI  
- Uses:
  - collision queries  

---

## 🧩 2D vs 3D

- 3D requires FOV and occlusion  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemy perception uses three layers: (1) vision cone (direction + range + LOS raycast — careful stealth), (2) hearing range (sphere overlap — noise events like running on stone, whistling), (3) proximity alarm (small sphere — unavoidable close-range trigger). Importantly, all three are separate `Area` volumes with independent ranges and conditions. Vision range is longest but requires LOS; hearing range is medium and omnidirectional; proximity is small but always active. This three-layer model creates the "stealth pyramid" of the game — crouch-walking is quiet, flat terrain means no rustling sound, and close range always gets you caught.

### 🟦 Godot 4.x
**Node/API:** `Area3D` volumes for range checks + `RayCast3D` for LOS — isolate each perception type
```gdscript
class_name EnemyPerception
extends Node3D

@export var vision_range: float = 15.0
@export var vision_fov_degrees: float = 90.0
@export var hearing_range: float = 8.0
@export var proximity_range: float = 2.0

@onready var vision_ray: RayCast3D = $VisionRay
@onready var hearing_area: Area3D = $HearingArea
@onready var proximity_area: Area3D = $ProximityArea

var last_known_player_position: Vector3 = Vector3.ZERO
var _player: Node3D = null

func _ready() -> void:
    proximity_area.body_entered.connect(_on_proximity_triggered)
    hearing_area.body_entered.connect(_on_hearing_triggered)

func can_see_player() -> bool:
    if _player == null:
        return false
    var to_player: Vector3 = _player.global_position - global_position
    if to_player.length() > vision_range:
        return false
    var angle: float = rad_to_deg(global_basis.z.angle_to(to_player.normalized()))
    if angle > vision_fov_degrees * 0.5:
        return false
    vision_ray.target_position = vision_ray.to_local(_player.global_position)
    vision_ray.force_raycast_update()
    if vision_ray.is_colliding():
        return vision_ray.get_collider() == _player
    last_known_player_position = _player.global_position
    return true

func _on_proximity_triggered(body: Node3D) -> void:
    if body.is_in_group("player"):
        _player = body
        last_known_player_position = body.global_position

func _on_hearing_triggered(body: Node3D) -> void:
    if body.is_in_group("player") and body.has_method("is_making_noise"):
        if body.is_making_noise():
            last_known_player_position = body.global_position
```
**Pitfalls:**
- Raycasting every frame for every enemy is expensive — throttle vision checks to every 0.1–0.2s using a timer, and only do LOS checks when the target is already within the FOV angle (cheaper check first).
- Keep `EnemyPerception` as a separate child node (component), not inline in the enemy script. This makes it reusable across enemy types and independently testable.

---

# 5. Decision Timing & Updates

## 🎯 Goal
Control how often AI makes decisions

---

## 🛠️ Techniques

### A. Fixed Interval Updates
```pseudo
if time_since_last_update > interval:
    update_ai()
```

---

### B. Event-driven Updates
```pseudo
on_event():
    update_ai()
```

---

### C. Staggered Updates
```pseudo
update_subset_of_agents()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Fixed | Predictable | Wasteful |
| Event-driven | Efficient | Needs triggers |
| Staggered | Scalable | Less responsive |

---

## 💥 Failure Cases

- AI reacts too slowly  
- Performance spikes  
- Inconsistent behavior  

---

## 🔗 Composability Notes

- Must balance:
  - performance  
  - responsiveness  
- Interacts with:
  - perception  
  - navigation  

---

## 🧩 2D vs 3D

- Same concept  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemy AI updates are staggered — in a camp of 8 enemies, not all 8 update their decision logic on the same frame. Updates are distributed across 4 frames (2 enemies per frame), so decision spikes are spread evenly. The stagger is invisible to the player because a 4-frame delay (67ms at 60fps) is imperceptible for non-reactive enemies in patrol state. For enemies in Combat state, updates happen every frame for that specific enemy — the stagger only applies to Patrol/Idle states. This selectively expensive approach gives full responsiveness where it matters and performance savings where it doesn't.

### 🟦 Godot 4.x
**Node/API:** Stagger via `int` offset + `Engine.get_process_frames()` modulo; or `Timer` per enemy
```gdscript
extends Node3D

@export var decision_interval: float = 0.15  # how often AI decides
@export var stagger_offset: int = 0  # set differently per enemy instance

var _decision_timer: float = 0.0

func _ready() -> void:
    # Stagger: distribute initial timer offset so all enemies don't tick together
    _decision_timer = float(stagger_offset % 4) * (decision_interval / 4.0)

func _physics_process(delta: float) -> void:
    _decision_timer -= delta
    if _decision_timer <= 0.0:
        _decision_timer = decision_interval
        _make_decision()

func _make_decision() -> void:
    pass  # override in subclass or state
```
**Pitfalls:**
- Per-enemy `Timer` nodes are fine for <20 enemies; for large crowds (50+), use a central `AIManager` Autoload that ticks groups of enemies rather than letting each enemy manage its own timer.
- Staggering the AI tick does NOT mean the enemy moves less frequently — movement (`_physics_process`) still runs every frame. Only the "what should I do next" decision is staggered.

---

# 6. Coordination & Group Behavior

## 🎯 Goal
Manage multiple agents acting together

---

## 🛠️ Techniques

### A. Shared Targets
```pseudo
group_target = player_position
```

---

### B. Role Assignment
```pseudo
assign_role(agent, ATTACKER)
assign_role(agent, SUPPORT)
```

---

### C. Formation Systems
```pseudo
position = formation.get_slot(agent)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Shared Target | Simple | Predictable blob behavior |
| Roles | Varied behavior | Needs assignment logic |
| Formation | Organized | Complex |

---

## 💥 Failure Cases

- Agents overlap  
- Group deadlocks  
- Unrealistic coordination  

---

## 🔗 Composability Notes

- Works with:
  - navigation  
  - steering  
- Needs:
  - communication system  

---

## 🧩 2D vs 3D

- Same logic  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Enemy squads use role assignment — each unit in a group is tagged as one of: Frontliner (advance and engage), Ranged Support (stay behind frontliners, attack from distance), or Healer (prioritize healing allies over attacking player). Roles are static (defined in level data) but role behavior evaluates dynamically each turn. A Frontliner without a path to the player (due to blocking terrain) temporarily adopts Flanker behavior (pathfinding around). The role system doesn't need constant coordination — each unit checks its role tag and evaluates its own scoring function independently, producing coordinated-looking behavior from decentralized decisions.

### 🟦 Godot 4.x
**Node/API:** Shared group state via Autoload + role tag per enemy
```gdscript
# enemy_group.gd (Autoload or per-encounter Node)
class_name EnemyGroup
extends Node

signal group_alert(target_position: Vector3)

var shared_target: Node3D = null
var _members: Array[Node3D] = []

enum Role { FRONTLINER, RANGED, HEALER }

func register_member(member: Node3D, role: Role) -> void:
    _members.append(member)
    member.set_meta("group_role", role)

func alert_group(target: Node3D) -> void:
    shared_target = target
    group_alert.emit(target.global_position)

# In each enemy's FSM:
# func _on_group_alert(target_pos: Vector3) -> void:
#     if get_meta("group_role") == EnemyGroup.Role.FRONTLINER:
#         nav_agent.target_position = target_pos  # advance
#     elif get_meta("group_role") == EnemyGroup.Role.RANGED:
#         nav_agent.target_position = _find_cover_position()  # hang back
```
**Pitfalls:**
- Shared target via an Autoload or group node is fine; avoid having enemies call methods directly on each other (tight coupling). Use signals for group events.
- Role assignment through `set_meta()` works for simple cases; for complex games, define a typed `GroupRole` resource that each enemy holds as an `@export var`.

---

# 7. Debugging & Visualization

## 🎯 Goal
Understand AI decisions

---

## 🛠️ Techniques

### A. Debug States
```pseudo
print(current_state)
```

---

### B. Visual Debugging
```pseudo
draw_path(path)
draw_fov()
```

---

### C. Decision Logging
```pseudo
log(decision, score)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Logging | Simple | Verbose |
| Visual | Intuitive | Needs tools |
| Debug States | Clear | Limited detail |

---

## 💥 Failure Cases

- Hard-to-reproduce bugs  
- Hidden logic errors  
- Lack of visibility  

---

## 🔗 Composability Notes

- Essential for:
  - complex AI  
- Should be built early  

---

## 🧩 2D vs 3D

- Same tools  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Nintendo's AI team uses in-engine debug overlays that visualize each enemy's current state (as a floating text label), sight cone (as a geometric wireframe), and last known player position (as a glowing marker). These tools are present in debug builds and were crucial for tuning the multi-state perception system. The key lesson: these overlays are built into the game code from day one, not added as an afterthought. Shipping a game with AI issues often comes from not having visibility into what the AI actually "sees" and "decides" during development.

### 🟦 Godot 4.x
**Node/API:** `DebugManager` (from graybox-4) + `draw_line()` for 2D, `ImmediateMesh` for 3D overlays
```gdscript
# In debug builds: visualize AI state via the DebugManager from graybox-4
extends Node3D

@export var show_debug: bool = false

func _process(_delta: float) -> void:
    if not show_debug:
        return
    _draw_debug()

func _draw_debug() -> void:
    # State label
    DebugManager.show_label(name + "_state", global_position + Vector3.UP * 2.5, _current_state_name())
    # Vision cone (Godot 4: use DebugDraw or ImmediateMesh)
    DebugManager.draw_cone(global_position, -global_basis.z, 15.0, deg_to_rad(45.0), Color.GREEN)
    # Last known player position
    if last_known_player_position != Vector3.ZERO:
        DebugManager.draw_sphere(last_known_player_position, 0.3, Color.RED)

func _current_state_name() -> String:
    return str(_current_state)  # override to return readable state name
```
**Pitfalls:**
- Debug visualizations should be gated on `OS.is_debug_build()` or a project setting, not `@export var show_debug` on individual nodes — toggling each enemy individually is impractical.
- Use the `DebugManager` infrastructure established in graybox-4 rather than creating per-enemy debug systems — centralized debug controls are easier to enable/disable.

---

# 🧠 FINAL INSIGHT

AI systems are a decision pipeline:

Perception → Evaluation → Decision → Action → Feedback

Most bugs come from:
- Poor state transitions  
- Lack of constraints  
- Overly complex logic  
- Missing debugging tools  
