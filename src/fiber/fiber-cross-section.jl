"""
Local optical properties of an ideal step-index fiber cross section.

This file intentionally models only quantities that are meaningful for a single
transverse slice of fiber of infinitesimal length. It excludes any property
that depends on fiber length, path through space, accumulated phase, or
concatenation of segments.

The baseline object is a circular step-index fiber cross section described by
core/cladding materials and diameters. Perturbations such as core ellipticity,
bending, axial tension, and twist are handled by separate functions with
explicit arguments rather than stored on the type.

NOTE: All the dω derivatives computed in this file are computed by ChatGPT-5.4 and have
not been checked by a human.

Example
-------
fiber = FiberCrossSection(
    GermaniaSilicaGlass(0.036),
    GermaniaSilicaGlass(0.0),
    8.2e-6,
    125e-6;
    manufacturer = "Corning",
    model_number = "SMF-like"
)

λ = 1550e-9
T = 297.15

v = normalized_frequency(fiber, λ, T)
β = propagation_constant(fiber, λ, T)
Aeff = effective_mode_area(fiber, λ, T)
Δβ_bend = bending_birefringence(fiber, λ, T; bend_radius_m = 0.03) +
    axial_tension_birefringence(fiber, λ, T; bend_radius_m = 0.03, axial_tension_N = 0.5)
"""

#################################################
#
# Abstract structures
#
#################################################

abstract type FiberCrossSection end

struct BirefringenceResponse{T}
    Δβ::T
    dω::T
end

#################################################
#
# Validation utilities
#
#################################################

function validate_positive_length(value::Real, name::AbstractString)
    x = float(value)
    if !(isfinite(x) && x > zero(x))
        throw(ArgumentError("$(name) must be a finite positive value in meters"))
    end
    return x
end

function validate_bend_radius(bend_radius_m)
    if isinf(bend_radius_m) && bend_radius_m > zero(bend_radius_m)
        return bend_radius_m
    end
    if !(isfinite(bend_radius_m) && bend_radius_m > zero(bend_radius_m))
        throw(ArgumentError(
            "bend_radius_m must be a finite positive value in meters or Inf"
        ))
    end
    return bend_radius_m
end

function validate_axis_ratio(axis_ratio)
    if !(isfinite(axis_ratio) && axis_ratio > zero(axis_ratio))
        throw(ArgumentError("axis_ratio must be a finite positive value"))
    end
    return axis_ratio
end