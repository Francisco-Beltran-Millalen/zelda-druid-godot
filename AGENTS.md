# AGENTS.md — Game Workflow (Prototype)

This is the **Game Workflow** — a structured, AI-collaborative process for building playable game prototypes.

**Session-start read path:** `docs/architecture/CONSTITUTION.md` + `docs/architecture/ARCHITECTURE-MAP.md` + this file.

**Before doing any work, identify which stage we're in and read the corresponding stage file.**

## Stage Files

### On-Demand Stages

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| 0 | `.agents/stage-0/SKILL.md` | Workflow Engineer | `docs/logs/YYYY-month/changelog.md` |
| teacher | `.agents/teacher/SKILL.md` | Patient Teacher | No artifacts |
| plan-eval | `.agents/plan-eval/SKILL.md` | Cold Skeptical Evaluator | No artifacts (cold agent report) |

### gdd-kickstart: GDD Kickstart

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| gdd-1 | `workflow/stages/gdd-kickstart/01-vision-and-references.md` | Creative Director | `docs/human-gdd.md` |
| gdd-2 | `workflow/stages/gdd-kickstart/02-gameplay-experience.md` | Lead Game Designer | `docs/human-gdd.md` |
| gdd-3 | `workflow/stages/gdd-kickstart/03-systems-design.md` | Systems Designer | `docs/human-gdd.md` |
| gdd-4 | `workflow/stages/gdd-kickstart/04-aesthetics-and-world.md` | Art & Audio Director | `docs/human-gdd.md` |
| gdd-5 | `workflow/stages/gdd-kickstart/05-knowledge-research.md` | Research Analyst | `docs/human-gdd.md` |
| gdd-6 | `workflow/stages/gdd-kickstart/06-technical-roadmap.md` | Technical Director | `docs/human-gdd.md` |
| gdd-7 | `workflow/stages/gdd-kickstart/07-agent-export.md` | Workflow Engineer | `docs/agent-gdd.xml` |


### architecture: System Architecture

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| architecture-0 | `workflow/stages/architecture/00-system-map.md` | Systems Architect | `docs/architecture/00-system-map.md` |
| architecture-1 | `workflow/stages/architecture/01-scope-and-boundaries.md` | Systems Architect | `docs/architecture/01-scope-and-boundaries-[group].md` |
| architecture-2 | `workflow/stages/architecture/02-data-flow.md` | Systems Architect | `docs/architecture/02-data-flow-[group].md` |
| architecture-3 | `workflow/stages/architecture/03-edge-cases.md` | Systems Architect | `docs/architecture/03-edge-cases-[group].md` |
| architecture-4 | `workflow/stages/architecture/04-systems-and-components.md` | Systems Architect | `docs/architecture/04-systems-and-components-[group].md` |
| architecture-5 | `workflow/stages/architecture/05-project-scaffold.md` | Systems Architect | `docs/architecture/05-project-scaffold-[group].md` |
| architecture-6 | `workflow/stages/architecture/06-interfaces-and-contracts.md` | Systems Architect | `docs/architecture/06-interfaces-and-contracts-[group].md` |
| architecture-audit | `workflow/stages/architecture/07-architecture-audit.md` | Architecture Auditor | `docs/architecture/audit-report-[group].md` |

### mechanic: Mechanic Analysis

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| mechanic-1 | `workflow/stages/mechanic/01-mechanic-spec.md` | Game Designer | `docs/mechanic-spec.md` |
| mechanic-2 | `workflow/stages/mechanic/02-mechanic-design.md` | Systems Designer | `docs/mechanic-designs/[slug].md` (repeating per mechanic) |

### graybox: Implementation (Godot/GDScript)

| Stage | Tool/Skill | Persona | When |
|-------|------|---------|------|
| graybox-1 | `workflow/stages/graybox/01-project-initiator.md` | Senior Godot Developer | Once — before any mechanic |
| slice | `/slice` | Slice Orchestrator | Per feature slice — scope → solution selection loop → plan → implement loop → tests |
| run-tests | `/run-stage-tests` | Test Engineer | Per feature slice (standalone) — verifies functionality |

### asset: Asset Pipeline

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| asset-1 | `workflow/stages/asset/01-art-direction.md` | Art Director | `docs/art-direction.md` *(production-level style guide + 2D/3D/mixed decision)* |
| asset-2 | `workflow/stages/asset/02-asset-list.md` | Production Manager | `docs/asset-list.md` |
| asset-3 | `workflow/stages/asset/03-concept.md` | Concept Artist | `docs/assets/concepts/` |
| asset-4-2d | `workflow/stages/asset/04-production-2d.md` | Senior 2D Artist | Sprite sheets + Godot integration |
| asset-4-3d | `workflow/stages/asset/04-production-3d.md` | Senior 3D Artist | GLTF models + Godot integration |
| asset-4-mixed | `workflow/stages/asset/04-production-mixed.md` | Senior Artist | Mixed assets + Godot integration |

### sound: Sound Pipeline

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| sound-1 | `workflow/stages/sound/01-sound-direction.md` | Sound Designer | `docs/sound-direction.md` |
| sound-2 | `workflow/stages/sound/02-sound-event-list.md` | Sound Designer | `docs/sound-event-list.md` |
| sound-3 | `workflow/stages/sound/03-production-loop.md` | Sound Designer | SFX files + Godot integration |

### writing: Game Writing (conditional — narrative/dialogue games)

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| writing-1 | `workflow/stages/writing/01-story-foundation.md` | Narrative Director | `docs/story-foundation.md` |
| writing-2 | `workflow/stages/writing/02-world-lore.md` | Lore Architect | `docs/world-lore.md` |
| writing-3 | `workflow/stages/writing/03-character-voices.md` | Dialogue Director | `docs/character-voices.md` |
| writing-4 | `workflow/stages/writing/04-scene-plan.md` | Narrative Producer | `docs/scene-plan.md` |
| writing-5 | `workflow/stages/writing/05-writing-loop.md` | Game Writer / Dialogue Editor | `docs/scenes/<slug>.md` (repeating per scene) |

### testing: Unit Testing

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| testing-1 | `workflow/stages/testing/01-test-scaffold.md` | Senior Godot Developer | `docs/testing-guidelines.md` + GUT setup in `graybox-prototype/` |
| testing-2 | `workflow/stages/testing/02-test-loop.md` | Test Engineer | `graybox-prototype/test/unit/test_<slug>.gd` (repeating per mechanic) |

### feel: Feel & Details (on-demand, complementary)

**On-demand phase** — invoke at any point during or after implementation phases. Each stage is independent.

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| feel-1 | `workflow/stages/feel/01-graybox-feel.md` | Game Feel Artist | Updated `graybox-prototype/` |
| feel-2 | `workflow/stages/feel/02-asset-feel.md` | Technical Artist | Updated `graybox-prototype/` |
| feel-3 | `workflow/stages/feel/03-sound-feel.md` | Sound Designer | Updated `graybox-prototype/` |

### fusion: Fusion (final phase)

| Stage | File | Persona | Output |
|-------|------|---------|--------|
| fusion-1 | `workflow/stages/fusion/01-integration-loop.md` | Integration Engineer | Production-ready mechanics + updated `docs/mechanic-spec.md` |

---

## Architectural Assumptions

- **Tool versions:** Always use the latest stable version of all tools, libraries, and engines unless the project explicitly specifies otherwise.
- **Engine:** Godot 4.6+ (GDScript)
- **Visuals (graybox):** Godot primitive meshes — BoxMesh, SphereMesh, CylinderMesh, CapsuleMesh, PlaneMesh
- **No persistent database** — game state lives in memory
- **Asset tools:** Krita, Blender, Inkscape, Material Maker *(asset phase — TBD)*
- **Audio tools:** Audacity — SFX only (music deferred)
- **3D models:** GLTF 2.0 `.glb` (binary) — established in asset-1; apply transforms before export
- **2D textures:** PNG — world: VRAM compressed + mipmaps ON; UI: lossless + mipmaps OFF
- **Audio:** OGG Vorbis for music/long ambient; WAV for short SFX (< 3s)
- **Import standards (3D):** LOD generation ON, shadow meshes ON, lightmap UV ON — set in asset-1
- **Physics engine:** Jolt (default since Godot 4.6) — verify in Project Settings if migrating from older version
- **Godot Composition Pattern (all phases):** Any self-contained concern becomes a dedicated child node, Resource, or Autoload — not inlined into the parent script. The question to ask at every composition design: "Does this behavior have a clear boundary and could it be swapped, reused, or driven externally?" If yes, make it a child node. Examples already in the project: `PlayerInput` (isolates input source from controller), `StaminaComponent` (isolates stamina logic from controller). The pattern applies to: hitboxes, audio cues, physics sensors, state machines, timers — anything with a clear interface.

---

## How to Determine Current Stage

Check `docs/` for existing artifacts:

**gdd-kickstart phase:**
- No artifacts → gdd-1
- `docs/human-gdd.md` exists, `docs/agent-gdd.xml` does not exist → (run gdd-2 through gdd-7)
- `docs/agent-gdd.xml` exists → gdd-kickstart phase complete → architecture-1

**architecture phase:**
- `docs/architecture/00-system-map.md` does not exist → architecture-0
- `docs/architecture/00-system-map.md` exists, no `01-scope-and-boundaries-[group].md` artifacts exist yet → architecture-1
- any target `[group]` has `01-scope-and-boundaries-[group].md` but not `02-data-flow-[group].md` → architecture-2
- any target `[group]` has `02-data-flow-[group].md` but not `03-edge-cases-[group].md` → architecture-3
- any target `[group]` has `03-edge-cases-[group].md` but not `04-systems-and-components-[group].md` → architecture-4
- any target `[group]` has `04-systems-and-components-[group].md` but not `05-project-scaffold-[group].md` → architecture-5
- any target `[group]` has `05-project-scaffold-[group].md` but not `06-interfaces-and-contracts-[group].md` → architecture-6
- any target `[group]` has `06-interfaces-and-contracts-[group].md` but not `audit-report-[group].md` → architecture-audit
- all target `[group]` artifacts have `docs/architecture/audit-report-[group].md` with verdict CLEAN → architecture phase complete → graybox-1

**mechanic phase:**
- `docs/mechanic-spec.md` does not exist → mechanic-1
- `docs/mechanic-spec.md` exists, any mechanic has `Analysis Status: [ ] Not started` → mechanic-2 (repeating per mechanic)
- All mechanics have `Analysis Status: [x] Done` → mechanic phase complete → graybox-2

**graybox phase (Implementation):**
- `docs/graybox-visual-language.md` does not exist → graybox-1
- `docs/graybox-visual-language.md` exists, `graybox-prototype/` does not → graybox-1 (still in progress)
- `graybox-prototype/` exists, any slice not yet complete → `/slice`
- All slices done → phase complete

> **Stage order (per slice):**
> `/slice` (scope → solution selection loop → plan → implement loop → tests, with iteration caps)

**asset phase:**
- `docs/art-direction.md` does not exist → asset-1
- `docs/art-direction.md` exists, no `asset-list.md` → asset-2
- `docs/asset-list.md` exists, concepts not done → asset-3
- Concepts done, assets not all complete → asset-4-2d / asset-4-3d / asset-4-mixed (per art-direction.md track decision)
- All assets `[x] Done` → asset phase complete

**sound phase:**
- `docs/sound-direction.md` does not exist → sound-1
- `docs/sound-direction.md` exists, no `sound-event-list.md` → sound-2
- `docs/sound-event-list.md` exists, events not all done → sound-3
- All events `[x] Done` → sound phase complete

**writing phase (conditional — narrative/dialogue games):**
- writing-1 can start after gdd-7 and graybox-1 are complete (needs `docs/agent-gdd.xml`, `docs/mechanic-spec.md`)
- writing-2 through writing-4 follow sequentially after writing-1
- writing-5 repeats per scene until all `core` entries in `docs/scene-plan.md` are `[x] done`
- writing phases run **independently of graybox phases** (can run in parallel)
- If `docs/agent-gdd.xml` flags "no narrative/dialogue", confirm with user before starting
- `docs/story-foundation.md` does not exist → writing-1
- `docs/story-foundation.md` exists, `docs/world-lore.md` does not → writing-2
- `docs/world-lore.md` exists, `docs/character-voices.md` does not → writing-3
- `docs/character-voices.md` exists, `docs/scene-plan.md` does not → writing-4
- `docs/scene-plan.md` exists, `core` scenes not all `[x] done` → writing-5 (loop)
- All `core` scenes `[x] done` → writing phase complete

**testing phase:**
- testing-1 runs once, after graybox-1 is complete (`graybox-prototype/` must exist)
- testing-2 repeats after each graybox-6 mechanic implementation
- `docs/testing-guidelines.md` does not exist → testing-1
- `docs/testing-guidelines.md` exists → testing-2 (loop per mechanic)

**feel phase (on-demand):**
- Invoke `feel-1` anytime after a mechanic is implemented — add engine feel effects
- Invoke `feel-2` anytime after real art is ready for an effect — upgrade placeholder visuals
- Invoke `feel-3` anytime after sound files exist for an event — add audio variation/detail
- No sequential dependency — each stage is independently invocable

**fusion phase:**
- Invoke `fusion-1` when a mechanic has code + assets + sounds in place
- Loop per mechanic until all target mechanics are marked `[x] Integrated`

---

## Conversation Logging

Each stage session should produce one final log file.

### Logging Strategy

- **During session**: Auto-export runs every 5 minutes for crash protection
- **On stage completion**: Export the final log using `/export-log <stage-identifier>`
- **Off-stage conversations**: No logs kept

### Exporting Logs

At the end of each stage session:

```bash
/export-log graybox-1
```

This creates: `docs/logs/stage-graybox-1-project-initiator-20260319-143022.txt`

---

## On-Demand Stages

**On-demand stages** are not part of the phase cycle. Invoke them anytime:
- **Stage 0** (`/start-stage 0`) — Fix workflow issues
- **Stage teacher** (`/start-stage teacher`) — Socratic teaching sessions
- **feel-1 / feel-2 / feel-3** — Add feel effects to any mechanic, anytime during implementation

---

## Critical Rules

1. **ALWAYS read the stage file** before starting work
2. **ALWAYS adopt the persona** defined in the stage file
3. **ALWAYS use `/start-stage`** to start stages — it runs the Existing Artifact Protocol when artifacts already exist
4. **In graybox-2: ALWAYS read `docs/mechanic-designs/[slug].md` fully before generating an execution plan** — the plan is a translation, not a redesign
5. **In graybox-5: ALWAYS read `docs/enforcement-checklists/[slug].md` before writing a single line** — violations found by the Auditor are escalated back to Code Writer
6. **In graybox-6: ALWAYS run audit COLD** — do not use context from the Code Writer session
7. **In mechanic-2: ALWAYS read ALL `docs/architecture/*.md` files first** — they define the binding contracts that every mechanic design must conform to.
8. **Follow stage order** within each phase (gdd-kickstart and architecture are strictly sequential; mechanic-2 and graybox execution loop per mechanic)
9. **writing is conditional** — only for narrative/dialogue games; can run in parallel with graybox; starts after gdd-7 + mechanic-1
10. **graybox-7 (Debugger) is on-demand** — invoke only when the running game has incorrect behavior
11. **plan-eval is on-demand** — use it to cold-evaluate any plan before implementation (mechanic designs, execution plans, architecture proposals, etc.)

---

## Quick Commands

### Slash Commands (Skills)

- `/slice` → Orchestrated slice loop (scope → solution selection loop → plan → implement loop → tests)
- `/slice-builder` → Builder sub-agent (used internally by `/slice`)
- `/slice-reviewer` → Reviewer sub-agent (used internally by `/slice`)
- `/start-stage <stage-identifier>` → Start a stage (e.g., `/start-stage graybox-1`)
- `/stage-0` → Meta-Workflow (fix workflow issues)
- `/teacher` → Teacher
- `/log-session` → Log session to `docs/logs/YYYY-month/` (changelog.md + summary.md)
- `/gdd-to-pdf` → Export GDD to PDF

### Natural Language

- "Start graybox-1" → Project Initiator (one-time Godot setup)
- "What stage are we in?" → Check `docs/` for artifacts
- "Log the session" → Summarize and update changelog

---

## Project Structure

```
project-root/
├── README.md                    ← Standalone repository info
├── AGENTS.md                    ← Canonical workflow instructions
├── CLAUDE.md                    ← Claude Code redirect to AGENTS.md
├── GEMINI.md                    ← Gemini redirect to AGENTS.md
├── .claude/                     
│   └── skills/                  ← Claude custom slash commands (thin wrappers)
├── .gemini/                     
│   └── skills/                  ← Gemini custom slash commands (thin wrappers)
├── .agents/                     ← Canonical skill content and remote agents
│   ├── gdd-to-pdf/              ← gdd_to_pdf.py script and skill
│   └── ...                      ← other skills
├── imported-artifacts/          ← Raw imports + adapted files
├── graybox-prototype/           ← Godot graybox prototype code
├── docs/
│   ├── logs/                    ← Conversation logs
│   ├── assets/                  ← Diagrams, design specs
│   ├── adrs/                    ← Architecture Decision Records
│   ├── mechanic-designs/        ← Per-mechanic design blueprints (mechanic-2)
│   └── *.md                     ← Working design artifacts
└── workflow/
    ├── stages/
    │   ├── gdd-kickstart/       ← GDD Kickstart stages (gdd-1 → gdd-7)
    │   ├── architecture/        ← System Architecture stages (architecture-1 → architecture-6)
    │   ├── mechanic/            ← Mechanic Analysis stages (mechanic-1 → mechanic-2)
    │   ├── graybox/             ← Graybox Prototype stages (Godot)
    │   ├── deferred/            ← Stages deferred to later phases
    │   └── legacy/              ← Archived superseded stage files
    ├── common-techniques/       ← Game dev technique reference library (INDEX.md for navigation)
    └── templates/               ← Output templates
```

---

## Artifact Storage

- Working design artifacts: `docs/`
- Graybox prototype code: `graybox-prototype/`
- Architecture decisions: `docs/adrs/`
- Session logs: `docs/logs/YYYY-month/changelog.md` (detailed) and `docs/logs/YYYY-month/summary.md` (quick read)
- Mechanic design journals: `docs/mechanic-designs/`
- Scene / dialogue scripts: `docs/scenes/`
- Unit tests: `graybox-prototype/test/unit/`
- Integration tests: `graybox-prototype/test/integration/`

---

## Optimization Phase Reference

Which technique is enforced in which phase. Rules marked **All phases** are never relaxed.

| Technique | Phase | Notes |
|-----------|-------|-------|
| `_process`/`_physics_process` disabled by default | architecture-4 → **all phases** | Universal rule, never relaxed |
| Signal-only cross-node communication | architecture-4 → **all phases** | Universal rule |
| No group iteration in hot paths | architecture-4 → **all phases** | Universal rule |
| Godot Composition Pattern (child nodes for isolatable concerns) | architecture-4 → **all phases** | Universal rule; `PlayerInput` and `StaminaComponent` are examples; enables network/AI input swapping and reuse |
| Simple collision shapes (gameplay nodes) | graybox-5 | Graybox only — static env may use mesh collision in asset phase |
| Object pooling thresholds | architecture-4 | Thresholds decided at architecture-4; may be revised in asset phase |
| MultiMeshInstance3D thresholds | architecture-4 | Thresholds decided at architecture-4; may be revised in asset phase |
| Jolt physics (default, Godot 4.6) | architecture-4 (verify) | No action for new 4.6 projects; verify if migrating |
| Unshaded rendering / no GI | graybox only | Replaced at asset-1 with GI decision |
| Asset import format standards | **asset-1** | GLTF .glb, PNG, OGG/WAV — defined in `docs/art-direction.md` |
| LOD auto-generation (import setting) | **asset-1** | ON for all 3D meshes; Godot 4.6 LOD pruning improved for multi-part meshes |
| Occlusion culling plan | **asset-1** | Bake after level geometry finalized |
| GI stance (LightmapGI / VoxelGI / SDFGI) | **asset-1** | Decided before any lighting is baked |
| Texture compression per use case | **asset-1** | VRAM for world; lossless for UI |
| SSR configuration | **feel phase** | After real geometry exists; Godot 4.6 SSR fully rewritten — half vs full resolution |
| Particle budgets | **feel phase** | Max particles per effect type |
| Full profiler pass | **fusion phase** | Before any mechanic marked ship-ready |
| Network bandwidth profiling | **fusion phase** | Bytes/sec per player under full load (multiplayer only) |

---

## Project Status

> Current phase and stage are determined by checking `docs/` for existing artifacts.

### Meta Artifacts
- [ ] `docs/logs/YYYY-month/` (session logs)

### gdd-kickstart phase
- [ ] `docs/human-gdd.md` started ← gdd-1 complete
- [ ] `docs/human-gdd.md` section 4 ← gdd-2 complete
- [ ] `docs/human-gdd.md` section 5 ← gdd-3 complete
- [ ] `docs/human-gdd.md` section 6 ← gdd-4 complete
- [ ] `docs/human-gdd.md` section 7 ← gdd-5 complete
- [ ] `docs/human-gdd.md` section 8 ← gdd-6 complete
- [ ] `docs/agent-gdd.xml` ← gdd-7 complete

### architecture phase
- [ ] `docs/architecture/00-system-map.md` ← architecture-0 complete
- [ ] `docs/architecture/01-scope-and-boundaries-[group].md` ← architecture-1 complete
- [ ] `docs/architecture/02-data-flow-[group].md` ← architecture-2 complete
- [ ] `docs/architecture/03-edge-cases-[group].md` ← architecture-3 complete
- [ ] `docs/architecture/04-systems-and-components-[group].md` ← architecture-4 complete
- [ ] `docs/architecture/05-project-scaffold-[group].md` ← architecture-5 complete
- [ ] `docs/architecture/06-interfaces-and-contracts-[group].md` ← architecture-6 complete
- [ ] `docs/architecture/audit-report-[group].md` verdict CLEAN ← architecture-audit complete

### mechanic phase
- [ ] `docs/mechanic-spec.md` ← mechanic-1 complete
- [ ] All mechanics have `Analysis Status: [x] Done` in `mechanic-spec.md` ← mechanic-2 complete (per mechanic)
- Design documents in `docs/mechanic-designs/<slug>.md`

### graybox phase (Implementation)
- [ ] `docs/graybox-visual-language.md` + `graybox-prototype/` setup ← graybox-1 complete
- Per slice loop:
  - [ ] Slice complete (solutions doc + plan written, code audited, tests pass) ← `/slice` complete

### asset phase
- [ ] `docs/art-direction.md` ← asset-1 complete
- [ ] `docs/asset-list.md` ← asset-2 complete
- [ ] `docs/assets/concepts/` populated ← asset-3 complete
- [ ] All assets `[x] Done` in `asset-list.md` ← asset-4 complete

### sound phase
- [ ] `docs/sound-direction.md` ← sound-1 complete
- [ ] `docs/sound-event-list.md` ← sound-2 complete
- [ ] All events `[x] Done` in `sound-event-list.md` ← sound-3 complete

### writing phase (conditional — narrative/dialogue games)
- [ ] `docs/story-foundation.md` ← writing-1 complete
- [ ] `docs/world-lore.md` ← writing-2 complete
- [ ] `docs/character-voices.md` ← writing-3 complete
- [ ] `docs/scene-plan.md` ← writing-4 complete
- [ ] All `core` entries `[x] done` in `docs/scene-plan.md` ← writing-5 complete
- Scenes written to `docs/scenes/<slug>.md` (one file per scene)

### testing phase
- [ ] `docs/testing-guidelines.md` ← testing-1 complete
- [ ] Test files `graybox-prototype/test/unit/test_<slug>.gd` per mechanic ← testing-2 complete (per mechanic)

### feel phase (on-demand — no completion gate)
- feel-1: engine feel effects per mechanic (invoke per mechanic, multiple times)
- feel-2: asset feel upgrades per effect (invoke when art is ready)
- feel-3: sound feel detail per event (invoke when audio is ready)

### fusion phase
- [ ] All target mechanics `[x] Integrated` in `docs/mechanic-spec.md` ← fusion complete
