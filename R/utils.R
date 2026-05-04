# Internal utility functions for hyperspectR
# Not exported — used by other package functions

#' Validate an hsi_cube Object
#' @param x Object to validate.
#' @return Invisible `x` if valid; otherwise errors.
#' @noRd
.validate_cube <- function(x) {
  if (!inherits(x, "hsi_cube")) {
    cli::cli_abort("{.arg x} must be an {.cls hsi_cube} object.")
  }

  if (!is.array(x$data) || length(dim(x$data)) != 3L) {
    cli::cli_abort("{.field data} must be a 3D array (rows x cols x bands).")
  }

  if (length(x$wavelengths) != dim(x$data)[3L]) {
    cli::cli_abort(
      "Length of {.field wavelengths} ({length(x$wavelengths)}) must match band count ({dim(x$data)[3L]})."
    )
  }

  if (!is.null(x$mask) && !identical(dim(x$mask), dim(x$data)[1:2])) {
    cli::cli_abort(
      "{.field mask} dimensions must match spatial dimensions of {.field data}."
    )
  }

  invisible(x)
}

#' Find Band Index Nearest to a Target Wavelength
#' @param wavelengths Numeric vector of wavelengths.
#' @param target Numeric scalar target wavelength.
#' @return Integer index.
#' @noRd
.band_index <- function(wavelengths, target) {
  which.min(abs(wavelengths - target))
}

#' Average Reflectance Across a Wavelength Range
#' @param cube An hsi_cube object.
#' @param range Numeric vector of length 2 (min_wl, max_wl).
#' @return Matrix (rows x cols) of mean reflectance in the range,
#'   or NULL if no bands fall within the range.
#' @noRd
.band_mean <- function(cube, range) {
  idx <- which(cube$wavelengths >= range[1] & cube$wavelengths <= range[2])
  if (length(idx) == 0L) return(NULL)
  if (length(idx) == 1L) return(cube$data[, , idx])
  rowMeans(cube$data[, , idx, drop = FALSE], dims = 2L)
}

#' Apply a Mask to a Matrix
#' @param mat Numeric matrix.
#' @param mask Logical matrix (same dims). TRUE = valid.
#' @return Matrix with masked pixels set to NA.
#' @noRd
.apply_mask <- function(mat, mask) {
  if (is.null(mask)) return(mat)
  mat[!mask] <- NA_real_
  mat
}

#' Check Wavelength Coverage
#' @param wavelengths Numeric vector of available wavelengths.
#' @param required Numeric vector of length 2 (min, max required).
#' @param index_name Character. Name of the index for warning message.
#' @return Logical. TRUE if coverage is sufficient.
#' @noRd
.check_wavelength_coverage <- function(wavelengths, required, index_name) {
  wl_range <- range(wavelengths)
  if (wl_range[1] > required[1] || wl_range[2] < required[2]) {
    cli::cli_warn(c(
      "!" = "Wavelength range ({wl_range[1]}-{wl_range[2]} nm) does not fully cover {index_name} requirements ({required[1]}-{required[2]} nm).",
      "i" = "Results may be approximate."
    ))
    return(FALSE)
  }
  TRUE
}

#' Wavelength to Approximate Visible Color
#' @param wavelength Numeric. Wavelength in nm.
#' @return Character. Hex color string.
#' @noRd
.wavelength_to_color <- function(wavelength) {
  vapply(wavelength, function(wl) {
    if (wl < 380 || wl > 780) return("#333333")

    if (wl < 440) {
      r <- -(wl - 440) / (440 - 380)
      g <- 0
      b <- 1
    } else if (wl < 490) {
      r <- 0
      g <- (wl - 440) / (490 - 440)
      b <- 1
    } else if (wl < 510) {
      r <- 0
      g <- 1
      b <- -(wl - 510) / (510 - 490)
    } else if (wl < 580) {
      r <- (wl - 510) / (580 - 510)
      g <- 1
      b <- 0
    } else if (wl < 645) {
      r <- 1
      g <- -(wl - 645) / (645 - 580)
      b <- 0
    } else {
      r <- 1
      g <- 0
      b <- 0
    }

    # Intensity factor for edge roll-off
    if (wl < 420) {
      factor <- 0.3 + 0.7 * (wl - 380) / (420 - 380)
    } else if (wl > 700) {
      factor <- 0.3 + 0.7 * (780 - wl) / (780 - 700)
    } else {
      factor <- 1.0
    }

    r <- r * factor
    g <- g * factor
    b <- b * factor

    grDevices::rgb(r, g, b)
  }, character(1))
}

#' Linear Histogram Stretch
#' @param x Numeric vector or matrix.
#' @param quantiles Numeric vector of length 2. Percentile clip bounds.
#' @return Numeric, same dimensions as x, stretched to 0-1 range.
#' @noRd
.linear_stretch <- function(x, quantiles = c(0.02, 0.98)) {
  lo <- stats::quantile(x, quantiles[1], na.rm = TRUE)
  hi <- stats::quantile(x, quantiles[2], na.rm = TRUE)
  if (hi == lo) return(x * 0 + 0.5)
  out <- (x - lo) / (hi - lo)
  out[out < 0] <- 0
  out[out > 1] <- 1
  out
}

#' Savitzky-Golay Convolution Coefficients (built-in fallback)
#' @param window Integer. Window size (must be odd).
#' @param poly Integer. Polynomial order.
#' @param deriv Integer. Derivative order.
#' @return Numeric vector of filter coefficients.
#' @noRd
.sg_coefficients <- function(window, poly, deriv = 0L) {
  half <- (window - 1L) / 2L
  x <- seq(-half, half)
  # Build Vandermonde matrix
  J <- outer(x, seq(0, poly), "^")
  # Pseudoinverse
  coefs <- solve(crossprod(J), t(J))
  # Row for the derivative order (with factorial scaling)
  coefs[deriv + 1L, ] * factorial(deriv)
}
