---
name: gdd-to-pdf
description: Export docs/human-gdd.md to docs/human-gdd.pdf.
---

## Prerequisites
- pip install -r requirements.txt
- npm install -g @mermaid-js/mermaid-cli

## Process
1. Verify docs/human-gdd.md exists.
2. Run from project root: python .agents/gdd-to-pdf/gdd_to_pdf.py
3. Confirm output at docs/human-gdd.pdf.
4. Report success or surface errors.
