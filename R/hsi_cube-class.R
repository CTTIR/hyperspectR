#' Create an HSI Cube Object
#'
#' Constructs a hyperspectral imaging data cube as an S3 object. The cube
#' stores a 3D array of spectral data (rows x columns x bands) along with
#' wavelength metadata, spatial mask, and additional metadata.
#'
#' @param data Numeric 3D array with dimensions (rows, cols, bands).
#' @param wavelengths Numeric vector of band center wavelengths in nanometers.
#'   Length must match `dim(data)[3]`.
#' @param fwhm Numeric vector of full-width-at-half-maximum values per band in nm.
#'   Default `NULL` (unknown). If scalar, recycled to all bands.
#' @param metadata Named list of metadata (camera model, integration time,
#'   processing mode, acquisition timestamp, etc.). Default empty list.
#' @param mask Logical matrix matching spatial dimensions. `TRUE` = valid pixel.
#'   Default `NULL` (all pixels valid).
#'
#' @return An `hsi_cube` S3 object (a named list with class `"hsi_cube"`).
#'
#' @examples
#' # Create a small synthetic cube
#' data <- array(runif(10 * 10 * 5), dim = c(10, 10, 5))
#' wavelengths <- c(500, 550, 600, 650, 700)
#' cube <- hsi_cube(data, wavelengths)
#' print(cube)
#'
#' @export
hsi_cube <- function(data, wavelengths, fwhm = NULL, metadata = list(),
                     mask = NULL) {
  # Validate data

if (!is.numeric(data)) {
    cli::cli_abort("{.arg data} must be numeric.")
  }

  if (!is.array(data) || length(dim(data)) != 3L) {
    cli::cli_abort("{.arg data} must be a 3D array with dimensions (rows, cols, bands).")
  }

  # Validate wavelengths
  wavelengths <- as.numeric(wavelengths)
  if (length(wavelengths) != dim(data)[3L]) {
    cli::cli_abort(
      "Length of {.arg wavelengths} ({length(wavelengths)}) must match number of bands ({dim(data)[3L]})."
    )
  }

  if (is.unsorted(wavelengths, strictly = TRUE)) {
    cli::cli_warn("Wavelengths are not strictly monotonically increasing; sorting.")
    ord <- order(wavelengths)
    wavelengths <- wavelengths[ord]
    data <- data[, , ord, drop = FALSE]
  }

  # Validate / process fwhm
  if (!is.null(fwhm)) {
    fwhm <- as.numeric(fwhm)
    if (length(fwhm) == 1L) {
      fwhm <- rep(fwhm, length(wavelengths))
    }
    if (length(fwhm) != length(wavelengths)) {
      cli::cli_abort(
        "Length of {.arg fwhm} ({length(fwhm)}) must match number of bands ({length(wavelengths)})."
      )
    }
  }

  # Validate metadata
  if (!is.list(metadata)) {
    cli::cli_abort("{.arg metadata} must be a list.")
  }

  # Validate mask
  if (!is.null(mask)) {
    if (!is.logical(mask) || !is.matrix(mask)) {
      cli::cli_abort("{.arg mask} must be a logical matrix.")
    }
    if (!identical(dim(mask), dim(data)[1:2])) {
      cli::cli_abort(
        "{.arg mask} dimensions ({paste(dim(mask), collapse='x')}) must match spatial dimensions ({paste(dim(data)[1:2], collapse='x')})."
      )
    }
  }

  obj <- list(
    data = data,
    wavelengths = wavelengths,
    fwhm = fwhm,
    metadata = metadata,
    mask = mask
  )

  class(obj) <- "hsi_cube"
  obj
}
