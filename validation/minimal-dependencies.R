# Builds a real isolated library of hard dependencies plus testthat.
# Run against an installed development package. Optional backend tests skip.
output <- Sys.getenv("HYPERSPECTR_VALIDATION_OUTPUT", "validation/results")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
lib <- tempfile("hyperspectr-minimal-")
dir.create(lib)
ip <- installed.packages()
deps <- tools::package_dependencies(c("hyperspectR", "testthat"), db = ip,
                                    which = c("Depends", "Imports", "LinkingTo"), recursive = TRUE)
packages <- setdiff(unique(c("hyperspectR", "testthat", unlist(deps))), "R")
for (package in packages) {
  index <- which(ip[, "Package"] == package)[1]
  if (!is.na(index)) file.symlink(file.path(ip[index, "LibPath"], package), file.path(lib, package))
}
.libPaths(lib, include.site = FALSE)
stopifnot(!requireNamespace("shiny", quietly = TRUE), !requireNamespace("nnls", quietly = TRUE),
          !requireNamespace("prospectr", quietly = TRUE), !requireNamespace("signal", quietly = TRUE))
library(hyperspectR)
library(testthat)
# Package tests are sourced from the repository; fixtures are installed assets.
results <- testthat::test_dir("tests/testthat", package = "hyperspectR", reporter = "summary", stop_on_failure = TRUE)
saveRDS(results, file.path(output, "minimal-tests.rds"))
unlink(lib, recursive = TRUE)
