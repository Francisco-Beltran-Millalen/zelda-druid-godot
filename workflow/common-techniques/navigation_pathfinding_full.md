# 🌍 5. Navigation & Pathfinding

## 📌 Scope

How entities decide where to go

### Includes:
- NavMesh  
- A* pathfinding  
- Steering behaviors  

---

## 🔍 Typical sub-problems

- Getting stuck  
- Path smoothing  
- Dynamic obstacles  

---

# 🧠 DESIGN PRINCIPLE (IMPORTANT)

Navigation is about choosing feasible movement through space, not directly moving the entity.

That means:
- Pathfinding decides where to go  
- Movement decides how to move there  
- Steering decides how to adjust locally  

---

## 🎮 Reference Games

| Game | Platform | Relevant to |
|------|----------|-------------|
| The Legend of Zelda: Breath of the Wild | 3D | NavMesh navigation, patrol/alert/combat FSM, dynamic replanning |
| Fire Emblem: Three Houses | Strategy 2D | Grid-based A*, movement range display, threat zone visualization, turn-based pathfinding |

---

# 🧱 PROBLEM SET

---

# 1. Graph-based Pathfinding

## 🎯 Goal
Find a traversable route from start to destination

---

## 🛠️ Techniques

### A. A* Search
```pseudo
open_set = [start]

while open_set not empty:
    current = node_with_lowest_f_score(open_set)

    if current == goal:
        return reconstruct_path()

    for neighbor in current.neighbors:
        tentative_g = current.g + cost(current, neighbor)

        if tentative_g < neighbor.g:
            neighbor.parent = current
            neighbor.g = tentative_g
            neighbor.f = neighbor.g + heuristic(neighbor, goal)
```

---

### B. Dijkstra
```pseudo
for each node:
    distance[node] = infinity

distance[start] = 0
```

---

### C. Breadth-First Search (BFS)
```pseudo
queue.push(start)

while queue not empty:
    current = queue.pop()
    visit_neighbors(current)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| A* | Fast, practical, goal-directed | Needs good heuristic; degrades toward Dijkstra with poor heuristic |
| Dijkstra | Finds shortest path everywhere | Expensive — explores all directions |
| BFS | Simple | Only good for unweighted graphs |

---

## 💥 Failure Cases

- Poor heuristic → A* behaves like Dijkstra  
- Large graphs → performance spikes  
- No path found → agent stalls  

---

## 🔗 Composability Notes

- A* often feeds:
  - waypoint following  
  - steering  
- Graph quality strongly affects all higher systems  
- Requires good cost definitions for terrain and obstacles  

---

## 🧩 2D vs 3D

- Same logic  
- 3D often uses navigation surfaces or layered graphs  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Enemy units use Dijkstra (not A*) for movement range calculation — they need the full reachable-cell map, not just the path to one target. A* finds the single best path to a goal; Dijkstra naturally produces a "movement range" map as a by-product. The blue/red threat zone overlays on the map ARE the Dijkstra distance field visualized — each cell is colored based on whether any enemy can reach it within their movement budget. This is a case where choosing the right algorithm eliminates extra work.

### 🟦 Godot 4.x
**Node/API:** `AStarGrid2D` (built-in, Godot 4.2+) for tile-based A*; `AStar3D` for custom 3D graphs
```gdscript
extends Node2D

var _astar: AStarGrid2D = AStarGrid2D.new()

@export var grid_width: int = 20
@export var grid_height: int = 20
@export var cell_size: Vector2 = Vector2(32.0, 32.0)

func _ready() -> void:
    _astar.region = Rect2i(0, 0, grid_width, grid_height)
    _astar.cell_size = cell_size
    _astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    _astar.update()

func set_cell_solid(cell: Vector2i, is_solid: bool) -> void:
    _astar.set_point_solid(cell, is_solid)

func find_path(from_cell: Vector2i, to_cell: Vector2i) -> PackedVector2Array:
    return _astar.get_point_path(from_cell, to_cell)
```
**Pitfalls:**
- `AStarGrid2D` requires `update()` to be called after any `set_point_solid()` changes — forgetting this means the old graph is used.
- For large grids (100×100+), A* can spike on long paths; use weighted regions (`set_point_weight_scale()`) for terrain cost rather than adding extra nodes.

---

# 2. NavMesh Navigation

## 🎯 Goal
Represent walkable space as connected navigation regions

---

## 🛠️ Techniques

### A. Polygon NavMesh
```pseudo
start_poly = find_nav_polygon(start)
goal_poly = find_nav_polygon(goal)
path = search_connected_polygons(start_poly, goal_poly)
```

---

### B. Portal / Funnel Method
```pseudo
portals = extract_portals(path_polygons)
smoothed_path = funnel(portals)
```

---

### C. Off-mesh Links
```pseudo
if gap_detected:
    use_link(jump_link)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| NavMesh | Natural movement areas | Requires baking / generation |
| Funnel | Smooth paths | Needs clean polygon path |
| Off-mesh Links | Supports jumps/ladders | Manual setup or extra logic |

---

## 💥 Failure Cases

- Agent near mesh border gets stuck  
- Badly baked mesh causes invalid paths  
- Off-mesh links not matched to movement ability  

---

## 🔗 Composability Notes

- NavMesh usually outputs a high-level path  
- Funnel smoothing often comes after polygon search  
- Off-mesh links must integrate with:
  - animation  
  - movement states  
  - controller abilities  

---

## 🧩 2D vs 3D

- 2D may use grids or nav polygons  
- 3D NavMesh is much more common  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemies use baked NavMesh for all 3D navigation. Each patrol area has its own NavMesh region that is manually tuned — the mesh excludes cliffs, water, and unintended shortcut routes. Off-mesh links connect patrol platforms and bridges. The key insight from BotW's AI is the layered goal system: enemies don't pathfind to the player every frame. They pathfind to their "investigation point" (where they last saw the player) and switch goals only when new information arrives. This reduces pathfinding calls dramatically.

### 🟦 Godot 4.x
**Node/API:** `NavigationRegion3D` + `NavigationMesh` + `NavigationAgent3D`
```gdscript
extends CharacterBody3D

@export var move_speed: float = 4.0
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    nav_agent.velocity_computed.connect(_on_velocity_computed)
    nav_agent.path_desired_distance = 1.0
    nav_agent.target_desired_distance = 1.5

func set_target(target_position: Vector3) -> void:
    nav_agent.target_position = target_position

func _physics_process(_delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var desired_vel: Vector3 = (next_pos - global_position).normalized() * move_speed
    nav_agent.velocity = desired_vel  # avoidance enabled: async callback

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity = safe_velocity
    move_and_slide()
```
**Pitfalls:**
- `NavigationAgent3D.velocity_computed` only fires when `avoidance_enabled = true` — if avoidance is off, set `velocity` directly from `get_next_path_position()`.
- Bake `NavigationMesh` after all `StaticBody3D` geometry is final; re-bake is required when level geometry changes at runtime.

---

# 3. Grid-based Navigation

## 🎯 Goal
Navigate discretized space as cells or tiles

---

## 🛠️ Techniques

### A. Uniform Grid
```pseudo
grid[x][y] = walkable or blocked
path = astar(grid_start, grid_goal)
```

---

### B. Weighted Grid
```pseudo
cost = terrain_cost(cell)
```

---

### C. Flow Field
```pseudo
for each cell:
    direction = best_neighbor_toward_goal
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Uniform Grid | Easy to implement | Blocky paths |
| Weighted Grid | Terrain-aware | More tuning |
| Flow Field | Great for crowds | Expensive to generate |

---

## 💥 Failure Cases

- Stair-step paths  
- Resolution too low → poor navigation  
- Resolution too high → expensive  

---

## 🔗 Composability Notes

- Grids pair well with:
  - tactics games  
  - tilemaps  
  - RTS movement  
- Often followed by:
  - path smoothing  
  - local avoidance  

---

## 🧩 2D vs 3D

- 2D grids are common  
- 3D voxel grids are possible but heavier  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** The grid uses a weighted A* where each cell has a terrain cost (plains = 1, forest = 2, mountain = 3). Each unit has a movement budget — the pathfinding search stops when the total cost exceeds the unit's movement stat. The "available movement" highlight is computed by running a Dijkstra flood-fill from the unit's position up to their movement budget, then highlighting all cells reached. This is a different query from "find path to target" — the game separates "where can I go" (Dijkstra flood-fill) from "how do I get there" (A* on demand).

### 🟦 Godot 4.x
**Node/API:** `AStarGrid2D` with `set_point_weight_scale()` for terrain costs
```gdscript
extends Node

var _astar: AStarGrid2D = AStarGrid2D.new()

@export var grid_rect: Rect2i = Rect2i(0, 0, 30, 30)
@export var cell_size: Vector2 = Vector2(64.0, 64.0)

enum TerrainCost { PLAINS = 1, FOREST = 2, MOUNTAIN = 3, IMPASSABLE = 0 }

func _ready() -> void:
    _astar.region = grid_rect
    _astar.cell_size = cell_size
    _astar.update()

func set_terrain(cell: Vector2i, cost: TerrainCost) -> void:
    if cost == TerrainCost.IMPASSABLE:
        _astar.set_point_solid(cell, true)
    else:
        _astar.set_point_weight_scale(cell, float(cost))

func get_movement_range(origin: Vector2i, budget: int) -> Array[Vector2i]:
    # Flood-fill within budget using Dijkstra logic
    var reachable: Array[Vector2i] = []
    var distances: Dictionary = {origin: 0}
    var queue: Array[Vector2i] = [origin]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        reachable.append(current)
        for neighbor: Vector2i in _get_neighbors(current):
            var cost: int = int(_astar.get_point_weight_scale(neighbor))
            var new_dist: int = distances[current] + cost
            if new_dist <= budget and (not neighbor in distances or new_dist < distances[neighbor]):
                distances[neighbor] = new_dist
                queue.append(neighbor)
    return reachable

func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
    return [
        Vector2i(cell.x + 1, cell.y), Vector2i(cell.x - 1, cell.y),
        Vector2i(cell.x, cell.y + 1), Vector2i(cell.x, cell.y - 1)
    ]
```
**Pitfalls:**
- `set_point_weight_scale()` multiplies the edge cost, not the node cost — diagonal movement (if enabled) may produce unexpected paths.
- `AStarGrid2D.DIAGONAL_MODE_NEVER` is recommended for turn-based games with grid-aligned movement; diagonal movement creates 8-directional paths that look unnatural on a square grid.

---

# 4. Path Smoothing

## 🎯 Goal
Turn raw paths into more natural motion

---

## 🛠️ Techniques

### A. Funnel Algorithm
```pseudo
smoothed_path = funnel(portals)
```

---

### B. Line-of-Sight Shortcutting
```pseudo
if raycast_clear(node_a, node_c):
    remove(node_b)
```

---

### C. Curve Interpolation
```pseudo
smooth_path = spline(path_points)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Funnel | Excellent for navmesh | Requires portals |
| Shortcutting | Simple, effective | Needs visibility checks |
| Curves | Natural look | Can leave traversable area |

---

## 💥 Failure Cases

- Smoothed path cuts through obstacles  
- Over-smoothing creates unrealistic turns  
- Curves ignore collision constraints  

---

## 🔗 Composability Notes

- Always validate smoothed paths against traversable space  
- Pairs with:
  - waypoint following  
  - steering  
- Must respect agent radius and movement limits  

---

## 🧩 2D vs 3D

- Same idea  
- 3D needs vertical validity checks  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemy paths on NavMesh use the funnel algorithm (built into the NavMesh system) combined with a soft look-ahead — enemies don't aim at the next waypoint directly but at a point slightly ahead of the next waypoint. This prevents the "robot walking to waypoints" look where the entity makes sharp turns at each node. The combination of funnel smoothing + look-ahead creates natural-looking curved movement through complex environments without spline computation.

### 🟦 Godot 4.x
**Node/API:** `NavigationAgent3D.path_postprocessing` — built-in funnel smoothing
```gdscript
extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    # Enable funnel smoothing (corridors/narrow passages)
    nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
    # Or edge-center for simpler open areas:
    # nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
```
**Pitfalls:**
- `PATH_POSTPROCESSING_CORRIDORFUNNEL` produces better paths in narrow passages but is more expensive; use `EDGECENTERED` for open-world enemies where path quality matters less.
- Path smoothing does not account for agent radius — add a margin (`nav_agent.path_metadata_flags`) so the smoothed path keeps the agent away from walls.

---

# 5. Local Avoidance & Steering

## 🎯 Goal
React to nearby obstacles and moving agents

---

## 🛠️ Techniques

### A. Seek / Arrive / Flee
```pseudo
desired_velocity = normalize(target - position) * speed
steering = desired_velocity - current_velocity
```

---

### B. Obstacle Avoidance
```pseudo
if raycast_ahead_hits():
    steering += avoid_force
```

---

### C. Velocity Obstacles / RVO-like
```pseudo
safe_velocity = choose_velocity_outside_collision_cones()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Seek/Arrive | Simple | Not enough alone |
| Obstacle Avoidance | Reactive | Can jitter |
| RVO-like | Good for crowds | Complex |

---

## 💥 Failure Cases

- Agents oscillate left/right  
- Avoidance fights path following  
- Crowd deadlocks  

---

## 🔗 Composability Notes

- Steering is usually layered on top of path following  
- Must not fully override high-level navigation  
- Needs priority rules between:
  - goal seeking  
  - avoidance  
  - animation constraints  

---

## 🧩 2D vs 3D

- Same logic  
- 3D flying agents are much harder  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Enemy units use Arrive steering (slow down as they approach their destination cell) rather than hard-stop waypoint following. Multiple units moving toward the same target coordinate through a shared "occupied cell" registry — before moving, each unit checks if its target cell is claimed by another unit and selects an adjacent cell instead. This simple reservation system prevents crowd deadlocks without needing full RVO, which is overkill for turn-based movement where units move one at a time.

### 🟦 Godot 4.x
**Node/API:** `NavigationAgent3D.avoidance_enabled = true` — built-in RVO avoidance
```gdscript
extends CharacterBody3D

@export var move_speed: float = 4.0
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
    nav_agent.avoidance_enabled = true
    nav_agent.radius = 0.5  # agent physical radius for avoidance
    nav_agent.neighbor_distance = 15.0
    nav_agent.max_neighbors = 10
    nav_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(_delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return
    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var desired: Vector3 = (next_pos - global_position).normalized() * move_speed
    nav_agent.velocity = desired  # triggers avoidance computation

func _on_velocity_computed(safe_vel: Vector3) -> void:
    velocity = safe_vel
    move_and_slide()
```
**Pitfalls:**
- RVO avoidance in Godot runs on a separate thread — `velocity_computed` fires asynchronously, so avoid reading `velocity` between setting `nav_agent.velocity` and the callback.
- With many agents (50+), avoidance can become expensive; set `max_neighbors` to limit how many agents each agent considers.

---

# 6. Dynamic Obstacles & Replanning

## 🎯 Goal
Handle worlds that change after path computation

---

## 🛠️ Techniques

### A. Periodic Repathing
```pseudo
if time_since_last_path > interval:
    recompute_path()
```

---

### B. Event-driven Replanning
```pseudo
if obstacle_blocks_path:
    recompute_path()
```

---

### C. Partial Path Repair
```pseudo
repair_remaining_path_from(current_position)
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Periodic | Simple | Wasted work |
| Event-driven | Efficient | Needs reliable triggers |
| Repair | Fast | Harder to implement |

---

## 💥 Failure Cases

- Constant repathing loops  
- Agent stuck on moving obstacle  
- Path invalidates every frame  

---

## 🔗 Composability Notes

- Requires coordination between:
  - perception  
  - pathfinding  
  - movement  
- Dynamic updates often need fallback behaviors like waiting or sidestepping  

---

## 🧩 2D vs 3D

- Same concept  
- 3D dynamic nav updates are costlier  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemy replanning is event-driven with a throttle — enemies only recompute their path when one of these conditions triggers: (1) they reach the current waypoint, (2) they hear a sound event, (3) they lose sight of Link for 3 seconds. This prevents the "constant repathing" problem where enemies recalculate every frame. The 3-second sight-loss delay also serves a gameplay purpose: enemies "search" for Link rather than immediately giving up, creating tension without expensive per-frame queries.

### 🟦 Godot 4.x
**Node/API:** `NavigationObstacle3D` for dynamic obstacles; `NavigationAgent3D.target_position` setter triggers replanning
```gdscript
extends CharacterBody3D

@export var replan_interval: float = 1.5  # seconds between replan checks
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _replan_timer: float = 0.0
var _last_target: Vector3 = Vector3.ZERO

func update_target(new_target: Vector3) -> void:
    # Only replan if target moved significantly or timer elapsed
    if new_target.distance_to(_last_target) > 2.0 or _replan_timer <= 0.0:
        nav_agent.target_position = new_target
        _last_target = new_target
        _replan_timer = replan_interval

func _physics_process(delta: float) -> void:
    _replan_timer -= delta
    # NavigationAgent3D handles path following; update_target() controls when to replan
```
**Pitfalls:**
- Setting `nav_agent.target_position` every frame triggers pathfinding every frame — throttle it with a timer or distance check.
- `NavigationObstacle3D` for moving obstacles requires `avoidance_enabled = true` on nearby agents to have any effect on local steering.

---

# 7. Waypoint Following

## 🎯 Goal
Move along a computed path reliably

---

## 🛠️ Techniques

### A. Sequential Waypoint Traversal
```pseudo
if distance_to(current_waypoint) < threshold:
    waypoint_index += 1
```

---

### B. Look-ahead Following
```pseudo
target = path[waypoint_index + offset]
move_toward(target)
```

---

### C. Predictive Targeting
```pseudo
target = estimate_future_path_point()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Sequential | Simple | Robotic motion |
| Look-ahead | Smoother | Can skip corners badly |
| Predictive | Natural | More tuning |

---

## 💥 Failure Cases

- Agent circles waypoint  
- Agent overshoots corners  
- Waypoint threshold too small or too large  

---

## 🔗 Composability Notes

- Follows output of:
  - A*  
  - navmesh  
  - smoothed path  
- Closely tied to:
  - movement controller  
  - steering system  

---

## 🧩 2D vs 3D

- Same principle  
- 3D requires vertical/path validity awareness  

---

### 🎮 Nintendo Reference
**Fire Emblem: Three Houses:** Unit movement uses look-ahead following with exact cell arrival — units always land precisely on grid cells (threshold = cell center, ~2 pixels). The look-ahead is 1 cell ahead of the current target, which smooths corner turns visually. The arrival condition is an exact cell-center snap rather than a distance threshold, ensuring units always end up aligned to the grid (critical for game logic that depends on grid positions). Purely cosmetic interpolation handles the smooth visual transition between cells.

### 🟦 Godot 4.x
**Node/API:** `NavigationAgent3D.get_next_path_position()` — handles waypoint advancing automatically
```gdscript
extends CharacterBody3D

@export var move_speed: float = 4.0
@export var arrival_distance: float = 0.5
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        velocity = Vector3.ZERO
        move_and_slide()
        return

    var next_pos: Vector3 = nav_agent.get_next_path_position()
    var dist: float = global_position.distance_to(next_pos)

    # NavigationAgent3D automatically advances to the next waypoint when
    # distance to current waypoint < path_desired_distance
    velocity = (next_pos - global_position).normalized() * move_speed
    move_and_slide()
```
**Pitfalls:**
- `NavigationAgent3D` manages waypoint advancement automatically — do not manually index into the path array unless you have a specific reason. Doing both causes double-advancement bugs.
- Set `nav_agent.path_desired_distance` (when to advance to next waypoint) to be slightly larger than the agent's physical radius to prevent micro-circling.

---

# 8. Getting Stuck & Recovery Behaviors

## 🎯 Goal
Recover when navigation fails in practice

---

## 🛠️ Techniques

### A. Stuck Detection by Progress Check
```pseudo
if distance_to_goal_not_decreasing():
    stuck_timer += delta
```

---

### B. Local Recovery Move
```pseudo
try_side_step()
try_back_up()
```

---

### C. Full Replan / Reset
```pseudo
if stuck_timer > threshold:
    recompute_path()
```

---

## ⚖️ Tradeoffs

| Technique | Pros | Cons |
|----------|------|------|
| Progress Check | Easy | Can false trigger |
| Local Recovery | Cheap | May fail repeatedly |
| Replan | Robust | More expensive |

---

## 💥 Failure Cases

- Agent loops forever  
- Recovery conflicts with steering  
- Constant stuck/un-stuck flicker  

---

## 🔗 Composability Notes

- Essential in real games because perfect pathfinding is not enough  
- Combines with:
  - dynamic replanning  
  - waypoint following  
  - local avoidance  

---

## 🧩 2D vs 3D

- Same problem  
- 3D geometry causes more edge cases  

---

### 🎮 Nintendo Reference
**Zelda BotW:** Enemies use a three-tier stuck recovery: (1) if no progress for 1s, try a random sidestep; (2) if still stuck after 3s, abandon current goal and return to patrol route; (3) if patrol route fails, teleport to a safe NavMesh point (off-screen). The teleport fallback is invisible to the player and prevents "enemy frozen at geometry edge" from being a persistent issue. This escalating recovery is cheaper than perfect pathfinding and handles the 1% edge cases that would otherwise require engineering effort.

### 🟦 Godot 4.x
**Node/API:** Progress timer + `NavigationAgent3D.distance_to_target()` for stuck detection
```gdscript
extends CharacterBody3D

@export var stuck_time_threshold: float = 2.0
@export var stuck_distance_threshold: float = 0.3

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _stuck_timer: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _position_check_interval: float = 0.5
var _position_check_timer: float = 0.0

func _physics_process(delta: float) -> void:
    _position_check_timer -= delta
    if _position_check_timer <= 0.0:
        _position_check_timer = _position_check_interval
        var moved: float = global_position.distance_to(_last_position)
        if moved < stuck_distance_threshold and not nav_agent.is_navigation_finished():
            _stuck_timer += _position_check_interval
        else:
            _stuck_timer = 0.0
        _last_position = global_position

    if _stuck_timer >= stuck_time_threshold:
        _on_stuck()

func _on_stuck() -> void:
    _stuck_timer = 0.0
    # Try replanning to a nearby alternative point
    nav_agent.target_position = _find_nearby_fallback()

func _find_nearby_fallback() -> Vector3:
    # Move the target slightly to find a valid navmesh point
    return nav_agent.target_position + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
```
**Pitfalls:**
- Check position change over a time window (0.5s+), not per-frame — a character briefly stopping to turn will false-trigger a per-frame check.
- Stuck detection should be disabled while the agent is intentionally waiting (in an idle state) — gate the timer on `_current_state == CHASE` or equivalent.

---

# 🧠 FINAL INSIGHT

Navigation is usually a layered stack:

Path Search → Path Smoothing → Waypoint Following → Local Avoidance → Recovery

Most bugs come from:
- Mixing global navigation with local steering incorrectly  
- Bad navigation representation  
- No recovery behavior when paths fail in practice  
- Pathfinding knowing the map, but movement not being able to execute the path  
