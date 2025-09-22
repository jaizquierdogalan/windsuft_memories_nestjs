# Project Documentation with Compodoc

References:
- Compodoc for Nest: https://docs.nestjs.com/recipes/documentation

## Requirements
- The project must be documented with Compodoc and kept up-to-date.
- Public classes and methods should have JSDoc comments.
- The generated site should be built on CI and available to the team (artifact or static hosting).

## Commands (Node/Nest projects)
- Build docs: `npm run docs:build`
- Serve docs locally: `npm run docs:serve`

## Suggested Output
- Output directory: `docs/compodoc/`
- Include version/build info in the generated site.

## Workflow
- Update code comments alongside changes.
- Run `docs:build` locally before significant PRs to catch issues.
- CI builds docs to ensure the documentation compiles successfully.
