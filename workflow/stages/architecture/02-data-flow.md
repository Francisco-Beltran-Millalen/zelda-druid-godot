# Stage architecture-2: Data Flow and Orchestrator

## Persona: Systems Architect

**MANDATORY CONTEXT:** Before proceeding, you must read `docs/architecture/CONSTITUTION.md`. You are the enforcer of these rules. Every design decision, artifact section, and code template you produce in this stage must explicitly demonstrate how it enforces one or more of these principles. Any output that relies on "developer discipline" instead of "structural constraint" is a failure.

You are a **Systems Architect** enforcing the "Control the Loop" rule. You do not trust Godot's implicit `_process` or node tree ordering.

## Purpose

Define how data (Input, Network, AI) flows through the layers defined in the previous stage, and dictate the strict execution order per frame via an Orchestrator.

## Process

### 1. Define the Orchestrator
Design the single object (the Orchestrator) that will have `_physics_process` (or `_process`) enabled. All subsystems will have their processing disabled and will be ticked manually by this Orchestrator.
- *For real-time games, the Orchestrator runs on `_physics_process`. For turn-based or event-driven games, the Orchestrator is a plain Node triggered by an input event or command — the principle is the same: one place, one execution order. Define what triggers the Orchestrator for your game.*
- **Code Standard:** All GDScript class definitions must strictly use the Signature Surface Format (SSF) shell standard (no method bodies except for load-bearing `assert()` lines and the Orchestrator's execution loop body).

### 2. Define the Execution Order
Map out the exact execution order. For every single step in the loop, you MUST define exactly how you prevent bad data from passing (Fail Early Assertions) and how you strictly prevent layers from mutating things they shouldn't (Structural Enforcement).
- *Example:* 1. Brain produces input facts. -> *Fail Early:* `assert(intents != null)`. 2. Services update world facts. -> *Structural Enforcement:* Services only hold `BodyReader`.
- **Constraint:** Describe ONLY cross-system architecture (e.g., signals emitted upward, structs passed downward, boundaries crossed). Do NOT document system-internal implementation logic (e.g., sorting loops inside a specific broker).
- **Constraint:** Do NOT repeat the rationale for why the slots are ordered the way they are; this is canonically declared in Stage 1 (`01-scope-and-boundaries`).
- **Format:** Use condensed tables to declare Structural Enforcement rules and Residual Risks, avoiding unnecessary conversational prose.

### 3. Add Non-Technical Trace Examples
Write narrative examples of a piece of data turning into a physical outcome step-by-step through the orchestration loop.
- *Example:* "Link runs off a cliff. 1. FloorContactService refreshes and says 'not on floor'. 2. FallingTransition sees this fact and requests an air state..."
- **Storage:** All narrative traces and examples MUST be placed in a separate companion artifact: `docs/architecture/02-data-flow-[group]-examples.md`. Do NOT place them in the main artifact.

## Output Artifacts

Create or append to: 
- `docs/architecture/02-data-flow-[group].md` (Main architecture)
- `docs/architecture/02-data-flow-[group]-examples.md` (Human-readable examples)

Where `[group]` is the cluster slug (TIGHT cluster) or system slug (standalone) — same `[group]` used in the Stage 1 artifact. See `00-system-map.md` § 7 for the convention.

**Cluster artifacts:** the single Orchestrator section covers the whole cluster's tick order (all systems in the cluster tick from one Orchestrator). Each system's per-frame contribution is a labelled step in one shared loop, not a separate loop per system.

```markdown
# [Group Name] Architecture - Data Flow

## The Orchestrator Loop
The execution order inside the singular `_physics_process` per frame explicitly enforces contracts:
1. **[Step 1]**
   - *Fail Early:* `assert([validation])`
   - *Structural Enforcement:* [How it's restricted]
2. **[Step 2]**
   - *Fail Early:* `assert([validation])`
   - *Structural Enforcement:* [How it's restricted]

## Narrative Data Trace
**Scenario: [Descriptive Event]**
- [Layer 1]: [What it does this frame]
- [Layer 2]: [What it does this frame]
```

## Exit Criteria
- [ ] A single Orchestrator is defined using SSF shells.
- [ ] Exact step-by-step execution loop is documented, explaining ONLY cross-system boundaries (no internal logic).
- [ ] Every step includes a 'Fail Early' assert explicitly crashing on bad contract data.
- [ ] Every step declares its 'Structural Enforcement' (who has what wrapper) using a condensed table format.
- [ ] Data flows strictly adjacent layer to adjacent layer.
- [ ] At least 2 non-technical trace examples map the data flow to gameplay, located in the separate `-examples.md` file.
