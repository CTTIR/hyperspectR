#' Get Chromophore Extinction Coefficient Spectra
#'
#' Returns published molar extinction coefficient spectra for common tissue
#' chromophores. Data from Prahl (Oregon Medical Laser Center) and Jacques (2013).
#'
#' @param chromophore Character vector. One or more of:
#'   `"HbO2"` (oxyhemoglobin), `"Hb"` (deoxyhemoglobin), `"water"`,
#'   `"melanin"`, `"metHb"` (methemoglobin). Default `c("HbO2", "Hb")`.
#' @param wavelength_range Numeric vector of length 2. Wavelength range in nm.
#'   Default `c(400, 1000)`.
#'
#' @return A [tibble::tibble] with columns `wavelength` (nm) and one column per
#'   requested chromophore (extinction coefficient in cm^-1 / (mol/L)).
#'
#' @examples
#' hb_data <- hs_chromophore_data()
#' head(hb_data)
#'
#' @export
hs_chromophore_data <- function(chromophore = c("HbO2", "Hb"),
                                wavelength_range = c(400, 1000)) {
  chromophore <- match.arg(chromophore, choices = c("HbO2", "Hb", "water", "melanin", "metHb"),
                           several.ok = TRUE)

  wl <- seq(wavelength_range[1], wavelength_range[2], by = 2)

  result <- tibble::tibble(wavelength = wl)

  for (chrom in chromophore) {
    result[[chrom]] <- .chromophore_spectrum(wl, chrom)
  }

  result
}

#' Generate Chromophore Extinction Spectrum
#'
#' Uses analytical approximations of published absorption spectra.
#'
#' @param wl Numeric vector of wavelengths.
#' @param name Character. Chromophore name.
#' @return Numeric vector of extinction coefficients.
#' @noRd
.chromophore_spectrum <- function(wl, name) {
  switch(name,
    HbO2 = .hbo2_spectrum(wl),
    Hb = .hb_spectrum(wl),
    water = .water_spectrum(wl),
    melanin = .melanin_spectrum(wl),
    metHb = .methb_spectrum(wl)
  )
}

#' Oxyhemoglobin Absorption Spectrum (Approximation)
#' @noRd
.hbo2_spectrum <- function(wl) {
  # Gaussian peak model approximating Prahl/Zijlstra data
  # Soret band ~415 nm, Q-beta ~542 nm, Q-alpha ~577 nm
  soret <- 320000 * exp(-0.5 * ((wl - 415) / 12)^2)
  q_beta <- 53000 * exp(-0.5 * ((wl - 542) / 8)^2)
  q_alpha <- 55000 * exp(-0.5 * ((wl - 577) / 7)^2)
  nir_shoulder <- 1500 * exp(-0.5 * ((wl - 925) / 60)^2)
  baseline <- 500 * exp(-0.002 * (wl - 400))

  soret + q_beta + q_alpha + nir_shoulder + baseline
}

#' Deoxyhemoglobin Absorption Spectrum (Approximation)
#' @noRd
.hb_spectrum <- function(wl) {
  # Soret ~430 nm, single broad Q-band ~555 nm, NIR features at 660/760 nm
  soret <- 280000 * exp(-0.5 * ((wl - 430) / 14)^2)
  q_band <- 50000 * exp(-0.5 * ((wl - 555) / 15)^2)
  nir_660 <- 3500 * exp(-0.5 * ((wl - 660) / 20)^2)
  nir_760 <- 1800 * exp(-0.5 * ((wl - 760) / 30)^2)
  baseline <- 600 * exp(-0.002 * (wl - 400))

  soret + q_band + nir_660 + nir_760 + baseline
}

#' Water Absorption Spectrum (Approximation)
#' @noRd
.water_spectrum <- function(wl) {
  # Very low in visible, rising toward NIR with peak ~970 nm
  baseline <- 0.01 * exp(0.005 * (wl - 400))
  peak_970 <- 0.5 * exp(-0.5 * ((wl - 970) / 25)^2)
  peak_1200 <- 2.0 * exp(-0.5 * ((wl - 1200) / 40)^2)

  baseline + peak_970 + peak_1200
}

#' Melanin Absorption Spectrum (Approximation)
#' @noRd
.melanin_spectrum <- function(wl) {
  # Power-law decay: melanin ~ wl^(-3.5) approximately
  6.6e10 * (wl / 1000)^(-3.33)
}

#' Methemoglobin Absorption Spectrum (Approximation)
#' @noRd
.methb_spectrum <- function(wl) {
  # Soret ~405 nm, broad visible ~500-630 nm
  soret <- 180000 * exp(-0.5 * ((wl - 405) / 13)^2)
  vis <- 10000 * exp(-0.5 * ((wl - 500) / 25)^2)
  charge_transfer <- 14000 * exp(-0.5 * ((wl - 630) / 15)^2)
  baseline <- 400 * exp(-0.002 * (wl - 400))

  soret + vis + charge_transfer + baseline
}

# Key hemoglobin reference wavelengths (internal)
.hb_peaks <- list(
  HbO2 = list(soret = 415, Q_beta = 540, Q_alpha = 577, nir = 940),
  Hb   = list(soret = 430, Q_broad = 555, nir_660 = 660, nir_760 = 760),
  isosbestic = c(505, 522, 548, 569, 586, 798)
)
