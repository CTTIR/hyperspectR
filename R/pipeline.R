#' Define a Reproducible Processing Recipe
#'
#' Recipes contain ordered operations and their explicit parameters. A fitted
#' MSC reference is stored in the returned recipe, allowing reuse on held-out data.
#' @param steps List of steps, each with `method` and an optional `args` list.
#'   Methods: `smooth`, `snv`, `msc`, `derivative`, `absorbance`, `resample`,
#'   `continuum_removal`, `calibrate`, `dark_correct`, `white_normalize`, `fix_bad_pixels`.
#' @param seed Integer random seed recorded with the recipe.
#' @return An `hsi_recipe` object.
#' @examples
#' recipe <- hs_recipe(list(
#'   list(method = "snv"),
#'   list(method = "msc")
#' ))
#' length(recipe$steps)
#' @export
hs_recipe <- function(steps = list(), seed = 1L) {
  if (!is.list(steps)) cli::cli_abort("steps must be a list.")
  if (length(seed) != 1L || !is.finite(seed) || seed < 0 || seed > .Machine$integer.max) cli::cli_abort("seed must be a non-negative integer.")
  for (step in steps) {
    if (!is.list(step) || length(step$method) != 1L || !step$method %in% names(.recipe_methods()) ||
        (!is.null(step$args) && !is.list(step$args))) cli::cli_abort("Each recipe step needs a supported method and an args list.")
    if ("cube" %in% names(step$args)) cli::cli_abort("Recipe arguments must not replace the input cube.")
  }
  structure(list(steps = steps, seed = as.integer(seed), schema_version = 1L), class = "hsi_recipe")
}

.recipe_methods <- function() list(smooth = hs_smooth, snv = hs_snv, msc = hs_msc,
  derivative = hs_derivative, absorbance = hs_absorbance, resample = hs_resample,
  continuum_removal = hs_continuum_removal, calibrate = hs_calibrate,
  dark_correct = hs_dark_correct, white_normalize = hs_white_normalize,
  fix_bad_pixels = hs_fix_bad_pixels)

#' Execute a Processing Recipe
#' @param cube An [hsi_cube] object.
#' @param recipe A recipe from [hs_recipe()].
#' @param learn Logical. Allow fitting an unspecified MSC reference on this cube.
#'   Set FALSE for validation or prediction data.
#' @return List containing the processed `cube` and reusable fitted `recipe`.
#' @examples
#' recipe <- hs_recipe(list(list(method = "snv"), list(method = "msc")))
#' fitted <- hs_process(hs_example_cube(), recipe)
#' # Reuse the MSC reference learned above on held-out data
#' new_cube <- hs_simulate_cube(rows = 10, cols = 10, seed = 7)
#' held_out <- hs_process(new_cube, fitted$recipe, learn = FALSE)
#' dim(held_out$cube)
#' @export
hs_process <- function(cube, recipe = hs_recipe(), learn = TRUE) {
  .validate_cube(cube)
  if (!inherits(recipe, "hsi_recipe")) cli::cli_abort("recipe must be created with hs_recipe().")
  methods <- .recipe_methods()
  for (i in seq_along(recipe$steps)) {
    step <- recipe$steps[[i]]
    args <- step$args %||% list()
    if (step$method == "msc" && is.null(args$reference) && !learn) cli::cli_abort("Fit the MSC reference on training data before applying it with learn=FALSE.")
    cube <- do.call(methods[[step$method]], c(list(cube = cube), args))
    if (step$method == "msc") recipe$steps[[i]]$args$reference <- cube$metadata$msc_reference
  }
  cube$metadata$recipe <- recipe
  list(cube = cube, recipe = recipe)
}

#' Run and Resume a Manifest of Hyperspectral Recordings
#'
#' Each recording is isolated: failures are recorded without discarding successful
#' results. Resume requires matching input checksums, recipe, analysis parameters,
#' package implementation, R version and dependency versions, plus an intact
#' versioned output record. Legacy or damaged records are recomputed. The output
#' checksum detects accidental changes; it does not authenticate an untrusted
#' file. Failed recomputation leaves the previous result file unchanged. Input and output
#' paths are local; no network or hardware acquisition is performed.
#' TIVITA input identity includes the consumed metadata log and the names/paths
#' of reference images returned by the reader. Reference image bytes are not
#' read by the analysis and are not checksummed.
#' For Cubert sessions, file bytes and explicit reader arguments are tracked,
#' but external vendor SDK settings and assets are not enumerated. Use
#' `resume = FALSE` when that external configuration may have changed.
#' @param manifest Data frame with distinct `id` and `path` columns. Optional
#'   `reader_args` list-column provides per-recording reader arguments.
#' @param recipe A recipe from [hs_recipe()].
#' @param out_dir Directory for per-recording RDS files and `run-summary.csv`.
#' @param analysis One of `"summary"`, `"beer_lambert"`, or `"pca"`.
#' @param analysis_args Named list of arguments for the analysis function.
#' @param resume Logical. Reuse intact results only if their fingerprint matches.
#' @return Data frame of recording identifiers, statuses, result files and errors.
#' @examples
#' \donttest{
#' dir <- file.path(tempdir(), "hs-batch-example")
#' hdr <- hs_example_files(tempdir())
#' manifest <- data.frame(id = "example", path = hdr)
#' first <- hs_batch(manifest, out_dir = dir)
#' first$status
#' # A second run reuses the intact result
#' hs_batch(manifest, out_dir = dir)$status
#' unlink(dir, recursive = TRUE)
#' }
#' @export
hs_batch <- function(manifest, recipe = hs_recipe(), out_dir,
                     analysis = c("summary", "beer_lambert", "pca"),
                     analysis_args = list(), resume = TRUE) {
  analysis <- match.arg(analysis)
  if (!is.data.frame(manifest) || !all(c("id", "path") %in% names(manifest)) || !nrow(manifest) ||
      anyNA(manifest[c("id", "path")]) || anyDuplicated(manifest$id) ||
      any(!grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$", manifest$id))) cli::cli_abort("Manifest needs distinct safe id values and input paths.")
  if (!inherits(recipe, "hsi_recipe")) cli::cli_abort("recipe must be created with hs_recipe().")
  if (!is.list(analysis_args) || "cube" %in% names(analysis_args) || "object" %in% names(analysis_args)) cli::cli_abort("analysis_args must be a list that does not replace the cube.")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(out_dir)) cli::cli_abort("Cannot create output directory.")
  environment <- .analysis_environment()
  implementation <- .object_checksum(lapply(sort(ls(asNamespace("hyperspectR"), all.names = TRUE)), function(name) {
    value <- get(name, asNamespace("hyperspectR"))
    if (is.function(value)) list(name = name, formals = paste(deparse(formals(value)), collapse = "\n"), body = paste(deparse(body(value)), collapse = "\n")) else NULL
  }))
  records <- vector("list", nrow(manifest))
  for (i in seq_len(nrow(manifest))) {
    id <- as.character(manifest$id[i])
    result_path <- file.path(out_dir, paste0(id, ".rds"))
    status <- "complete"
    error <- NA_character_
    tryCatch({
      path <- as.character(manifest$path[i])
      reader_args <- if ("reader_args" %in% names(manifest)) manifest$reader_args[[i]] else list()
      paths <- path
      references <- character()
      if (tolower(tools::file_ext(path)) == "hdr") paths <- unlist(.resolve_envi_paths(path), use.names = FALSE)
      if (tolower(tools::file_ext(path)) %in% c("dat", "img", "raw", "bsq", "bil", "bip")) {
        header <- paste0(tools::file_path_sans_ext(path), ".hdr")
        if (file.exists(header)) {
          paths <- c(path, header)
        } else if (tolower(tools::file_ext(path)) == "dat" && .is_tivita_file(path)) {
          log_file <- sub("_SpecCube[.]dat$", "_meta.log", path)
          if (file.exists(log_file)) paths <- unique(c(paths, log_file))
          rlang::check_installed("tivis.r")
          references <- tivis.r::tivis_reference_images(path)
        }
      }
      if (any(!file.exists(paths))) stop("Input file is missing.")
      hashes <- tools::md5sum(paths)
      fingerprint <- .object_checksum(list(input = hashes, references = references, recipe = recipe,
        analysis = analysis, args = analysis_args, reader = reader_args, record = manifest[i, , drop = FALSE],
        environment = environment, implementation = implementation))
      cached <- if (resume && file.exists(result_path)) tryCatch(readRDS(result_path), error = function(e) NULL) else NULL
      if (.batch_cache_valid(cached, fingerprint, id, analysis)) {
        status <- "resumed"
      } else {
        cube <- do.call(hs_read_cube, c(list(path = path), reader_args))
        if ("domain" %in% names(manifest)) cube$metadata$processing_mode <- as.character(manifest$domain[i])
        processed <- hs_process(cube, recipe)
        fun <- switch(analysis, summary = summary.hsi_cube, beer_lambert = hs_beer_lambert, pca = hs_pca)
        result <- do.call(fun, c(list(processed$cube), analysis_args))
        output <- list(schema_version = 1L, id = id, fingerprint = fingerprint,
          input_checksums = hashes, input_references = references,
          manifest_record = manifest[i, , drop = FALSE], recipe = processed$recipe,
          analysis = analysis, analysis_args = analysis_args, result = result,
          history = processed$cube$metadata$history, environment = environment,
          implementation = implementation, completed_at = format(Sys.time(), tz = "UTC", usetz = TRUE))
        output$output_checksum <- .object_checksum(output)
        .atomic_save_rds(output, result_path)
      }
    }, error = function(e) {
      status <<- "failed"
      error <<- conditionMessage(e)
    })
    records[[i]] <- data.frame(id = id, status = status,
      result_file = if (status == "failed") NA_character_ else result_path, error = error)
    utils::write.csv(do.call(rbind, records[seq_len(i)]), file.path(out_dir, "run-summary.csv"), row.names = FALSE)
  }
  do.call(rbind, records)
}

.batch_cache_valid <- function(cached, fingerprint, id, analysis) {
  fields <- c("schema_version", "id", "fingerprint", "input_checksums", "input_references",
              "manifest_record", "recipe", "analysis", "analysis_args", "result",
              "history", "environment", "implementation", "completed_at",
              "output_checksum")
  if (!is.list(cached) || is.null(names(cached)) ||
      anyDuplicated(names(cached)) || !setequal(names(cached), fields) ||
      !identical(cached$schema_version, 1L) ||
      !identical(cached$id, id) || !identical(cached$analysis, analysis) ||
      !identical(cached$fingerprint, fingerprint) || !is.list(cached$result) ||
      !length(cached$result) || !is.character(cached$output_checksum) ||
      length(cached$output_checksum) != 1L || is.na(cached$output_checksum)) {
    return(FALSE)
  }
  payload <- cached[names(cached) != "output_checksum"]
  identical(cached$output_checksum, .object_checksum(payload))
}

.object_checksum <- function(object) {
  file <- tempfile()
  on.exit(unlink(file))
  saveRDS(object, file, version = 3, compress = FALSE)
  unname(tools::md5sum(file))
}

.atomic_save_rds <- function(object, path) {
  temporary <- tempfile(tmpdir = dirname(path))
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary)
  .publish_file_pair(temporary, path)
  invisible(path)
}

.analysis_environment <- function() {
  packages <- c("hyperspectR", "terra", "prospectr", "signal", "nnls", "ranger", "e1071", "uwot", "cuvis.r", "tivis.r")
  versions <- vapply(packages, function(package) {
    path <- find.package(package, quiet = TRUE)
    if (length(path)) as.character(utils::packageVersion(package)) else NA_character_
  }, character(1))
  list(R = R.version.string, platform = R.version$platform, packages = versions)
}
