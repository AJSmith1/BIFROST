# Documenter.jl Compliance

Load this when the repository has a Documenter build (a `docs/make.jl`, a `docs/Project.toml`
listing `Documenter`, or `@autodocs`/`@docs` blocks in `docs/`). A docstring that *reads*
correctly can still fail `makedocs`. These rules close the gap between "looks right" and
"survives a strict build".

## The build is the real check

The audit checklist in `julia-docstring-patterns.md` is eyeball-based. When a Documenter
build exists, the authoritative compliance check is to run it and treat a nonzero exit as a
failure to fix — do not declare docstrings compliant until it passes:

```bash
# Once, to set up the docs environment (skip if docs/ already instantiated):
julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'

# The check itself:
julia --project=docs docs/make.jl
```

Documenter v1 errors (not warns) by default on broken links, missing docstrings, and
duplicate docstrings. Read the error block — it names the file, the symbol, and the rule.

## Cross-references (`@ref`)

- Link to another documented symbol with ``[`name`](@ref)`` (backticks inside the link
  text). For a specific method, give the signature: ``[`build(::Subpath)`](@ref)``.
- **Every `@ref` target must itself be documented and land on a rendered page.** A `@ref` to
  a symbol that has no docstring, or whose docstring is not pulled onto any page, is a hard
  error. This is the most common strict-build failure.
- Prefer `@ref` over bare backticks in `# See also` sections so links are checked, not just
  styled.

## Getting every docstring onto a page

A docstring that is never placed on a page triggers a "missing docs" error under strict mode.
Two ways to place them:

- **`@autodocs`** — pulls all matching docstrings from a module automatically. Preferred when
  documenting a whole module/submodule, because it also keeps `@ref` targets resolvable:

  ````markdown
  ```@autodocs
  Modules = [MyPkg.PathGeometry]
  ```
  ````

  Filter with `Order`, `Public`, `Private`, or `Pages` when needed. `@autodocs` over a module
  whose includes pull extra files into the *same* module will document those symbols too —
  scope by module, not by source file.

- **`@docs`** — lists symbols by hand. Use only when you need a curated subset; every symbol
  listed must have a docstring, and symbols `@ref`-ed from it must also be on some page.

## `checkdocs` — coverage as an error knob

`makedocs(checkdocs = ...)` controls which undocumented symbols *fail* the build:

- `:exports` (good default early on) — only exported names must be documented; undocumented
  private/`_`-prefixed helpers are allowed.
- `:all` — every symbol in the listed `modules` must be documented. Use once internal
  coverage is complete.
- `:none` — no coverage enforcement.

Match the "prefer public APIs" guidance to this knob: documenting exports first makes a
`checkdocs = :exports` build pass, and you can tighten to `:all` later.

## Duplicate / multi-method docstrings

Documenter errors when two docstrings attach to the *same binding* without distinguishing
signatures. If a function has several methods that genuinely differ for callers, give each
docstring a distinct signature line (e.g. `f(::A)` vs `f(::B)`); otherwise document the
generic signature once and describe the variation in prose.

## LaTeX and raw strings

Heavy math still applies: use `@doc raw"""..."""` so `$...$` and backslashes reach
Documenter's KaTeX renderer uninterpolated. Inline math is `$...$`; display math is a fenced
` ```math ` block.

## Quick failure → cause map

| Strict-build error mentions | Likely cause |
| --- | --- |
| "no docs found for reference" / broken `@ref` | `@ref` target undocumented or not on any page |
| "missing docstring" | symbol in `modules` not placed via `@autodocs`/`@docs`, under current `checkdocs` |
| "duplicate docs" | two docstrings on one binding without distinct signatures |
| garbled math / stray `$` | LaTeX docstring not using `@doc raw"""` |
