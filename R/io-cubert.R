#' Read a Cubert .cu3s Session File
#'
#' Reads Cubert session files using the `cuvis.r` package, an R wrapper
#' for the Cubert CUVIS C SDK
#' (see \url{https://github.com/r-heller/cuvis.r}).
#'
#' The processing context automatically loads dark/white references embedded
#' in the session file, so separate reference files are typically not needed.
#'
#' Cubert reflectance values are stored as uint16 scaled by 10000
#' (i.e. 10000 = 100% reflectance). This function automatically converts
#' to fractional reflectance (0-1) when `mode = "reflectance"`.
#'
#' @param path Path to `.cu3s` Cubert session file.
#' @param index Integer. Measurement index within session (1-based). Default `1`.
#' @param mode Character. Processing mode: `"reflectance"` (default),
#'   `"spectral_radiance"`, `"dark_subtract"`, `"raw"`.
#' @param settings_dir Character or `NULL`. Path to the CUVIS settings
#'   directory (e.g., `"C:/ProgramData/cuvis"`). If `NULL` (default), uses
#'   the `CUVIS_SETTINGS` environment variable or a temporary directory.
#' @param verbose Logical. Print progress messages. Default `TRUE`.
#'
#' @return An [hsi_cube] object. Reflectance data is in 0-1 range.
#'
#' @examples
#' \donttest{
#' # Requires cuvis.r package and Cubert CUVIS SDK
#' # cube <- hs_read_cubert("path/to/session.cu3s")
#' }
#'
#' @export
hs_read_cubert <- function(path, index = 1L,
                           mode = c("reflectance", "spectral_radiance",
                                    "dark_subtract", "raw"),
                           settings_dir = NULL,
                           verbose = TRUE) {
  rlang::check_installed("cuvis.r",
    reason = "to read Cubert .cu3s files",
    action = function(pkg, ...) {
      cli::cli_inform(c(
        "i" = "Install with: {.code install.packages('remotes'); remotes::install_github('r-heller/cuvis.r')}",
        "i" = "Also requires the Cubert CUVIS SDK: {.url https://cloud.cubert-gmbh.de/s/qpxkyWkycrmBK9m}"
      ))
    }
  )

  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  mode <- match.arg(mode)

  if (verbose) cli::cli_inform("Reading Cubert session: {.file {basename(path)}}")

  # Initialize CUVIS SDK
  cuvis.r::cuvis_init(settings_dir)
  on.exit(cuvis.r::cuvis_shutdown(), add = TRUE)

  # Open session and extract measurement
  session <- cuvis.r::cuvis_session(path)

  if (verbose) {
    cli::cli_inform("  Session contains {length(session)} measurement(s).")
  }

  mesu <- cuvis.r::cuvis_get_measurement(session, as.integer(index))
  md <- cuvis.r::cuvis_get_metadata(mesu)

  # Processing context auto-loads embedded dark/white references
  ctx <- cuvis.r::cuvis_processing_context(session, load_references = TRUE)

  # Reprocess in-place, then extract cube

  cuvis.r::cuvis_reprocess(ctx, mesu, mode = mode)
  cube_array <- cuvis.r::cuvis_get_cube(mesu)
  wavelengths <- attr(cube_array, "wavelengths")

  # Cubert reflectance is uint16 scaled by 10000 (10000 = 100%)
  if (mode == "reflectance") {
    cube_array <- cube_array / 10000
  }

  if (verbose) {
    d <- dim(cube_array)
    cli::cli_inform("  {d[2]} cols x {d[1]} rows x {d[3]} bands")
    cli::cli_inform("  Wavelength range: {round(min(wavelengths))}-{round(max(wavelengths))} nm")
    cli::cli_inform("  Processing mode: {mode}")
  }

  hsi_cube(
    data = cube_array,
    wavelengths = as.numeric(wavelengths),
    metadata = list(
      camera = md$product_name,
      serial = md$serial_number,
      source_file = normalizePath(path, mustWork = FALSE),
      processing_mode = mode,
      integration_time_ms = md$integration_time,
      measurement_name = md$name,
      measurement_index = as.integer(index)
    )
  )
}
