#' Savitzky-Golay Spectral Smoothing
#'
#' Applies a Savitzky-Golay filter along the spectral dimension. Optionally
#' computes derivatives per nanometer on a uniform wavelength grid. Only
#' full-window center bands are returned. Invalid spectra remain missing.
#'
#' @param cube An [hsi_cube] object.
#' @param window Integer (odd). Filter window size in bands. Default `5`.
#' @param poly Integer. Polynomial order. Must be less than `window`. Default `2`.
#' @param deriv Integer. Derivative order (0 = smoothing only, 1 = first
#'   derivative, 2 = second derivative). Default `0`.
#'
#' @param backend Character. Explicit backend: `"builtin"` (default),
#'   `"prospectr"`, or `"signal"`. All use the same band support and units.
#' @return An [hsi_cube] object with smoothed/differentiated spectra.
#'
#' @examples
#' cube <- hs_example_cube()
#' smoothed <- hs_smooth(cube, window = 5, poly = 2)
#' dim(smoothed)
#'
#' @export
hs_smooth <- function(cube, window = 5L, poly = 2L, deriv = 0L,
                      backend = c("builtin", "prospectr", "signal")) {
  .validate_cube(cube)
  .require_wavelengths(cube)
  backend <- match.arg(backend)
  for (value in list(window, poly, deriv)) {
    if (length(value) != 1L || !is.finite(value) || value < 0 || value != as.integer(value)) {
      cli::cli_abort("SG parameters must be non-negative integers.")
    }
  }
  if (window < 1L || window %% 2L == 0L) cli::cli_abort("{.arg window} must be odd and positive.")
  if (poly >= window) cli::cli_abort("{.arg poly} must be less than {.arg window}.")
  if (deriv > poly) cli::cli_abort("{.arg deriv} must be <= {.arg poly}.")
  if (window > dim(cube$data)[3L]) cli::cli_abort("{.arg window} exceeds number of bands.")
  spacing <- diff(cube$wavelengths)
  delta <- if (length(spacing)) mean(spacing) else 1
  if (length(spacing) && max(abs(spacing - delta)) > 1e-7 * delta) {
    cli::cli_abort("Savitzky-Golay filtering requires a uniform wavelength grid; resample first.")
  }
  half <- (window - 1L) / 2L
  keep <- seq.int(half + 1L, length(cube$wavelengths) - half)
  pixels <- .pixel_matrix(cube)
  valid <- .valid_pixels(cube)
  out <- matrix(NA_real_, nrow(pixels), length(keep))
  if (backend != "builtin") rlang::check_installed(backend)
  if (any(valid)) {
    x <- pixels[valid, , drop = FALSE]
    if (backend == "prospectr") {
      filtered <- prospectr::savitzkyGolay(x, m = deriv, p = poly, w = window, delta.wav = delta)
    } else if (backend == "signal") {
      filtered <- t(vapply(seq_len(nrow(x)), function(i) {
        as.numeric(signal::sgolayfilt(x[i, ], p = poly, n = window, m = deriv, ts = delta))[keep]
      }, numeric(length(keep))))
    } else {
      coefficients <- .sg_coefficients(window, poly, deriv) / delta^deriv
      filtered <- vapply(keep, function(k) as.vector(x[, seq.int(k - half, k + half), drop = FALSE] %*% coefficients), numeric(nrow(x)))
    }
    out[valid, ] <- matrix(filtered, nrow = sum(valid), ncol = length(keep))
  }
  result <- cube[, , keep]
  result$data <- array(out, dim(result$data))
  result$metadata$sg_window <- window
  result$metadata$sg_poly <- poly
  result$metadata$sg_deriv <- deriv
  domain <- if (deriv > 0) "derivative" else NULL
  .record_step(result, "savitzky_golay", list(window = window, poly = poly,
    deriv = deriv, delta_nm = delta, backend = backend, edge = "trim"), domain)
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
  pixel_mat <- .pixel_matrix(cube)

  row_means <- rowMeans(pixel_mat)
  row_sds <- apply(pixel_mat, 1L, stats::sd)
  row_sds[row_sds == 0] <- 1  # Prevent division by zero

  snv_mat <- (pixel_mat - row_means) / row_sds

  cube$data <- array(snv_mat, dim = d)
  cube$metadata$snv_applied <- TRUE
  .record_step(cube, "snv", domain = "snv")
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
  pixel_mat <- .pixel_matrix(cube)

  if (is.null(reference)) {
    reference <- colMeans(pixel_mat[.valid_pixels(cube), , drop = FALSE])
  }

  if (length(reference) != d[3] || any(!is.finite(reference)) || stats::sd(reference) == 0) {
    cli::cli_abort("MSC reference must be finite, non-constant and match the band count.")
  }
  msc_mat <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = ncol(pixel_mat))

  for (i in which(.valid_pixels(cube))) {
    fit <- stats::lm.fit(cbind(1, reference), pixel_mat[i, ])
    intercept <- fit$coefficients[1]
    slope <- fit$coefficients[2]
    if (!is.finite(slope) || abs(slope) < sqrt(.Machine$double.eps)) next
    msc_mat[i, ] <- (pixel_mat[i, ] - intercept) / slope
  }

  cube$data <- array(msc_mat, dim = d)
  cube$metadata$msc_applied <- TRUE
  cube$metadata$msc_reference <- reference
  .record_step(cube, "msc", list(reference = reference), "msc")
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
