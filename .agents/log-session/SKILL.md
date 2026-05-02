---
name: log-session
description: Log the current session to docs/logs/YYYY-month/ — detailed entry in changelog.md, quick summary in summary.md.
---

## Process

1. Determine today's month-year folder name: `YYYY-month` (lowercase month name, e.g., `2026-may`).
2. Review the session: what was worked on, the main problem/goal, what was done, files modified.
3. Draft the **changelog entry** (detailed):
   ```
   ## YYYY-MM-DD: [Title]
   **Problem:** [What was addressed]
   **Fix:** [What was done and why]
   **Files:**
   - `path/to/file`
   ```
4. Draft the **summary entry** (2–4 sentences capturing the core of this session for quick recall).
5. Show both drafts and confirm with user.
6. Ensure `docs/logs/YYYY-month/` exists (create it if needed — use `mkdir -p` via Bash).
7. Append the changelog entry to `docs/logs/YYYY-month/changelog.md`:
   - If the file does not exist, create it with a `# Changelog — [Month YYYY]` header.
   - Insert newest entry at the top (below the header), before any existing entries.
8. Append the summary entry to `docs/logs/YYYY-month/summary.md`:
   - If the file does not exist, create it with a `# Summary — [Month YYYY]` header.
   - Insert newest entry at the top (below the header), before any existing entries.

## Reading Logs

- **Default — read `summary.md`** in the relevant month folder for a quick overview.
- **Need details — read `changelog.md`** in the same folder.
- Folder location: `docs/logs/YYYY-month/` (e.g., `docs/logs/2026-may/`).
