# Git Commit Skill

Walk through a git commit workflow one command at a time. The user approves, rejects, or asks for explanation at each step.

## Interaction Pattern

For every command:

1. Show the command in a code block
2. Give a one-line plain-English explanation
3. Ask: `Run this? [yes / no / explain more]`
4. Wait for the response before proceeding

If the user says **explain more**: give a fuller explanation of what the command does and why, then ask again.
If the user says **no**: skip that step and note it, then move to the next.
If the user says **yes**: run the command and show the output before continuing.

**Never run a command without approval.**

---

## Process

### Step 1: Check What Changed

```bash
git status
```
> Shows all modified, new, and deleted files so we know what's in scope for this commit.

Run this? [yes / no / explain more]

---

### Step 2: Determine Stage Context

Use the stage identifier and context from the current session to determine what was just completed — e.g., "graybox-1 mechanic spec" or "implement player movement mechanic".

If context is unclear, ask: "What should I use as the commit message context?"

---

### Step 3: Stage the Files

Based on `git status` output, propose adding files relevant to the completed work.

For each logical group, show one `git add` command:

```bash
git add graybox-prototype/ docs/mechanic-spec.md
```
> Stages the Godot project changes and updated mechanic spec for the completed mechanic.

Run this? [yes / no / explain more]

If there are workflow artifacts that changed (e.g., `docs/mechanic-spec.md`, stage files):

```bash
git add docs/mechanic-spec.md
```
> Stages the updated mechanic spec.

Run this? [yes / no / explain more]

---

### Step 4: Review What's Staged

```bash
git diff --staged --stat
```
> Shows a summary of exactly what will be included in the commit.

Run this? [yes / no / explain more]

---

### Step 5: Commit

Propose a commit message based on the stage context:

**Format:**
- Mechanic implementation (graybox-5): `graybox: implement [mechanic name]`
- Asset added (asset-4): `asset: add [asset-name] + Godot integration`
- Sound added (sound-3): `sound: add [event-name] sfx`
- Design artifact (gdd/architecture/mechanic, graybox-1/2/4, asset-1/2, sound-1/2): `docs: [stage] [artifact name]`
- Scaffold / setup (graybox-1): `chore: scaffold Godot project`
- Meta / workflow (stage 0): `workflow: [what was fixed or added]`

Example:
```bash
git commit -m "graybox: implement player movement"
```
> Creates a commit with all staged changes and this message.

Run this? [yes / no / explain more]

---

### Step 6: Push (Optional)

Ask: "Do you want to push to the remote branch?"

If yes:

```bash
git push
```
> Uploads the commit to the remote repository on the current branch.

Run this? [yes / no / explain more]

If the branch has no upstream:

```bash
git push -u origin <current-branch>
```
> Pushes to remote and sets this branch to track the remote branch for future pushes.

Run this? [yes / no / explain more]
