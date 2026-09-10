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

  if (!is.numeric(x$data) || !is.array(x$data) || length(dim(x$data)) != 3L || any(dim(x$data) == 0L)) {
    cli::cli_abort("{.field data} must be a 3D array (rows x cols x bands).")
  }

  if (any(!is.finite(x$wavelengths)) || any(x$wavelengths <= 0) ||
      is.unsorted(x$wavelengths, strictly = TRUE)) {
    cli::cli_abort("Wavelengths must be finite, positive, unique and increasing.")
  }
  if (!is.null(x$fwhm) && (length(x$fwhm) != dim(x$data)[3L] ||
      any(!is.finite(x$fwhm)) || any(x$fwhm <= 0))) {
    cli::cli_abort("FWHM must be finite, positive and match the band count.")
  }

  if (length(x$wavelengths) != dim(x$data)[3L]) {
    cli::cli_abort(
      "Length of {.field wavelengths} ({length(x$wavelengths)}) must match band count ({dim(x$data)[3L]})."
    )
  }
  if (!is.null(x$mask)) .validate_spatial_mask(x$mask, x)

  if (!is.null(x$mask) && !identical(dim(x$mask), dim(x$data)[1:2])) {
    cli::cli_abort(
      "{.field mask} dimensions must match spatial dimensions of {.field data}."
    )
  }

  invisible(x)
}

.validate_spatial_mask <- function(mask, cube) {
  if (!is.logical(mask) || !is.matrix(mask) || anyNA(mask) ||
      !identical(dim(mask), dim(cube$data)[1:2])) {
    cli::cli_abort("Mask must be a logical matrix without NA matching spatial dimensions.")
  }
  invisible(mask)
}

.pixel_matrix <- function(cube, bands = seq_along(cube$wavelengths)) {
  x <- matrix(cube$data, nrow = prod(dim(cube$data)[1:2]))[, bands, drop = FALSE]
  x[!is.finite(x)] <- NA_real_
  if (!is.null(cube$mask)) x[!as.vector(cube$mask), ] <- NA_real_
  x
}

.valid_pixels <- function(cube, bands = seq_along(cube$wavelengths)) {
  rowSums(!is.finite(.pixel_matrix(cube, bands))) == 0L
}

.spatial_map <- function(x, cube) matrix(x, nrow = dim(cube$data)[1L], ncol = dim(cube$data)[2L])

.band_matrix <- function(cube, band) .spatial_map(.pixel_matrix(cube, band), cube)

.record_step <- function(cube, method, parameters = list(), domain = NULL) {
  cube$metadata$history <- c(cube$metadata$history, list(list(
    method = method, parameters = parameters,
    package_version = as.character(utils::packageVersion("hyperspectR"))
  )))
  if (!is.null(domain)) cube$metadata$processing_mode <- domain
  cube
}

.require_wavelengths <- function(cube) {
  if (identical(cube$metadata$wavelengths_known, FALSE)) {
    cli::cli_abort("Measured wavelengths in nm are required for spectral analysis.")
  }
  invisible(cube)
}

#' Find Band Index Nearest to a Target Wavelength
#' @param wavelengths Numeric vector of wavelengths.
#' @param target Numeric scalar target wavelength.
#' @return Integer index.
#' @noRd
.band_index <- function(wavelengths, target) {
  if (length(target) != 1L || !is.finite(target)) {
    cli::cli_abort("Target wavelength must be a finite scalar.")
  }
  which.min(abs(wavelengths - target))
}

#' Average Reflectance Across a Wavelength Range
#' @param cube An hsi_cube object.
#' @param range Numeric vector of length 2 (min_wl, max_wl).
#' @return Matrix (rows x cols) of mean reflectance in the range,
#'   or NULL if no bands fall within the range.
#' @noRd
.band_mean <- function(cube, range) {
  .require_wavelengths(cube)
  if (length(range) != 2L || any(!is.finite(range)) || range[1] > range[2]) {
    cli::cli_abort("Band range must contain two finite increasing wavelengths.")
  }
  idx <- which(cube$wavelengths >= range[1] & cube$wavelengths <= range[2])
  if (length(idx) == 0L) return(NULL)
  .spatial_map(rowMeans(.pixel_matrix(cube, idx)), cube)
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
  x[!is.finite(x)] <- NA_real_
  if (all(is.na(x))) return(x)
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

.validate_pixel_coordinates <- function(pixels, cube) {
  if (!is.data.frame(pixels) || !all(c("x", "y") %in% names(pixels)) || !nrow(pixels) ||
      !is.numeric(pixels$x) || !is.numeric(pixels$y) || any(!is.finite(as.matrix(pixels[c("x", "y")])))) {
    cli::cli_abort("Pixels must contain finite x/y coordinates.")
  }
  if (any(pixels$x != as.integer(pixels$x) | pixels$y != as.integer(pixels$y)) ||
      any(pixels$x < 1 | pixels$x > dim(cube$data)[2] | pixels$y < 1 | pixels$y > dim(cube$data)[1])) {
    cli::cli_abort("Pixel coordinates must be integers within spatial dimensions.")
  }
  invisible(pixels)
}

.feature_contract <- function(cube) list(
  domain = cube$metadata$processing_mode %||% "unknown", fwhm = cube$fwhm,
  msc_reference = cube$metadata$msc_reference,
  sg_window = cube$metadata$sg_window, sg_poly = cube$metadata$sg_poly,
  sg_deriv = cube$metadata$sg_deriv)
