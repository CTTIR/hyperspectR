# Use /usr/bin/time -v around this script for process peak resident memory.
library(hyperspectR)
output <- Sys.getenv("HYPERSPECTR_VALIDATION_OUTPUT", "validation/results")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
results <- list()
for (side in c(16L, 32L, 64L)) {
  cube <- hs_simulate_cube(rows = side, cols = side, wavelengths = seq(500, 600, 4), seed = 44)
  endmembers <- cbind(cube$data[1, 1, ], cube$data[side, side, ])
  for (chunk in c(256L, 10000L)) {
    elapsed <- system.time(fit <- hs_unmix_nnls(cube, endmembers, keep_residuals = FALSE, chunk_size = chunk))
    if (chunk == 256L) reference <- fit else stopifnot(isTRUE(all.equal(reference$abundances, fit$abundances)), isTRUE(all.equal(reference$rmse, fit$rmse)))
    results[[length(results) + 1L]] <- data.frame(rows = side, cols = side, bands = length(cube$wavelengths),
      chunk_size = chunk, residuals = FALSE, elapsed_seconds = unname(elapsed["elapsed"]),
      cube_bytes = as.numeric(object.size(cube)), result_bytes = as.numeric(object.size(fit)))
  }
}
write.csv(do.call(rbind, results), file.path(output, "performance.csv"), row.names = FALSE)
writeLines(c(capture.output(Sys.info()), capture.output(sessionInfo())), file.path(output, "performance-environment.txt"))
