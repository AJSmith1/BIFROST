using Test
using LinearAlgebra
using Bifrost

# End-to-end convergence study for the adaptive step-doubling solver. The point
# of issue #26 task 2 is to answer "how small is small enough" for `rtol`/`atol`
# and to pin a recommended default. We propagate a fixed reference fiber at a
# sequence of tightening tolerances, treat the tightest run as ground truth, and
# (1) confirm the error shrinks as tolerance tightens and (2) confirm the
# package-default `SolverParams()` already meets a documented accuracy target.

# Reference fiber: SMF-like step index, lead-in straight + 90° bend + lead-out.
# The small-radius bend injects real birefringence, so both the Jones matrix and
# the DGD respond to the solver tolerance — exactly what a convergence study
# needs. This mirrors the construction in test/human/demo-smallest.jl.
const _CONV_XS = StepIndexCrossSection(
    SilicaGermaniaGlass(0.036), SilicaGermaniaGlass(0.0),
    8.2e-6, 125e-6,
)
const _CONV_T_REF = 297.15
const _CONV_λ = 1550e-9

# Recommended-default accuracy targets. These document the answer to "how small
# is small enough": at the package default (rtol = 1e-9) the Jones matrix is
# correct to well under 1e-7 (phase-insensitive) and the DGD to under 1 fs.
# Update these intentionally if the physics model or solver changes.
const _CONV_J_TARGET = 1e-7        # phase-insensitive Jones error at default rtol
const _CONV_DGD_TARGET = 1e-15     # DGD error in seconds (1 fs)

function _conv_fiber()
    sb = SubpathBuilder(); start!(sb)
    straight!(sb; length = 0.5, meta = [Nickname("lead-in")])
    bend!(sb; radius = 0.05, angle = π / 2, meta = [Nickname("90 deg bend")])
    straight!(sb; length = 0.5, meta = [Nickname("lead-out")])
    seal!(sb)
    return Fiber(build(sb); cross_section = _CONV_XS, T_ref_K = _CONV_T_REF)
end

@testset "solver tolerance convergence" begin
    fiber = _conv_fiber()

    # Ground-truth reference, tighter than anything in the sweep below.
    ref_params = SolverParams(rtol = 1e-12, atol = 1e-14)
    J_ref, _ = propagate_fiber(fiber; λ_m = _CONV_λ, verbose = false, params = ref_params)
    Js_ref, G_ref, _ = propagate_fiber_sensitivity(
        fiber; λ_m = _CONV_λ, verbose = false, params = ref_params,
    )
    dgd_ref = output_dgd(Js_ref, G_ref)

    # Sweep from loose to tight. atol tracks rtol so the relative term dominates.
    rtols = [1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9, 1e-10]
    j_errs = Float64[]
    dgd_errs = Float64[]
    for rt in rtols
        p = SolverParams(rtol = rt, atol = rt * 1e-3)
        J, _ = propagate_fiber(fiber; λ_m = _CONV_λ, verbose = false, params = p)
        Js, G, _ = propagate_fiber_sensitivity(
            fiber; λ_m = _CONV_λ, verbose = false, params = p,
        )
        push!(j_errs, phase_insensitive_error(J_ref, J))
        push!(dgd_errs, abs(output_dgd(Js, G) - dgd_ref))
    end

    @testset "errors shrink as tolerance tightens" begin
        # T-SIM-REGRESSION: tightening rtol must improve accuracy. We require at
        # least an order-of-magnitude gain end to end, and forbid any single
        # tightening step from making the Jones error meaningfully worse. The
        # additive 1e-13 slack absorbs floor noise once the error approaches the
        # reference's own truncation level.
        @test j_errs[end] < j_errs[1] / 10
        for i in 1:(length(j_errs) - 1)
            @test j_errs[i + 1] <= 2 * j_errs[i] + 1e-13
        end
    end

    @testset "recommended default is small enough" begin
        # T-SIM-REGRESSION: the package default SolverParams() uses rtol = 1e-9.
        # Confirm that default already meets the documented accuracy targets, so
        # users need not hand-tune tolerances for typical fibers.
        @test SolverParams().rtol == 1e-9
        idx_default = findfirst(==(1e-9), rtols)
        @test idx_default !== nothing
        @test j_errs[idx_default] < _CONV_J_TARGET
        @test dgd_errs[idx_default] < _CONV_DGD_TARGET
    end
end
