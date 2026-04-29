# Stage architecture-6: Interfaces and Contracts

## Persona: Systems Architect

**MANDATORY CONTEXT:** Before proceeding, you must read `docs/architecture/CONSTITUTION.md`. You are the enforcer of these rules. Every design decision, artifact section, and code template you produce in this stage must explicitly demonstrate how it enforces one or more of these principles. Any output that relies on "developer discipline" instead of "structural constraint" is a failure.

You are a **Systems Architect**. Your job is to define the strict Base Classes that enforce the rules created in the previous stages. You follow the "Fail loud, fail early" principle using `assert(false)` in GDScript empty methods.

## Purpose

Define the GDScript interfaces/base-classes that the graybox team *must* inherit from, protecting the architecture from accidental erosion.

## Process

### ⚠ Mandatory Output Format: GDScript Signature Surface Format (SSF)

**Every `gdscript` code block you write in this artifact MUST be an SSF shell — not a full implementation.** This is a hard constraint that applies to all steps below.

The graybox team inherits from these shells; they do not copy-paste logic from them. Full method bodies, implementation comments, signal wiring inside `_ready`, and gameplay math belong in the game code — not here.

**SSF rules — what to KEEP:**
- `class_name ClassName extends ParentClass` — on one line
- `## One-line class contract` docstring (two lines maximum, at the top of the class)
- `signal signal_name(param: Type)` — all signals
- `enum EnumName { ... }` — enum declarations are the type contract, keep in full
- `const CONST_NAME: Type = value` — only if the value itself is the architectural contract (e.g., sentinels like `Vector3.INF`, capacity limits from Stage 4)
- `@export var name: Type` — keep without assignments (inspector wiring is architecturally meaningful)
- `var name: Type` — keep type annotation; include a default value only if the default IS the contract (e.g., `= []` for an empty array, `= false` for a gate)
- `func method(param: Type) -> ReturnType: pass` — one line per method
- `## VIRTUAL — override required` comment on virtual methods
- `_init` validation `assert`s — these are the "fail early" contract; keep them, but as one assert per field maximum

**SSF rules — what to STRIP:**
- All method bodies beyond `pass` (no motion math, no match statements, no signal connections)
- Multi-line inline implementation comments inside code blocks (`# 1. Delegate velocity…`, etc.)
- Narrative rationale paragraphs inside code blocks — move to prose above the block if needed
- Signal `.connect()` calls inside `_ready` — the Signal-Listener Contract table (prose section) is the SSoT for those
- Helper logic and variable manipulation that belongs in the implementation

**SSF example — `EntityController` (before: 117 lines → after SSF: ~25 lines):**
```gdscript
class_name EntityController extends Node3D
## Composition root + signal hub for every Movement-bearing entity (player, AI).
## No _physics_process — GameOrchestrator drives ticks via EntityTickBundle.

var _body: Body
var _brain: BaseBrain
var _stamina: StaminaComponent
var _form_broker: FormBroker
var _movement_broker: MovementBroker
var _locomotion_state: LocomotionState
var _locomotion_reader: LocomotionStateReader
var _combat_broker: CombatBroker
var _services: Array[BaseService] = []
var _motors: Array[BaseMotor] = []
var _combat_actions: Array[CombatAction] = []

func forward_forced_proposal(proposal: TransitionProposal) -> void: pass
func forward_motor_mask(mask: Array[StringName]) -> void: pass
func forward_collision_shape(new_shape: Shape3D) -> void: pass
func forward_shift_gate(enabled: bool) -> void: pass
func receive_incoming_attack(event: DamageEvent) -> void: pass
func wire_components() -> void: pass  ## VIRTUAL — override required
```

**What is NOT covered by SSF:**
Prose sections (compliance tables, Signal-Listener tables, DI contract tables, narrative rationale, diagrams) are never subject to SSF — write them as fully as the architecture requires. SSF applies only to `gdscript` fenced code blocks.

---

### 1. Design Base Classes
For every layer that implies a pattern (Services, Motors, Transitions), write the GDScript SSF shell for its Base Class (`BaseService.gd`, `BaseMotor.gd`).
- *`BaseMotor`, `BaseService`, `BaseTransition` are examples for an action game. If your game uses different pattern names (e.g., `BaseAction`, `BaseResolver`), generate the equivalent base classes for those. The enforcement mechanism — `assert(false, "override me")` — applies regardless of name.*

### 2. Enforce Virtual Methods
Define what methods a subclass MUST override. Put `assert(false, "override me")` in the base class versions to crash the game immediately if a subclass forgets.
- *Example:* A `BaseMotor` must enforce `on_enter()`, `on_exit()`, and `on_tick()`.

### 2b. Debug Overlay Contracts (project-wide — generated ONCE)

The `BaseDebugContext` class and `DebugOverlay` singleton push interface are **project-wide contracts** — they belong to the whole game, not to any one `[group]`. They must be declared **exactly once**, in the **first** `06-interfaces-and-contracts-*.md` artifact written for this project (whether that first artifact is cluster-scoped or standalone).

**Decision procedure for THIS stage run:**
1. Look in `docs/architecture/` for any prior `06-interfaces-and-contracts-*.md` artifact (cluster or standalone).
2. If a prior artifact exists and already defines `BaseDebugContext` and `DebugOverlay.push`: **do NOT redeclare them**. Instead, in this artifact's section 2b, write a single line: *"`BaseDebugContext` and `DebugOverlay.push` are defined in `06-interfaces-and-contracts-[first-group].md`. This `[group]`'s debug contexts extend `BaseDebugContext` and are shown in Stage 4 / Stage 5."*
3. If no prior artifact exists (this is the first `[group]`'s 06 artifact for this project): generate the contracts below in full. They live in this file regardless of whether this first `[group]` is a cluster or a standalone.

**`BaseDebugContext`** — base class for every F-key panel:
```gdscript
class_name BaseDebugContext
extends Node

var _data: Dictionary = {}

func get_panel_key() -> int:
    assert(false, "%s must override get_panel_key()" % get_script().resource_path)
    return -1

func render(container: VBoxContainer) -> void:
    assert(false, "%s must override render()" % get_script().resource_path)
```

**`DebugOverlay` singleton push contract:**
```gdscript
func push(context_key: int, data: Dictionary) -> void:
    if not OS.is_debug_build():
        return
    # route to matching context node by key
```

The `if not OS.is_debug_build(): return` guard is an architectural contract, not an implementation detail — it must appear here so graybox-6 can audit for it.

### 3. Define Pure Data Structures and Reader Classes
Define the structures that pass between these boundaries. 
- *Example:* The `InputStruct` with immutable flags. No logic, just fields.
- *Fail Early enforcement:* Any struct parsing or initial setup should contain basic data validation asserts, e.g., `assert(data != null)`.

Crucially, **define the Reader Wrapper classes** that will protect your Mutable SSoT state (Rule 6 + Rule 2). 
- *Example:* Code block for `BodyReader` that accepts a `CharacterBody3D` in its `_init` but only exposes `get_position()` and `get_velocity()`.

Also define `DebugSnapshot` as an optional richer wrapper for push calls:
```gdscript
class_name DebugSnapshot
extends RefCounted

var timestamp: float = 0.0
var source_node_path: NodePath
var data: Dictionary = {}
```

## Output Artifacts

Create or append to: `docs/architecture/06-interfaces-and-contracts-[group].md`

Where `[group]` is the cluster slug (TIGHT cluster) or system slug (standalone). See `00-system-map.md` § 7.

**Cluster artifacts:** contracts owned by each system in the cluster are declared once, in a per-system sub-section within this single file. Shared structs that cross system boundaries within the cluster (e.g., `Intents` owned by Movement but carrying Combat fields) are declared under the owning system's sub-section with a note naming every cluster member that populates or consumes fields.

```markdown
# [Group Name] Architecture - Interfaces & Contracts

## Pure Data Structs

```gdscript
class_name [StructName]
extends RefCounted

var [field]: [Type] = [DefaultValue]
```

## Reader Wrappers (Structural Isolation)

```gdscript
class_name [ReaderName]
extends RefCounted

var _target: [MutableType]

func _init(target: [MutableType]):
    assert(target != null, "Reader must be initialized with valid target")
    _target = target

func get_[field]() -> [Type]:
    return _target.[field]
```

## Base Classes (Strict Enforcement)

### `[BaseClassName]`
```gdscript
class_name [BaseClassName]
extends Node

func [required_method]() -> void:
    assert(false, "%s must override [required_method]()" % get_script().resource_path)
```
```

## Exit Criteria
- [ ] **SSF compliance:** every `gdscript` fenced code block is a signature shell (no method bodies beyond `pass`, no inline implementation comments, no signal wiring inside `_ready`). Prose sections are exempt.
- [ ] GDScript base classes are fully defined with runtime assertions (`assert(false, "%s must override …")` on all virtual methods).
- [ ] Pure immutable data structs are defined.
- [ ] Reader Wrapper classes are explicitly defined to enforce structural Read-Only boundaries.
- [ ] Data validation assertions are included in struct `_init` methods.
- [ ] All architectural layers defined in Stage 1 have programmatic enforcement mapped out here.
- [ ] DebugOverlay contracts (`BaseDebugContext` and `push()` interface) are either defined here (if this is the first `[group]`'s 06 artifact for this project) or referenced as already-defined-elsewhere (if a prior 06 artifact owns them). Never duplicated.
- [ ] If custom pattern vocabulary is used, base classes match it.
