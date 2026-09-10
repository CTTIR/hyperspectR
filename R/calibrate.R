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
#' @param saturation Optional finite saturation threshold in raw data units.
#'   Defaults to `metadata$saturation_value` when present; otherwise saturation
#'   remains an unresolved QC check.
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
hs_calibrate <- function(cube, dark, white, clamp = TRUE, saturation = NULL) {
  .validate_cube(cube)

  dark_data <- .extract_cal_data(dark, cube)
  white_data <- .extract_cal_data(white, cube)

  denom <- white_data - dark_data
  tolerance <- sqrt(.Machine$double.eps) * pmax(1, abs(white_data), abs(dark_data))
  invalid <- !is.finite(denom) | denom <= tolerance
  saturation <- saturation %||% cube$metadata$saturation_value
  saturated <- array(FALSE, dim(cube$data))
  if (!is.null(saturation)) {
    if (length(saturation) != 1L || !is.finite(saturation) || saturation <= 0) cli::cli_abort("saturation must be a finite positive threshold.")
    saturated <- (is.finite(cube$data) & cube$data >= saturation) |
      (is.finite(white_data) & white_data >= saturation) |
      (is.finite(dark_data) & dark_data >= saturation)
    invalid <- invalid | saturated
  }
  cube$metadata$calibration_saturated <- saturated
  cube$metadata$saturation_checked <- !is.null(saturation)
  denom[invalid] <- NA_real_

  cal_data <- (cube$data - dark_data) / denom

  clipped <- is.finite(cal_data) & (cal_data < 0 | cal_data > 1)
  cube$metadata$calibration_clipped <- clipped
  fields <- c("integration_time", "gain", "sensor_id")
  cube$metadata$calibration_compatibility_unknown <- fields[!vapply(fields, function(field) {
    all(vapply(list(cube, dark, white), function(ref) {
      inherits(ref, "hsi_cube") && .known_acquisition(ref$metadata[[field]])
    }, logical(1)))
  }, logical(1))]
  if (clamp) {
    cal_data[cal_data < 0] <- 0
    cal_data[cal_data > 1] <- 1
  }

  cube$data <- cal_data
  cube$metadata$processing_mode <- "reflectance"
  cube$metadata$calibrated <- TRUE
  cube$metadata$calibration_invalid <- invalid
  cube$mask <- .spatial_map(.valid_pixels(cube), cube)
  .record_step(cube, "calibrate", list(clamp = clamp, saturation = saturation), "reflectance")
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
  .record_step(cube, "dark_correct", domain = "dark_corrected")
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

  white_data[!is.finite(white_data) | white_data <= 0] <- NA_real_
  cube$data <- cube$data / white_data
  cube$metadata$white_normalized <- TRUE
  cube$mask <- .spatial_map(.valid_pixels(cube), cube)
  .record_step(cube, "white_normalize", domain = "reflectance")
}

#' Detect and Correct Bad Pixels
#'
#' Identifies dead/hot pixels by statistical deviation from spatial
#' neighborhood median/MAD and replaces with neighborhood interpolation.
#' Detection uses the immutable image; replacement excludes every detected
#' defect. Defects occupying most of a neighborhood may not be distinguishable.
#'
#' @param cube An [hsi_cube] object.
#' @param threshold Numeric. Robust standard deviation (scaled MAD) threshold.
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

  if (length(threshold) != 1L || !is.finite(threshold) || threshold <= 0) {
    cli::cli_abort("Threshold must be finite and positive.")
  }
  d <- dim(cube$data)
  original <- .pixel_matrix(cube)
  means <- rowMeans(original)
  valid <- .valid_pixels(cube)
  detected <- rep(FALSE, nrow(original))
  neighbors <- function(index) {
    row <- ((index - 1L) %% d[1L]) + 1L
    col <- ((index - 1L) %/% d[1L]) + 1L
    grid <- expand.grid(row = seq.int(max(1L, row - 1L), min(d[1L], row + 1L)),
                        col = seq.int(max(1L, col - 1L), min(d[2L], col + 1L)))
    ids <- grid$row + (grid$col - 1L) * d[1L]
    ids[ids != index & valid[ids]]
  }
  for (i in which(valid)) {
    ids <- neighbors(i)
    if (length(ids) < 2L) next
    deviation <- abs(means[i] - stats::median(means[ids]))
    spread <- stats::mad(means[ids])
    detected[i] <- deviation > threshold * spread + .Machine$double.eps * max(1, abs(means[i]))
  }
  output <- original
  repaired <- rep(FALSE, nrow(original))
  for (i in which(detected)) {
    ids <- neighbors(i)
    ids <- ids[!detected[ids]]
    if (!length(ids)) { output[i, ] <- NA_real_; next }
    output[i, ] <- if (method == "mean") colMeans(original[ids, , drop = FALSE]) else
      apply(original[ids, , drop = FALSE], 2L, stats::median)
    repaired[i] <- TRUE
  }
  cube$data <- array(output, d)
  cube$metadata$bad_pixels_fixed <- sum(repaired)
  cube$metadata$repair_mask <- .spatial_map(repaired, cube)
  cube$metadata$defect_mask <- .spatial_map(detected, cube)
  cube$mask <- .spatial_map(.valid_pixels(cube), cube)
  .record_step(cube, "repair_bad_pixels", list(threshold = threshold, method = method))
}

#' Extract Calibration Data Array
#' @noRd
.extract_cal_data <- function(ref, cube) {
  if (inherits(ref, "hsi_cube")) {
    .validate_cube(ref)
    if (!isTRUE(all.equal(ref$wavelengths, cube$wavelengths, tolerance = 1e-8))) {
      cli::cli_abort("Calibration reference wavelengths must match the cube.")
    }
    for (field in c("integration_time", "gain", "sensor_id")) {
      if (.known_acquisition(ref$metadata[[field]]) && .known_acquisition(cube$metadata[[field]]) &&
          !identical(ref$metadata[[field]], cube$metadata[[field]])) {
        cli::cli_abort("Calibration reference {field} must match the cube.")
      }
    }
    data <- array(.pixel_matrix(ref), dim(ref$data))
  } else if (is.numeric(ref) && is.array(ref) && length(dim(ref)) == 3L) {
    data <- ref
  } else {
    cli::cli_abort("Calibration reference must be an {.cls hsi_cube} or 3D array.")
  }
  if (!identical(dim(data), dim(cube$data))) cli::cli_abort("Calibration reference dimensions must match the cube.")
  data
}

.known_acquisition <- function(value) !is.null(value) && length(value) > 0L && !anyNA(value)
