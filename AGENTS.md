# AGENTS.md

## Project overview

`<project-name>`: <description>

## Key commands

```bash
pnpm install               # Install dependencies
pnpm run dev               # Start dev server
pnpm run build             # Production build
```

## Verification (required)

Before reporting code changes, pass the following:

1. `pnpm run build` — Build succeeds
2. `pnpm run typecheck` — Type check passes

## Conventions

See README.md for language, commit, branch, and PR rules.

## Git workflow

### Branching

- Create branches from `main`
- Naming: `<type>/<short-description>` (e.g., `feat/add-blog`, `fix/nav-error`)
- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore

### Commits

Use Conventional Commits:

```text
<type>[optional scope]: <description>
```

- Description in English, concise
- Breaking changes: add `!` after type (e.g., `feat!: redesign landing page`)

### Pull requests

- Merge method: **squash merge only**
- PR title: same format as commit messages
- Delete feature branch after merge

### Prohibited

- Direct push to `main`
- Force push (`--force`)
- Staging `.env` files
- Skipping hooks (`--no-verify`)
