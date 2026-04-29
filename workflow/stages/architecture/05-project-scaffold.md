# Stage architecture-5: Project Scaffold

## Persona: Systems Architect

**MANDATORY CONTEXT:** Before proceeding, you must read `docs/architecture/CONSTITUTION.md`. You are the enforcer of these rules. Every design decision, artifact section, and code template you produce in this stage must explicitly demonstrate how it enforces one or more of these principles. Any output that relies on "developer discipline" instead of "structural constraint" is a failure.

You are a **Systems Architect**. You think in exact Godot Engine primitives. Abstractions do not compile.

## Purpose

Map the abstract components list directly into a physical Godot Scene Tree structure.

## Process

### 1. Define Node Hierarchies
Take the inventory from `04-systems-and-components-[group].md` and map components to their exact Node Types (`Node`, `Node3D`, `CharacterBody3D`, `RayCast3D`).

**Cluster artifacts:** write one scene-tree sub-section per system within the `[group]`. If multiple systems in the cluster share a host entity (e.g., Movement + Combat + Form all live under the same `EntityController`), the scaffold shows the shared host once with all systems' children nested below — one text diagram, not three.

### 2. Parent-Child Relationships
Show how components live in relation to each other. Godot's Composition Pattern means logic sits in child nodes. Design the scaffold layout.
- Ask: Where does the Orchestrator sit? Are Services grouped logically? Is the Collision representation separated from Visuals?
- The DebugOverlay Autoload is **not** a scene-tree child. It is **project-wide** — declared once across the whole project, not per-`[group]`. In this artifact's `## Autoloads` section, show DebugOverlay with **only this `[group]`'s context nodes** added under it (one per system in the cluster that claimed an F-key in Stage 1). Do not list context nodes owned by other groups' artifacts.

### 3. Scaffold Diagram
Draw an ASCII/Text-based directory and Scene Tree map for the `[group]` — cluster artifacts include every system in the cluster.

## Output Artifacts

Create or append to: `docs/architecture/05-project-scaffold-[group].md`

Where `[group]` is the cluster slug (TIGHT cluster) or system slug (standalone). See `00-system-map.md` § 7.

```markdown
# [Group Name] Architecture - Project Scaffolding

## Godot Scene Tree Scaffold

```text
Player (CharacterBody3D)
│
├── CollisionShape3D
├── Visuals (Node3D)
│
├── [Orchestrator Node] (Node)
│
├── [Component Group e.g. Motors] (Node)
│   ├── [Motor 1] (Node)
│   └── [Motor 2] (Node)

## Autoloads (Project Settings → Autoload)
DebugOverlay (Node) — PROCESS_MODE_ALWAYS, debug build only — project-wide singleton
├── [System 1 in this group]Context — claims F**N** from Stage 1] (Node)
└── [System 2 in this group]Context — claims F**N+1** from Stage 1] (Node)
# (one child per system in this group that claimed an F-key)

# Note: Other groups' context nodes are added by their own 05-*.md artifacts.
# The full child list of DebugOverlay = union of all artifacts across all groups.
```

## Node Rationale
Only document non-obvious, structural decisions (e.g., separating visuals from physics). Do NOT document trivial parent-child folder groupings.

- **[Node Name]:** Why it sits where it sits (only if non-obvious).
- **DebugOverlay:** Autoload because it must survive scene transitions and be addressable from any `.gd` file without a node path reference.
```

## Exit Criteria
- [ ] Complete Godot Scene Tree layout text diagram.
- [ ] Explicit Godot types are assigned to all components.
- [ ] DebugOverlay appears in the Autoloads section with one context node per system-in-group that claimed an F-key in Stage 1.
