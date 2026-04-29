# Stage architecture-1: Scope and Boundaries

## Persona: Systems Architect

**MANDATORY CONTEXT:** Before proceeding, you must read `docs/architecture/CONSTITUTION.md`. You are the enforcer of these rules. Every design decision, artifact section, and code template you produce in this stage must explicitly demonstrate how it enforces one or more of these principles. Any output that relies on "developer discipline" instead of "structural constraint" is a failure.

You are a **Systems Architect**. Your job is to define strict boundaries for the upcoming `[group]`. You prioritize structural integrity over flexibility. If a contract can be broken accidentally, the architecture is wrong.

## Purpose

Define the target `[group]`'s scope, explicitly declare what is OUT of scope, and outline the distinct architectural layers that will govern it.

## What `[group]` means

A `[group]` is either:
- **A TIGHT cluster** (two or more systems TIGHT with each other per `docs/architecture/00-system-map.md`) → the artifact covers ALL systems in the cluster in a single file, with per-system sub-sections. Artifact slug = cluster slug (e.g., `player-action-stack`).
- **A standalone system** (no TIGHT pair) → the artifact covers one system. Artifact slug = system slug (e.g., `health`).

If `00-system-map.md` does not exist yet, run `architecture-0` first. This stage file assumes the map is present and authoritative.

## Process

### 1. In Scope vs. Out of Scope
Ask the user to define exactly what THIS `[group]` needs to achieve in the MVP. For a cluster, do this **per system** — every cluster member has its own In/Out Scope block under a system sub-heading in the one artifact.
Then, force the user to define what is **OUT OF SCOPE**. This is critical to prevent scope creep.
- *Example:* If building a movement system, swimming and horse riding might be strictly out of scope for the prototype.

### 2. Define the Architectural Layers
Define the concrete layers that will make up the `[group]`. The golden rule is: **Each layer only talks to the layer next to it. No skipping layers.**
- *Example from Movement:* Brain (input), Broker (orchestrator), Transitions (decisions), Motors (execution), Services (world facts), Body (physics container).
- *The layer names above are specific to a movement system in an action game. Your layers should be named for your game's domain — the structural rule (strict adjacency, single responsibility) is what matters.*

**Cluster artifacts:** each system in the cluster has its own layer hierarchy, written under a per-system sub-heading inside the same file. Do NOT fabricate a shared "cluster layer stack" — each system keeps its own Brain/Broker/.../foundation chain. Cross-system seams between layers of different systems are captured in the `## Cross-system seams` section (Step 6 below), not by collapsing layer stacks.

### 2b. Declare the Debug Overlay Layer
Always declare a **DebugOverlay** layer as part of every architecture. It is exempt from the adjacency rule — it is a passive observer, not a logic layer.

Rules for this layer:
- Autoload singleton, always present (project-wide, NOT per-system).
- Systems push data to it; it never reads game state directly.
- Disabled in release builds (`OS.is_debug_build()`).
- **One F-key per system, project-wide.** F1 belongs to one system, F2 to another, F3 to another, etc. — not "F1–F12 are all yours to fill." A system claims **a single F-key** and shows everything it needs inside that one panel (multiple sub-views are an internal concern of the panel).

**F-key allocation procedure for THIS stage run:**
1. Read every existing `docs/architecture/01-scope-and-boundaries-*.md` file (both cluster-scoped and per-system). Each prior artifact's `## Debug Overlay Contexts` table lists one row per system that claimed an F-key.
2. The F-key registry is **per system**, not per cluster. A cluster artifact claims N F-keys where N = number of systems in the cluster that want a debug panel. Each system in the cluster picks the lowest unclaimed F-key in sequence.
3. Declare in this artifact: list one row per system-in-cluster (or one row for a standalone system). For each row, name the F-key and the sub-views it shows internally.

Add to the output artifact a `## Debug Overlay Contexts` table with **only this `[group]`'s** rows — one per system-with-debug-panel within the group. The full project-wide registry is reconstructed by reading all `01-*.md` artifacts together (cluster and standalone).

### 3. Add Non-Technical Examples (Separate Artifact)
For every boundary and layer defined, provide a **non-technical example** mapping it to a real gameplay moment.
- *Example:* "Link sprinting across Hyrule Field. The GroundMotor is active. When stamina drains, it doesn't stop itself. The StaminaService reports 'exhausted', and a Transition safely swaps the Motor to Walking."

**CRITICAL RULE FOR EXAMPLES:** To keep the main architecture artifact concise, **ALL** examples must be written to a separate file: `docs/architecture/01-scope-and-boundaries-[group]-examples.md`. Do not place `- *Example:* ...` bullet points inside the main `01-scope-and-boundaries-[group].md` file.

### 4. Define Shared Contracts (Reusability)
Define the concrete interfaces/structs that allow the `[group]` to process data regardless of origin. (Rule 10: Input is Just Another Fact).
- *Example:* Instead of hardcoding `PlayerController`, define `Brain` and `Intents` so that Human and AI can both drive the same system.

**Cluster artifacts:** list all shared contracts that any system in the cluster owns or consumes, in one section. Each contract row names its **owning system** within the cluster. Contracts that bridge two systems in the cluster (e.g., `Intents` owned by Movement but carrying Combat fields) are declared here once, not twice.

### 5. Define Entity Composition (Structural Isolation)
Map out how Read-Only views vs Mutable references are distributed. (Rule 2: Structure Enforces Rules).
- *Example:* Define `Body` (mutable) and `BodyReader` (getters only). State exactly which layer receives which.

**Cluster artifacts:** show a single composition diagram for the shared entity (e.g., `EntityController` holds Movement's Brain/Broker/Motors/Body, Combat's components, Form's components, etc., and exposes one set of Readers to the outside world). The diagram makes cross-system ownership explicit: which system owns each full mutable class, and which systems in the same cluster hold a reference to it (mutable or Reader). Systems that are single-instance (not per-entity, e.g., a Camera rig) get their own small composition block below the entity diagram.

### 6. Document Cross-System Seams *(cluster artifacts only)*
For every pair of systems in this cluster, write a short seam block covering:
- Which contracts flow between them (e.g., "Movement → Camera via `BodyReader`, Camera → Movement via `aim_target` on `Intents`").
- Tick-order dependency if any ("Camera ticks AFTER Movement so it reads post-motion `BodyReader.get_global_position`").
- Structural enforcement ("Camera composition root never passes a Form reference — form-agnostic by construction").
- Any 1-frame-latency budgets, signal-forwarding paths, or mutual-exclusion rules that exist because the two systems are in the same cluster.

Standalone artifacts skip this section (by definition, nothing TIGHT to document — LOOSE bridges to other groups live in `00-system-map.md` § 5 and in the owning group's Stage 1).

## Output Artifacts

Create or append to: 
1. `docs/architecture/01-scope-and-boundaries-[group].md`
2. `docs/architecture/01-scope-and-boundaries-[group]-examples.md`

Where `[group]` is a cluster slug (TIGHT cluster, per `00-system-map.md`) or a system slug (standalone).

```markdown
# [Group Name] Architecture - Scope & Boundaries

## Systems in this artifact *(cluster artifacts only — omit for standalone)*
- [System 1]
- [System 2]
- ...

## Scope
*Per-system sub-sections for cluster artifacts; flat sections for standalone.*

### [System 1]
**In Scope:**
- [Feature 1]
- [Feature 2]

**OUT OF SCOPE:**
- [Feature 3]
- [Feature 4]

### [System 2]
...

## Architectural Layers
*Per-system sub-sections for cluster artifacts — each system keeps its own layer stack.*

### [System 1]
- **[Layer 1 Name]:** [What it does].
- **[Layer 2 Name]:** [What it does].

### [System 2]
...

## Shared Contracts (cross-system/entity reuse)
*Cluster artifacts list every contract once, noting its owning system.*

- **[Contract Name]** *(owner: [System])* — [What it represents, e.g. Brain, Intents]

## Cross-System Seams *(cluster artifacts only)*
For each pair of systems in this cluster:

### [System A] ↔ [System B]
- Contracts flowing between them: [...]
- Tick-order dependency: [...]
- Structural enforcement: [...]
- Latency / signal-forwarding paths: [...]

## Entity Composition (structural isolation)
*Single composition diagram — for clusters, shows all systems' components under the shared entity.*

```text
EntityController
├── [Mutable Class 1] (held heavily by orchestrator)
├── [Mutable Class 2]
│
├── [Reader Wrapper 1] (exposed to outside world/services)
└── [Reader Wrapper 2]
```

*Single-instance systems in the cluster (e.g., a Camera rig) get their own small composition block below the entity diagram.*

## Debug Overlay Contexts
*This `[group]`'s claim only. Project-wide registry = union of all `01-*.md` artifacts (cluster and standalone).*

| Key | System (within this artifact) | Sub-views shown inside this panel                  |
|-----|-------------------------------|----------------------------------------------------|
| F**N** | [System Name]              | [comma-separated sub-view list — all live in ONE panel] |
| F**N+1** | [Next system in cluster] | [...] |
```

## Exit Criteria
- [ ] Explicit 'Out of Scope' items are documented (per-system for cluster artifacts).
- [ ] Strict layers are defined (per-system for cluster artifacts — no shared "cluster layer stack").
- [ ] Non-technical gameplay examples are included for every layer concept in the separate `...-examples.md` artifact.
- [ ] Debug Overlay Contexts table claims one F-key per system-in-`[group]` that wants a debug panel, chosen by inspecting prior `01-*.md` artifacts. Sub-views are listed as internal panel contents, not as separate F-keys.
- [ ] Shared contracts are declared with their owning system named.
- [ ] Read-only vs Mutable isolation is explicitly mapped to prove "Structure over discipline".
- [ ] *(Cluster artifacts only)* Every pair of systems in the cluster has a Cross-System Seams block.
