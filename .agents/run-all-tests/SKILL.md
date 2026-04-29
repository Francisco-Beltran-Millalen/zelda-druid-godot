# Run All Tests Skill

Run the full test suite for the Godot graybox prototype.

## Process

1. Confirm `graybox-prototype/project.godot` exists — if not, the scaffold hasn't been set up yet; tell the user.

2. Run Godot headless tests (if GUT or another test framework is set up):
   ```bash
   godot --headless --path graybox-prototype res://tests/run_tests.tscn
   ```

   If no automated test framework is set up, tell the user:
   > "No automated test suite found in `graybox-prototype/`. Godot tests require a framework like GUT (Godot Unit Test). Would you like to set one up, or should I test manually by running the project?"

3. Report:
   - How many tests passed / failed / skipped
   - If any failed: show the failure names and error messages
   - If all passed: confirm clearly
