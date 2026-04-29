This README IS OBSOLETE, IT WILL BE FIXED IN THE FUTURE
# Game Workflow (Prototype)

A structured, AI-collaborative workflow for building game prototypes — from raw idea to playable prototype, one stage at a time.

This repository serves as a standalone workspace.

---

## What This Is

This is not a tool. It is a **process**.

A sequence of stages, each with a defined goal, a persona, concrete input artifacts, and concrete output artifacts. You run it with an LLM CLI (Claude Code, Gemini CLI, or any tool that supports `AGENTS.md`). The AI plays a role in each stage — asking questions, proposing designs, writing code — and you approve, adjust, and steer.

The workflow is specialized for **game development with Godot/GDScript**, producing a graybox prototype using geometric primitives, then replacing them with real assets and sound.

---

## Core Philosophies

### 1. Collaborative by Design — AI Proposes, You Approve

Every significant decision goes through a propose-approve loop. The AI suggests a mechanic implementation, a visual language, an asset pipeline approach. You say yes, no, or adjust. Nothing is implemented without your sign-off.

### 2. Personas Per Stage — Not a Generic Assistant

Each stage has a defined persona with a specific responsibility:
- **Creative Director** — asks questions until the game idea is clear
- **Systems Architect** — establishes system boundaries and constraints
- **Game Designer** — identifies mechanics and writes feel contracts
- **Systems Designer** — matches mechanics to architecture to create execution blueprints
- **Plan Generator** — translates blueprints into file-by-file execution plans
- **Code Writer** — executes plans by writing Godot code
- **Auditor** — strictly reviews written code against architectural constraints

### 3. Artifacts as Context Bridges

Every stage consumes specific input artifacts and produces specific output artifacts. The output of one stage is the input of the next. Sessions can end at any time — the artifacts capture the state.

### 4. Stage 0 — The Workflow Improves Itself

Stage 0 (Meta-Workflow) is a dedicated stage for fixing the workflow itself.

### 5. Prototype Mindset

The workflow produces a **playable graybox prototype** using Godot primitive meshes (BoxMesh, SphereMesh, CapsuleMesh, CylinderMesh, PlaneMesh) before any real assets exist. Mechanics are validated first; polish comes after.

### 6. Logs as Institutional Memory

Every stage session can be logged. You manually run the `/log-session` command to summarize the session and append the notes to the workflow changelog.

### 7. Tool-Agnostic by Design

The canonical workflow instructions live in `AGENTS.md`. Tool-specific configuration (`.claude/`, `.gemini/`) contains only thin wrappers that delegate to the canonical layer in `.agents/`.

---

## The Four Phases

| Phase | Goal | Key Outputs |
|-------|------|-------------|
| **gdd-kickstart** | Clarify the game idea, audit knowledge, fill gaps | `human-gdd.md`, `agent-gdd.xml` |
| **architecture** | Define system boundaries, data flow, and components | `docs/architecture/*.md` |
| **mechanic** | Spec mechanics, create isolated mechanic blueprints | `mechanic-spec.md`, `mechanic-designs/*.md` |
| **graybox** | Execute blueprints using a multi-agent pipeline in Godot | `execution-plans/*.md`, `graybox-prototype/` |
| **asset** | Define art direction, produce 2D/3D assets, integrate into Godot | `art-direction.md`, `asset-list.md`, sprite sheets / GLTF models |
| **sound** | Define sonic identity, produce SFX, integrate into Godot | `sound-direction.md`, `sound-event-list.md`, `.ogg files / .wav files` |

### On-Demand Stages

| Stage | Purpose |
|-------|---------|
| **Stage 0** — Meta-Workflow | Fix the workflow itself |
| **Stage teacher** — Teacher | Socratic learning sessions, rubber duck mode, and knowledge testing |

### What It Produces

- A playable Godot/GDScript prototype with all core mechanics implemented
- Graybox prototype with geometric primitives (validated before asset production)
- 2D sprites, 3D models, or mixed assets — integrated and animating in Godot
- SFX suite sourced, edited, and integrated into Godot
- Complete set of design blueprints (`human-gdd.md`, `mechanic-spec.md`, `art-direction.md`, `sound-direction.md`, architecture docs, etc.)

---

## Prerequisites

**Required:**
- An LLM CLI that supports `AGENTS.md` (Claude Code or Gemini CLI)
- Python 3
- Godot Engine 4.6+ (executable in PATH recommended)
- Git

**Required for asset phase:**
- Krita (2D art) — [krita.org](https://krita.org)
- Blender (3D modeling) — [blender.org](https://blender.org) *(3D/mixed track only)*
- Material Maker (procedural textures) *(optional)*

**Required for sound phase:**
- Audacity (audio editing) — [audacityteam.org](https://www.audacityteam.org)

**Quick check:**
```bash
echo "Python 3:  $(python3 --version 2>/dev/null || echo 'NOT FOUND')"
echo "bash:      $(bash --version 2>/dev/null | head -1 || echo 'NOT FOUND')"
echo "Godot:     $(godot --version 2>/dev/null || echo 'NOT FOUND')"
echo "git:       $(git --version 2>/dev/null || echo 'NOT FOUND')"
```

---

## Quick Start

1. **Clone this repository** into your new project directory
   ```bash
   git clone <repo-url> my-game
   cd my-game
   ```

2. **Open the project** in your LLM CLI
   ```bash
   claude  # or: gemini, etc.
   ```

3. **Start the first stage** to begin the game concept phase
   ```bash
   /start-stage gdd-1
   ```

4. **Follow the stage**. The AI will adopt the Creative Director persona and ask about your game idea. Answer, discuss, and at the end of the session, log the work:
   ```bash
   /log-session
   ```

5. **Continue stage by stage.** Each stage reads the outputs of the previous one. The workflow guides you.

---

## Project Structure

```
project-root/
├── README.md                    ← Standalone repository info
├── AGENTS.md                    ← Canonical workflow instructions (read by all LLM tools)
├── CLAUDE.md                    ← Claude Code redirect → AGENTS.md
├── GEMINI.md                    ← Gemini CLI redirect → AGENTS.md
├── .claude/                     
│   └── skills/                  ← Claude custom slash commands (thin wrappers)
├── .gemini/                     
│   └── skills/                  ← Gemini custom slash commands (thin wrappers)
├── .agents/                     ← Canonical skill content and remote agents
│   ├── gdd-to-pdf/              ← gdd_to_pdf.py script and skill
│   └── ...                      ← other skills
├── imported-artifacts/          ← Raw imports + adapted *-imported.md files
├── graybox-prototype/           ← Godot graybox prototype code
├── docs/
│   ├── logs/                    ← Conversation logs
│   ├── assets/                  ← Diagrams, concept art, textures
│   ├── adrs/                    ← Architecture Decision Records
│   └── *.md                     ← Working design artifacts
└── workflow/
    ├── stages/
    │   ├── gdd-kickstart/       ← GDD Kickstart stages
    │   ├── architecture/        ← System Architecture stages
    │   ├── mechanic/            ← Mechanic Analysis stages
    │   ├── graybox/             ← Graybox Prototype stages
    │   ├── asset/               ← Asset Pipeline stages
    │   ├── sound/               ← Sound Pipeline stages
    │   ├── writing/             ← Game Writing stages
    │   ├── testing/             ← Unit Testing stages
    │   ├── feel/                ← Feel & Details stages
    │   ├── fusion/              ← Fusion stages
    │   └── legacy/              ← Archived stages
    └── templates/               ← Output templates
```

---

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/start-stage gdd-1` | Start a specific stage |
| `/stage-0` | Start the Meta-Workflow (fix workflow issues) |
| `/teacher` | Start a teaching / knowledge-test session |
| `/log-session` | Summarize and update changelog |

---

## The Workflow Changelog

Every change to the workflow itself is logged in [`docs/workflow-changelog.md`](docs/workflow-changelog.md). This file is the record of how the workflow evolved — what problems were found, what was fixed, and why.
