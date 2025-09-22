# Windsurf Global Rules (Memories) — Installation & Usage

This `memories/` directory contains reusable, organization-wide rules and guidelines for Windsurf AI. The intent is to host this folder in a common repo and install it on each developer machine so all projects inherit the same baseline.

## What’s inside
- `global_rules.md`: Index that links to all embedded guidelines under `memories/guidelines/`.
- `guidelines/`: Modular docs for communication, code, commits, tooling, architecture, NestJS, CQRS, Docker, security, docs, etc.

Use this as your global baseline. Each project then adds its own `.windsurfrules.md` with project-specific overrides.

## Installation Options

Prerequisites:
- macOS/Linux with bash

### Option 1: Install as Global Windsurf Rules (All Projects)

Install globally for all Windsurf projects on your machine:

One-liner (public repo):
```bash
curl -fsSL https://raw.githubusercontent.com/jaizquierdogalan/windsuft_memories_nestjs/master/memories/install_windsurf_global_rules.sh \
  | REPO_URL="https://github.com/jaizquierdogalan/windsuft_memories_nestjs.git" bash
```
Tarball fallback (no git required):
```bash
curl -fsSL https://raw.githubusercontent.com/jaizquierdogalan/windsuft_memories_nestjs/master/memories/install_windsurf_global_rules.sh \
  | REPO_TARBALL_URL="https://github.com/jaizquierdogalan/windsuft_memories_nestjs/archive/refs/heads/master.tar.gz" bash
```

Install from local repository:
```bash
bash memories/install_windsurf_global_rules.sh
```

### Option 2: Install as Project-Specific Rules (Recommended)

Install rules only for the current project where you execute the script. This approach gives you more control and avoids affecting other projects:

One-liner (public repo):
```bash
curl -fsSL https://raw.githubusercontent.com/jaizquierdogalan/windsuft_memories_nestjs/master/memories/install_project_rules.sh | bash
```

Install from local repository (run from your project root):
```bash
bash /path/to/windsuft_memories/memories/install_project_rules.sh
```

**What the project installation does:**
- Creates `.windsurf/memories/` directory in your current project
- Copies all rules and guidelines to the project-local directory
- Creates/updates `.windsurfrules.md` to reference the local rules
- Rules apply **only to the current project** where you run the script

## Installation Paths

**Global installation** (Option 1):
- Target path: `~/.codeium/windsurf/memories`
- Affects: All Windsurf projects on your machine
- Backup: Creates `~/.codeium/windsurf/memories.backup.<timestamp>` if previous installation exists

**Project-specific installation** (Option 2):
- Target path: `./.windsurf/memories` (in your current project)
- Affects: Only the current project where you run the script
- Backup: Creates `./.windsurf/memories.backup.<timestamp>` if previous installation exists

## Verify Installation

### For Global Installation (Option 1):
- Check that `~/.codeium/windsurf/memories/global_rules.md` exists
- Verify the guidelines directory: `ls ~/.codeium/windsurf/memories/guidelines/`
- Create a `.windsurfrules.md` in your project that references the global rules:
  ```md
  ## Rules Hierarchy
  - Organization-wide rules: `~/.codeium/windsurf/memories/global_rules.md`
  - Project rules (this file): `.windsurfrules.md`
  ```

### For Project-Specific Installation (Option 2):
- Check that `./.windsurf/memories/global_rules.md` exists in your project
- Verify the guidelines directory: `ls .windsurf/memories/guidelines/`
- The `.windsurfrules.md` file should be automatically created and reference local rules:
  ```md
  ## Rules Hierarchy
  - Project-specific rules (this file): `.windsurfrules.md`
  - Shared organization rules: `.windsurf/memories/global_rules.md`
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
