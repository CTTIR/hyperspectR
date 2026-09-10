# Independent forward calculation: no hs_simulate_cube() or fitting helpers.
# This is numerical/synthetic evidence, not an empirical tissue validation study.
library(hyperspectR)
output <- Sys.getenv("HYPERSPECTR_VALIDATION_OUTPUT", "validation/results")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
reference_file <- system.file("extdata", "prahl-hemoglobin-v1.csv", package = "hyperspectR")
reference <- read.csv(reference_file)
config <- expand.grid(fraction = c(.2, .35, .5, .65, .8), noise = c(0, .002),
                      fwhm = c(0, 25), offset = c(0, .02), gain = c(1, 1.03))
config$split <- ifelse(config$fraction %in% c(.35, .65), "holdout", "development")
config$seed <- 1000L + seq_len(nrow(config))
config$id <- seq_len(nrow(config))
write.csv(config, file.path(output, "sensitivity-config.csv"), row.names = FALSE)
wl <- seq(500, 600, 4)
rows <- list()
for (i in seq_len(nrow(config))) {
  case <- config[i, ]
  set.seed(case$seed)
  coefficients <- c(case$fraction, 1 - case$fraction) * 1e-5
  optical_density <- reference$HbO2 * coefficients[1] + reference$Hb * coefficients[2]
  high_resolution <- 10^(-optical_density)
  reflectance <- if (case$fwhm == 0) approx(reference$wavelength, high_resolution, xout = wl)$y else {
    sigma <- case$fwhm / (2 * sqrt(2 * log(2)))
    vapply(wl, function(center) {
      weights <- dnorm(reference$wavelength, center, sigma)
      sum(high_resolution * weights) / sum(weights)
    }, numeric(1))
  }
  measured <- matrix(rep(reflectance * case$gain + case$offset, each = 12L), 12L) +
    matrix(rnorm(12L * length(wl), sd = case$noise), 12L)
  measured <- pmax(measured, 1e-6)
  cube <- hsi_cube(array(measured, c(3L, 4L, length(wl))), wl,
    fwhm = if (case$fwhm > 0) case$fwhm else NULL,
    metadata = list(processing_mode = "reflectance"))
  for (response in if (case$fwhm > 0) c("point", "gaussian") else "point") {
    for (window in list(c(500, 600), c(520, 580))) {
      fit <- hs_beer_lambert(cube, response = response, wavelength_range = window)
      errors <- as.vector(fit$sto2) - case$fraction * 100
      valid <- is.finite(errors)
      rows[[length(rows) + 1L]] <- data.frame(id = case$id, split = case$split,
        response = response, lower_nm = window[1], upper_nm = window[2],
        bias_pp = mean(errors[valid]), rmse_pp = sqrt(mean(errors[valid]^2)),
        error_q025 = unname(quantile(errors[valid], .025)), error_q975 = unname(quantile(errors[valid], .975)),
        failed = sum(!valid), total = length(errors), condition_number = fit$condition_number)
    }
  }
}
results <- do.call(rbind, rows)
write.csv(results, file.path(output, "sensitivity-results.csv"), row.names = FALSE)
matched <- config$id[config$noise == 0 & config$fwhm == 0 & config$offset == 0 & config$gain == 1]
stopifnot(max(results$rmse_pp[results$id %in% matched]) < 1e-6)
writeLines(c("Synthetic sensitivity evaluation; no clinical accuracy claim.",
  paste("Reference MD5:", unname(tools::md5sum(reference_file))),
  paste("Cases:", nrow(config), "fit configurations:", nrow(results)),
  paste("Failed pixel fits:", sum(results$failed)),
  paste("Maximum RMSE across deliberate model mismatch cases (percentage points):", max(results$rmse_pp)),
  "Holdout fractions were prespecified; no parameters were tuned using these results.",
  "Error quantiles describe simulation replicates, not independent subject confidence intervals.",
  capture.output(sessionInfo())), file.path(output, "sensitivity.txt"))

# Summarize a prespecified subset of held-out model stress cases.
joined <- merge(results, config, by = c("id", "split"))
heldout <- joined[joined$split == "holdout" & joined$lower_nm == 500 & joined$offset == 0 & joined$gain == 1, ]
summary <- aggregate(rmse_pp ~ fwhm + noise + response, heldout, mean)
summary$case <- paste0("FWHM ", summary$fwhm, " nm; noise ", summary$noise, "; ", summary$response)
write.csv(summary, file.path(output, "sensitivity-summary.csv"), row.names = FALSE)
png(file.path(output, "sensitivity.png"), width = 1300, height = 700, res = 130)
par(mar = c(5, 17, 4, 2))
barplot(summary$rmse_pp, names.arg = summary$case, horiz = TRUE, las = 1,
        col = ifelse(summary$response == "gaussian", "#2E86AB", "#D17541"),
        xlab = "Mean held-out simulation RMSE (percentage points)",
        main = "Spectral response assumptions change the fitted fraction")
dev.off()
