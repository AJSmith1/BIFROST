# Julia Docstring Patterns

## Function Or Method

Use one generic signature unless methods differ in caller-visible behavior.

````julia
"""
    solve_system(A, b; rtol = 1e-8, maxiter = 100)

Return an approximate solution to `A * x == b`.

# Arguments
- `A`: Linear operator or matrix.
- `b`: Right-hand-side vector.

# Keywords
- `rtol`: Relative convergence tolerance.
- `maxiter`: Maximum number of iterations.

# Examples
```jldoctest
julia> solve_system(I, [1.0, 2.0])
2-element Vector{Float64}:
 1.0
 2.0
```
"""
function solve_system(A, b; rtol = 1e-8, maxiter = 100)
    ...
end
````

Use `# Examples` without `jldoctest` when output is long, nondeterministic, or depends on
repo setup that is not shown.

## Struct Or Abstract Type

Document meaning, invariants, units, and fields that callers construct or inspect.

```julia
"""
    StepIndexFiber(core_radius_m, cladding_radius_m; core, cladding)

Represent a weakly guiding step-index fiber cross section.

Fields use SI units. `core_radius_m` must be positive and smaller than
`cladding_radius_m`.
"""
struct StepIndexFiber
    core_radius_m::Float64
    cladding_radius_m::Float64
end
```

For abstract types, document the interface that subtypes are expected to implement.

## Module

Use a module docstring to explain scope and primary entry points, not every symbol.

```julia
"""
Utilities for constructing piecewise-smooth optical fiber paths.

Most callers create a `SubpathBuilder`, add path segments, then call `build`.
"""
module PathGeometry
...
end
```

## Macro

Show the macro call form and describe generated behavior or side effects.

```julia
"""
    @with_units expr

Evaluate `expr` while checking that unit-bearing quantities are dimensionally valid.
"""
macro with_units(expr)
    ...
end
```

## Callable Object

Document the call overload separately when the object construction and call behavior are
both important.

```julia
"""
    (profile::TemperatureProfile)(s)

Return the temperature at arc length `s`.
"""
function (profile::TemperatureProfile)(s)
    ...
end
```

## Audit Checklist

- The docstring is immediately before the documented object.
- The first block is an indented Julia signature when documenting a callable API.
- The first prose sentence is direct and imperative.
- Argument and keyword names match the implementation.
- Units, valid domains, mutating behavior, and thrown errors are documented when relevant.
- Examples are verified or clearly illustrative.
- Public API names are documented before private implementation helpers.
- Markdown wraps to the local project limit.
- The docstring does not promise behavior that tests or implementation do not support.
