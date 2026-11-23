#' Print hyperspectR Result Objects
#'
#' Compact console overviews for the objects returned by the analysis
#' functions. Without these methods R prints every score map, residual cube
#' and fitted model in full. Each method shows the class, the dimensions and
#' the key settings, and returns its argument invisibly. The objects stay
#' plain lists: use `names()`, `str()` or `$` to reach every element.
#'
#' @param x An object returned by [summary.hsi_cube()], [hs_pca()],
#'   [hs_mnf()], [hs_umap()], [hs_unmix_nnls()], [hs_beer_lambert()],
#'   [hs_sam()], [hs_classify_svm()], [hs_classify_rf()], [hs_roi_rect()],
#'   [hs_roi_polygon()] or [hs_recipe()].
#' @param ... Additional arguments (ignored).
#'
#' @return Invisible `x`.
#'
#' @examples
#' cube <- hs_example_cube()
#' summary(cube)
#' hs_pca(cube, n_components = 3)
#' hs_roi_rect(cube, x_range = c(5, 15), y_range = c(5, 15))
#' hs_recipe(list(list(method = "snv"), list(method = "msc")))
#'
#' @name print.hsi_result
NULL

format_values <- function(x, digits = 4) {
  paste(format(signif(x, digits), trim = TRUE), collapse = ", ")
}

format_range <- function(x, digits = 4) {
  x <- x[is.finite(x)]
  if (!length(x)) return("[NA, NA]")
  paste0("[", format_values(range(x), digits), "]")
}

format_percent <- function(part, total) {
  paste0(part, "/", total, " (", round(100 * part / total, 1), "%)")
}

#' @rdname print.hsi_result
#' @export
print.summary.hsi_cube <- function(x, ...) {
  d <- x$dimensions
  cli::cli_h1("summary.hsi_cube")
  cli::cli_text("Dimensions: {d[1]} rows x {d[2]} cols x {d[3]} bands")
  wl <- round(x$wavelength_range, 1)
  cli::cli_text("Wavelengths: {wl[1]}-{wl[2]} nm")
  cli::cli_text("Valid pixels: {format_percent(x$n_valid_pixels, x$n_total_pixels)}")
  cli::cli_text("Data range: {format_range(x$data_range)}")
  cli::cli_text("Band means: {format_range(x$band_means)}")
  cli::cli_text("Band SDs: {format_range(x$band_sds)}")
  if (length(x$metadata) > 0L) {
    cli::cli_text("Metadata: {paste(names(x$metadata), collapse = ', ')}")
  }
  invisible(x)
}

.print_transform <- function(x, class_name) {
  d <- dim(x$scores)
  shown <- utils::head(x$variance_explained, 5L)
  cli::cli_h1(class_name)
  cli::cli_text("Scores: {d[1]} rows x {d[2]} cols x {d[3]} components")
  cli::cli_text("Loadings: {nrow(x$loadings)} bands x {ncol(x$loadings)} components")
  more <- if (d[3] > 5L) ", ..." else ""
  cli::cli_text("Variance explained (%): {format_values(100 * shown, 3)}{more}")
  cli::cli_text("Valid pixels: {format_percent(sum(!is.na(x$scores[, , 1L])), prod(d[1:2]))}")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_pca <- function(x, ...) {
  .print_transform(x, "hsi_pca")
  cli::cli_text("Centered: {!identical(x$center, FALSE)}; scaled: {!identical(x$scale, FALSE)}")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_mnf <- function(x, ...) {
  .print_transform(x, "hsi_mnf")
  cli::cli_text("Noise estimate: {x$noise_pairs} adjacent pixel pairs")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_umap <- function(x, ...) {
  cli::cli_h1("hsi_umap")
  cli::cli_text("Embedding: {x$dims[1]} rows x {x$dims[2]} cols x {x$n_components} components")
  cli::cli_text("Valid pixels: {format_percent(sum(!is.na(x$embedding[, 1L])), nrow(x$embedding))}")
  cli::cli_text("Seed: {x$seed}")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_unmix <- function(x, ...) {
  d <- dim(x$abundances)
  status <- table(x$status)
  cli::cli_h1("hsi_unmix")
  cli::cli_text("Abundances: {d[1]} rows x {d[2]} cols x {d[3]} endmembers")
  cli::cli_text("Endmembers: {paste(x$endmember_names, collapse = ', ')}")
  cli::cli_text("Solver: {x$backend}; sum to one: {x$sum_to_one}")
  cli::cli_text("Fit status: {paste0(names(status), ' ', status, collapse = ', ')}")
  cli::cli_text("RMSE range: {format_range(x$rmse)}")
  cli::cli_text("Residuals kept: {!is.null(x$residuals)}")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_chromophore_fit <- function(x, ...) {
  d <- dim(x$rmse)
  status <- table(x$status)
  cli::cli_h1("hsi_chromophore_fit")
  cli::cli_text("Maps: {d[1]} rows x {d[2]} cols")
  cli::cli_text("Chromophores: {paste(x$chromophores, collapse = ', ')} ({x$coefficient_units})")
  fit_range <- paste0(x$wavelength_range[1], "-", x$wavelength_range[2], " nm")
  cli::cli_text("Fit range: {fit_range} ({length(x$wavelengths)} bands, {x$response} response)")
  cli::cli_text("Input domain: {x$input_domain}; reference: {x$reference_id}")
  if (!is.null(x$sto2)) cli::cli_text("Fitted HbO2 fraction (%): {format_range(x$sto2)}")
  cli::cli_text("Fit status: {paste0(names(status), ' ', status, collapse = ', ')}")
  cli::cli_text("RMSE range: {format_range(x$rmse)}")
  cli::cli_text("{x$interpretation}")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_classification <- function(x, ...) {
  d <- dim(x$class_map)
  counts <- table(x$class_map)
  method <- if (is.null(x$model)) "spectral angle mapper" else class(x$model)[1L]
  cli::cli_h1("hsi_classification")
  cli::cli_text("Class map: {d[1]} rows x {d[2]} cols ({method})")
  cli::cli_text("Classes: {paste0(names(counts), ' ', counts, collapse = ', ')}")
  cli::cli_text("Unassigned (NA) pixels: {sum(is.na(x$class_map))}")
  if (!is.null(x$threshold)) cli::cli_text("Angle threshold: {x$threshold} rad")
  if (!is.null(x$training_pixels)) cli::cli_text("Training pixels: {x$training_pixels}")
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_roi <- function(x, ...) {
  d <- dim(x$mask)
  cli::cli_h1("hsi_roi")
  cli::cli_text("Type: {x$type}")
  selected <- format_percent(sum(x$mask), length(x$mask))
  cli::cli_text("Mask: {d[1]} rows x {d[2]} cols, {selected} pixels selected")
  if (identical(x$type, "rectangle")) {
    cli::cli_text("Columns {x$x_range[1]}-{x$x_range[2]}, rows {x$y_range[1]}-{x$y_range[2]}")
  } else if (!is.null(x$vertices)) {
    cli::cli_text("Vertices: {nrow(x$vertices)}")
  }
  invisible(x)
}

#' @rdname print.hsi_result
#' @export
print.hsi_recipe <- function(x, ...) {
  cli::cli_h1("hsi_recipe")
  cli::cli_text("Steps: {length(x$steps)}; seed: {x$seed}")
  for (i in seq_along(x$steps)) {
    step <- x$steps[[i]]
    args <- names(step$args)
    detail <- if (length(args)) paste0(" (", paste(args, collapse = ", "), ")") else ""
    cli::cli_text("{i}. {step$method}{detail}")
  }
  invisible(x)
}
