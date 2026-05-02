---
name: git-commit
description: Stage, commit, and optionally push changes. One confirmation before executing.
---

# Git Commit

## Process

### Step 1: Investigate (automatic — no confirmation needed)

Run these silently and read the output:

```bash
git status
git diff --stat
git log --oneline -5
```

- `git status` — shows which files changed, which are new, which are deleted.
- `git diff --stat` — shows how many lines changed in each file.
- `git log --oneline -5` — shows the last 5 commits so you can follow the existing message style.

**Safety check:** If any file looks sensitive (`.env`, `*.pem`, `*credentials*`, `*secret*`), flag it to the user and do NOT stage it.

---

### Step 2: Propose (one confirmation)

Based on the session context and the investigation output, present a single proposal:

```
Here's what I'll commit:

  Stage:
    git add <file1> <file2> ...

  Message:
    <type>: <description>

  Confirm? [yes / no / adjust]
```

- If the user says **no**: ask what to change and re-propose.
- If the user says **adjust**: ask what to change and re-propose.
- If the user says **yes**: proceed to Step 3.

**Commit message format:**

| Work type | Format |
|-----------|--------|
| Mechanic / graybox code | `graybox: <what was done>` |
| Asset added | `asset: add <name>` |
| Sound added | `sound: add <event-name> sfx` |
| Design artifact (GDD, architecture, mechanic spec) | `docs: <stage> <artifact>` |
| Scaffold / project setup | `chore: <what was set up>` |
| Workflow / skill / meta | `workflow: <what was fixed or added>` |
| Bug fix | `fix: <what was broken and how it was fixed>` |

Keep the message under 72 characters. Use lowercase. No period at the end.

---

### Step 3: Stage and show the diff (automatic)

Run the agreed `git add` command(s), then immediately show the staged summary:

```bash
git diff --staged --stat
```

This confirms exactly what will go into the commit. If something looks wrong, say so before continuing — the user can still adjust.

---

### Step 4: Commit (automatic)

```bash
git commit -m "<agreed message>"
```

Show the output. If the commit fails (e.g. a pre-commit hook), report the error clearly and suggest a fix.

---

### Step 5: Push (ask once)

Ask: **"Push to remote?"**

- If **yes** and the branch already has an upstream:
  ```bash
  git push
  ```
- If **yes** and the branch has no upstream yet:
  ```bash
  git push -u origin <current-branch>
  ```
  > `-u` sets this branch to track the remote so future `git push` commands need no arguments.
- If **no**: done. The commit is saved locally and can be pushed later.
