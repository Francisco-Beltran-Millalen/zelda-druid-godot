# Stage architecture-0: System Map

## Persona: Systems Architect

**MANDATORY CONTEXT:** Before proceeding, you must read `docs/architecture/CONSTITUTION.md`. The System Map is the first artifact where these rules apply — every coupling classification and contract reservation must trace back to one or more of these principles.

You are a **Systems Architect**. Your job in this stage is to map the full system landscape before any per-system deep dive. You identify which systems are tightly coupled (must be co-designed), which are loosely coupled (need a reserved contract bridge), and which are independent. This map prevents the "retro-edit rot" that occurs when systems are architected in isolation and later discovered to clash.

## Purpose

Produce a single project-wide artifact that every future `architecture-1` through `architecture-6` session references for cross-system coherence. The map answers one question for any system: **"If I start Stage 1 for this system, which other systems must be co-authored in the same session, and which can I defer behind a reserved bridge contract?"**

This stage runs **once per project**, before any per-system architecture stage (or as early as possible if some systems already have artifacts — the map incorporates their established contracts as known facts).

## Process

### 1. System Inventory

Identify every system the game needs for the MVP.

1. Ask the user: *"What are ALL the systems your game needs for MVP?"*
2. Cross-reference with the GDD (`docs/agent-gdd.xml` or equivalent GDD docs) to catch systems the user may have forgotten.
3. For each system, write:
   - **Name** — short, unambiguous (e.g., "Combat", "Zone State").
   - **One-line role** — what it owns and does, not how.
   - **Status** — `done` (has architecture artifacts), `partial` (some artifacts exist), or `pending` (no artifacts yet).

If architecture artifacts already exist for some systems, read them now. Their declared contracts, coupling points, and resource allocations are **known facts** that anchor the rest of the map.

### 2. Coupling Classification

For every pair of systems that might interact, classify the coupling:

- **TIGHT** — systems must share contracts on day 1; designing one without the other forces retro-edits to the first. Systems classified as TIGHT must be co-authored in the same Stage 1 session.
  - *Indicators:* shared data structs (e.g., one system's input struct carries fields for another), shared tick ordering, shared scene-tree hierarchy, one system mutating another's owned state.
- **LOOSE** — systems exchange data through a single Reader / event / struct bridge; they can be designed independently if the bridge contract is reserved upfront.
  - *Indicators:* one system subscribes to another's signal, one system reads another's state through a read-only wrapper, one system's Autoload provides a service the other consumes.
- **TBD** — coupling classification depends on a design decision not yet made.
  - State the deciding question (e.g., "Does Progression push stat mods into Movement via mutable reference (TIGHT) or expose a ProgressionReader (LOOSE)?").
- Pairs not listed = **NONE** — no direct data exchange.

**Evidence sources:** GDD system-interaction diagrams, existing architecture artifacts, technical unknowns sections, gameplay loop descriptions.

Present the classification as a sparse listing: every TIGHT pair and every LOOSE pair, each with a one-line reason and the contract/seam that creates the coupling (or "TBD" if the contract is not yet reserved). Do not list NONE pairs.

### 3. Cluster Identification

Group all TIGHT systems into named clusters. A cluster is a set of systems where every member is TIGHT with at least one other member in the set.

- Give each cluster a descriptive name (e.g., "Player Action Stack", "World Lifecycle Loop").
- Visualize with a Mermaid graph: tight clusters as `subgraph` boxes, loose bridges as dashed edges between clusters, TBD edges as dotted.
- Systems that are TIGHT with no other system form their own single-member cluster.

### 4. Tick Order Skeleton (per tight cluster)

For each tight cluster that participates in the game's main loop:

1. Show the known deterministic tick slots within the project's main game loop (e.g., `GameOrchestrator._physics_process`).
2. Mark **TBD** where new (pending) systems in the cluster must insert their tick.
3. If the cluster has no tick-order concern (e.g., purely event-driven systems), note "No tick ordering — event-driven."

This prevents the 1-frame-lag bug where system B reads system A's stale state because it ticked first.

### 5. Cross-Cluster Bridge Registry

For every LOOSE seam between clusters, create a row with:

| Contract | Owner | Consumer(s) | Type | Notes |
|----------|-------|-------------|------|-------|

- **Contract** — the name of the Reader, event, struct, or Autoload that bridges the seam.
- **Owner** — the system that owns and produces this contract.
- **Consumer(s)** — the system(s) that consume it.
- **Type:**
  - `STATE` — getter / struct polling (consumer reads on demand).
  - `PULSE` — signal / event (consumer reacts when fired).
  - `BOTH` — contract exposes getters AND signals.
- **Notes** — e.g., "already declared in Movement-06", "stub exists in CombatContextStub", "TBD — not yet reserved."

All bridges default to **same-tick** timing (signals fire inline in most engines; getters are synchronous). Only flag bridges with genuinely **async** timing (filesystem I/O, network) explicitly in the Notes column.

### 6. Project-Wide Resource Allocation

Pre-allocate shared project resources to prevent squatting conflicts in future Stage 1 runs:

**Debug overlay F-key registry:**
- One F-key per system **that has real-time gameplay state worth debugging at runtime**.
- Systems that are data-only (e.g., Save/Persistence), input-forwarding, or UI-presentation typically do NOT need a debug panel — mark them `N/A` in the registry.
- This naturally keeps allocation under the physical keyboard limit.
- If any systems already have F-keys allocated (from existing artifacts), those are anchored first.

**Autoload registry:**
- List every Autoload (global singleton) likely to exist.
- For each: name, owner system, one-line responsibility.
- If Autoloads already exist (from existing artifacts), those are anchored first.

### 7. Recommended Stage 1 Batching

Sequence per-cluster Stage 1 sessions in dependency order:
- Foundational clusters (no upstream dependencies) come first.
- Dependent clusters follow, noting which foundational bridges they consume.
- Note which clusters can be authored in **parallel** sessions vs which must be **sequential**.

**Artifact granularity — cluster-scoped for TIGHT clusters:**

For any TIGHT cluster (two or more systems TIGHT with each other), Stages 1–6 produce **one artifact per cluster per stage** — never one per system. All members of the cluster are authored side-by-side in the single file, with per-system sub-sections where a stage requires per-system detail (e.g., scene-tree in Stage 5). The artifact is named after the **cluster slug**, not any single system.

For **standalone systems** — systems that are not TIGHT with any other system — each produces its own per-system artifact as before.

**Naming convention for `[group]`:**
- TIGHT cluster → cluster slug (lower-kebab-case of the cluster name; e.g., "Player Action Stack" → `player-action-stack`; "World Lifecycle Loop" → `world-lifecycle-loop`).
- Standalone system → system slug (e.g., `health`, `audio`, `ui`).

Every downstream stage file (01–06, architecture-audit), `AGENTS.md`, and the `start-stage` skill use `[group]` as the placeholder in artifact paths. This map is the authoritative source for which systems share a `[group]`.

**Batching semantics:** a "session" authors one cluster artifact (or one standalone artifact) from start to finish of whatever stage it's working on. Cross-system coherence is guaranteed structurally by the single-file artifact, not by discipline during parallel editing.

## Output Artifacts

Create: `docs/architecture/00-system-map.md`

```markdown
# System Map — [Game Title]

## 1. System Inventory
| # | System | Role | Status |
|---|--------|------|--------|
| 1 | [Name] | [One-line role] | done / partial / pending |

## 2. Coupling Matrix (sparse — TIGHT, LOOSE, TBD only)
| System A | System B | Coupling | Reason | Contract / Seam |
|----------|----------|----------|--------|-----------------|

## 3. Cluster Map
[Mermaid graph]

## 4. Tick Order Skeletons
### [Cluster Name]
[Tick order with TBD slots]

## 5. Cross-Cluster Bridge Registry
| Contract | Owner | Consumer(s) | Type | Notes |
|----------|-------|-------------|------|-------|

## 6. Resource Allocation
### F-Key Registry
| Key | System | Status |
|-----|--------|--------|

### Autoload Registry
| Name | Owner | Responsibility |
|------|-------|----------------|

## 7. Recommended Stage 1 Batching
### Session 1: [Cluster Name]
- Systems: [list]
- Depends on: [nothing / prior session]
- Deliverable: `docs/architecture/01-scope-and-boundaries-[cluster-slug].md` (single cluster artifact)
### Session 2: ...
```

**Reminder when filling this section:** each session's deliverable is **one artifact per cluster** (cluster slug), not one per system. For single-member clusters and standalone systems, the deliverable is `01-scope-and-boundaries-[system-slug].md`.

## Exit Criteria
- [ ] Every MVP system appears in the inventory.
- [ ] Every TIGHT pair names the contract/seam that creates the coupling.
- [ ] Every LOOSE pair names the bridge contract, its owner, its consumers, and its type (STATE/PULSE/BOTH).
- [ ] Every TBD pair states the design question that determines its classification.
- [ ] Every tight cluster has a tick order skeleton with known + TBD slots (or is marked event-driven).
- [ ] F-key registry has no duplicates and stays within physical keyboard limits.
- [ ] Autoload registry names each singleton with its owning system.
- [ ] Recommended batching section sequences clusters so a reader can pick the next session to run.
- [ ] Read-back test: pick any system from the inventory; the map answers "if I start Stage 1 for this system, which others must be co-authored (same cluster) vs deferred (bridge contract)?"
