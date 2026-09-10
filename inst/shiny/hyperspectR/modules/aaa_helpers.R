.app_try <- function(expression) {
  tryCatch(withCallingHandlers(expression, warning = function(w) {
    shiny::showNotification(conditionMessage(w), type = "warning", duration = 8)
    invokeRestart("muffleWarning")
  }), error = function(e) {
    shiny::showNotification(conditionMessage(e), type = "error", duration = 10)
    NULL
  })
}

.read_uploaded_cube <- function(info, wavelengths = "", domain = "auto") {
  if (!is.data.frame(info) || !all(c("name", "datapath") %in% names(info)) || !nrow(info)) stop("Select a cube file or an ENVI header/binary pair.")
  names <- basename(info$name)
  if (anyDuplicated(tolower(names)) || any(names != info$name)) stop("Upload filenames must be distinct plain filenames.")
  extension <- tolower(tools::file_ext(names))
  header <- which(extension == "hdr")
  if (length(header)) {
    if (length(header) != 1L || nrow(info) != 2L) stop("Upload exactly one ENVI header and its binary companion together.")
    binary <- setdiff(seq_len(nrow(info)), header)
    if (!extension[binary] %in% c("dat", "img", "raw", "bsq", "bil", "bip", "") ||
        tolower(tools::file_path_sans_ext(names[header])) != tolower(tools::file_path_sans_ext(names[binary]))) stop("ENVI header and binary must share the same basename.")
    selected <- header
  } else {
    if (nrow(info) != 1L) stop("Select one TIFF, Cubert or TIVITA file.")
    selected <- 1L
  }
  dir <- tempfile("hyperspectr-upload-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  staged_names <- names
  if (length(header)) { staged_names[header] <- "cube.hdr"; staged_names[binary] <- "cube.dat" }
  paths <- file.path(dir, staged_names)
  if (!all(file.copy(info$datapath, paths))) stop("Unable to stage uploaded files.")
  args <- list(path = paths[selected], verbose = FALSE)
  if (extension[selected] %in% c("tif", "tiff")) {
    wl <- suppressWarnings(as.numeric(strsplit(trimws(wavelengths), "[,;[:space:]]+")[[1]]))
    if (!length(wl) || any(!is.finite(wl))) stop("Enter one wavelength in nm per TIFF band.")
    args$wavelengths <- wl
  }
  cube <- do.call(hyperspectR::hs_read_cube, args)
  if (!is.null(domain) && domain != "auto") cube$metadata$processing_mode <- match.arg(domain, c("raw", "reflectance", "absorbance"))
  cube$metadata$source_file <- names[selected]
  cube
}

.write_envi_archive <- function(cube, path) {
  dir <- tempfile("hyperspectr-export-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  files <- hyperspectR::hs_write_envi(cube, file.path(dir, "cube"), verbose = FALSE)
  provenance <- file.path(dir, "provenance.rds")
  saveRDS(list(metadata = cube$metadata, wavelengths = cube$wavelengths,
               fwhm = cube$fwhm, mask = cube$mask,
               package_version = as.character(utils::packageVersion("hyperspectR"))), provenance)
  archive <- file.path(dir, "download.zip")
  status <- utils::zip(zipfile = archive, files = c(files, provenance), flags = "-j -q")
  if (!identical(status, 0L) || !file.exists(archive) || !file.copy(archive, path, overwrite = TRUE)) stop("Unable to create the ENVI archive; verify that the zip utility is installed.")
  invisible(path)
}

# One cancellable worker per module. A replacement cancels the previous worker,
# so an obsolete result cannot overwrite a newer cube or parameter selection.
.app_job <- function(session, on_result) {
  rlang::check_installed("callr")
  state <- shiny::reactiveVal("Ready")
  worker <- NULL
  cancel <- function() {
    if (!is.null(worker)) {
      if (worker$is_alive()) worker$kill()
      worker <<- NULL
      state("Cancelled")
    }
    invisible(NULL)
  }
  start <- function(method, args) {
    cancel()
    state("Running")
    package_path <- system.file(package = "hyperspectR")
    worker <<- callr::r_bg(function(method, args, package_path) {
      if (file.exists(file.path(package_path, "R", "hsi_cube-class.R")) && requireNamespace("pkgload", quietly = TRUE)) {
        pkgload::load_all(package_path, quiet = TRUE)
      } else library(hyperspectR)
      warnings <- character()
      value <- withCallingHandlers(do.call(getExportedValue("hyperspectR", method), args), warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
      list(value = value, warnings = unique(warnings))
    }, args = list(method = method, args = args, package_path = package_path),
    libpath = .libPaths(), supervise = TRUE)
  }
  shiny::observe({
    state()
    if (!is.null(worker)) {
      if (worker$is_alive()) {
        shiny::invalidateLater(200, session)
      } else {
        current <- worker
        worker <<- NULL
        result <- tryCatch(current$get_result(), error = function(e) {
          state("Failed")
          shiny::showNotification(conditionMessage(e), type = "error", duration = 10)
          NULL
        })
        if (!is.null(result)) {
          state("Complete")
          for (warning in result$warnings) shiny::showNotification(warning, type = "warning", duration = 8)
          on_result(result$value)
        }
      }
    }
  })
  session$onSessionEnded(cancel)
  list(start = start, cancel = cancel, status = state)
}
