#' Estimate the Oxygenated Hemoglobin Fraction for Research
#'
#' Returns the fitted HbO2 fraction from [hs_beer_lambert()]. This is a
#' research model estimate and requires empirical validation for tissue use.
#'
#' @param cube An [hsi_cube] object with reflectance data.
#' @param band1,band2 Retired ratio-method arguments. Supplying either raises a
#'   migration error; use [hs_band_ratio()] or the fitting range in [hs_beer_lambert()].
#' @param method `"beer_lambert"` (default). The former `"ratio"` method
#'   is rejected; use [hs_band_ratio()] for a relative band ratio.
#'
#' @return A numeric matrix (rows x cols) with values 0-100 representing
#'   estimated tissue oxygen saturation percentage. Returns `NA` for masked pixels.
#'
#' @examples
#' cube <- hs_example_cube()
#' sto2 <- hs_sto2(cube)
#' range(sto2, na.rm = TRUE)
#'
#' @export
hs_sto2 <- function(cube, band1 = c(500, 650), band2 = c(700, 815),
                    method = "beer_lambert") {
  .validate_cube(cube)
  method <- match.arg(method, c("beer_lambert", "ratio"))
  if (method == "ratio") {
    cli::cli_abort("The scene-stretched ratio was not oxygen saturation. Use hs_band_ratio(cube, band2, band1) for a dimensionless relative index.")
  }
  if (!missing(band1) || !missing(band2)) cli::cli_abort("band1/band2 belong to the retired ratio method. Use hs_band_ratio() or hs_beer_lambert(wavelength_range=...).")
  hs_beer_lambert(cube, wavelength_range = c(500, 600))$sto2
}

#' Compute Near-Infrared Perfusion Index (NPI)
#'
#' Legacy name for a dimensionless NIR band ratio. It is not a validated
#' perfusion measurement or an implementation of a vendor index.
#'
#' @param cube An [hsi_cube] object with reflectance data.
#' @param band1 Numeric vector of length 2. Default `c(655, 735)`.
#' @param band2 Numeric vector of length 2. Default `c(825, 910)`.
#'
#' @return A numeric matrix of unscaled dimensionless band ratios.
#'
#' @examples
#' cube <- hs_example_cube()
#' npi <- hs_npi(cube)
#'
#' @export
hs_npi <- function(cube, band1 = c(655, 735), band2 = c(825, 910)) {
  .validate_cube(cube)
  .check_wavelength_coverage(cube$wavelengths, c(band1[1], band2[2]), "NPI")

  b1 <- .band_mean(cube, band1)
  b2 <- .band_mean(cube, band2)

  if (is.null(b1) || is.null(b2)) {
    cli::cli_abort("Required wavelength bands not available for NPI computation.")
  }

  ratio <- b2 / b1
  result <- ratio

  result[!is.finite(result)] <- NA_real_
  .apply_mask(result, cube$mask)
}

#' Compute Tissue Hemoglobin Index (THI)
#'
#' Legacy name for a dimensionless reference/Hb-band reflectance ratio.
#' It is not a hemoglobin concentration measurement.
#'
#' @param cube An [hsi_cube] object.
#' @param band1 Numeric vector of length 2. Default `c(530, 590)` (Hb Q-bands).
#' @param band2 Numeric vector of length 2. Default `c(785, 825)` (reference).
#'
#' @return A numeric matrix of unscaled dimensionless band ratios.
#'
#' @examples
#' cube <- hs_example_cube()
#' thi <- hs_thi(cube)
#'
#' @export
hs_thi <- function(cube, band1 = c(530, 590), band2 = c(785, 825)) {
  .validate_cube(cube)
  .check_wavelength_coverage(cube$wavelengths, c(band1[1], band2[2]), "THI")

  b1 <- .band_mean(cube, band1)
  b2 <- .band_mean(cube, band2)

  if (is.null(b1) || is.null(b2)) {
    cli::cli_abort("Required wavelength bands not available for THI computation.")
  }

  # Reference-band reflectance relative to the Hb-band reflectance.
  ratio <- b1 / b2
  result <- 1 / ratio

  result[!is.finite(result)] <- NA_real_
  .apply_mask(result, cube$mask)
}

#' Compute Tissue Water Index (TWI)
#'
#' Legacy name for a dimensionless NIR reflectance ratio. The default
#' 830-910 nm bands do not include the 970 nm water peak and do not measure
#' water content.
#'
#' @param cube An [hsi_cube] object.
#' @param numerator Numeric vector of length 2. Default `c(880, 910)` (adapted
#'   for Cubert range).
#' @param denominator Numeric vector of length 2. Default `c(830, 870)`.
#'
#' @return A numeric matrix of unscaled dimensionless ratios, or an NA matrix with a warning
#'   if required wavelengths are unavailable.
#'
#' @examples
#' cube <- hs_example_cube()
#' twi <- hs_twi(cube)
#'
#' @export
hs_twi <- function(cube, numerator = c(880, 910), denominator = c(830, 870)) {
  .validate_cube(cube)

  num <- .band_mean(cube, numerator)
  den <- .band_mean(cube, denominator)

  if (is.null(num) || is.null(den)) {
    cli::cli_warn(c(
      "!" = "Required wavelength bands not available for TWI computation.",
      "i" = "TWI requires wavelengths up to ~980 nm. Cubert Ultris X MR covers 430-910 nm.",
      "i" = "Returning NA matrix."
    ))
    return(matrix(NA_real_, nrow = dim(cube$data)[1], ncol = dim(cube$data)[2]))
  }

  .check_wavelength_coverage(cube$wavelengths, c(denominator[1], numerator[2]), "TWI")

  ratio <- num / den
  result <- 1 / ratio

  result[!is.finite(result)] <- NA_real_
  .apply_mask(result, cube$mask)
}

#' Compute Normalized Difference Index (General Purpose)
#'
#' NDI = (R_band1 - R_band2) / (R_band1 + R_band2). A flexible building block
#' for any two-band ratio index.
#'
#' @param cube An [hsi_cube] object.
#' @param band1 Numeric. Center wavelength or range `c(min, max)` for first band.
#' @param band2 Numeric. Center wavelength or range `c(min, max)` for second band.
#'
#' @return A numeric matrix, in `[-1, 1]` for nonnegative input spectra.
#'   Zero denominators are NA; transformed signed spectra can exceed these bounds.
#'
#' @examples
#' cube <- hs_example_cube()
#' ndi <- hs_ndi(cube, band1 = 540, band2 = 660)
#' range(ndi, na.rm = TRUE)
#'
#' @export
hs_ndi <- function(cube, band1, band2) {
  .validate_cube(cube)
  .require_wavelengths(cube)

  if (length(band1) == 1L) {
    idx1 <- .band_index(cube$wavelengths, band1)
    b1 <- .band_matrix(cube, idx1)
  } else {
    b1 <- .band_mean(cube, band1)
  }

  if (length(band2) == 1L) {
    idx2 <- .band_index(cube$wavelengths, band2)
    b2 <- .band_matrix(cube, idx2)
  } else {
    b2 <- .band_mean(cube, band2)
  }

  if (is.null(b1) || is.null(b2)) {
    cli::cli_abort("Required wavelength bands not available for NDI computation.")
  }

  denom <- b1 + b2
  denom[denom == 0] <- NA_real_

  result <- (b1 - b2) / denom
  result[!is.finite(result)] <- NA_real_
  .apply_mask(result, cube$mask)
}

#' Compute All Available Clinical Indices
#'
#' Convenience function that computes StO2, NPI, THI, and TWI (if wavelength
#' range permits) and returns them as a named list of matrices.
#'
#' @param cube An [hsi_cube] object with reflectance data.
#'
#' @return A named list of numeric matrices: `sto2`, `npi`, `thi`, `twi`
#'   (TWI may be NA matrix if wavelengths are insufficient).
#'
#' @examples
#' cube <- hs_example_cube()
#' indices <- hs_clinical_indices(cube)
#' names(indices)
#'
#' @export
hs_clinical_indices <- function(cube) {
  .validate_cube(cube)

  list(
    sto2 = hs_sto2(cube),
    npi = hs_npi(cube),
    thi = hs_thi(cube),
    twi = suppressWarnings(hs_twi(cube))
  )
}

#' Compute an Unscaled Spectral Band Ratio
#'
#' A scene-independent, dimensionless ratio of mean spectral values. It is
#' not calibrated oxygen saturation, perfusion, concentration or water content.
#' @param cube An [hsi_cube] object.
#' @param numerator,denominator Numeric scalar wavelength or two-element range in nm.
#' @return A spatial numeric matrix. Zero denominators and invalid pixels are NA.
#' @export
hs_band_ratio <- function(cube, numerator, denominator) {
  .validate_cube(cube)
  .require_wavelengths(cube)
  band <- function(x) {
    if (length(x) == 1L) .band_matrix(cube, .band_index(cube$wavelengths, x)) else .band_mean(cube, x)
  }
  num <- band(numerator)
  den <- band(denominator)
  if (is.null(num) || is.null(den)) cli::cli_abort("Required wavelength bands not available for band ratio.")
  result <- num / den
  result[!is.finite(result)] <- NA_real_
  result[!is.finite(result)] <- NA_real_
  .apply_mask(result, cube$mask)
}
