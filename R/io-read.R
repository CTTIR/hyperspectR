#' Read an ENVI Hyperspectral Image File
#'
#' Reads ENVI format hyperspectral data consisting of a `.hdr` header file
#' and a binary data file. Supports BSQ, BIL, and BIP interleave formats.
#'
#' @param path Path to the ENVI header file (.hdr) or binary file.
#' @param backend Character. `"auto"` (default) uses terra if available,
#'   otherwise falls back to built-in reader. `"builtin"` forces pure-R reader.
#'   `"terra"` forces terra (errors if not installed).
#' @param bands Integer vector of band indices to read. Default `NULL` = all.
#' @param extent Numeric vector `c(row_start, row_end, col_start, col_end)` for
#'   spatial subset. Default `NULL` = full image.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return An [hsi_cube] object.
#'
#' @examples
#' hdr_path <- hs_example_files()
#' cube <- hs_read_envi(hdr_path, verbose = FALSE)
#' dim(cube)
#'
#' @export
hs_read_envi <- function(path, backend = "auto", bands = NULL,
                         extent = NULL, verbose = TRUE) {
  backend <- match.arg(backend, c("auto", "builtin", "terra"))

  # Resolve header and data file paths
  paths <- .resolve_envi_paths(path)
  hdr_path <- paths$hdr
  dat_path <- paths$dat

  if (!file.exists(hdr_path)) {
    cli::cli_abort("Header file not found: {.file {hdr_path}}")
  }
  if (!file.exists(dat_path)) {
    cli::cli_abort("Data file not found: {.file {dat_path}}")
  }

  # Parse header
  header <- .parse_envi_header(hdr_path)

  if (verbose) {
    cli::cli_inform("Reading ENVI file: {.file {basename(dat_path)}}")
    cli::cli_inform("  {header$samples} cols x {header$lines} rows x {header$bands} bands ({header$interleave})")
  }

  # Use terra backend only if explicitly requested
  if (backend == "terra") {
    if (!requireNamespace("terra", quietly = TRUE)) {
      cli::cli_abort("Package {.pkg terra} is required for backend='terra'. Install with {.code install.packages('terra')}.")
    }
    cube_data <- tryCatch(
      .read_envi_terra(dat_path, header, bands, extent),
      error = function(e) {
        cli::cli_warn("terra backend failed, falling back to builtin reader.")
        .read_envi_builtin(dat_path, header, bands, extent)
      }
    )
  } else {
    cube_data <- .read_envi_builtin(dat_path, header, bands, extent)
  }

  # Extract wavelengths
  wavelengths <- header$wavelength
  if (!is.null(bands)) {
    wavelengths <- wavelengths[bands]
  }

  fwhm <- header$fwhm
  if (!is.null(fwhm) && !is.null(bands)) {
    fwhm <- fwhm[bands]
  }

  # Build metadata
  metadata <- list(
    source_file = normalizePath(hdr_path, mustWork = FALSE),
    interleave = header$interleave,
    data_type = header$data_type
  )
  if (!is.null(header$description)) metadata$description <- header$description
  if (!is.null(header$sensor_type)) metadata$sensor_type <- header$sensor_type

  if (verbose) {
    cli::cli_inform("  Wavelength range: {round(min(wavelengths))}-{round(max(wavelengths))} nm")
  }

  hsi_cube(
    data = cube_data,
    wavelengths = wavelengths,
    fwhm = fwhm,
    metadata = metadata
  )
}

#' Read a Multi-Channel TIFF File
#'
#' Reads a multi-band TIFF file as a hyperspectral cube. Requires the `terra`
#' package for TIFF reading.
#'
#' @param path Path to multi-channel TIFF file.
#' @param wavelengths Numeric vector of wavelengths (required for TIFF files
#'   as they lack spectral metadata).
#' @param fwhm Numeric vector of FWHM values. Default `NULL`.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return An [hsi_cube] object.
#'
#' @examples
#' \donttest{
#' # Requires terra package
#' # cube <- hs_read_tiff("path/to/image.tif", wavelengths = seq(430, 910, by = 8))
#' }
#'
#' @export
hs_read_tiff <- function(path, wavelengths, fwhm = NULL, verbose = TRUE) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    cli::cli_abort(c(
      "!" = "Package {.pkg terra} is required to read TIFF files.",
      "i" = "Install with {.code install.packages('terra')}."
    ))
  }

  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  if (verbose) cli::cli_inform("Reading TIFF: {.file {basename(path)}}")

  r <- terra::rast(path)
  n_layers <- terra::nlyr(r)

  if (length(wavelengths) != n_layers) {
    cli::cli_abort(
      "Length of {.arg wavelengths} ({length(wavelengths)}) must match number of TIFF bands ({n_layers})."
    )
  }

  vals <- terra::values(r)
  rows <- terra::nrow(r)
  cols <- terra::ncol(r)
  data <- array(vals, dim = c(rows, cols, n_layers))

  if (verbose) {
    cli::cli_inform("  {cols} cols x {rows} rows x {n_layers} bands")
  }

  hsi_cube(
    data = data,
    wavelengths = wavelengths,
    fwhm = fwhm,
    metadata = list(source_file = normalizePath(path, mustWork = FALSE))
  )
}

#' Read a Hyperspectral Data Cube from Any Supported Format
#'
#' Auto-detects format from file extension and dispatches to the appropriate
#' reader. Supported formats: ENVI (.hdr), TIFF (.tif/.tiff), Cubert (.cu3s).
#'
#' @param path Path to the hyperspectral data file.
#' @param ... Additional arguments passed to the format-specific reader.
#'
#' @return An [hsi_cube] object.
#'
#' @examples
#' hdr_path <- hs_example_files()
#' cube <- hs_read_cube(hdr_path, verbose = FALSE)
#' dim(cube)
#'
#' @export
hs_read_cube <- function(path, ...) {
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  ext <- tolower(tools::file_ext(path))

  switch(ext,
    hdr = hs_read_envi(path, ...),
    dat = , img = , raw = , bsq = , bil = , bip = hs_read_envi(path, ...),
    tif = , tiff = hs_read_tiff(path, ...),
    cu3s = hs_read_cubert(path, ...),
    cli::cli_abort(c(
      "!" = "Unsupported file extension: {.val {ext}}",
      "i" = "Supported formats: ENVI (.hdr), TIFF (.tif/.tiff), Cubert (.cu3s)"
    ))
  )
}


# ---- Internal ENVI parsing functions ----

#' Resolve ENVI Header and Data File Paths
#' @noRd
.resolve_envi_paths <- function(path) {
  ext <- tolower(tools::file_ext(path))
  base <- tools::file_path_sans_ext(path)

  if (ext == "hdr") {
    hdr <- path
    # Try common data file extensions
    dat_exts <- c("dat", "img", "raw", "bsq", "bil", "bip", "")
    dat <- NULL
    for (e in dat_exts) {
      candidate <- if (e == "") base else paste0(base, ".", e)
      if (file.exists(candidate) && candidate != hdr) {
        dat <- candidate
        break
      }
    }
    if (is.null(dat)) {
      cli::cli_abort("Cannot find data file for header: {.file {path}}")
    }
  } else {
    dat <- path
    hdr <- paste0(base, ".hdr")
  }

  list(hdr = hdr, dat = dat)
}

#' Parse ENVI Header File
#' @noRd
.parse_envi_header <- function(path) {
  lines <- readLines(path, warn = FALSE)

  # Remove "ENVI" header line if present
  if (length(lines) > 0L && grepl("^ENVI", lines[1])) {
    lines <- lines[-1L]
  }

  # Join continuation lines (lines starting with whitespace or within {})
  joined <- character()
  current <- ""
  in_braces <- FALSE

  for (line in lines) {
    line <- trimws(line, which = "right")
    if (nchar(line) == 0L) next

    if (in_braces) {
      current <- paste0(current, " ", trimws(line))
      if (grepl("\\}", line)) {
        in_braces <- FALSE
        joined <- c(joined, current)
        current <- ""
      }
    } else if (grepl("\\{", line) && !grepl("\\}", line)) {
      in_braces <- TRUE
      current <- line
    } else {
      joined <- c(joined, line)
    }
  }

  # Parse key = value pairs
  header <- list()
  for (line in joined) {
    if (!grepl("=", line)) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    key <- trimws(tolower(parts[1]))
    val <- trimws(paste(parts[-1], collapse = "="))
    header[[key]] <- val
  }

  # Extract required fields
  result <- list()
  result$samples <- as.integer(header[["samples"]])
  result$lines <- as.integer(header[["lines"]])
  result$bands <- as.integer(header[["bands"]])
  result$data_type <- as.integer(header[["data type"]] %||% "4")
  result$interleave <- tolower(header[["interleave"]] %||% "bsq")
  result$byte_order <- as.integer(header[["byte order"]] %||% "0")
  result$header_offset <- as.integer(header[["header offset"]] %||% "0")

  # Parse wavelengths
  wl_str <- header[["wavelength"]]
  if (!is.null(wl_str)) {
    wl_str <- gsub("[{}]", "", wl_str)
    result$wavelength <- as.numeric(strsplit(trimws(wl_str), "[,\\s]+")[[1]])
    # Convert micrometers to nm if needed
    wl_units <- tolower(header[["wavelength units"]] %||% "nanometers")
    if (grepl("micro", wl_units)) {
      result$wavelength <- result$wavelength * 1000
    }
  } else {
    result$wavelength <- seq_len(result$bands)
  }

  # Parse FWHM
  fwhm_str <- header[["fwhm"]]
  if (!is.null(fwhm_str)) {
    fwhm_str <- gsub("[{}]", "", fwhm_str)
    result$fwhm <- as.numeric(strsplit(trimws(fwhm_str), "[,\\s]+")[[1]])
  }

  # Optional fields
  result$description <- header[["description"]]
  result$sensor_type <- header[["sensor type"]]

  result
}

#' ENVI Data Type to R Type Mapping
#' @noRd
.envi_type_info <- function(data_type) {
  switch(as.character(data_type),
    "1"  = list(what = "integer", size = 1L, signed = FALSE),  # uint8
    "2"  = list(what = "integer", size = 2L, signed = TRUE),   # int16
    "3"  = list(what = "integer", size = 4L, signed = TRUE),   # int32
    "4"  = list(what = "double",  size = 4L, signed = TRUE),   # float32
    "5"  = list(what = "double",  size = 8L, signed = TRUE),   # float64
    "12" = list(what = "integer", size = 2L, signed = FALSE),  # uint16
    "13" = list(what = "integer", size = 4L, signed = FALSE),  # uint32
    "14" = list(what = "integer", size = 8L, signed = TRUE),   # int64
    "15" = list(what = "integer", size = 8L, signed = FALSE),  # uint64
    cli::cli_abort("Unsupported ENVI data type: {data_type}")
  )
}

#' Read ENVI Binary (Pure R Implementation)
#' @noRd
.read_envi_builtin <- function(dat_path, header, bands, extent) {
  type_info <- .envi_type_info(header$data_type)
  endian <- if (header$byte_order == 0L) "little" else "big"

  n_rows <- header$lines
  n_cols <- header$samples
  n_bands <- header$bands
  n_total <- n_rows * n_cols * n_bands

  con <- file(dat_path, "rb")
  on.exit(close(con), add = TRUE)

  # Skip header offset
  if (header$header_offset > 0L) {
    readBin(con, "raw", n = header$header_offset)
  }

  # Read all data
  if (type_info$what == "double") {
    raw_data <- readBin(con, what = "double", n = n_total,
                        size = type_info$size, endian = endian)
  } else {
    raw_data <- readBin(con, what = "integer", n = n_total,
                        size = type_info$size, signed = type_info$signed,
                        endian = endian)
    raw_data <- as.numeric(raw_data)
  }

  # Reshape based on interleave
  data <- switch(header$interleave,
    bsq = {
      # Band Sequential: [bands][rows][cols]
      arr <- array(raw_data, dim = c(n_cols, n_rows, n_bands))
      aperm(arr, c(2, 1, 3))
    },
    bil = {
      # Band Interleaved by Line: [rows][bands][cols]
      arr <- array(raw_data, dim = c(n_cols, n_bands, n_rows))
      aperm(arr, c(3, 1, 2))
    },
    bip = {
      # Band Interleaved by Pixel: [rows][cols][bands]
      arr <- array(raw_data, dim = c(n_bands, n_cols, n_rows))
      aperm(arr, c(3, 2, 1))
    },
    cli::cli_abort("Unsupported interleave: {header$interleave}")
  )

  # Apply spatial subset
  if (!is.null(extent)) {
    data <- data[extent[1]:extent[2], extent[3]:extent[4], , drop = FALSE]
  }

  # Apply band subset
  if (!is.null(bands)) {
    data <- data[, , bands, drop = FALSE]
  }

  data
}

#' Read ENVI via terra Backend
#' @noRd
.read_envi_terra <- function(dat_path, header, bands, extent) {
  r <- terra::rast(dat_path)
  vals <- terra::values(r)
  n_rows <- terra::nrow(r)
  n_cols <- terra::ncol(r)
  n_bands <- terra::nlyr(r)

  data <- array(vals, dim = c(n_rows, n_cols, n_bands))

  if (!is.null(extent)) {
    data <- data[extent[1]:extent[2], extent[3]:extent[4], , drop = FALSE]
  }
  if (!is.null(bands)) {
    data <- data[, , bands, drop = FALSE]
  }

  data
}
