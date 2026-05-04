#' Calibrate Raw HSI Data to Reflectance
#'
#' Applies dark current subtraction and white reference normalization:
#' `R(x,y,lambda) = (raw - dark) / (white - dark)`. Values are clamped to
#' `[0, 1]` unless `clamp = FALSE`.
#'
#' @param cube An [hsi_cube] object with raw data.
#' @param dark An [hsi_cube] object or 3D array representing the dark reference
#'   (lens cap measurement).
#' @param white An [hsi_cube] object or 3D array representing the white
#'   reference (Spectralon panel measurement).
#' @param clamp Logical. Clamp output to `[0, 1]`. Default `TRUE`.
#'
#' @return An [hsi_cube] object with reflectance values.
#'
#' @examples
#' cube <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0)
#' dark <- hsi_cube(array(0.01, dim(cube$data)), cube$wavelengths)
#' white <- hsi_cube(array(0.95, dim(cube$data)), cube$wavelengths)
#' cal <- hs_calibrate(cube, dark, white)
#' range(cal$data)
#'
#' @export
hs_calibrate <- function(cube, dark, white, clamp = TRUE) {
  .validate_cube(cube)

  dark_data <- .extract_cal_data(dark, cube)
  white_data <- .extract_cal_data(white, cube)

  denom <- white_data - dark_data
  denom[denom == 0] <- 1e-10

  cal_data <- (cube$data - dark_data) / denom

  if (clamp) {
    cal_data[cal_data < 0] <- 0
    cal_data[cal_data > 1] <- 1
  }

  cube$data <- cal_data
  cube$metadata$processing_mode <- "reflectance"
  cube$metadata$calibrated <- TRUE
  cube
}

#' Apply Dark Current Correction
#'
#' Subtracts a dark reference from the cube data.
#'
#' @param cube An [hsi_cube] object.
#' @param dark An [hsi_cube] object or 3D array representing the dark reference.
#'
#' @return An [hsi_cube] object with dark-corrected values.
#'
#' @examples
#' cube <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0)
#' dark <- hsi_cube(array(0.01, dim(cube$data)), cube$wavelengths)
#' corrected <- hs_dark_correct(cube, dark)
#'
#' @export
hs_dark_correct <- function(cube, dark) {
  .validate_cube(cube)
  dark_data <- .extract_cal_data(dark, cube)
  cube$data <- cube$data - dark_data
  cube$metadata$dark_corrected <- TRUE
  cube
}

#' Apply White Reference Normalization
#'
#' Normalizes the cube by a white reference, optionally with dark correction.
#'
#' @param cube An [hsi_cube] object.
#' @param white An [hsi_cube] object or 3D array representing the white reference.
#' @param dark An [hsi_cube] object or 3D array representing the dark reference.
#'   Default `NULL` (no dark subtraction).
#'
#' @return An [hsi_cube] object with normalized values.
#'
#' @examples
#' cube <- hs_simulate_cube(rows = 10, cols = 10, noise_sd = 0)
#' white <- hsi_cube(array(0.95, dim(cube$data)), cube$wavelengths)
#' norm <- hs_white_normalize(cube, white)
#'
#' @export
hs_white_normalize <- function(cube, white, dark = NULL) {
  .validate_cube(cube)

  if (!is.null(dark)) {
    cube <- hs_dark_correct(cube, dark)
    white_data <- .extract_cal_data(white, cube) - .extract_cal_data(dark, cube)
  } else {
    white_data <- .extract_cal_data(white, cube)
  }

  white_data[white_data == 0] <- 1e-10
  cube$data <- cube$data / white_data
  cube$metadata$white_normalized <- TRUE
  cube
}

#' Detect and Correct Bad Pixels
#'
#' Identifies dead/hot pixels by statistical deviation from spatial
#' neighborhood and replaces with neighborhood interpolation.
#'
#' @param cube An [hsi_cube] object.
#' @param threshold Numeric. Standard deviation threshold for detection.
#'   Default `3`.
#' @param method Character. Replacement method: `"mean"` or `"median"` of
#'   spatial neighbors. Default `"median"`.
#'
#' @return An [hsi_cube] object with corrected pixels.
#'
#' @examples
#' cube <- hs_example_cube()
#' # Introduce a hot pixel
#' cube$data[15, 15, ] <- 999
#' fixed <- hs_fix_bad_pixels(cube, threshold = 3)
#'
#' @export
hs_fix_bad_pixels <- function(cube, threshold = 3, method = "median") {
  .validate_cube(cube)
  method <- match.arg(method, c("mean", "median"))

  d <- dim(cube$data)
  n_rows <- d[1]
  n_cols <- d[2]

  # Compute mean spectrum per pixel
  pixel_means <- rowMeans(cube$data, dims = 2L)

  # Compute neighborhood statistics
  n_fixed <- 0L
  data <- cube$data

  for (i in seq_len(n_rows)) {
    for (j in seq_len(n_cols)) {
      # Get 8-connected neighbors
      i_range <- max(1L, i - 1L):min(n_rows, i + 1L)
      j_range <- max(1L, j - 1L):min(n_cols, j + 1L)

      # Exclude self
      neighbor_vals <- pixel_means[i_range, j_range]
      self_val <- pixel_means[i, j]

      # Remove self from neighbors
      neighbor_flat <- as.vector(neighbor_vals)
      self_idx <- which(i_range == i) + (which(j_range == j) - 1L) * length(i_range)
      if (length(self_idx) == 1L) {
        neighbor_flat <- neighbor_flat[-self_idx]
      }

      if (length(neighbor_flat) < 2L) next

      n_mean <- mean(neighbor_flat)
      n_sd <- stats::sd(neighbor_flat)
      if (is.na(n_sd) || n_sd == 0) next

      if (abs(self_val - n_mean) > threshold * n_sd) {
        # Replace pixel
        neighbor_spectra <- data[i_range, j_range, , drop = FALSE]
        # Reshape to matrix of neighbor spectra
        dim_ns <- dim(neighbor_spectra)
        ns_mat <- matrix(neighbor_spectra, nrow = dim_ns[1] * dim_ns[2], ncol = dim_ns[3])

        if (method == "median") {
          data[i, j, ] <- apply(ns_mat, 2L, stats::median)
        } else {
          data[i, j, ] <- colMeans(ns_mat)
        }
        n_fixed <- n_fixed + 1L
      }
    }
  }

  cube$data <- data
  cube$metadata$bad_pixels_fixed <- n_fixed
  cube
}

#' Extract Calibration Data Array
#' @noRd
.extract_cal_data <- function(ref, cube) {
  if (inherits(ref, "hsi_cube")) {
    ref$data
  } else if (is.array(ref) && length(dim(ref)) == 3L) {
    ref
  } else {
    cli::cli_abort("Calibration reference must be an {.cls hsi_cube} or 3D array.")
  }
}
