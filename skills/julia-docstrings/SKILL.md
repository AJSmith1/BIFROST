---
name: julia-docstrings
description: >
  Create, revise, or audit inline documentation for Julia code following the Julia
  manual and local repository conventions. Use when working on Julia docstrings for
  modules, functions, methods, structs, abstract types, macros, callable objects,
  examples, doctests, Documenter-friendly markdown, or documentation coverage reviews.
---

# Julia Docstrings

## Workflow

Use this skill to write Julia docstrings that are helpful to developers and compatible
with Julia's documentation system.

1. Inspect local guidance first: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`,
   `ARCHITECTURE.md`, `.JuliaFormatter.toml`, `.editorconfig`, and nearby docstrings.
2. Identify the API surface that needs documentation. Prefer public APIs, exported names,
   constructors, nontrivial internal helpers, and behavior that callers must understand.
3. Place each docstring immediately before the documented object, with no blank line or
   ordinary comment between them.
4. Start function and macro docstrings with an indented signature block. Use the most
   generic useful signature; do not list every method unless behavior differs.
5. Write a one-sentence imperative summary after the signature. Use "Return ...",
   "Create ...", "Compute ...", or another direct verb.
6. Add optional sections only when they add useful caller-facing information:
   `# Arguments`, `# Keywords`, `# Returns`, `# Examples`, `# See also`,
   `# Implementation`, or `# Extended help`.
7. Verify examples before presenting them as runnable `jldoctest` blocks. If an example is
   illustrative or depends on larger setup, do not mark it as a doctest.
8. Preserve local line length and formatting. In BIFROST, use the formatter margin from
   `.JuliaFormatter.toml` unless a newer repo instruction overrides it.

## Style Rules

- Follow the Julia manual's "Writing Documentation" conventions.
- Use triple-quoted strings for normal docstrings.
- Use `@doc raw"""..."""` when the docstring contains heavy LaTeX, many backslashes,
  or dollar signs that should not be interpolated.
- Use Markdown backticks for Julia identifiers, literals, and signatures.
- Document units, domains, mutating behavior, exceptions, and numerical assumptions when
  callers need them.
- Keep implementation notes short and separated from caller-facing behavior.
- Avoid documenting obvious one-line private helpers unless the repo asks for full
  internal coverage.
- Do not invent guarantees, accepted input ranges, citations, or example output. Infer
  behavior from the implementation and tests, and state uncertainty explicitly if needed.

## References

Load `references/julia-docstring-patterns.md` when writing more than a trivial
one-sentence docstring, choosing a template, or auditing a file for documentation quality.
