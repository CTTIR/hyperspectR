#' Compute Tissue Oxygen Saturation (StO2)
#'
#' Estimates superficial tissue oxygenation from visible-range hemoglobin
#' absorption. Uses the ratio of reflectance in the 500-650 nm (oxy/deoxy-Hb
#' Q-bands) and 700-815 nm (NIR oxy-Hb shoulder) regions.
#'
#' @param cube An [hsi_cube] object with reflectance data.
#' @param band1 Numeric vector of length 2. Wavelength range for first band
#'   (default `c(500, 650)`, visible Hb absorption).
#' @param band2 Numeric vector of length 2. Wavelength range for second band
#'   (default `c(700, 815)`, NIR region).
#' @param method Character. `"ratio"` for band-ratio index (default),
#'   `"beer_lambert"` for full chromophore fitting.
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
                    method = "ratio") {
  .validate_cube(cube)
  method <- match.arg(method, c("ratio", "beer_lambert"))

  .check_wavelength_coverage(cube$wavelengths, c(band1[1], band2[2]), "StO2")

  if (method == "beer_lambert") {
    fit <- hs_beer_lambert(cube, wavelength_range = c(500, 600))
    return(fit$sto2)
  }

  b1 <- .band_mean(cube, band1)
  b2 <- .band_mean(cube, band2)

  if (is.null(b1) || is.null(b2)) {
    cli::cli_abort("Required wavelength bands not available for StO2 computation.")
  }

  # StO2 ~ ratio of absorption regions
  # Higher b2/b1 = higher oxygenation (less deoxy-Hb absorption in NIR)
  ratio <- b2 / (b1 + 1e-10)
  # Scale to 0-100
  result <- .linear_stretch(ratio) * 100

  .apply_mask(result, cube$mask)
}

#' Compute Near-Infrared Perfusion Index (NPI)
#'
#' Estimates deeper tissue perfusion (4-6 mm depth) from NIR wavelengths.
#' Note: Cubert Ultris X MR upper limit is 910 nm; the original TIVITA NPI
#' extends to 925 nm. Results are approximate with Cubert data.
#'
#' @param cube An [hsi_cube] object with reflectance data.
#' @param band1 Numeric vector of length 2. Default `c(655, 735)`.
#' @param band2 Numeric vector of length 2. Default `c(825, 910)`.
#'
#' @return A numeric matrix with values 0-100.
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

  ratio <- b2 / (b1 + 1e-10)
  result <- .linear_stretch(ratio) * 100

  .apply_mask(result, cube$mask)
}

#' Compute Tissue Hemoglobin Index (THI)
#'
#' Estimates relative hemoglobin concentration at superficial depth.
#'
#' @param cube An [hsi_cube] object.
#' @param band1 Numeric vector of length 2. Default `c(530, 590)` (Hb Q-bands).
#' @param band2 Numeric vector of length 2. Default `c(785, 825)` (reference).
#'
#' @return A numeric matrix with values 0-100.
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

  # THI ~ inverse of reflectance in Hb absorption region relative to NIR
  # Lower reflectance in Q-bands = higher Hb concentration
  ratio <- b1 / (b2 + 1e-10)
  result <- (1 - .linear_stretch(ratio)) * 100

  .apply_mask(result, cube$mask)
}

#' Compute Tissue Water Index (TWI)
#'
#' Estimates tissue water content from the 960 nm water absorption band.
#' The Cubert Ultris X MR (430-910 nm) does NOT fully cover this range.
#'
#' @param cube An [hsi_cube] object.
#' @param numerator Numeric vector of length 2. Default `c(880, 910)` (adapted
#'   for Cubert range).
#' @param denominator Numeric vector of length 2. Default `c(830, 870)`.
#'
#' @return A numeric matrix with values 0-100, or an NA matrix with a warning
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

  ratio <- num / (den + 1e-10)
  result <- (1 - .linear_stretch(ratio)) * 100

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
#' @return A numeric matrix with values in `[-1, 1]`.
#'
#' @examples
#' cube <- hs_example_cube()
#' ndi <- hs_ndi(cube, band1 = 540, band2 = 660)
#' range(ndi, na.rm = TRUE)
#'
#' @export
hs_ndi <- function(cube, band1, band2) {
  .validate_cube(cube)

  if (length(band1) == 1L) {
    idx1 <- .band_index(cube$wavelengths, band1)
    b1 <- cube$data[, , idx1]
  } else {
    b1 <- .band_mean(cube, band1)
  }

  if (length(band2) == 1L) {
    idx2 <- .band_index(cube$wavelengths, band2)
    b2 <- cube$data[, , idx2]
  } else {
    b2 <- .band_mean(cube, band2)
  }

  if (is.null(b1) || is.null(b2)) {
    cli::cli_abort("Required wavelength bands not available for NDI computation.")
  }

  denom <- b1 + b2
  denom[denom == 0] <- 1e-10

  result <- (b1 - b2) / denom
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
