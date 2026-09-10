#' Launch Interactive Hyperspectral Image Explorer
#'
#' Opens a Shiny application for interactive exploration of hyperspectral
#' cubes. Provides band selection, spectral profiling, research index mapping,
#' cancellable background processing and analysis, and export tools across six tabs.
#'
#' @param cube An [hsi_cube] object to explore. If `NULL` (default), the app
#'   starts with the example cube.
#' @param port Integer. Port for Shiny server. Default `NULL` (auto).
#' @param launch.browser Logical. Open in browser. Default `TRUE`.
#'
#' @param max_upload_mb Positive upload limit in MiB. Default 256. Uploaded
#'   cubes and background workers must also fit available memory.
#' @return Invisible `NULL`. Launches a Shiny application.
#'
#' @examples
#' \donttest{
#' cube <- hs_example_cube()
#' if (interactive()) {
#'   hs_run_app(cube)
#' }
#' }
#'
#' @export
hs_run_app <- function(cube = NULL, port = NULL, launch.browser = TRUE, max_upload_mb = 256) {
  if (length(max_upload_mb) != 1L || !is.finite(max_upload_mb) || max_upload_mb <= 0) cli::cli_abort("max_upload_mb must be positive and finite.")
  previous_options <- options(shiny.maxRequestSize = max_upload_mb * 1024^2)
  on.exit(options(previous_options), add = TRUE)
  # The app is optional, so its dependencies live in Suggests. Check them here
  # rather than letting the app fail partway through rendering: bslib in
  # particular is used unconditionally by the UI.
  rlang::check_installed(c("shiny", "bslib", "callr"),
    reason = "to run the hyperspectR Shiny application"
  )

  app_dir <- system.file("shiny", "hyperspectR", package = "hyperspectR")
  if (app_dir == "") {
    cli::cli_abort("Could not find Shiny app directory. Try reinstalling {.pkg hyperspectR}.")
  }

  # Hand the cube to the app through Shiny's own option mechanism rather than
  # the global environment: CRAN policy forbids packages writing to .GlobalEnv.
  shiny::shinyOptions(hyperspectR_cube = cube)

  shiny::runApp(app_dir, port = port, launch.browser = launch.browser)
}
