#' Read a TIVITA Suite Recording
#'
#' Reads a Diaspective Vision TIVITA `*_SpecCube.dat` recording through the
#' \pkg{tivis.r} package and returns it as an [hsi_cube].
#'
#' Unlike the Cubert reader, this needs no vendor SDK: the TIVITA container is
#' a plain binary format and \pkg{tivis.r} is pure R.
#'
#' Acquisition metadata from the Suite's `*_meta.log` is attached to the cube
#' when present, along with the paths of the parameter images the Suite
#' exported beside the recording (RGB rendering, oxygenation, NIR perfusion,
#' THI, TWI). Those are vendor outputs for comparison, not independent
#' physiological ground truth or equivalents of this package's research indices.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param bands Optional integer vector of band indices to read. `NULL`
#'   (default) reads all bands.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return An [hsi_cube] object. Values are calibrated reflectance, normally
#'   within `[0, 1]` but not clamped, since specular regions legitimately
#'   exceed it.
#'
#' @seealso [hs_read_cube()] for extension-based dispatch,
#'   [hs_read_cubert()] for Cubert session files.
#'
#' @examples
#' \donttest{
#' # Requires the tivis.r package
#' # cube <- hs_read_tivita("2019_11_25_13_29_24_SpecCube.dat")
#' }
#'
#' @export
hs_read_tivita <- function(path, bands = NULL, verbose = TRUE) {
  rlang::check_installed("tivis.r",
    reason = "to read TIVITA .dat recordings",
    action = function(pkg, ...) {
      cli::cli_inform(c(
        "i" = "Install with: {.code install.packages('remotes'); remotes::install_github('CTTIR/tivis.r')}",
        "i" = "No vendor SDK is required: {.pkg tivis.r} is pure R."
      ))
    }
  )

  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  if (verbose) cli::cli_inform("Reading TIVITA cube: {.file {basename(path)}}")

  arr <- tivis.r::tivis_read_cube(path, bands = bands)
  wl <- attr(arr, "wavelengths")
  attr(arr, "wavelengths") <- NULL

  log_file <- sub("_SpecCube[.]dat$", "_meta.log", path)
  raw_meta <- tivis.r::tivis_get_metadata(log_file)
  refs <- tivis.r::tivis_reference_images(path)

  metadata <- list(
    source = "TIVITA",
    file = path,
    timestamp = tivis.r::tivis_parse_timestamp(basename(path)),
    processing_mode = "reflectance",
    vendor_mode = raw_meta$Aufnahme$Aufnahmemodus %||% NA_character_,
    camera_id = raw_meta$Camera$CamID %||% NA_character_,
    integration_time = raw_meta$Camera$Exposure %||% NA_real_,
    software_version = raw_meta$SW$Version %||% NA_character_,
    reference_images = refs,
    tivita_meta = raw_meta
  )

  if (verbose) {
    cli::cli_inform(
      "{dim(arr)[2]} cols x {dim(arr)[1]} rows x {dim(arr)[3]} bands, \\
       {min(wl)}-{max(wl)} nm"
    )
  }

  hsi_cube(data = arr, wavelengths = wl, metadata = metadata)
}


# Does this file look like a TIVITA container? The header is three big-endian
# uint32 dimensions, and the file size must equal 12 + w*h*b*4 exactly. That
# arithmetic is specific enough to distinguish TIVITA from a headerless ENVI
# .dat without relying on the extension.
.is_tivita_file <- function(path) {
  if (!file.exists(path)) return(FALSE)
  size <- file.size(path)
  if (is.na(size) || size <= 12) return(FALSE)

  dims <- tryCatch({
    con <- file(path, "rb")
    on.exit(close(con), add = TRUE)
    readBin(con, what = "integer", n = 3L, size = 4L, endian = "big")
  }, error = function(e) NULL)

  if (is.null(dims) || length(dims) < 3L || anyNA(dims) || any(dims <= 0L)) {
    return(FALSE)
  }
  isTRUE(size == 12 + prod(as.double(dims)) * 4)
}
