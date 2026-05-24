"""
Material properties for silica-germania binary glasses.

This file defines pure SiO2, pure germania GeO2, and mixtures
defined by a doping fraction of germania into a silica base.

Units (SI unless noted):
- λ                     wavelength in m
- T_K                   temperature in K
- x_ge                  dopant molar fraction (dimensionless, 0..1)
- refractive indices, Poisson ratio, photoelastic constants: dimensionless
- cte                   1/K
- softening_temperature  K
- youngs_modulus        Pa
- nonlinear_refractive_index (n_2)  m²/W

[Example usage]

glass = GermaniaSilicaGlass(0.036)   # 3.6 mol% GeO2 in SiO2
T_K = 297.15
λ = 1550e-9
n = refractive_index(glass, λ, T_K)
cte_value = cte(glass, T_K)
"""

#################################################
#
# Material constants
#
#################################################

const SILICA_TERM_1 = SellmeierTerm(
    TemperaturePolynomial((1.10127, -4.94251e-5, 5.27414e-7, -1.59700e-9, 1.75949e-12)),
    TemperaturePolynomial((-8.906e-2, 9.0873e-6, -6.53638e-8, 7.77072e-11, 6.84605e-14))
)

const SILICA_TERM_2 = SellmeierTerm(
    TemperaturePolynomial((1.78752e-5, 4.76391e-5, -4.49019e-7, 1.44546e-9, -1.57223e-12)),
    TemperaturePolynomial((2.97562e-1, -8.59578e-4, 6.59069e-6, -1.09482e-8, 7.85145e-13))
)

const SILICA_TERM_3 = SellmeierTerm(
    TemperaturePolynomial((7.93552e-1, -1.27815e-3, 1.84595e-5, -9.20275e-8, 1.48829e-10)),
    TemperaturePolynomial((9.34454, -70.9788e-3, 1.01968e-4, -5.07660e-7, 8.21348e-10))
)

const GERMANIA_TERM_1 = SellmeierTerm(SellmeierConstantLaw(0.80686642), SellmeierConstantLaw(0.068972606))
const GERMANIA_TERM_2 = SellmeierTerm(SellmeierConstantLaw(0.71815848), SellmeierConstantLaw(0.15396605))
const GERMANIA_TERM_3 = SellmeierTerm(SellmeierConstantLaw(0.85416831), SellmeierConstantLaw(11.841931))

const GERMANIA_REFERENCE_TEMPERATURE_K = 297.15

const SILICA_CTE = 5.4e-7
const GERMANIA_CTE = 10e-6

const SILICA_SOFTENING_TEMPERATURE_K = 1100.0 + 273.15
const GERMANIA_SOFTENING_TEMPERATURE_K = 300.0 + 273.15

const SILICA_POISSON_RATIO = 0.170
const GERMANIA_POISSON_RATIO = 0.212

const SILICA_PHOTOELASTIC_CONSTANTS = (0.121, 0.270)
const GERMANIA_PHOTOELASTIC_CONSTANTS = (0.130, 0.288)

const SILICA_YOUNGS_MODULUS = 74e9
const GERMANIA_YOUNGS_MODULUS = 45.5e9

const SILICA_N2 = 2.2e-20
const GERMANIA_N2 = 4.6e-20

#################################################
#
# Structures and Utility Methods
#
#################################################

struct SiO2 <: AbstractMaterial
    sellmeier_terms::NTuple{3, SellmeierTerm}
end

struct GeO2 <: AbstractMaterial
    sellmeier_terms::NTuple{3, SellmeierTerm}
end

struct GermaniaSilicaGlass <: AbstractMaterial
    x_ge::Float64
    function GermaniaSilicaGlass(x_ge::Real)
        xf = validate_molar_fraction(x_ge)
        return new(xf)
    end
end

const PURE_SILICA = SiO2((SILICA_TERM_1, SILICA_TERM_2, SILICA_TERM_3))
SiO2() = PURE_SILICA

const PURE_GERMANIA = GeO2((GERMANIA_TERM_1, GERMANIA_TERM_2, GERMANIA_TERM_3))
GeO2() = PURE_GERMANIA

#################################################
#
# Pure Silica SiO2 Refractive Index
#
#################################################

function sellmeier_coefficients(material::SiO2, T_K)
    T = validate_model_temperature(T_K)
    return map(term -> evaluate(term, T), material.sellmeier_terms)
end

function refractive_index(::ValueOnly, material::SiO2, λ, T_K)
    coeffs = sellmeier_coefficients(material, T_K)
    return sellmeier_index_from_coefficients(coeffs, λ)
end

function refractive_index(::WithDerivative, material::SiO2, λ, T_K)
    coeffs = sellmeier_coefficients(material, T_K)
    return sellmeier_index_from_coefficients_dω(coeffs, λ)
end

#################################################
#
# Pure Germania GeO2 Refractive Index
#
#################################################

function thermo_optic_index_shift(material::GeO2, T_K)
    T = validate_model_temperature(T_K)
    Tref = GERMANIA_REFERENCE_TEMPERATURE_K
    return 6.2153e-13 / 4 * (T^4 - Tref^4) -
           5.3387e-10 / 3 * (T^3 - Tref^3) +
           1.6654e-7 / 2 * (T^2 - Tref^2)
end

function reference_refractive_index(material::GeO2, λ, T_K)
    T = validate_model_temperature(T_K)
    base_coeffs = map(term -> evaluate(term, T), material.sellmeier_terms)
    n_ref = sellmeier_index_from_coefficients(base_coeffs, λ)
    return n_ref + thermo_optic_index_shift(material, T)
end

function reference_refractive_index(::WithDerivative, material::GeO2, λ, T_K)
    T = validate_model_temperature(T_K)
    base_coeffs = map(term -> evaluate(term, T), material.sellmeier_terms)
    base = sellmeier_index_from_coefficients_dω(base_coeffs, λ)
    return SpectralResponse(base.value + thermo_optic_index_shift(material, T), base.dω)
end

refractive_index(style::ValueOnly, material::GeO2, λ, T_K) =
    reference_refractive_index(material, λ, T_K)

refractive_index(style::WithDerivative, material::GeO2, λ, T_K) =
    reference_refractive_index(style, material, λ, T_K)

#################################################
#
# Binary Si-Ge Glass Refractive Index
#
#################################################

function refractive_index(::ValueOnly, glass::GermaniaSilicaGlass, λ, T_K)
    n_silica = refractive_index(ValueOnly(), PURE_SILICA, λ, T_K)
    n_germania = refractive_index(ValueOnly(), PURE_GERMANIA, λ, T_K)
    return interpolate_scalar(n_silica, n_germania, glass.x_ge)
end

function refractive_index(::WithDerivative, glass::GermaniaSilicaGlass, λ, T_K)
    n_silica = refractive_index(WithDerivative(), PURE_SILICA, λ, T_K)
    n_germania = refractive_index(WithDerivative(), PURE_GERMANIA, λ, T_K)
    return SpectralResponse(
        interpolate_scalar(n_silica.value, n_germania.value, glass.x_ge),
        interpolate_scalar(n_silica.dω, n_germania.dω, glass.x_ge)
    )
end

#################################################
#
# Other Material Properties
#
#################################################

cte(::SiO2, _) = SILICA_CTE
cte(::GeO2, _) = GERMANIA_CTE
cte(glass::GermaniaSilicaGlass, _) = interpolate_scalar(SILICA_CTE, GERMANIA_CTE, glass.x_ge)

softening_temperature(::SiO2, _) = SILICA_SOFTENING_TEMPERATURE_K
softening_temperature(::GeO2, _) = GERMANIA_SOFTENING_TEMPERATURE_K
softening_temperature(glass::GermaniaSilicaGlass, _) = interpolate_scalar(SILICA_SOFTENING_TEMPERATURE_K, GERMANIA_SOFTENING_TEMPERATURE_K, glass.x_ge)

poisson_ratio(::SiO2, _) = SILICA_POISSON_RATIO
poisson_ratio(::GeO2, _) = GERMANIA_POISSON_RATIO
poisson_ratio(glass::GermaniaSilicaGlass, _) = interpolate_scalar(SILICA_POISSON_RATIO, GERMANIA_POISSON_RATIO, glass.x_ge)

photoelastic_constants(::SiO2, _) = SILICA_PHOTOELASTIC_CONSTANTS
photoelastic_constants(::GeO2, _) = GERMANIA_PHOTOELASTIC_CONSTANTS
photoelastic_constants(glass::GermaniaSilicaGlass, _) = interpolate_pair(SILICA_PHOTOELASTIC_CONSTANTS, GERMANIA_PHOTOELASTIC_CONSTANTS, glass.x_ge)

youngs_modulus(::SiO2, _) = SILICA_YOUNGS_MODULUS
youngs_modulus(::GeO2, _) = GERMANIA_YOUNGS_MODULUS
youngs_modulus(glass::GermaniaSilicaGlass, _) = interpolate_scalar(SILICA_YOUNGS_MODULUS, GERMANIA_YOUNGS_MODULUS, glass.x_ge)

function nonlinear_refractive_index(::SiO2, λ, T_K)
    validate_model_wavelength(λ)
    validate_model_temperature(T_K)
    return SILICA_N2
end

function nonlinear_refractive_index(::GeO2, λ, T_K)
    validate_model_wavelength(λ)
    validate_model_temperature(T_K)
    return GERMANIA_N2
end

function nonlinear_refractive_index(glass::GermaniaSilicaGlass, λ, T_K)
    validate_model_wavelength(λ)
    validate_model_temperature(T_K)
    return interpolate_scalar(SILICA_N2, GERMANIA_N2, glass.x_ge)
end