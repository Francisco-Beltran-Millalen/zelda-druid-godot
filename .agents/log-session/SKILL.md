---
name: log-session
description: Summarize the current session and append a structured entry to docs/workflow-changelog.md.
---

## Process

1. Automatically review the session context to determine: stage/type of work, main problem/goal, what was done, files modified.
2. Draft entry using today's date:
   ## YYYY-MM-DD: [Title]
   **Problem:** [What was addressed]
   **Fix:** [What was done and why]
   **Files:**
   - `path/to/file`
3. Show draft, confirm with user.
4. Insert entry into docs/workflow-changelog.md immediately after the "# Workflow Changelog" header
   and the "---" separator, before the most recent existing entry (newest-first order).
