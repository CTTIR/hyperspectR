# Invoke twice in separate R sessions. The second run must resume the same result.
library(hyperspectR)
output <- Sys.getenv("HYPERSPECTR_VALIDATION_OUTPUT", "validation/results")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
path <- file.path(output, "batch-input")
if (!file.exists(paste0(path, ".hdr"))) {
  cube <- hs_example_cube()[1:2, 1:3, ]
  hs_write_envi(cube, path, verbose = FALSE)
}
recipe <- hs_recipe(list(list(method = "smooth", args = list(window = 5))))
manifest <- data.frame(id = "fixture", path = normalizePath(paste0(path, ".hdr")))
out_dir <- file.path(output, "batch")
expected <- if (file.exists(file.path(out_dir, "fixture.rds"))) "resumed" else "complete"
result <- hs_batch(manifest, recipe, out_dir, analysis = "beer_lambert")
stopifnot(identical(result$status, expected))
cat("Fresh-session batch status:", result$status, "\n")
