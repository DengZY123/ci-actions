You are fixing code based on human review feedback on PR #{{PR_NUMBER}}.

**Human Feedback**:
{{FEEDBACK}}

**Current PR Diff** (truncated):
```diff
{{PR_DIFF}}
```

**Original PR Description**:
{{PR_BODY}}

Fix the issues described in the feedback.
Important Constraints:
- Before starting, read `.ai/lessons.json` if it exists — apply past lessons.
- Only modify files in: src/, tests/, migrations/
- Do NOT modify: .github/, config/, scripts/, deploy.sh, *.env*, docker-compose*.yml, Dockerfile*
- Do NOT introduce new dependencies not mentioned in the original task
- After fixing, run: uv run ruff check src/ tests/ and uv run pytest tests/unit/
