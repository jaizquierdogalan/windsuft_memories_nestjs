# Tool Usage Guidelines

- Use AI-assisted code edits through structured patches; avoid dumping large code blobs in chat.
- Import dependencies at the top of files. For edits, add missing imports in a separate patch if needed.
- Break large edits into smaller, safe patches. Ensure the code remains runnable.
- Before editing, inspect files (`grep`/search + open) to get full context. Avoid blind edits.
- Terminal commands:
  - Do not auto-run potentially destructive commands.
  - Do not use `cd`; specify the working directory via tooling.
  - Print short outputs (e.g., `git log -n 10`).
- Keep `docs/user_stories.md` and `docs/traceability_matrix.md` up to date when implementing changes.
- Prefer using the local workflow `windsurf_workflows/test_and_lint.yaml` before pushes/PRs.
