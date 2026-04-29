# Run Stage Tests Skill

Run the tests for the mechanic currently being implemented.

## Process

### 1. Identify the Current Mechanic

Read `docs/mechanic-spec.md`.

Look for the mechanic marked `[~] In progress`, or if none is in-progress, the most recently completed one.

If unclear, ask the user: "Which mechanic should I run tests for?"

### 2. Run the Test

Godot does not have a built-in test runner. If a test framework (e.g., GUT) is set up:

```bash
godot --headless --path graybox-prototype res://tests/run_tests.tscn
```

Otherwise, tell the user to run the project (F5) and manually verify the mechanic against its feel contract in `docs/mechanic-spec.md`.

### 3. Report

Report:
- Which mechanic was tested
- Whether it matches the feel contract
- Any issues observed
