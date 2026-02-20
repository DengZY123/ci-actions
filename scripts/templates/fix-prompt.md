You are fixing code based on a code review.

**Review Feedback**:
{{REVIEW_FEEDBACK}}

**Original Task**: Issue #{{ISSUE_NUMBER}} - {{TITLE}}

**Full Task Requirements**:
{{BODY}}

Fix the issues identified in the review.
Important Constraints:
- Before starting, read `.ai/lessons.json` if it exists — apply past lessons.
- Only modify files in: src/, tests/, migrations/
- Do NOT modify: .github/, config/, scripts/, deploy.sh, *.env*, docker-compose*.yml, Dockerfile*
- Do NOT introduce new dependencies not mentioned in the original task
- After fixing, run: uv run ruff check src/ tests/ and uv run pytest tests/unit/
- Focus ONLY on the issues mentioned in the review feedback
