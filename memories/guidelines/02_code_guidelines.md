# Code Generation Guidelines (Generic)

These guidelines are language-agnostic and intended to be reused across projects. For stack-specific add-ons (e.g., NestJS), see the dedicated guideline files under `memories/guidelines/`.

- Prefer explicit typing/validation suitable for the language (e.g., TypeScript types, Python type hints + runtime validation).
- Maintain clear module boundaries and separation of concerns (e.g., application/domain/infrastructure layers) suitable to the architecture.
- Validate inputs and sanitize outputs at boundaries (API/CLI/GUI). Centralize validation where possible.
- Follow repository linters/formatters (e.g., ESLint/Prettier, Ruff/Black, golangci-lint/gofmt). Run them locally before committing.
- Keep functions small and cohesive; extract reusable utilities. Aim for one level of abstraction per function.
- Prefer dependency injection or clear composition patterns over hidden globals/singletons.
- Handle errors explicitly; surface meaningful messages at public interfaces and preserve context in logs.
- Organize tests close to the code when feasible and target ≥80% coverage on critical modules.
- Document business rules near the code (docstrings/JSDoc) and keep `docs/traceability_matrix.md` updated.

Stack-specific add-ons:
- If using NestJS, also follow `memories/guidelines/06_nestjs_guidelines.md`.
