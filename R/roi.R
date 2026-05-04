#' Define Rectangular ROI
#'
#' Creates a rectangular region of interest on an HSI cube.
#'
#' @param cube An [hsi_cube] object.
#' @param x_range Numeric vector of length 2 (column indices, min and max).
#' @param y_range Numeric vector of length 2 (row indices, min and max).
#'
#' @return A list with class `"hsi_roi"` containing the mask and bounds.
#'
#' @examples
#' cube <- hs_example_cube()
#' roi <- hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
#' sum(roi$mask)
#'
#' @export
hs_roi_rect <- function(cube, x_range, y_range) {
  .validate_cube(cube)

  d <- dim(cube$data)
  mask <- matrix(FALSE, nrow = d[1], ncol = d[2])

  y_idx <- max(1L, y_range[1]):min(d[1], y_range[2])
  x_idx <- max(1L, x_range[1]):min(d[2], x_range[2])
  mask[y_idx, x_idx] <- TRUE

  result <- list(
    mask = mask,
    type = "rectangle",
    x_range = x_range,
    y_range = y_range
  )
  class(result) <- "hsi_roi"
  result
}

#' Define Polygon ROI
#'
#' Creates a polygon region of interest using point-in-polygon testing.
#'
#' @param cube An [hsi_cube] object.
#' @param vertices Matrix with columns `x` and `y` (polygon vertices in pixel
#'   coordinates).
#'
#' @return A list with class `"hsi_roi"` containing the mask.
#'
#' @examples
#' cube <- hs_example_cube()
#' verts <- matrix(c(5, 5, 15, 15, 5, 20, 5, 20), ncol = 2,
#'                 dimnames = list(NULL, c("x", "y")))
#' roi <- hs_roi_polygon(cube, verts)
#'
#' @export
hs_roi_polygon <- function(cube, vertices) {
  .validate_cube(cube)

  if (is.data.frame(vertices)) vertices <- as.matrix(vertices)
  if (ncol(vertices) != 2L) {
    cli::cli_abort("{.arg vertices} must have 2 columns (x, y).")
  }

  d <- dim(cube$data)
  mask <- matrix(FALSE, nrow = d[1], ncol = d[2])

  # Point-in-polygon test using ray casting
  poly_x <- vertices[, 1]
  poly_y <- vertices[, 2]
  n_verts <- nrow(vertices)

  for (row in seq_len(d[1])) {
    for (col in seq_len(d[2])) {
      inside <- .point_in_polygon(col, row, poly_x, poly_y, n_verts)
      mask[row, col] <- inside
    }
  }

  result <- list(
    mask = mask,
    type = "polygon",
    vertices = vertices
  )
  class(result) <- "hsi_roi"
  result
}

#' Compute ROI Statistics
#'
#' Computes per-band spectral statistics within a region of interest.
#'
#' @param cube An [hsi_cube] object.
#' @param roi An `hsi_roi` object (from [hs_roi_rect()] or [hs_roi_polygon()]),
#'   or a logical mask matrix.
#'
#' @return A [tibble::tibble] with columns `wavelength`, `mean`, `sd`, `median`,
#'   `min`, `max`, `n_pixels`.
#'
#' @examples
#' cube <- hs_example_cube()
#' roi <- hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
#' stats <- hs_roi_stats(cube, roi)
#' head(stats)
#'
#' @export
hs_roi_stats <- function(cube, roi) {
  .validate_cube(cube)

  if (inherits(roi, "hsi_roi")) {
    mask <- roi$mask
  } else if (is.logical(roi) && is.matrix(roi)) {
    mask <- roi
  } else {
    cli::cli_abort("{.arg roi} must be an {.cls hsi_roi} object or logical matrix.")
  }

  d <- dim(cube$data)
  n_pixels <- sum(mask)

  if (n_pixels == 0L) {
    cli::cli_warn("ROI contains no pixels.")
    return(tibble::tibble(
      wavelength = cube$wavelengths,
      mean = NA_real_, sd = NA_real_, median = NA_real_,
      min = NA_real_, max = NA_real_, n_pixels = 0L
    ))
  }

  # Extract ROI pixels
  result <- tibble::tibble(
    wavelength = cube$wavelengths,
    mean = NA_real_,
    sd = NA_real_,
    median = NA_real_,
    min = NA_real_,
    max = NA_real_,
    n_pixels = as.integer(n_pixels)
  )

  for (b in seq_len(d[3])) {
    band_vals <- cube$data[, , b][mask]
    result$mean[b] <- mean(band_vals, na.rm = TRUE)
    result$sd[b] <- stats::sd(band_vals, na.rm = TRUE)
    result$median[b] <- stats::median(band_vals, na.rm = TRUE)
    result$min[b] <- min(band_vals, na.rm = TRUE)
    result$max[b] <- max(band_vals, na.rm = TRUE)
  }

  result
}

#' Point-in-Polygon Test (Ray Casting)
#' @noRd
.point_in_polygon <- function(px, py, poly_x, poly_y, n) {
  inside <- FALSE
  j <- n
  for (i in seq_len(n)) {
    if (((poly_y[i] > py) != (poly_y[j] > py)) &&
        (px < (poly_x[j] - poly_x[i]) * (py - poly_y[i]) /
         (poly_y[j] - poly_y[i] + 1e-10) + poly_x[i])) {
      inside <- !inside
    }
    j <- i
  }
  inside
}
