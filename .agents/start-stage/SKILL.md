# Start Stage Skill

Start the specified workflow stage.

## Arguments

- Stage identifier:
  - `0` for meta-workflow
  - `teacher` for teacher
  - `<phase-name>-<stage-number>` for regular stages (e.g., `graybox-1`, `mechanic-2`)

## Instructions

1. Parse the stage identifier and build the file path using base `workflow/stages/`:
   - If `0`: Read `.agents/stage-0/SKILL.md`
   - If `teacher`: Read `.agents/teacher/SKILL.md`
   - If `plan-eval`: Read `.agents/plan-eval/SKILL.md`
   - If `architecture-0`: Read `workflow/stages/architecture/00-system-map.md`
   - If `architecture-audit`: Read `workflow/stages/architecture/07-architecture-audit.md`
   - If `gdd-<stage-number>`: Read `workflow/stages/gdd-kickstart/<NN>-*.md`
   - If `<phase-name>-<stage-number>`: Read `workflow/stages/<phase-name>/<NN>-*.md`
     where `<NN>` is the stage number zero-padded to 2 digits (1 → `01`, 9 → `09`, 10 → `10`)
   - If `<phase-name>-<stage-number>-<variant>` (e.g., `asset-4-2d`, `asset-4-3d`): Read `workflow/stages/<phase-name>/<NN>-*-<variant>.md`
     (same zero-padding rule applies)
2. Adopt the persona defined in the stage file
3. For all named phase stages (not 0 or teacher): check if the stage's output artifacts (listed in `## Output Artifacts`) already exist. If any do, follow the Existing Artifact Protocol before proceeding to step 4:
   - Identify: Identify which artifacts exist vs which are missing.
   - Read/summarize: Read the existing artifacts and summarize their current state.
   - Ask why: Ask the user "These artifacts already exist. Are we continuing previous work, fixing an issue, or starting over?"
   - Proceed: Based on the reason, either append/continue, fix the specific issue, or overwrite.
4. Follow the stage process

## Stage Mapping

### On-Demand Stages
- 0: meta-workflow (fix workflow issues)
- teacher: teacher (Socratic teaching sessions)
- plan-eval: plan-eval (evaluate a graybox mechanic design before implementation)

### gdd-kickstart: GDD Kickstart
- gdd-1: vision-and-references
- gdd-2: gameplay-experience
- gdd-3: systems-design
- gdd-4: aesthetics-and-world
- gdd-5: knowledge-research
- gdd-6: technical-roadmap
- gdd-7: agent-export

### architecture: System Architecture
- architecture-0: system-map (project-wide coupling map and batching plan)
- architecture-1: scope-and-boundaries
- architecture-2: data-flow
- architecture-3: edge-cases
- architecture-4: systems-and-components
- architecture-5: project-scaffold
- architecture-6: interfaces-and-contracts
- architecture-audit: architecture-audit (cross-artifact consistency check after all 6 artifacts exist for the target `[group]`)

### mechanic: Mechanic Analysis
- mechanic-1: mechanic-spec (extract mechanics from GDD, cross-reference architecture, write feel contracts — one-time)
- mechanic-2: mechanic-design (5-level contract review per mechanic against architecture artifacts — repeating per mechanic)

### graybox: Graybox Prototype (Godot/GDScript)
- graybox-1: project-initiator (visual language + Godot scaffold from architecture artifacts — one-time)
- graybox-2: plan-generator (translate approved mechanic design into file-by-file execution plan — per mechanic)
- *(plan-eval from phase-0 is called after graybox-2 to evaluate the execution plan)*
- graybox-4: rule-enforcer (derive enforcement checklist from architecture contracts before coding — per mechanic)
- graybox-5: code-writer (execute the approved plan — no design decisions — per mechanic)
- graybox-6: auditor (audit written code against enforcement checklist — per mechanic)
- graybox-7: debugger (on-demand — diagnose and fix runtime bugs)

Stage order (per mechanic): mechanic-2 → plan-eval → graybox-2 → plan-eval → graybox-4 → graybox-5 → graybox-6 → [graybox-7 if bugs]

### asset: Asset Pipeline
- asset-1: art-direction (style, palette, 2D/3D/mixed decision)
- asset-2: asset-list (enumerate and prioritize all assets)
- asset-3: concept (concept sketch per asset before production)
- asset-4-2d: production-2d (Krita pipeline, sprite sheets, Godot integration)
- asset-4-3d: production-3d (Blender pipeline, GLTF, Godot integration)
- asset-4-mixed: production-mixed (both tracks, cohesion rules, Godot integration)

### sound: Sound Pipeline
- sound-1: sound-direction (sonic identity, tonal rules, references)
- sound-2: sound-event-list (enumerate every SFX event from mechanics + animations + UI)
- sound-3: production-loop (library → record → synthesize fallback, Audacity edit, Godot integration)

### writing: Game Writing (conditional — narrative/dialogue games)
- writing-1: story-foundation (narrative spine, protagonist/antagonist arc, key story events, mechanic–narrative bridges)
- writing-2: world-lore (world systems with costs/limits, factions, history, lore reveal map)
- writing-3: character-voices (per-character dialogue patterns, evasion methods, sample lines, dynamic pairs)
- writing-4: scene-plan (full writing inventory: cutscenes, NPC dialogue trees, quest text, items, environmental)
- writing-5: writing-loop (per scene: brief → draft → voice check → integration check — repeating)

### testing: Unit Testing
- testing-1: test-scaffold (GUT 9.6.0 installation, test directory structure, verify setup — one-time, after graybox-1)
- testing-2: test-loop (per mechanic: identify testable units, write GUT tests, run, update design doc — repeating)

### feel: Feel & Details (on-demand)
- feel-1: graybox-feel (engine effects per interaction — particles, tween, shaders, camera shake)
- feel-2: asset-feel (upgrade placeholder effects with real art per effect)
- feel-3: sound-feel (audio variation and detail per sound event)

### fusion: Fusion (final phase)
- fusion-1: integration-loop (per mechanic — wire up all components, replace placeholders, verify everything plays together)

## Example Usage

```
/start-stage 0
```
Starts Stage 0 (Meta-Workflow) with the Workflow Engineer persona.

```
/start-stage graybox-1
```
Starts the Project Initiator stage — one-time Godot project setup (visual language + scaffold) with the Senior Godot Developer persona.

```
/start-stage graybox-2 player-movement
```
Starts the Plan Generator for the `player-movement` mechanic — translates the approved mechanic design into a step-by-step execution plan.

```
/start-stage graybox-5 player-movement
```
Starts the Code Writer for the `player-movement` mechanic — executes the approved plan, writes GDScript, escalates on ambiguity.

```
/start-stage graybox-6 player-movement
```
Starts the Auditor for the `player-movement` mechanic — cold audit of written code against the enforcement checklist.

```
/start-stage graybox-7 player-movement
```
Starts the Debugger on-demand — diagnoses and fixes runtime bugs without redesigning the mechanic.
