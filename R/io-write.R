#' Write an HSI Cube to ENVI Format
#'
#' Writes an [hsi_cube] object as an ENVI header (.hdr) and binary (.dat) file pair.
#'
#' @param cube An [hsi_cube] object.
#' @param path Character. Output path without extension. Files `.hdr` and `.dat`
#'   will be created.
#' @param interleave Character. Data interleave format: `"bsq"` (default),
#'   `"bil"`, or `"bip"`.
#' @param data_type Integer. ENVI data type code. Default `4` (float32).
#'   Float32 rounds values to single precision; finite values outside its
#'   nonzero range are rejected before replacing files. Use `5` (float64)
#'   to retain the full R double range. Missing and masked values require a
#'   floating-point output type.
#' @param verbose Logical. Print progress. Default `TRUE`.
#'
#' @return Invisible character vector of written file paths.
#'
#' @examples
#' cube <- hs_example_cube()
#' dir <- tempdir()
#' paths <- hs_write_envi(cube, file.path(dir, "test_cube"), verbose = FALSE)
#' file.exists(paths)
#'
#' @export
hs_write_envi <- function(cube, path, interleave = "bsq", data_type = 4L,
                          verbose = TRUE) {
  .validate_cube(cube)
  interleave <- match.arg(interleave, c("bsq", "bil", "bip"))

  type_info <- .envi_type_info(data_type)
  output_data <- array(.pixel_matrix(cube), dim(cube$data))
  if (type_info$what == "integer") {
    limits <- switch(as.character(data_type), "1" = c(0, 255), "2" = c(-32768, 32767),
                     "3" = c(-2147483648, 2147483647), "12" = c(0, 65535))
    if (any(!is.finite(output_data)) || any(output_data != trunc(output_data)) ||
        any(output_data < limits[1] | output_data > limits[2])) {
      cli::cli_abort("Integer ENVI output requires finite whole values within the selected type range; use floating point for masks or missing data.")
    }
  }
  if (as.character(data_type) == "4") .validate_float32_range(output_data)
  hdr_path <- paste0(path, ".hdr")
  dat_path <- paste0(path, ".dat")

  d <- dim(cube$data)
  n_rows <- d[1]
  n_cols <- d[2]
  n_bands <- d[3]

  if (verbose) {
    cli::cli_inform("Writing ENVI: {.file {basename(dat_path)}}")
    cli::cli_inform("  {n_cols} cols x {n_rows} rows x {n_bands} bands ({interleave})")
  }

  # Write header
  hdr_lines <- c(
    "ENVI",
    paste0("samples = ", n_cols),
    paste0("lines = ", n_rows),
    paste0("bands = ", n_bands),
    paste0("data type = ", data_type),
    paste0("interleave = ", interleave),
    "byte order = 0",
    "header offset = 0",
    paste0("hyperspectr domain = ", cube$metadata$processing_mode %||% "unknown"),
    if (!identical(cube$metadata$wavelengths_known, FALSE)) c(
      "wavelength units = Nanometers", "wavelength = {",
      paste0("  ", paste(format(cube$wavelengths, digits = 17, trim = TRUE), collapse = ", ")),
      "}")
  )

  if (!is.null(cube$fwhm)) {
    hdr_lines <- c(hdr_lines,
      paste0("fwhm = {"),
      paste0("  ", paste(format(cube$fwhm, digits = 17, trim = TRUE), collapse = ", ")),
      "}"
    )
  }

  staged_header <- tempfile(tmpdir = dirname(hdr_path))
  staged_data <- tempfile(tmpdir = dirname(dat_path))
  on.exit(unlink(c(staged_header, staged_data)), add = TRUE)
  writeLines(hdr_lines, staged_header)

  # Write binary data
  type_info <- .envi_type_info(data_type)

  # Reorder for interleave
  flat <- switch(interleave,
    bsq = as.vector(aperm(output_data, c(2, 1, 3))),
    bil = as.vector(aperm(output_data, c(2, 3, 1))),
    bip = as.vector(aperm(output_data, c(3, 2, 1)))
  )

  con <- file(staged_data, "wb")
  on.exit(if (isOpen(con)) close(con), add = TRUE)

  if (type_info$what == "double") {
    writeBin(as.double(flat), con, size = type_info$size, endian = "little")
  } else {
    # The NA integer bit pattern is the valid ENVI int32 lower endpoint.
    # Input missingness was rejected above, so only that endpoint is encoded here.
    if (as.character(data_type) == "3") flat[flat == -2147483648] <- NA_real_
    writeBin(as.integer(flat), con, size = type_info$size, endian = "little")
  }

  close(con)
  on.exit(NULL, add = FALSE)
  on.exit(unlink(c(staged_header, staged_data)), add = TRUE)
  .publish_file_pair(c(staged_header, staged_data), c(hdr_path, dat_path))

  if (verbose) {
    cli::cli_inform("  Written: {.file {hdr_path}}, {.file {dat_path}}")
  }

  invisible(c(hdr_path, dat_path))
}

#' Write an HSI Cube to Multi-Band TIFF
#'
#' Writes an [hsi_cube] object as a multi-band GeoTIFF file. Requires the
#' `terra` package. Values are stored as float64 to preserve the R double
#' range and precision; this can use more disk space than float32 TIFF.
#' A completed temporary TIFF replaces the target only after
#' encoding succeeds; ordinary write failures leave an existing target intact.
#'
#' @param cube An [hsi_cube] object.
#' @param path Character. Output path (should end in .tif).
#' @param verbose Logical. Print progress. Default `TRUE`.
#'
#' @return Invisible path to the written file.
#'
#' @examples
#' \donttest{
#' # Requires terra package
#' # cube <- hs_example_cube()
#' # hs_write_tiff(cube, file.path(tempdir(), "test.tif"))
#' }
#'
#' @export
hs_write_tiff <- function(cube, path, verbose = TRUE) {
  .validate_cube(cube)

  if (!requireNamespace("terra", quietly = TRUE)) {
    cli::cli_abort(c(
      "!" = "Package {.pkg terra} is required to write TIFF files.",
      "i" = "Install with {.code install.packages('terra')}."
    ))
  }

  d <- dim(cube$data)
  if (verbose) cli::cli_inform("Writing TIFF: {.file {basename(path)}}")

  # Create raster from array
  r <- terra::rast(nrows = d[1], ncols = d[2], nlyrs = d[3])
  terra::values(r) <- matrix(aperm(array(.pixel_matrix(cube), d), c(2, 1, 3)), nrow = d[1] * d[2], ncol = d[3])
  names(r) <- paste0("band_", round(cube$wavelengths))

  staged <- tempfile(tmpdir = dirname(path), fileext = ".tif")
  on.exit(unlink(staged), add = TRUE)
  terra::writeRaster(r, staged, overwrite = TRUE, datatype = "FLT8S")
  .publish_file_pair(staged, path)

  if (verbose) cli::cli_inform("  Written: {.file {path}}")
  invisible(path)
}

#' Export a Single-Band Image as PNG
#'
#' Exports a single band or index map from an HSI cube as a PNG image.
#'
#' @param data Numeric matrix to export (rows x cols).
#' @param path Character. Output file path (should end in .png).
#' @param palette Character. Color palette: `"viridis"`, `"magma"`, `"inferno"`,
#'   `"plasma"`, `"grey"`. Default `"viridis"`.
#' @param range Numeric vector of length 2. Data range for color mapping.
#'   Default `NULL` (auto from finite data). Finite ordered endpoints are
#'   required; a constant range uses the first palette color. Non-finite
#'   pixels are black, including an image with no finite pixels.
#' @param width Integer. Image width in pixels. Default `NULL` (matches data cols).
#' @param height Integer. Image height in pixels. Default `NULL` (matches data rows).
#'
#' @return Invisible path to the written file.
#'
#' @examples
#' cube <- hs_example_cube()
#' mat <- cube$data[, , 30]
#' path <- file.path(tempdir(), "band30.png")
#' hs_export_png(mat, path)
#'
#' @export
hs_export_png <- function(data, path, palette = "viridis", range = NULL,
                          width = NULL, height = NULL) {
  if (!is.matrix(data) || !is.numeric(data) || is.complex(data) || any(dim(data) == 0L)) {
    cli::cli_abort("{.arg data} must be a numeric matrix.")
  }

  if (is.null(range)) {
    finite <- data[is.finite(data)]
    range <- if (length(finite)) base::range(finite) else c(0, 0)
  }
  if (!is.numeric(range) || is.complex(range) || !is.null(dim(range)) ||
      length(range) != 2L || any(!is.finite(range)) || range[1] > range[2]) {
    cli::cli_abort("Color range must contain two finite ordered numeric values.")
  }
  if (is.null(width)) width <- ncol(data)
  if (is.null(height)) height <- nrow(data)
  for (size in list(width, height)) {
    if (!is.numeric(size) || length(size) != 1L || !is.finite(size) ||
        size < 1 || size != floor(size) || size > .Machine$integer.max) {
      cli::cli_abort("PNG width and height must be positive whole pixel counts.")
    }
  }

  # Normalize data to [0, 1]
  norm_data <- .normalize_range(data, range)

  # Get color palette
  n_colors <- 256L
  pal <- switch(palette,
    viridis = viridisLite::viridis(n_colors),
    magma = viridisLite::magma(n_colors),
    inferno = viridisLite::inferno(n_colors),
    plasma = viridisLite::plasma(n_colors),
    grey = grDevices::grey.colors(n_colors),
    viridisLite::viridis(n_colors)
  )

  # Map values to colors
  idx <- pmin(pmax(round(norm_data * (n_colors - 1)) + 1L, 1L), n_colors)
  col_matrix <- matrix(pal[idx], nrow = nrow(data), ncol = ncol(data))
  col_matrix[!is.finite(data)] <- "#000000"

  # Write PNG
  staged <- tempfile(tmpdir = dirname(path), fileext = ".png")
  on.exit(unlink(staged), add = TRUE)
  grDevices::png(staged, width = width, height = height)
  device <- grDevices::dev.cur()
  on.exit(if (device %in% grDevices::dev.list()) grDevices::dev.off(device), add = TRUE, after = FALSE)
  graphics::par(mar = c(0, 0, 0, 0))
  graphics::plot.new()
  graphics::plot.window(xlim = c(0, ncol(data)), ylim = c(0, nrow(data)), xaxs = "i", yaxs = "i")
  # Convert hex colors to raster
  graphics::rasterImage(
    as.raster(col_matrix),
    xleft = 0, ybottom = 0,
    xright = ncol(data), ytop = nrow(data),
    interpolate = FALSE
  )
  grDevices::dev.off(device)
  .publish_file_pair(staged, path)

  invisible(path)
}

.validate_float32_range <- function(x) {
  magnitude <- abs(x[is.finite(x)])
  if (any(magnitude > (2 - 2^-23) * 2^127 | (magnitude > 0 & magnitude < 2^-149))) {
    cli::cli_abort("Finite values exceed the nonzero float32 range; use data_type = 5 (float64).")
  }
  invisible(x)
}

.publish_file_pair <- function(staged, targets) {
  if (any(dir.exists(targets))) cli::cli_abort("Output target must be a file, not a directory.")
  backups <- vapply(targets, function(path) tempfile(tmpdir = dirname(path)), character(1))
  existed <- file.exists(targets)
  saved <- logical(length(targets))
  published <- logical(length(targets))
  complete <- FALSE
  on.exit({
    if (!complete) {
      unlink(targets[published])
      for (i in which(saved)) file.rename(backups[i], targets[i])
    }
    unlink(backups[file.exists(targets)])
  }, add = TRUE)
  for (i in which(existed)) {
    saved[i] <- file.rename(targets[i], backups[i])
    if (!saved[i]) cli::cli_abort("Cannot stage existing output for replacement: {targets[i]}")
  }
  for (i in seq_along(staged)) {
    published[i] <- file.rename(staged[i], targets[i])
    if (!published[i]) cli::cli_abort("Cannot publish output: {targets[i]}")
  }
  complete <- TRUE
  invisible(targets)
}
