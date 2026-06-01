using LinearAlgebra
using GLMakie 

const degrees = π / 180

function azel_2_xyz(az, el; pol=1.0)
    phi = 2 * az
    chi = -2 * el + 90 * degrees

    x = pol * sin(chi) * cos(phi)
    y = pol * sin(chi) * sin(phi)
    z = pol * cos(chi)

    return x, y, z
end

function jones_to_mueller(J)
    U = [
        1 0 0 1;
        1 0 0 -1;
        0 1 1 0;
        0 1im -1im 0
    ]

    M = U * kron(J, conj(J)) * inv(U)
    return real(M)
end

function mueller_to_axis_angle(M)
    R = M[2:4, 2:4]
    cos_angle = clamp((tr(R) - 1) / 2, -1, 1)
    angle = acos(cos_angle)
    skew = (R - R') / 2
    axis = [
        skew[3,2],
        skew[1,3],
        skew[2,1]
    ]
    n = norm(axis)
    if n < 1e-10
        axis = [1.0, 0.0, 0.0]
    else
        axis ./= n
    end
    return axis, angle
end

function rotation_arc(axis, start_vec, angle; n_points=120)
    axis = normalize(axis)
    u = start_vec - dot(start_vec, axis) * axis
    if norm(u) < 1e-10
        perp = abs(axis[1]) < 0.9 ? [1.0, 0.0, 0.0] : [0.0, 1.0, 0.0]
        u = perp - dot(perp, axis) * axis
    end
    u = normalize(u)
    v = cross(axis, u)
    ts = range(0, angle, length=n_points)
    r = norm(start_vec - dot(start_vec, axis) * axis)
    arc = [r * (cos(t)*u + sin(t)*v) + dot(start_vec, axis)*axis for t in ts]  # only once
    return getindex.(arc, 1), getindex.(arc, 2), getindex.(arc, 3)
end

function make_cone(tip, direction, radius=0.035, height=0.08)
    direction = normalize(direction)
    base_center = tip - direction * height
    
    perp = abs(direction[1]) < 0.9 ? [1.0, 0.0, 0.0] : [0.0, 1.0, 0.0]
    u = normalize(perp - dot(perp, direction) * direction)
    v = cross(direction, u)
    
    n_sides = 16
    angles = range(0, 2π, length=n_sides+1)[1:end-1]
    
    vertices = Vector{Point3f}(undef, n_sides + 1)
    vertices[1] = Point3f(tip...)
    for (k, a) in enumerate(angles)
        pt = base_center + radius*(cos(a)*u + sin(a)*v)
        vertices[k+1] = Point3f(pt...)
    end
    
    faces = [GLTriangleFace(1, i+1, mod1(i+1, n_sides)+1) for i in 1:n_sides]
    
    return vertices, faces
end

function plot_poincare(;
    figsize    = (700, 650),
    draw_axes  = true,
    draw_guides = true,
    sphere_alpha = 0.15,
    title      = "", )

    fig = Figure(size=figsize)

    # Making axes
    ax  = Axis3(fig[1,1];
        aspect = :equal,
        title = title,
        titlesize = 20,      
        xgridvisible = false,
        ygridvisible = false,
        zgridvisible = false,
        xspinesvisible = false,
        yspinesvisible = false,
        zspinesvisible = false,
        xticksvisible = false,
        yticksvisible = false,
        zticksvisible = false,
        xlabelvisible = false,
        ylabelvisible = false,
        zlabelvisible = false,
        xticklabelsvisible = false,
        yticklabelsvisible = false,
        zticklabelsvisible = false,
        viewmode = :fit,
        limits = (-1.2, 1.2, -1.2, 1.2, -1.2, 1.2),
    )

    # Making sphere surface
    el_range = range(-45*degrees, 45*degrees, length=60)
    az_range = range(0, 180*degrees, length=60)
    xs = [azel_2_xyz(az, el)[1] for el in el_range, az in az_range]
    ys = [azel_2_xyz(az, el)[2] for el in el_range, az in az_range]
    zs = [azel_2_xyz(az, el)[3] for el in el_range, az in az_range]
    surface!(ax, xs, ys, zs;
        color     = fill(RGBAf(0.4, 0.6, 0.9, sphere_alpha), size(xs)),
        shading   = true,
        transparency = true,
    )
    
    # Guide circles
    if draw_guides
        θ = range(0, 2π, length=361)
        guide_style = (; color=:darkslategray, linestyle=:dashdot, linewidth=1.5)
        lines!(ax, sin.(θ), cos.(θ), zeros(361); guide_style...)   # S3=0
        lines!(ax, sin.(θ), zeros(361), cos.(θ); guide_style...)   # S2=0
        lines!(ax, zeros(361), sin.(θ), cos.(θ); guide_style...)   # S1=0
    end

    # Stokes axes
    if draw_axes
        L = 1.2
        for (vec, label, col) in [
            ([L,0,0],  "S1",  :red),
            ([-L,0,0], "-S1", :red),
            ([0,L,0],  "S2",  :green),
            ([0,-L,0], "-S2", :green),
            ([0,0,L],  "S3",  :blue),
            ([0,0,-L], "-S3", :blue),
        ]
            # solid positive, dashed negative
            ls = startswith(label, "-") ? :dash : :solid
            lines!(ax, [0, vec[1]], [0, vec[2]], [0, vec[3]];
                color=col, linewidth=3, linestyle=ls)
            text!(ax, vec[1], vec[2], vec[3];
                text=label,
                color=col,
                fontsize=18,
                font=:bold,
                align=(:center, :center),
            )
        end
    end

    return fig, ax
end

function jones_arc(ax, J::Matrix{ComplexF64};
    axis_color       = :black,
    arc_color        = :crimson,
    axis_length      = 1.25,
    axis_width       = 5,
    arc_width        = 3,
    n_arrows         = 3,
    start_vec        = nothing,
    show_angle_label = true,)

    M    = jones_to_mueller(J)
    rotation_axis, angle = mueller_to_axis_angle(M)

    # Rotation axis
    av = rotation_axis * axis_length
    lines!(ax, [-av[1], av[1]], [-av[2], av[2]], [-av[3], av[3]];
        color=axis_color, linewidth=axis_width)

    # Arc start vector
    sv = if start_vec === nothing
        perp = abs(rotation_axis[1]) < 0.9 ? [1.0, 0.0, 0.0] : [0.0, 1.0, 0.0]
        normalize(perp - dot(perp, rotation_axis) * rotation_axis)
    else
        normalize(start_vec)
    end

    x_arc, y_arc, z_arc = rotation_arc(rotation_axis, sv, angle)

    # Arc line
    lines!(ax, x_arc, y_arc, z_arc; color=arc_color, linewidth=arc_width)

    # Arrowheads
    if n_arrows > 0
        n_pts = length(x_arc)
        indices = round.(Int, range(11, n_pts - 2, length=n_arrows))
        for i in indices
            tangent = normalize([
                x_arc[i+1] - x_arc[i-1],
                y_arc[i+1] - y_arc[i-1],
                z_arc[i+1] - z_arc[i-1],
            ])
            tip = [x_arc[i], y_arc[i], z_arc[i]]
            verts, faces = make_cone(tip, tangent)
            mesh!(ax, verts, faces; color=arc_color)
        end
    end

    # Angle label
    if show_angle_label
        mid = length(x_arc) ÷ 2
        lx, ly, lz = x_arc[mid]*1.15, y_arc[mid]*1.15, z_arc[mid]*1.15
        text!(ax, lx, ly, lz;
            text     = "$(round(angle/degrees, digits=1))°",
            color    = arc_color,
            fontsize = 16,
            font     = :bold,
            align    = (:center, :center),
        )
    end

    return ax
end

function plot_jones(J::Matrix{ComplexF64}; 
    figsize=( 700, 650), draw_axes=true, draw_guides=true,
    sphere_alpha=0.15, title="", kwargs...)

    fig, ax = plot_poincare(;
        figsize, draw_axes, draw_guides, sphere_alpha, title)
    jones_arc(ax, J; kwargs...)
    return fig, ax
end

function stokes_from_jones_vec(e::AbstractVector{<:Complex})
    e  = e ./ sqrt(sum(abs2, e))
    S1 =  real(abs2(e[1]) - abs2(e[2]))
    S2 =  2real(e[1] * conj(e[2]))
    S3 = -2imag(e[1] * conj(e[2]))
    return S1, S2, S3
end

function jones_vec_from_azel(az::Real, el::Real)
    ψ, χ = az, el
    ComplexF64[
        cos(χ)*cos(ψ) - 1im*sin(χ)*sin(ψ),
        cos(χ)*sin(ψ) + 1im*sin(χ)*cos(ψ),
    ]
end

function stokes_scatter!(ax, xs, ys, zs;
    param      = nothing,
    color      = :crimson,
    colormap   = :plasma,
    markersize = 10,
    label      = "",
    colorrange = nothing,)

    if param !== nothing
        cr = something(colorrange, extrema(param))
        sc = scatter!(ax, xs, ys, zs;
            color      = collect(Float64, param),
            colormap,
            markersize,
            label,
            colorrange = cr,
        )
    else
        sc = scatter!(ax, xs, ys, zs; color, markersize, label)
    end
    return sc
end

function plot_stokes_vec(datasets...;
    figsize       = (700, 650),
    draw_axes     = true,
    draw_guides   = true,
    sphere_alpha  = 0.15,
    title         = "",
    param         = nothing,
    param_name    = nothing,
    colormap      = :plasma,
    color         = :crimson,
    markersize    = 10,
    show_colorbar = true,)

    n = length(datasets)
 
    # Broadcast a scalar / single value to a per-dataset vector.
    # A vector already of length n (with n>1) is treated as per-dataset.
    _bvec(x) = (x isa AbstractVector && length(x) == n && n > 1) ? x : fill(x, n)
 
    cmaps  = _bvec(colormap)
    colors = _bvec(color)
    msizes = _bvec(markersize)
    pnames = _bvec(param_name)
 
    # `param` semantics:
    #   n == 1  →  param IS the colour array for that dataset
    #   n  > 1  →  param should be a length-n Vector of arrays (or nothing)
    params = if n == 1
        [param]
    elseif param === nothing
        fill(nothing, n)
    elseif param isa AbstractVector && length(param) == n
        param          # assumed to be [arr_for_ds1, arr_for_ds2, …]
    else
        fill(param, n) # same array broadcast to every dataset
    end
 
    fig, ax = plot_poincare(; figsize, draw_axes, draw_guides, sphere_alpha, title)
 
    next_col = 2       # next grid column for colorbars
    for (i, ds) in enumerate(datasets)
        xs, ys, zs = _extract_stokes_xyz(ds)
        sc = stokes_scatter!(ax, xs, ys, zs;
            param      = params[i],
            color      = colors[i],
            colormap   = cmaps[i],
            markersize = msizes[i],
        )
        if show_colorbar && params[i] !== nothing
            lbl = pnames[i] !== nothing ? string(pnames[i]) : ""
            Colorbar(fig[1, next_col];
                colormap = cmaps[i],
                limits   = extrema(params[i]),
                label    = lbl,
                width    = 18,
                height   = Relative(0.6),
                valign   = :center,
            )
            next_col += 1
        end
    end
 
    return fig, ax
end

function _extract_stokes_xyz(ds)
    if ds isa AbstractVector{<:Tuple} && length(first(ds)) == 3
        xs = [s[1] for s in ds]
        ys = [s[2] for s in ds]
        zs = [s[3] for s in ds]
    elseif ds isa Tuple && length(ds) == 3
        xs, ys, zs = ds
    elseif ds isa AbstractMatrix && size(ds, 2) == 3
        xs, ys, zs = ds[:, 1], ds[:, 2], ds[:, 3]
    else
        throw(ArgumentError(
            "Each dataset must be a 3-tuple (xs, ys, zs) or an N×3 matrix."))
    end
    return Float64.(xs), Float64.(ys), Float64.(zs)
end

function plot_ellipse(
    datasets...;
    figsize = (600, 600),
    N_angles = 91,
    show_rotation_label = true,
    draw_titles = true,
    draw_labels = true,
    limit = nothing,
    n_subplots = 1,
    datasets_per_subplot = nothing,

    # styling
    param = nothing,
    param_name = nothing,
    colormap = :plasma,
    color = :black,
    colorrange = nothing,
    show_colorbar = true,)

    n = length(datasets)
    n == 0 && error("At least one dataset required")

    function datasetvec(x)
        if x isa AbstractVector && length(x) == n
            return collect(x)
        else
            return fill(x, n)
        end
    end

    params        = datasetvec(param)
    param_names   = datasetvec(param_name)
    colormaps     = datasetvec(colormap)
    colors        = datasetvec(color)
    colorranges   = datasetvec(colorrange)
    show_cbs      = datasetvec(show_colorbar)

    # Subplot assignment

    if datasets_per_subplot === nothing
        base = div(n, n_subplots)
        rem  = n % n_subplots

        datasets_per_subplot = [
            base + (i <= rem ? 1 : 0)
            for i in 1:n_subplots
        ]
    else
        length(datasets_per_subplot) == n_subplots ||
            error("datasets_per_subplot must match n_subplots")
    end

    subplot_of = Int[]

    for (sp, count) in enumerate(datasets_per_subplot)
        append!(subplot_of, fill(sp, count))
    end

    # ------------------------------------------------------------
    # angle grid
    # ------------------------------------------------------------

    angles = range(0, 360degrees, length = N_angles)

    # ------------------------------------------------------------
    # compute ellipses
    # ------------------------------------------------------------

    all_Ex = Vector{Matrix{Float64}}(undef, n)
    all_Ey = Vector{Matrix{Float64}}(undef, n)

    for (d, data) in enumerate(datasets)

        N = length(data)

        Ex = zeros(N, N_angles)
        Ey = zeros(N, N_angles)

        for i in 1:N

            E0x = abs(data[i][1])
            E0y = abs(data[i][2])

            ϕx = angle(data[i][1])
            ϕy = angle(data[i][2])

            for (j, θ) in enumerate(angles)

                Ex[i, j] = E0x * cos(ϕx - θ)
                Ey[i, j] = E0y * cos(ϕy - θ)

            end
        end

        all_Ex[d] = Ex
        all_Ey[d] = Ey
    end

    # ------------------------------------------------------------
    # limits per subplot
    # ------------------------------------------------------------

    xlims = Vector{Tuple{Float64, Float64}}(undef, n_subplots)
    ylims = Vector{Tuple{Float64, Float64}}(undef, n_subplots)

    for sp in 1:n_subplots

        idx = findall(==(sp), subplot_of)

        if limit !== nothing

            xlims[sp] = (-limit, limit)
            ylims[sp] = (-limit, limit)

        else

            xs = vcat([vec(all_Ex[i]) for i in idx]...)
            ys = vcat([vec(all_Ey[i]) for i in idx]...)

            xmax = 1.2maximum(abs.(xs))
            ymax = 1.2maximum(abs.(ys))

            xlims[sp] = (-xmax, xmax)
            ylims[sp] = (-ymax, ymax)

        end
    end

    arrow_head(sp) = 0.05 * max(
        xlims[sp][2] - xlims[sp][1],
        ylims[sp][2] - ylims[sp][1],
    ) / 2

    # ------------------------------------------------------------
    # figure
    # ------------------------------------------------------------

    fig = Figure(size = (figsize[1] * n_subplots, figsize[2]))

    gl = fig[1, 1:n_subplots] = GridLayout()

    axs = [Axis(gl[1, i]) for i in 1:n_subplots]

    next_cb_col = n_subplots + 1

    # ------------------------------------------------------------
    # plotting
    # ------------------------------------------------------------

    for d in 1:n

        sp = subplot_of[d]
        ax = axs[sp]

        Ex = all_Ex[d]
        Ey = all_Ey[d]

        p      = params[d]
        cmap   = colormaps[d]
        c      = colors[d]
        crange = colorranges[d]

        curve_colored =
            p isa AbstractVector &&
            length(p) == size(Ex, 1)

        if curve_colored && crange === nothing
            crange = extrema(p)
        end

        for i in axes(Ex, 1)

            if curve_colored

                lines!(
                    ax,
                    Ex[i, :],
                    Ey[i, :];
                    color = p[i],
                    colormap = cmap,
                    colorrange = crange,
                )

            else

                lines!(
                    ax,
                    Ex[i, :],
                    Ey[i, :];
                    color = c,
                )

            end
        end

        xlims!(ax, xlims[sp])
        ylims!(ax, ylims[sp])

        if draw_labels
            ax.xlabel = "Eₓ"
            ax.ylabel = "Eᵧ"
        end

        if draw_titles

            names = [
                "E$i"
                for i in findall(==(sp), subplot_of)
            ]

            ax.title = join(names, ", ")
        end

        # --------------------------------------------------------
        # dataset-specific colorbar
        # --------------------------------------------------------

        if show_cbs[d] && curve_colored

            label =
                param_names[d] === nothing ?
                "" :
                string(param_names[d])

            Colorbar(
                fig[1, next_cb_col];
                colormap = cmap,
                limits = crange,
                label = label,
                width = 18,
                height = Relative(0.6),
                valign = :center,
            )

            next_cb_col += 1
        end
    end

    # ------------------------------------------------------------
    # rotation labels
    # ------------------------------------------------------------

    if show_rotation_label

        for sp in 1:n_subplots

            signed_sum = 0.0

            for d in findall(==(sp), subplot_of)

                for item in datasets[d]

                    signed_sum +=
                        sin(angle(item[2]) - angle(item[1]))

                end
            end

            text!(
                axs[sp],
                xlims[sp][2],
                ylims[sp][1];
                text = signed_sum >= 0 ? "CCW" : "CW",
                fontsize = 18,
                color = :black,
                align = (:right, :bottom),
            )
        end
    end

    return fig, axs

end