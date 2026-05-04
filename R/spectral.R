#' Convert Reflectance to Absorbance
#'
#' Computes `A(lambda) = -log10(R(lambda))`. Values of R at or below zero
#' are clamped to `floor` before log transformation.
#'
#' @param cube An [hsi_cube] object with reflectance values.
#' @param floor Numeric. Minimum reflectance value to prevent log(0). Default `1e-6`.
#'
#' @return An [hsi_cube] object with absorbance values.
#'
#' @examples
#' cube <- hs_example_cube()
#' abs_cube <- hs_absorbance(cube)
#'
#' @export
hs_absorbance <- function(cube, floor = 1e-6) {
  .validate_cube(cube)

  data <- cube$data
  data[data <= 0] <- floor
  data <- -log10(data)

  cube$data <- data
  cube$metadata$processing_mode <- "absorbance"
  cube
}

#' Continuum Removal
#'
#' Removes the spectral continuum (convex hull) from each spectrum. Useful
#' for enhancing absorption features and normalizing baseline variations.
#'
#' @param cube An [hsi_cube] object.
#' @param method Character. `"division"` (default) divides by the continuum,
#'   `"subtraction"` subtracts the continuum.
#'
#' @return An [hsi_cube] object with continuum-removed spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' cr <- hs_continuum_removal(cube, method = "division")
#'
#' @export
hs_continuum_removal <- function(cube, method = c("division", "subtraction")) {
  .validate_cube(cube)
  method <- match.arg(method)

  d <- dim(cube$data)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])
  wl <- cube$wavelengths

  cr_mat <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = ncol(pixel_mat))

  for (i in seq_len(nrow(pixel_mat))) {
    spec <- pixel_mat[i, ]
    hull <- .convex_hull_upper(wl, spec)

    if (method == "division") {
      hull[hull == 0] <- 1e-10
      cr_mat[i, ] <- spec / hull
    } else {
      cr_mat[i, ] <- spec - hull
    }
  }

  cube$data <- array(cr_mat, dim = d)
  cube$metadata$continuum_removed <- method
  cube
}

#' Resample Spectra to New Wavelength Grid
#'
#' Interpolates the spectral data to a new set of wavelength positions.
#'
#' @param cube An [hsi_cube] object.
#' @param target_wavelengths Numeric vector. Target wavelength positions in nm.
#' @param method Character. Interpolation method: `"linear"` (default),
#'   `"spline"`.
#'
#' @return An [hsi_cube] object with resampled spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' resampled <- hs_resample(cube, target_wavelengths = seq(450, 900, by = 10))
#' length(resampled$wavelengths)
#'
#' @export
hs_resample <- function(cube, target_wavelengths, method = "linear") {
  .validate_cube(cube)
  method <- match.arg(method, c("linear", "spline"))

  d <- dim(cube$data)
  n_new_bands <- length(target_wavelengths)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  resampled <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = n_new_bands)

  for (i in seq_len(nrow(pixel_mat))) {
    if (method == "linear") {
      resampled[i, ] <- stats::approx(cube$wavelengths, pixel_mat[i, ],
                                       xout = target_wavelengths,
                                       rule = 2)$y
    } else {
      resampled[i, ] <- stats::spline(cube$wavelengths, pixel_mat[i, ],
                                       xout = target_wavelengths,
                                       method = "natural")$y
    }
  }

  new_fwhm <- if (!is.null(cube$fwhm)) {
    stats::approx(cube$wavelengths, cube$fwhm,
                  xout = target_wavelengths, rule = 2)$y
  } else {
    NULL
  }

  hsi_cube(
    data = array(resampled, dim = c(d[1], d[2], n_new_bands)),
    wavelengths = target_wavelengths,
    fwhm = new_fwhm,
    metadata = cube$metadata,
    mask = cube$mask
  )
}

#' Compute Upper Convex Hull for Continuum Removal
#' @noRd
.convex_hull_upper <- function(wl, spec) {
  n <- length(spec)
  hull <- numeric(n)

  # Simple upper convex hull using linear interpolation between hull vertices
  hull_pts <- c(1L)
  i <- 2L
  while (i <= n) {
    # Check if current point is above line from last hull point to next
    best_slope <- -Inf
    best_j <- i
    for (j in i:n) {
      slope <- (spec[j] - spec[hull_pts[length(hull_pts)]]) /
        (wl[j] - wl[hull_pts[length(hull_pts)]] + 1e-10)
      if (slope > best_slope) {
        best_slope <- slope
        best_j <- j
      }
    }
    hull_pts <- c(hull_pts, best_j)
    i <- best_j + 1L
  }

  # Interpolate hull between vertices
  hull <- stats::approx(wl[hull_pts], spec[hull_pts], xout = wl, rule = 2)$y
  hull
}
