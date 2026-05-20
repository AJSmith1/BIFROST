using LinearAlgebra
using MonteCarloMeasurements
using Bifrost
using Bifrost.Plots
using Bifrost.Plots.PlotRuntime

include(joinpath(@__DIR__, "demo5.jl"))

# =====================================================================
# Index
# =====================================================================

const DEMO_INDEX = [
    (fn = demo_path_geometry, kwargs = NamedTuple(),
     desc = "Mixed-segment path: straight leads, circular bends, a catenary sag, and a " *
            "material twist overlay — illustrates the segment assembly API and " *
            "the Frenet–Serret sliding frame."),
    (fn = demo_path_geometry_segment_labels, kwargs = NamedTuple(),
     desc = "Same style of path as the mixed-segment demo, but each segment has a `nickname` " *
            "string; the HTML plot shows those names as 3D labels offset in the osculating plane."),
    (fn = demo_path_geometry_helix_0, kwargs = NamedTuple(),
     desc = "HelixSegment with axis_angle = 0 — winding plane aligned to fiber entry direction."),
    (fn = demo_path_geometry_helix_pi_3, kwargs = NamedTuple(),
     desc = "HelixSegment with axis_angle = π/3 — winding plane rotated by 60°."),
    (fn = demo_path_geometry_helix_2pi_3, kwargs = NamedTuple(),
     desc = "HelixSegment with axis_angle = 2π/3 — winding plane rotated by 120°."),
    (fn = demo_path_geometry_jumps_min_radius, kwargs = NamedTuple(),
     desc = "Demonstrate `jumpby!` and `jumpto!` with focus on the min_bend_radius parameter."),
    (fn = demo_modify_straight_length, kwargs = NamedTuple(),
     desc = "MCMadd(:length) on the first straight of a 3-segment inverted-U baseline."),
    (fn = demo_modify_bend_radius, kwargs = NamedTuple(),
     desc = "MCMadd(:radius) on the bend of a 3-segment inverted-U baseline."),
    (fn = demo_modify_bend_angle, kwargs = NamedTuple(),
     desc = "MCMadd(:angle) on the bend of a 3-segment inverted-U baseline."),
    (fn = demo_modify_straight_length_mul, kwargs = NamedTuple(),
     desc = "MCMmul(:length) on the first straight of a 3-segment inverted-U baseline."),
    (fn = demo_modify_bend_radius_mul, kwargs = NamedTuple(),
     desc = "MCMmul(:radius) on the bend of a 3-segment inverted-U baseline."),
    (fn = demo_modify_bend_angle_mul, kwargs = NamedTuple(),
     desc = "MCMmul(:angle) on the bend of a 3-segment inverted-U baseline."),
    (fn = demo_modify_helix_radius, kwargs = NamedTuple(),
     desc = "MCMadd(:radius) on the helix of a 4-segment (straight · bend · helix · straight) baseline."),
    (fn = demo_modify_helix_pitch, kwargs = NamedTuple(),
     desc = "MCMadd(:pitch) on the helix of a 4-segment baseline."),
    (fn = demo_modify_helix_turns, kwargs = NamedTuple(),
     desc = "MCMadd(:turns) on the helix of a 4-segment baseline."),
    (fn = demo_modify_helix_radius_mul, kwargs = NamedTuple(),
     desc = "MCMmul(:radius) on the helix of a 4-segment baseline."),
    (fn = demo_modify_helix_pitch_mul, kwargs = NamedTuple(),
     desc = "MCMmul(:pitch) on the helix of a 4-segment baseline."),
    (fn = demo_modify_helix_turns_mul, kwargs = NamedTuple(),
     desc = "MCMmul(:turns) on the helix of a 4-segment baseline."),
    (fn = demo_helix_mcm_twist, kwargs = NamedTuple(),
     desc = "Helix with MCM twist wobble on the lead-in straight (currently skipped pending twist refactor)."),
    (fn = demo_adaptive_step_doubling, kwargs = NamedTuple(),
     desc = "Adaptive step-doubling diagnostic on a smooth noncommuting generator " *
            "K(s) = α·i·σx·cos(πs) + β·i·σz·sin(2πs). Top panel: accepted/rejected " *
            "step sizes with ‖K(s)‖ overlay; bottom panel: err/tol ratio vs threshold."),
]

"""
    demo_all(; index_output)

Run every demo in `DEMO_INDEX` and write an `index.html` that links to each output file
with a short description of what it illustrates.
"""
function demo_all(; index_output::AbstractString = joinpath(@__DIR__, "..", "..", "output", "index.html"))
    entries = Tuple{String, String, String}[]

    for d in DEMO_INDEX
        result = d.fn(; d.kwargs...)
        paths = result isa NamedTuple ? values(result) : (result,)
        for v in paths
            if v isa AbstractString && endswith(v, ".html")
                push!(entries, (basename(v), v, d.desc))
            elseif v isa AbstractVector
                for item in v
                    item isa AbstractString && endswith(item, ".html") &&
                        push!(entries, (basename(item), item, d.desc))
                end
            end
        end
    end

    open(index_output, "w") do io
        println(io, """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BIFROST path-geometry demos</title>
  <style>
    body { font-family: sans-serif; max-width: 800px; margin: 2em auto; color: #222; }
    h1   { font-size: 1.5em; border-bottom: 1px solid #ccc; padding-bottom: 0.3em; }
    ul   { padding-left: 1.2em; }
    li   { margin: 1em 0; }
    a    { font-weight: bold; color: #1a6; }
    p.desc { margin: 0.3em 0 0 0; color: #555; font-size: 0.95em; }
  </style>
</head>
<body>
  <h1>BIFROST path-geometry demos</h1>
  <ul>""")
        for (title, path, desc) in entries
            println(io, "    <li>")
            println(io, "      <a href=\"$(path)\">$(title)</a>")
            println(io, "      <p class=\"desc\">$(desc)</p>")
            println(io, "    </li>")
        end
        println(io, """  </ul>
</body>
</html>""")
    end

    println("Wrote demo index to: ", index_output)
    return index_output
end

if abspath(PROGRAM_FILE) == @__FILE__
    demo_all()
end
