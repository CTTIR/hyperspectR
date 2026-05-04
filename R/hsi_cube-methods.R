#' Print an hsi_cube Object
#'
#' Displays a compact summary of the hyperspectral cube.
#'
#' @param x An [hsi_cube] object.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisible `x`.
#'
#' @examples
#' cube <- hs_example_cube()
#' print(cube)
#'
#' @export
print.hsi_cube <- function(x, ...) {
  d <- dim(x$data)
  wl <- x$wavelengths

  cli::cli_h1("hsi_cube")
  cli::cli_text("Dimensions: {d[1]} rows x {d[2]} cols x {d[3]} bands")
  cli::cli_text("Wavelengths: {round(min(wl), 1)}-{round(max(wl), 1)} nm ({d[3]} bands)")

  if (!is.null(x$fwhm)) {
    cli::cli_text("FWHM: {round(mean(x$fwhm), 1)} nm (mean)")
  }

  if (!is.null(x$mask)) {
    n_valid <- sum(x$mask)
    n_total <- prod(d[1:2])
    cli::cli_text("Mask: {n_valid}/{n_total} valid pixels ({round(100 * n_valid / n_total, 1)}%)")
  }

  data_range <- range(x$data, na.rm = TRUE)
  cli::cli_text("Data range: [{round(data_range[1], 4)}, {round(data_range[2], 4)}]")

  if (length(x$metadata) > 0L) {
    meta_names <- paste(names(x$metadata), collapse = ", ")
    cli::cli_text("Metadata: {meta_names}")
  }

  invisible(x)
}

#' Summarize an hsi_cube Object
#'
#' Returns a named list of cube statistics including per-band means and
#' standard deviations.
#'
#' @param object An [hsi_cube] object.
#' @param ... Additional arguments (ignored).
#'
#' @return A named list with elements `dimensions`, `wavelength_range`,
#'   `n_bands`, `data_range`, `band_means`, `band_sds`, `n_valid_pixels`,
#'   and `metadata`.
#'
#' @examples
#' cube <- hs_example_cube()
#' s <- summary(cube)
#' s$dimensions
#'
#' @export
summary.hsi_cube <- function(object, ...) {
  d <- dim(object$data)
  n_pixels <- d[1] * d[2]

  band_means <- apply(object$data, 3L, mean, na.rm = TRUE)
  band_sds <- apply(object$data, 3L, stats::sd, na.rm = TRUE)

  result <- list(
    dimensions = d,
    wavelength_range = range(object$wavelengths),
    n_bands = d[3],
    data_range = range(object$data, na.rm = TRUE),
    band_means = stats::setNames(band_means, round(object$wavelengths)),
    band_sds = stats::setNames(band_sds, round(object$wavelengths)),
    n_valid_pixels = if (!is.null(object$mask)) sum(object$mask) else n_pixels,
    n_total_pixels = n_pixels,
    metadata = object$metadata
  )

  class(result) <- "summary.hsi_cube"
  result
}

#' Get Dimensions of an hsi_cube
#'
#' @param x An [hsi_cube] object.
#'
#' @return Integer vector `c(rows, cols, bands)`.
#'
#' @examples
#' cube <- hs_example_cube()
#' dim(cube)
#'
#' @export
dim.hsi_cube <- function(x) {
  dim(x$data)
}

#' Subset an hsi_cube Object
#'
#' Extract spatial and/or spectral subsets from a cube. Subsetting preserves
#' the `hsi_cube` class.
#'
#' @param x An [hsi_cube] object.
#' @param i Row indices (spatial).
#' @param j Column indices (spatial).
#' @param k Band indices (spectral).
#' @param ... Additional arguments (ignored).
#'
#' @return A subsetted [hsi_cube] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' sub <- cube[1:10, 1:10, 1:5]
#' dim(sub)
#'
#' @export
`[.hsi_cube` <- function(x, i, j, k, ...) {
  d <- dim(x$data)

  if (missing(i)) i <- seq_len(d[1])
  if (missing(j)) j <- seq_len(d[2])
  if (missing(k)) k <- seq_len(d[3])

  new_data <- x$data[i, j, k, drop = FALSE]
  new_wl <- x$wavelengths[k]
  new_fwhm <- if (!is.null(x$fwhm)) x$fwhm[k] else NULL
  new_mask <- if (!is.null(x$mask)) x$mask[i, j, drop = FALSE] else NULL

  hsi_cube(
    data = new_data,
    wavelengths = new_wl,
    fwhm = new_fwhm,
    metadata = x$metadata,
    mask = new_mask
  )
}

#' Convert hsi_cube to Data Frame
#'
#' @param x An [hsi_cube] object.
#' @param ... Additional arguments (ignored).
#' @param long Logical. If `TRUE`, returns long format with columns
#'   `x`, `y`, `wavelength`, `value`. If `FALSE`, returns wide format with
#'   columns `x`, `y`, and one column per band. Default `FALSE`.
#'
#' @return A `data.frame`.
#'
#' @examples
#' cube <- hs_example_cube()
#' df <- as.data.frame(cube[1:3, 1:3, 1:3], long = TRUE)
#' head(df)
#'
#' @export
as.data.frame.hsi_cube <- function(x, ..., long = FALSE) {
  d <- dim(x$data)
  coords <- expand.grid(y = seq_len(d[1]), x = seq_len(d[2]))

  if (long) {
    # Reshape to long format
    pixel_mat <- matrix(x$data, nrow = d[1] * d[2], ncol = d[3])
    long_coords <- coords[rep(seq_len(nrow(coords)), each = d[3]), ]
    long_coords$wavelength <- rep(x$wavelengths, times = nrow(coords))
    long_coords$value <- as.vector(t(pixel_mat))
    rownames(long_coords) <- NULL
    long_coords[, c("x", "y", "wavelength", "value")]
  } else {
    # Wide format
    pixel_mat <- matrix(x$data, nrow = d[1] * d[2], ncol = d[3])
    colnames(pixel_mat) <- paste0("band_", round(x$wavelengths))
    cbind(coords[, c("x", "y")], as.data.frame(pixel_mat))
  }
}

#' Convert hsi_cube to Tibble
#'
#' @param x An [hsi_cube] object.
#' @param ... Additional arguments (ignored).
#' @param long Logical. If `TRUE` (default), returns long format. See
#'   [as.data.frame.hsi_cube()] for details.
#' @param .name_repair Name repair strategy (passed to [tibble::as_tibble()]).
#'
#' @return A [tibble::tibble].
#'
#' @examples
#' cube <- hs_example_cube()
#' tb <- as_tibble.hsi_cube(cube[1:3, 1:3, 1:3])
#' head(tb)
#'
#' @name as_tibble.hsi_cube
#' @export
as_tibble.hsi_cube <- function(x, ..., long = TRUE, .name_repair = "unique") {
  df <- as.data.frame.hsi_cube(x, long = long)
  tibble::as_tibble(df, .name_repair = .name_repair)
}
