# Windsurf Global Rules (Memories) — Installation & Usage

This `memories/` directory contains reusable, organization-wide rules and guidelines for Windsurf AI. The intent is to host this folder in a common repo and install it on each developer machine so all projects inherit the same baseline.

## What’s inside
- `global_rules.md`: Index that links to all embedded guidelines under `memories/guidelines/`.
- `guidelines/`: Modular docs for communication, code, commits, tooling, architecture, NestJS, CQRS, Docker, security, docs, etc.

Use this as your global baseline. Each project then adds its own `.windsurfrules.md` with project-specific overrides.

## Install as Windsurf Global Rules

Prerequisites:
- macOS/Linux with bash

One-liner (public repo):
```bash
curl -fsSL https://raw.githubusercontent.com/jaizquierdogalan/windsuft_memories/master/memories/install_windsurf_global_rules.sh \
  | REPO_URL="https://github.com/jaizquierdogalan/windsuft_memories.git" bash
```
Tarball fallback (no git required):
```bash
curl -fsSL https://raw.githubusercontent.com/jaizquierdogalan/windsuft_memories/master/memories/install_windsurf_global_rules.sh \
  | REPO_TARBALL_URL="https://github.com/jaizquierdogalan/windsuft_memories/archive/refs/heads/master.tar.gz" bash
```

Install (from the repository root):
```bash
bash memories/install_windsurf_global_rules.sh
```
What the script does:
- Backs up any existing global memories at `~/.codeium/windsurf/memories` to `~/.codeium/windsurf/memories.backup.<timestamp>`
- Copies this `memories/` directory to `~/.codeium/windsurf/memories`
- Idempotent and safe to re-run

Target path used by Windsurf AI:
```
~/.codeium/windsurf/memories
```

## Verify installation
- Check that `~/.codeium/windsurf/memories/global_rules.md` exists.
- Open any project and ensure a project rules file references the global index, for example in `.windsurfrules.md`:
  ```md
  ## Rules Hierarchy
  - Organization-wide rules (if present): `~/.codeium/windsurf/memories/global_rules.md`
  - Project rules (this file): `.windsurfrules.md`
  ```

## Updating the global rules
- Pull the latest changes in your shared rules repo.
- Re-run:
```bash
bash memories/install_windsurf_global_rules.sh
```
- The previous global rules are backed up with a timestamped folder.

## Using in new projects
1) Create a minimal `.windsurfrules.md` in the project root that:
   - Points to the global index (this directory) for the baseline
   - Contains only project-specific overrides (e.g., coverage thresholds, branch naming exceptions)
2) Align local enforcement (optional but recommended):
   - Husky + Commitlint (Conventional Commits)
   - Lint/format/test scripts and CI checks
3) Keep project docs and traceability up-to-date (user stories, matrix, ADRs)

## Notes
- Global rules inform the AI assistant (Cascade) about your standards. Actual enforcement is done by each repo’s tooling (hooks, CI) and by Cascade when generating/refactoring code.
- For stack-specific add-ons (e.g., NestJS, Docker), see the linked guidelines via `global_rules.md`.
