# Stage architecture-4: Systems and Components

## Persona: Systems Architect

**MANDATORY CONTEXT:** Before proceeding, you must read `docs/architecture/CONSTITUTION.md`. You are the enforcer of these rules. Every design decision, artifact section, and code template you produce in this stage must enforce these principles by class shape and structural constraint. Any output that relies on "developer discipline" instead of "structural constraint" is a failure.

> [!WARNING]
> Do **NOT** write a "Core Design Principles" justification section in the artifact. Your structural compliance must be evident in the component definitions themselves, not defended in bloated prose.

You are a **Systems Architect**. Your job is to translate the theoretical boundaries and data flows from previous stages into a concrete inventory of components — and to bind each component to the performance constraints it must respect.

## Purpose

Define the exhaustive list of specific components that fulfill the scope, their responsibility boundaries, and their performance budget. This is the binding contract between architecture and execution: any code written later must not exceed these constraints.

## Process

### 1. Concrete Inventory
For every layer identified in `01-scope-and-boundaries`, list the actual Godot Nodes that will need to exist.
- *Examples:*
  - **Motors List:** `GroundMotor`, `AirMotor`, `ClimbMotor`.
  - **Services List:** `FloorContactService`, `JumpService`.
- *`GroundMotor` and `FloorContactService` are examples from a movement system in an action game. Your component names should reflect your game's domain (e.g., a card game might have `HandManager`, `DeckService`, `PlayResolver`). The structural pattern — Motors execute, Services provide facts, Transitions decide state changes — translates to any game type under different names.*

### 2. Responsibilities per Component
State exactly what subset of the system each component is responsible for. Emphasize Single Responsibility.
- *Example:* `FloorContactService` ONLY detects the ground and slope normal. It does not decide if the character can jump.

### 2b. SSoT Ownership and Access
For every piece of state, define the Single Source of Truth component that owns it (Mutable). Then explicitly list which components are given the `Reader` view (Read-Only) vs the components that get the Mutable view. (Rule 6).
- Format this as a highly condensed 4-column Markdown table, not a bulleted list.

### 3. Narrative Examples for Components
Provide examples of gameplay moments where a specific component is the "star" of the show.

> [!NOTE]
> Extract all narrative traces and examples into a separate artifact (`docs/architecture/04-systems-and-components-[group]-examples.md`) to keep the primary artifact maximally dense.

- *Example:* "Link hits a rocky face. The `MovementProbesService` is responsible for detecting this wall..." (This would be placed in the `-examples.md` file).

### 3b. Autoloads

Declare all Autoload singletons. At minimum, every architecture includes:

- **DebugOverlay** — project-wide Autoload (declared once across the whole project, NOT per-system). Receives push calls from any system; routes to F-key panels. Read-only observer. Never holds game state. No-op in release (`OS.is_debug_build()`).
  - Sub-components: declare ONE context node for THIS system, claiming the single F-key chosen in Stage 1 for this artifact. Do NOT redeclare context nodes already owned by other systems' artifacts. The full `DebugOverlay` child list is the union of all systems' Stage-4 artifacts.
  - Sub-views inside this system's panel are an internal concern of the one context node, not separate sub-components.

Performance rules for DebugOverlay:
- Panel render runs only when that panel is visible (push is a no-op when hidden).
- May use `_process` for UI refresh in debug builds only.
- Data flows strictly game → DebugOverlay. Nothing reads from it.

### 4. Performance Constraints per Component

For each component, define the performance rules it must follow. These become enforceable rules for the Graybox Rule Enforcer and Auditor.

Go through each universal rule and state how it applies to each component:

**Universal rules (apply to all — confirm nothing overrides them):**

> [!NOTE]
> Keep the explanations in the "Applied to all components" column to 1-2 sentences maximum. Do not write verbose narrative proofs.

| Rule | Applied to all components | Override allowed? |
|------|--------------------------|-------------------|
| `_process` / `_physics_process` disabled by default | **Yes** — [1 sentence max implementation note] | **No**, except [explicit exceptions] |
| Signal-only cross-node communication | **Yes** — [1 sentence max] | **No** |
| No group iteration in hot paths | **Yes** — [1 sentence max] | **No** |
| Full static typing | **Yes** — [1 sentence max] | **No** |
| No magic numbers | **Yes** — [1 sentence max] | **No** |

**Game-specific performance decisions (decide once here — the number becomes law):**

For each category below, decide the project-specific threshold. These numbers travel into every subsequent stage.

- **Object pooling threshold:** At what spawn rate does a node type require pooling? (Example: any node type spawned more than 10× per second must be pre-pooled via ObjectPool Autoload.)
- **`MultiMeshInstance3D` threshold:** At what instance count does a repeated mesh require MultiMeshInstance3D? (Example: more than 20 identical static meshes in the scene.)
- **Physics threading:** Is Jolt multithreading needed? (Default since Godot 4.6 — verify in Project Settings. State explicitly.)
- **Large population limit:** What is the maximum number of active physics-simulated nodes before performance degrades? (Example: max 50 `RigidBody3D` with `freeze = false`.)

For each component in the inventory, state which thresholds apply and why:
- *Example:* "`BulletMotor` — spawns at high rate → must use ObjectPool. Target pool size: 30."
- *Example:* "`TerrainTile` — 200+ instances expected → must use MultiMeshInstance3D on `TerrainManager`."
- *Example:* "`GroundMotor` — 1 instance, physics callback only → standard. No pooling required."

## Output Artifacts

Create or append to: `docs/architecture/04-systems-and-components-[group].md`

Where `[group]` is the cluster slug (TIGHT cluster) or system slug (standalone). See `00-system-map.md` § 7.

**Cluster artifacts:** the Concrete Inventory is written with per-system sub-sections — each system's components listed under its own heading. SSoT ownership spans the whole cluster: if `LocomotionState` is owned by Movement but read by Combat/Camera/Form, the mapping lists those cross-system consumers in one row.

```markdown
# [Group Name] Architecture - Core Components

## Concrete Inventory
*Per-system sub-sections for cluster artifacts.*

### [System 1]

#### 1. [Layer e.g. Services]
| Component | Responsibility / Rules |
|---|---|
| **`[ComponentName]`** | [Concise responsibility. 1-2 sentences max.] |
| **`[ComponentName]`** | [Concise responsibility. 1-2 sentences max.] |

### [System 2]
...

## SSoT Ownership and Access Mapping
*Cross-system ownership is made explicit in cluster artifacts.*

| State | Owning Component | Mutable Access | Read-Only Access (via Reader) |
|---|---|---|---|
| **[State Name]** | `[Component]` ([System]) | `[List]` | `[List]` |

## Performance Constraints

### Universal Rules
All components in this system are bound by the following universal rules:

| Rule | Applied to all components | Override allowed? |
|------|---------------------------|-------------------|
| `_physics_process` disabled by default | **Yes** — [1 sentence max] | **No**, except [exceptions] |
| Signal-only cross-node communication | **Yes** — [1 sentence max] | **No** |
| No group iteration in hot paths | **Yes** — [1 sentence max] | **No** |
| Full static typing | **Yes** — [1 sentence max] | **No** |
| No magic numbers | **Yes** — [1 sentence max] | **No** |

### Game-Specific Thresholds
- Object pooling threshold: [N] spawns/sec
- MultiMeshInstance3D threshold: [N] instances
- Physics threading: [enabled / not needed — reason]
- Large population limit: [N] active physics nodes

### Per-Component Performance Notes
- **[ComponentName]:** [Which thresholds apply and why]

### Autoloads
- **DebugOverlay:** [Name THIS `[group]`'s context node(s) — one per system-in-cluster that claimed an F-key in Stage 1. Do not list context nodes owned by other groups' artifacts. Confirm no-op in release.]
```

## Exit Criteria
- [ ] Exhaustive list of concrete components required to fulfill the MVP scope.
- [ ] Each component has strict Single Responsibility boundaries defined.
- [ ] SSoT Ownership explicitly mapped showing who has mutable vs read-only access (cross-system consumers listed for cluster artifacts).
- [ ] Narrative examples are extracted to the external `-examples.md` artifact.
- [ ] Universal performance rules confirmed for all components.
- [ ] Game-specific thresholds decided (pooling, MultiMesh, physics threading, population limit).
- [ ] Per-component performance notes written.
- [ ] DebugOverlay Autoload mentioned, with one context sub-component per system-in-cluster that claimed an F-key in Stage 1.
