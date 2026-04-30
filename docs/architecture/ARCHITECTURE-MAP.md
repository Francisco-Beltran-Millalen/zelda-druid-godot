# Architecture Map

## Section 1 — Built

| Class | Path | Public surface | Constitution clauses |
|---|---|---|---|
| `Intents` | `graybox-prototype/scripts/base/intents.gd` | `var move_dir`, `raw_input`, `wish_dir`, `input_strength`; `is_moving_forward/back/left/right`, `is_climbing_up/down/left/right`; `wants_jump`, `wants_sprint`, `wants_sneak`, `wants_climb`, `wants_mantle`, `wants_vault`, `wants_glide`; `reset()` | G4, P1 |
| `TransitionProposal` | `graybox-prototype/scripts/base/transition_proposal.gd` | `enum Priority { OPPORTUNISTIC, PLAYER_REQUESTED, FORCED }`; fields `target_state`, `category`, `override_weight`, `source_id` | G4 |
| `BodyReader` | `graybox-prototype/scripts/base/body_reader.gd` | `_init(body)`; `get_global_position()`, `get_velocity()`, `get_basis()`, `is_on_floor()`, `get_floor_normal()` | P4 |
| `LocomotionStateReader` | `graybox-prototype/scripts/base/locomotion_state_reader.gd` | `_init(state)`; `get_current_mode()`; signal `state_changed` | P4 |
| `BaseMotor` | `graybox-prototype/scripts/base/base_motor.gd` | `gather_proposals(...)`, `tick(...)`, `_get_service(...)` | P2 |
| `BaseService` | `graybox-prototype/scripts/base/base_service.gd` | `update_facts(body_reader)` | — |
| `BaseDebugContext` | `graybox-prototype/scripts/base/base_debug_context.gd` | `clear()`, `push_data(_data: Dictionary)` | P6 |
| `LocomotionState` | `graybox-prototype/scripts/player_action_stack/movement/locomotion_state.gd` | `enum ID { IDLE, WALK, SPRINT, FALL, JUMP, AUTO_VAULT, CLIMB, MANTLE, STAIRS, LADDER, GLIDE, SNEAK, WALL_JUMP, EDGE_LEAP }`; `set_state()`, `get_active_mode()`; signal `state_changed` | G2, P3 |
| `MovementBroker` | `graybox-prototype/scripts/player_action_stack/movement/movement_broker.gd` | `get_current_mode()`, `get_body_reader()`; signal `state_changed` | P2, P3, P7 |
| `StaminaComponent` | `graybox-prototype/scripts/player_action_stack/movement/stamina_component.gd` | `drain()`, `recover()`, `is_exhausted()`, `get_current()`, `get_max()`, `get_normalized()`; signal `stamina_changed` | P3 |
| `PlayerBrain` | `graybox-prototype/scripts/player_action_stack/movement/player_brain.gd` | `get_intents() -> Intents` | P1 |
| `EdgeLeapMotor` | `graybox-prototype/scripts/player_action_stack/movement/motors/edge_leap_motor.gd` | `gather_proposals`, `tick` | P2 |
| `VisualsPivot` | `graybox-prototype/scripts/player_action_stack/movement/visuals_pivot.gd` | (no public methods — visual follower) | P5 |
| `CameraRig` | `graybox-prototype/scripts/player_action_stack/camera/camera_rig.gd` | (no public methods at present) | — |
| Per-Motor scripts | `graybox-prototype/scripts/player_action_stack/movement/motors/*.gd` | One row each: list `gather_proposals` and `tick` if overridden | P2 |
| Per-Service scripts | `graybox-prototype/scripts/player_action_stack/movement/services/*.gd` | One row each: list `update_facts` and any `gather_proposals` | — |
| `DebugOverlay` | `graybox-prototype/scripts/debug_overlay.gd` | `var panel_visible`, `register_context()`, `push()` | P6 |
| `PlayerActionDebugContext` | `graybox-prototype/scripts/player_action_stack/player_action_debug_context.gd` | `clear()`, `push_data(data: Dictionary)` | P6 |

> Splitting trigger: when this section exceeds 300 lines, split per cluster (e.g., ARCHITECTURE-MAP-player-action-stack.md). See Splitting Strategy.

## Section 2 — Deferred

| Pattern | Activation trigger |
|---|---|
| `GameOrchestrator` autoload + `EntityTickBundle` / `CameraTickBundle` / `MountTickBundle` registration | A 3rd Broker (Combat or Form) needs to tick per entity, OR multi-entity tick determinism becomes a measurable requirement (multiplayer milestone). |
| Body wrapper + `PhysicsProxy`: CharacterBody3D child + Transform Sync Contract | EntityController ever needs to expose a non-physics method whose name conflicts with CharacterBody3D, OR a ragdoll-swap requirement appears. |
| 4-tier priority (`DEFAULT` > `PLAYER_REQUESTED` > `OPPORTUNISTIC` > `FORCED`) + injective `FORCED` weight registry | Out-of-system `FORCED` interrupts ship (Combat stagger, Form shift, Health defeat). Today's 3-tier prototype is sufficient. |
| `IncomingAttackBuffer` + cross-entity `EntityController.receive_incoming_attack` | Combat ships AND ≥ 2 entities can damage each other in the same frame. |
| Caller-identity asserts (`set_shifts_enabled(enabled, caller)`, similar) | A real misuse case appears in code review. Default: do not introduce. |
| `Intents` combat fields (`wants_attack`, `wants_parry`, `wants_dodge`, `wants_archery_aim/release`, `wants_assassinate`, `wants_form_shift`, `aim_target`) | The consumer ships. Add fields one by one as Combat / Form Motors / actions are written. |
| `EntityController` extends Node3D composition root with `forward_*` methods | Any sibling system other than Movement needs a per-frame upward-signal route, OR the prototype's `EntityController: Node` no longer fits. |
| `LocomotionState.Mode` extension (`STAGGER_LIGHT/HEAVY/FINISHER`, `DEFEAT`, `CINEMATIC`, `MOUNT`, `SWIM`, `RAGDOLL`) | The corresponding Motor ships. Don't pre-add. |
