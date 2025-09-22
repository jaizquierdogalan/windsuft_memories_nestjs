# Branching and Environments

## Branches
- Long-lived branches: `main` or `master` (production), `staging` (pre-production), `dev` (development).
- Short-lived branches follow Conventional Branching: `feat/...`, `fix/...`, `chore/...`, `refactor/...`, `docs/...`, `test/...`, `ci/...`, `build/...`, `perf/...`, `style/...`.

## Source of truth
- Always branch from `master` (or `main`) for new feature/fix work. It represents the currently deployed, stable production state.

## CI/CD Mappings
- `dev`: deploy to development environment.
- `staging`: deploy to staging/pre-production.
- `main`/`master`: deploy to production.

## Configuration
- Prefer conventions to minimize infra-specific configuration; allow overrides via environment variables.

## PR Flow & Promotions
1. Feature start
   - Create `feat/...` (or `fix/...`, `chore/...`, etc.) from `master`.
2. Promote to Development (DEP/dev)
   - Open a Pull Request from your feature branch into `dev`.
   - Merge when checks pass to deploy/validate in the development environment.
3. Promote to Staging
   - Open a Pull Request from `dev` into `staging`.
   - Merge when checks pass to deploy/validate in pre-production.
4. Promote to Production
   - Open a Pull Request from `staging` into `master`.
   - Merge when checks pass to deploy to production.

## Hygiene
- Keep feature branches short-lived; rebase/merge from `master` as needed to reduce drift.
- Keep `dev` regularly synced with `master` to ensure differences are intentional and small.
- Protect `master` and `staging` with branch protections (PRs, reviews, passing checks). `dev` can be more permissive but should still run CI.
