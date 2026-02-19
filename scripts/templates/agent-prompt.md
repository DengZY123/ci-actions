You are an AI coding agent. Execute the following task:

**Issue #{{ISSUE_NUMBER}}**: {{TITLE}}

**Task Description**:
{{BODY}}

**Important Constraints**:
- Follow the implementation document in the issue description strictly
- Respect the safety boundaries defined in CLAUDE.md
- Only modify files in: src/, tests/, migrations/
- Do NOT modify: .github/, config/, scripts/, deploy.sh, *.env*, docker-compose*.yml, Dockerfile*
- Do NOT introduce dependencies not mentioned in the issue
- Do NOT modify files unrelated to the issue
- After completing changes, run verification:
  - uv run ruff check src/ tests/
  - uv run pytest tests/unit/

Execute this task now.
