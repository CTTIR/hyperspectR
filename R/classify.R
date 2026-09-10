#' Spectral Angle Mapper Classification
#'
#' Classifies each pixel by computing the spectral angle to a set of reference
#' endmember spectra and assigning the class with the smallest angle.
#'
#' @param cube An [hsi_cube] object.
#' @param endmembers Named matrix or data.frame. Rows = endmembers, cols = bands.
#'   Row names become class labels.
#' @param threshold Numeric. Maximum angle (radians) for assignment. Pixels
#'   exceeding this are classified as `"unclassified"`. Default `0.1`.
#'
#' @return A list with class `"hsi_classification"`:
#' \describe{
#'   \item{class_map}{Character matrix (rows x cols) of class labels.}
#'   \item{angle_map}{3D array of angles to each endmember.}
#'   \item{endmembers}{The endmember matrix used.}
#' }
#'
#' @examples
#' cube <- hs_example_cube()
#' # Define endmembers from specific pixels
#' em <- rbind(
#'   healthy = cube$data[5, 5, ],
#'   ischemic = cube$data[25, 5, ]
#' )
#' result <- hs_sam(cube, em, threshold = 0.5)
#' table(result$class_map)
#'
#' @export
hs_sam <- function(cube, endmembers, threshold = 0.1) {
  .validate_cube(cube)

  if (is.data.frame(endmembers)) endmembers <- as.matrix(endmembers)

  if (!is.matrix(endmembers) || !is.numeric(endmembers) || !nrow(endmembers) || any(!is.finite(endmembers)) || any(rowSums(endmembers^2) == 0)) cli::cli_abort("Endmembers must be finite non-zero spectra.")
  if (length(threshold) != 1L || !is.finite(threshold) || threshold < 0 || threshold > pi) cli::cli_abort("Threshold must be between zero and pi radians.")
  if (ncol(endmembers) != dim(cube$data)[3L]) {
    cli::cli_abort(
      "Endmember columns ({ncol(endmembers)}) must match cube bands ({dim(cube$data)[3L]})."
    )
  }

  if (is.null(rownames(endmembers))) {
    rownames(endmembers) <- paste0("class_", seq_len(nrow(endmembers)))
  }

  d <- dim(cube$data)
  n_em <- nrow(endmembers)
  class_names <- rownames(endmembers)

  pixel_mat <- .pixel_matrix(cube)

  # Compute spectral angles
  angle_mat <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = n_em)

  # Precompute endmember norms
  em_norms <- sqrt(rowSums(endmembers^2))

  for (e in seq_len(n_em)) {
    dots <- pixel_mat %*% endmembers[e, ]
    pixel_norms <- sqrt(rowSums(pixel_mat^2))
    cos_angle <- dots / (pixel_norms * em_norms[e])
    cos_angle <- pmin(pmax(cos_angle, -1), 1)
    angle_mat[, e] <- acos(cos_angle)
  }

  valid <- .valid_pixels(cube) & rowSums(pixel_mat^2, na.rm = TRUE) > 0
  class_vec <- rep(NA_character_, nrow(pixel_mat))
  for (i in which(valid)) {
    closest <- which.min(angle_mat[i, ])
    class_vec[i] <- if (angle_mat[i, closest] <= threshold) class_names[closest] else "unclassified"
  }

  class_map <- matrix(class_vec, nrow = d[1], ncol = d[2])
  angle_map <- array(angle_mat, dim = c(d[1], d[2], n_em))

  result <- list(
    class_map = class_map,
    angle_map = angle_map,
    endmembers = endmembers,
    threshold = threshold
  )

  class(result) <- "hsi_classification"
  result
}

#' SVM Pixel Classification
#'
#' Trains a Support Vector Machine on labeled pixels and classifies all pixels.
#' Requires the `e1071` package.
#'
#' @param cube An [hsi_cube] object.
#' @param training_labels Character or factor matrix (same spatial dims as cube)
#'   with class labels. `NA` for unlabeled pixels.
#' @param training_mask Logical matrix. Alternative to NA in labels. Default `NULL`.
#' @param kernel Character. SVM kernel: `"radial"` (default), `"linear"`, `"polynomial"`.
#' @param cost Numeric. Cost parameter. Default `10`.
#' @param gamma Numeric. Gamma parameter. Default `NULL` (auto).
#' @param ... Additional arguments passed to [e1071::svm()].
#'
#' @return A list with class `"hsi_classification"` containing `class_map`.
#'
#' @examples
#' \donttest{
#' # Requires e1071 package
#' cube <- hs_example_cube()
#' labels <- matrix(NA_character_, 30, 30)
#' labels[1:10, 1:10] <- "class_a"
#' labels[20:30, 20:30] <- "class_b"
#' if (requireNamespace("e1071", quietly = TRUE)) {
#'   result <- hs_classify_svm(cube, labels)
#' }
#' }
#'
#' @export
hs_classify_svm <- function(cube, training_labels, training_mask = NULL,
                            kernel = "radial", cost = 10, gamma = NULL, ...) {
  .validate_cube(cube)

  if (!requireNamespace("e1071", quietly = TRUE)) {
    cli::cli_abort(c(
      "!" = "Package {.pkg e1071} is required for SVM classification.",
      "i" = "Install with {.code install.packages('e1071')}."
    ))
  }

  d <- dim(cube$data)
  pixel_mat <- .pixel_matrix(cube)
  labels_vec <- .training_labels(cube, training_labels, training_mask)

  if (!is.null(training_mask)) {
    labels_vec[!as.vector(training_mask)] <- NA
  }

  # Get labeled pixels
  labeled <- !is.na(labels_vec)
  if (sum(labeled) < 2L) {
    cli::cli_abort("Need at least 2 labeled pixels for SVM training.")
  }

  train_x <- pixel_mat[labeled, , drop = FALSE]
  train_y <- factor(labels_vec[labeled])

  if (is.null(gamma)) gamma <- 1 / ncol(train_x)

  model <- e1071::svm(train_x, train_y, kernel = kernel,
                       cost = cost, gamma = gamma, ...)

  valid <- .valid_pixels(cube)
  predictions <- rep(NA_character_, nrow(pixel_mat))
  predictions[valid] <- as.character(stats::predict(model, pixel_mat[valid, , drop = FALSE]))
  class_map <- matrix(predictions, nrow = d[1], ncol = d[2])

  result <- list(
    class_map = class_map,
    model = model, wavelengths = cube$wavelengths, feature_contract = .feature_contract(cube),
    input_domain = cube$metadata$processing_mode %||% "unknown",
    training_pixels = sum(!is.na(labels_vec))
  )
  class(result) <- "hsi_classification"
  result
}

#' Random Forest Pixel Classification
#'
#' Trains a random forest on labeled pixels and classifies all pixels.
#' Requires the `ranger` package.
#'
#' @param cube An [hsi_cube] object.
#' @param training_labels Character or factor matrix with class labels.
#'   `NA` for unlabeled pixels.
#' @param training_mask Logical matrix. Default `NULL`.
#' @param num.trees Integer. Number of trees. Default `500`.
#' @param mtry Integer. Variables per split. Default `NULL` (auto).
#' @param ... Additional arguments passed to [ranger::ranger()].
#'
#' @return A list with class `"hsi_classification"` containing `class_map`.
#'
#' @examples
#' \donttest{
#' # Requires ranger package
#' cube <- hs_example_cube()
#' labels <- matrix(NA_character_, 30, 30)
#' labels[1:10, 1:10] <- "class_a"
#' labels[20:30, 20:30] <- "class_b"
#' if (requireNamespace("ranger", quietly = TRUE)) {
#'   result <- hs_classify_rf(cube, labels)
#' }
#' }
#'
#' @export
hs_classify_rf <- function(cube, training_labels, training_mask = NULL,
                           num.trees = 500L, mtry = NULL, ...) {
  .validate_cube(cube)

  if (!requireNamespace("ranger", quietly = TRUE)) {
    cli::cli_abort(c(
      "!" = "Package {.pkg ranger} is required for random forest classification.",
      "i" = "Install with {.code install.packages('ranger')}."
    ))
  }

  d <- dim(cube$data)
  pixel_mat <- .pixel_matrix(cube)
  labels_vec <- .training_labels(cube, training_labels, training_mask)

  if (!is.null(training_mask)) {
    labels_vec[!as.vector(training_mask)] <- NA
  }

  labeled <- !is.na(labels_vec)
  train_x <- as.data.frame(pixel_mat[labeled, , drop = FALSE])
  colnames(train_x) <- paste0("band_", seq_len(ncol(train_x)))
  train_x$label <- factor(labels_vec[labeled])

  model <- ranger::ranger(label ~ ., data = train_x,
                          num.trees = as.integer(num.trees),
                          mtry = mtry, ...)

  valid <- .valid_pixels(cube)
  predict_x <- as.data.frame(pixel_mat[valid, , drop = FALSE])
  colnames(predict_x) <- paste0("band_", seq_len(ncol(predict_x)))

  predictions <- stats::predict(model, data = predict_x)
  predicted <- rep(NA_character_, nrow(pixel_mat))
  predicted[valid] <- as.character(predictions$predictions)
  class_map <- matrix(predicted, nrow = d[1], ncol = d[2])

  result <- list(
    class_map = class_map,
    model = model, wavelengths = cube$wavelengths, feature_contract = .feature_contract(cube),
    input_domain = cube$metadata$processing_mode %||% "unknown",
    training_pixels = sum(!is.na(labels_vec))
  )
  class(result) <- "hsi_classification"
  result
}

#' Extract Endmember Spectra from a Cube
#'
#' Extracts endmember spectra from specified pixel locations.
#'
#' @param cube An [hsi_cube] object.
#' @param pixels Data.frame or matrix with columns `x` (col) and `y` (row).
#' @param labels Character vector of class labels for each pixel. Default `NULL`
#'   (auto-generated).
#'
#' @return A named matrix with endmember spectra (rows = endmembers, cols = bands).
#'
#' @examples
#' cube <- hs_example_cube()
#' pixels <- data.frame(x = c(5, 25), y = c(5, 25))
#' em <- hs_endmembers(cube, pixels, labels = c("region_1", "region_2"))
#' dim(em)
#'
#' @export
hs_endmembers <- function(cube, pixels, labels = NULL) {
  .validate_cube(cube)

  if (is.data.frame(pixels)) {
    x_coords <- pixels$x
    y_coords <- pixels$y
  } else {
    x_coords <- pixels[, 1]
    y_coords <- pixels[, 2]
  }

  .validate_pixel_coordinates(data.frame(x = x_coords, y = y_coords), cube)
  ids <- y_coords + (x_coords - 1L) * dim(cube$data)[1]
  if (any(!.valid_pixels(cube)[ids])) cli::cli_abort("Endmember pixels must contain valid finite spectra.")
  n <- length(x_coords)
  if (is.null(labels)) labels <- paste0("endmember_", seq_len(n))

  if (length(labels) != n || anyNA(labels) || anyDuplicated(labels)) cli::cli_abort("Labels must be unique and match the number of pixels.")
  em <- matrix(NA_real_, nrow = n, ncol = dim(cube$data)[3])
  for (i in seq_len(n)) {
    em[i, ] <- cube$data[y_coords[i], x_coords[i], ]
  }

  rownames(em) <- labels
  colnames(em) <- paste0("band_", round(cube$wavelengths))
  em
}

.training_labels <- function(cube, labels, mask) {
  if (!is.matrix(labels) || !identical(dim(labels), dim(cube$data)[1:2])) cli::cli_abort("Training labels must match spatial dimensions.")
  labels <- as.character(labels)
  if (!is.null(mask)) {
    .validate_spatial_mask(mask, cube)
    labels[!as.vector(mask)] <- NA_character_
  }
  labels[!.valid_pixels(cube)] <- NA_character_
  if (sum(!is.na(labels)) < 2L || length(unique(labels[!is.na(labels)])) < 2L) cli::cli_abort("Need at least 2 labeled pixels in at least two classes for training.")
  labels
}

#' Predict Classes in a New Cube Using a Fitted Classifier
#' @param model Classification result from [hs_classify_svm()] or [hs_classify_rf()].
#' @param cube New [hsi_cube] on the same wavelength grid and preprocessing domain.
#' @return Character matrix of predicted classes; invalid pixels are NA.
#' @export
hs_predict <- function(model, cube) {
  .validate_cube(cube)
  if (!inherits(model, "hsi_classification") || is.null(model$model)) cli::cli_abort("Supply a fitted SVM or random forest classification result.")
  if (!isTRUE(all.equal(model$wavelengths, cube$wavelengths, tolerance = 1e-8))) cli::cli_abort("Prediction wavelengths must match training wavelengths.")
  if (!identical(model$input_domain, cube$metadata$processing_mode %||% "unknown")) cli::cli_abort("Prediction preprocessing domain must match training.")
  if (!isTRUE(all.equal(model$feature_contract, .feature_contract(cube)))) cli::cli_abort("Prediction preprocessing and band response must match training.")
  valid <- .valid_pixels(cube)
  result <- rep(NA_character_, prod(dim(cube$data)[1:2]))
  if (any(valid)) {
    x <- .pixel_matrix(cube)[valid, , drop = FALSE]
    if (inherits(model$model, "svm")) result[valid] <- as.character(stats::predict(model$model, x)) else {
      x <- as.data.frame(x)
      names(x) <- paste0("band_", seq_len(ncol(x)))
      result[valid] <- as.character(stats::predict(model$model, data = x)$predictions)
    }
  }
  .spatial_map(result, cube)
}
