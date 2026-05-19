# BIFROST

BIFROST (Birefringence In Fiber: Research and Optical Simulation Toolkit) is a
Julia codebase for simulating polarization mode dispersion in optical fibers.
Silica-based fibers whose core and/or cladding are doped with germania can be
simulated.

The active implementation is a Julia refactor of the original Python
polarization model. Legacy Python code is retained under `test/legacy-python/`
as physics reference material and should not be edited during routine Julia
work.

## Installation

1. Install Juliaup, the Julia version manager:

   ```bash
   curl -fsSL https://install.julialang.org | sh
   ```

   Follow the on-screen instructions to add Juliaup to your PATH.

2. Install Julia 1.11.7 and set as system-wide default:

   ```bash
   juliaup add 1.11.7
   juliaup default 1.11.7
   ```
## Quick Start

From the repository root:

```bash
julia --project=. test/runtests.jl
```

Human-inspected demos live under `test/human/` and write standalone HTML
artifacts under `output/`:

```bash
julia --project=. test/human/demo-smallest.jl
julia --project=. test/human/demo1.jl
julia --project=. test/human/demo2.jl
julia --project=. test/human/demo3mcm.jl
julia --project=. test/human/demo3benchmark.jl
```

The code is currently organized as include-based Julia scripts rather than a
packaged module. Most tests and demos include only the files they need.

## Building Blocks

These files are intentionally useful on their own:

| File | Standalone role |
| --- | --- |
| `src/material-properties.jl` | Material constants and spectra; no path or fiber geometry. |
| `src/geometry/path-geometry.jl` | Three-dimensional path construction and geometric queries. |
| `src/path-integral.jl` | Generic adaptive propagation for callable `K(s)` and `Kω(s)`. |

The fiber layers combine and specialize those pieces:

| File | How it extends the standalone pieces |
| --- | --- |
| `src/fiber/fiber-cross-section.jl` | Adds step-index fiber optics and birefringence responses. |
| `src/fiber/fiber-path.jl` | Binds path geometry to a cross section and assembles bend/twist generators. |

High-level authoring is path based:

1. Build geometry with `PathSpecBuilder`.
2. Freeze and place it with `build(...)`, producing a `PathSpecCached`.
3. Bind that path to a `FiberCrossSection` with `Fiber(path; cross_section,
   T_ref_K)`.
4. Propagate at a requested wavelength with `propagate_fiber(fiber; λ_m=...)`.

### Regime of Operation

This library models step-index silica-based germania-doped optical fibers. It includes chromatic dispersion effects. At this time, the library does not model other possible dopants nor specially engineered materials such as dispersion-compensating fiber, and it does not model other index profiles, such as graded-index fibers.

At present, BIFROST models birefringence from four mechanisms:
* Core noncircularity
* Asymmetric thermal stress (due to differing coefficients of thermal expansion between core and cladding when core is noncircular)
* Bending
* Twisting
It does **not** model birefringence due to:
* Cladding noncircularity
* Non-concentric cladding and core
* External asymmetric stress (e.g. pushing on the fiber in one direction)
* Transverse electric fields
* Axial magnetic fields
The inclusion of these mechanisms in BIFROST is a direction for future work.

Based on validation work, as well as the limits of the approximations made and the validity range of the data used in BIFROST, we believe the codebase correctly computes supported contributions to birefringence in the following regime.  
* Single-mode operation, $`V<2.405`$
* The weakly guiding regime $`n_{\text{co}}-n_{\text{cl}} \ll 1`$ (which implicitly requires weak germanium doping)
* The nearly-circular-core regime, $`e^2 \ll 1`$
* Bend radii must be much larger than the cladding radius, $`R \gg r_{\text{cl}}`$
* Temperatures 200 K $`\lesssim T \lesssim`$ 300 K, limited by our model for the thermo-optic coefficient $`dn/dT`$ of bulk germania glass. Our knowledge of the Sellmeier coefficients for germania glass is only at 297 K, but in the weakly doped regime, the temperature dependence of these coefficients is dominated by that of fused silica (which we know well)
* Telecom wavelengths 1~$`\mu`$m $`\lesssim \lambda \lesssim`$ 2~$`\mu`$m. Our expression for the thermo-optic coefficient of bulk germania glass is measured at 1550 nm, but in the weakly doped regime, the core's refractive index is dominated by that of fused silica, which we know well over a broad range of wavelengths.
We do not model the temperature dependence of the coefficients of thermal expansion or the photoelastic constants $`p_{11}`$ and $`p_{12}`$ in fused silica and germania, as the variation is small within the above parameter regime.

At this time, we do not moedl polarization-dependent loss or nonlinear scattering effects. These are directions of possible future work.



