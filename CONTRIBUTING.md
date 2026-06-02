# Contributing

Read `AGENTS.md`, `CLAUDE.md`, and `ARCHITECTURE.md` before changing this repo. They
describe the agent workflow, project structure, architectural boundaries, tests, and
invariants that should guide implementation.

## Agent Skills

This repo owns reusable agent skills under `skills/`. The Julia documentation skill lives
at `skills/julia-docstrings/` and should be used when creating, revising, or auditing
inline documentation for Julia code.

Register repo-owned skills with your local agent tools by running:

```bash
skills/install-agent-skills.sh
```

The installer symlinks the repo skill into local Codex and Claude skill directories, so
updates from `git pull` are picked up without copying files. Use
`skills/install-agent-skills.sh --dry-run` to preview the target paths.

## Tests

Run the Julia test suite with:

```bash
julia --project=. test/runtests.jl
```
