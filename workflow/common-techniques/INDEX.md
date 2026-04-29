# Common Techniques Index

Reference library of game development technique documents. Each file covers a problem category: the core sub-problems, established techniques with tradeoff tables, composability notes, 2D/3D variations, Nintendo reference examples, and Godot 4.x implementation guidance.

**When to consult:** During mechanic-2 (Mechanic Design Loop) when designing how a mechanic should work. Also useful during graybox-4 (Rule Enforcer) and graybox-5 (Code Writer) to identify the correct Godot APIs and edge case handling.

**What each file contains (per problem area):**
- Technique comparison table with tradeoffs
- `## 🧩 2D vs 3D` — variation notes
- `### 🎮 Nintendo Reference` — how a shipped Nintendo game solved this specific problem (Zelda BotW/TotK for 3D, Metroid Dread for 2D, Fire Emblem: Three Houses for strategy/AI)
- `### 🟦 Godot 4.x` — primary node/API, typed GDScript snippet (5–15 lines), and 2 pitfall bullets

---

## Quick Lookup

| # | File | Covers | Most relevant at |
|---|------|--------|-----------------|
| 1 | [movement_locomotion_full.md](movement_locomotion_full.md) | Walking, running, jumping, slopes, stairs, air control, acceleration/deceleration, root motion vs code-driven | L5 Behavior Logic, L10 Godot Mapping |
| 2 | [collision_detection_queries_full.md](collision_detection_queries_full.md) | Raycasts, shapecasts, overlaps, hit detection, line of sight | L5, L10, L11 Performance |
| 3 | [collision_resolution_physics_full.md](collision_resolution_physics_full.md) | Wall sliding, bounce, friction, penetration correction, rigidbody physics | L5, L10 |
| 4 | [character_controller_architecture_full.md](character_controller_architecture_full.md) | Kinematic vs rigidbody controllers, state machines (idle/run/jump), input abstraction, motion composition | L3 Composition, L8 Scene Map, L10 |
| 5 | [navigation_pathfinding_full.md](navigation_pathfinding_full.md) | NavMesh, A\* pathfinding, steering behaviors | L5, L10 |
| 6 | [animation_systems_full.md](animation_systems_full.md) | Animation blending, state machines/animation graphs, root motion vs in-place, inverse kinematics | L5, L10 |
| 7 | [input_systems_full.md](input_systems_full.md) | Input buffering, action mapping, device abstraction | L3 Composition (PlayerInput), L5, L10 |
| 8 | [game_feel_feedback_full.md](game_feel_feedback_full.md) | Screen shake, hit stop/freeze frames, particles, sound, visual feedback, camera feedback | L7 Signals, L12 Debug Indicators |
| 9 | [camera_systems_full.md](camera_systems_full.md) | Follow cameras, smoothing/damping, camera collision, framing and composition | L5, L8 Scene Map, L10 |
| 10 | [ai_decision_systems_full.md](ai_decision_systems_full.md) | Finite State Machines, Behavior Trees, Utility AI | L3, L5, L10 |
| 11 | [game_state_architecture_full.md](game_state_architecture_full.md) | Game states (menu/gameplay/pause), scene/entity architecture, system communication, data flow | L3, L7, L8 |

---

## By Problem Category

### Physics & Movement
- Movement mechanics → `movement_locomotion_full.md`
- Detecting what you hit → `collision_detection_queries_full.md`
- Reacting to what you hit → `collision_resolution_physics_full.md`

### Controller Architecture
- How to structure the player character script → `character_controller_architecture_full.md`
- How input flows into the controller → `input_systems_full.md`

### AI & Enemies
- How enemies decide what to do → `ai_decision_systems_full.md`
- How enemies navigate the world → `navigation_pathfinding_full.md`

### Visual & Feel
- Animation and motion → `animation_systems_full.md`
- Juice, impact, and feedback → `game_feel_feedback_full.md`
- Camera behavior → `camera_systems_full.md`

### Architecture
- How game state is organized and shared → `game_state_architecture_full.md`
