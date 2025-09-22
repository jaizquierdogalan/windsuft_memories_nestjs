# Commit Message Guidelines (Conventional Commits)

Format:
```
<type>(<scope>): <short imperative summary>

[optional body]

[optional footer]
```

Types:
- feat, fix, chore, refactor, docs, test, ci, build, perf, style, revert

Rules:
- Keep the subject ≤72 chars; use present-imperative (e.g., "add", "fix").
- Use scope to identify module or area (e.g., `jira`, `graphql`, `infra`).
- Link user stories and traceability in the footer (e.g., `Refs: US-001`).
- Use `BREAKING CHANGE:` in body/footer for incompatible changes.

Examples:
- `feat(jira): add monthly throughput query handler`
- `fix(graphql): correct defect rate resolver for edge cases`
- `test(domain): cover cycle time calculation`
