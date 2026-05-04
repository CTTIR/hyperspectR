#' Savitzky-Golay Spectral Smoothing
#'
#' Applies a Savitzky-Golay filter along the spectral dimension. Optionally
#' computes spectral derivatives. Uses `prospectr` or `signal` if available,
#' otherwise falls back to a built-in convolution implementation.
#'
#' @param cube An [hsi_cube] object.
#' @param window Integer (odd). Filter window size in bands. Default `5`.
#' @param poly Integer. Polynomial order. Must be less than `window`. Default `2`.
#' @param deriv Integer. Derivative order (0 = smoothing only, 1 = first
#'   derivative, 2 = second derivative). Default `0`.
#'
#' @return An [hsi_cube] object with smoothed/differentiated spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' smoothed <- hs_smooth(cube, window = 5, poly = 2)
#' dim(smoothed)
#'
#' @export
hs_smooth <- function(cube, window = 5L, poly = 2L, deriv = 0L) {
  .validate_cube(cube)

  window <- as.integer(window)
  poly <- as.integer(poly)
  deriv <- as.integer(deriv)

  if (window %% 2L == 0L) {
    cli::cli_abort("{.arg window} must be odd. Got {window}.")
  }
  if (poly >= window) {
    cli::cli_abort("{.arg poly} ({poly}) must be less than {.arg window} ({window}).")
  }
  if (deriv > poly) {
    cli::cli_abort("{.arg deriv} ({deriv}) must be <= {.arg poly} ({poly}).")
  }
  if (window > dim(cube$data)[3L]) {
    cli::cli_abort("{.arg window} ({window}) exceeds number of bands ({dim(cube$data)[3L]}).")
  }

  d <- dim(cube$data)
  # Reshape to pixel matrix (n_pixels x n_bands)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  # Apply SG filter
  if (requireNamespace("prospectr", quietly = TRUE)) {
    smoothed <- prospectr::savitzkyGolay(pixel_mat, m = deriv, p = poly, w = window)
  } else if (requireNamespace("signal", quietly = TRUE)) {
    filt <- signal::sgolay(p = poly, n = window, m = deriv)
    smoothed <- t(apply(pixel_mat, 1L, function(x) signal::filter(filt, x)))
  } else {
    # Built-in fallback
    coeffs <- .sg_coefficients(window, poly, deriv)
    half <- (window - 1L) / 2L
    smoothed <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = ncol(pixel_mat))
    for (i in seq_len(nrow(pixel_mat))) {
      padded <- c(rep(pixel_mat[i, 1L], half), pixel_mat[i, ],
                  rep(pixel_mat[i, ncol(pixel_mat)], half))
      smoothed[i, ] <- stats::filter(padded, coeffs, sides = 1L)[(window):length(padded)]
    }
  }

  # Handle NA columns from edge effects
  keep_cols <- which(colSums(is.na(smoothed)) < nrow(smoothed))
  if (length(keep_cols) < ncol(smoothed)) {
    smoothed <- smoothed[, keep_cols, drop = FALSE]
    new_wl <- cube$wavelengths[keep_cols]
    new_fwhm <- if (!is.null(cube$fwhm)) cube$fwhm[keep_cols] else NULL
  } else {
    new_wl <- cube$wavelengths
    new_fwhm <- cube$fwhm
  }

  # Fill remaining NAs with 0
  smoothed[is.na(smoothed)] <- 0

  new_data <- array(smoothed, dim = c(d[1], d[2], length(new_wl)))

  hsi_cube(
    data = new_data,
    wavelengths = new_wl,
    fwhm = new_fwhm,
    metadata = c(cube$metadata, list(
      sg_window = window, sg_poly = poly, sg_deriv = deriv
    )),
    mask = cube$mask
  )
}

#' Standard Normal Variate Correction
#'
#' Normalizes each spectrum to zero mean and unit variance. Useful for
#' reducing multiplicative scatter effects and baseline variation.
#'
#' @param cube An [hsi_cube] object.
#'
#' @return An [hsi_cube] object with SNV-corrected spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' snv_cube <- hs_snv(cube)
#'
#' @export
hs_snv <- function(cube) {
  .validate_cube(cube)

  d <- dim(cube$data)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  row_means <- rowMeans(pixel_mat)
  row_sds <- apply(pixel_mat, 1L, stats::sd)
  row_sds[row_sds == 0] <- 1  # Prevent division by zero

  snv_mat <- (pixel_mat - row_means) / row_sds

  cube$data <- array(snv_mat, dim = d)
  cube$metadata$snv_applied <- TRUE
  cube
}

#' Multiplicative Scatter Correction
#'
#' Corrects spectra for multiplicative and additive scatter effects by
#' regressing each spectrum against a reference spectrum (default: mean
#' spectrum).
#'
#' @param cube An [hsi_cube] object.
#' @param reference Numeric vector. Reference spectrum. Default `NULL` = mean
#'   spectrum of the cube.
#'
#' @return An [hsi_cube] object with MSC-corrected spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' msc_cube <- hs_msc(cube)
#'
#' @export
hs_msc <- function(cube, reference = NULL) {
  .validate_cube(cube)

  d <- dim(cube$data)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  if (is.null(reference)) {
    reference <- colMeans(pixel_mat)
  }

  msc_mat <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = ncol(pixel_mat))

  for (i in seq_len(nrow(pixel_mat))) {
    fit <- stats::lm.fit(cbind(1, reference), pixel_mat[i, ])
    intercept <- fit$coefficients[1]
    slope <- fit$coefficients[2]
    if (is.na(slope) || slope == 0) slope <- 1
    msc_mat[i, ] <- (pixel_mat[i, ] - intercept) / slope
  }

  cube$data <- array(msc_mat, dim = d)
  cube$metadata$msc_applied <- TRUE
  cube
}

#' Spectral Derivative
#'
#' Computes the spectral derivative using Savitzky-Golay differentiation.
#' Shorthand for [hs_smooth()] with `deriv > 0`.
#'
#' @param cube An [hsi_cube] object.
#' @param order Integer. Derivative order. Default `1`.
#' @param window Integer (odd). SG window size. Default `5`.
#'
#' @return An [hsi_cube] object with derivative spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' d1 <- hs_derivative(cube, order = 1)
#'
#' @export
hs_derivative <- function(cube, order = 1L, window = 5L) {
  hs_smooth(cube, window = window, poly = max(as.integer(order) + 1L, 2L),
            deriv = as.integer(order))
}
