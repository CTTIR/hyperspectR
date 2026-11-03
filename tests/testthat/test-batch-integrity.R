test_that("batch resumes only complete intact output records", {
  dir <- withr::local_tempdir()
  cube <- hsi_cube(array(seq_len(12) / 12, c(2, 2, 3)), c(500, 600, 700))
  files <- hs_write_envi(cube, file.path(dir, "input"), verbose = FALSE)
  manifest <- data.frame(id = "example", path = files[[1]])
  output <- file.path(dir, "output")
  first <- hs_batch(manifest, out_dir = output)
  expect_equal(first$status, "complete")
  path <- first$result_file[[1]]
  original <- readRDS(path)
  expect_equal(hs_batch(manifest, out_dir = output)$status, "resumed")
  changed <- original
  changed$result <- list(n_bands = -999L, fabricated = "not an analysis")
  legacy <- original
  legacy$schema_version <- legacy$output_checksum <- NULL
  malformed <- original
  malformed <- c(malformed, list(result = original$result))
  for (record in list(changed, legacy, malformed, list(fingerprint = original$fingerprint), 42)) {
    saveRDS(record, path)
    expect_equal(hs_batch(manifest, out_dir = output)$status, "complete")
    expect_equal(readRDS(path)$result, original$result)
    expect_equal(hs_batch(manifest, out_dir = output)$status, "resumed")
  }
  writeBin(charToRaw("truncated RDS"), path)
  expect_equal(hs_batch(manifest, out_dir = output)$status, "complete")
  expect_equal(readRDS(path)$result, original$result)
})

test_that("failed recomputation preserves the previous batch output", {
  dir <- withr::local_tempdir()
  cube <- hsi_cube(array(seq_len(12), c(2, 2, 3)), c(500, 600, 700))
  files <- hs_write_envi(cube, file.path(dir, "input"), verbose = FALSE)
  manifest <- data.frame(id = "example", path = files[[1]])
  output <- file.path(dir, "output")
  first <- hs_batch(manifest, out_dir = output)
  path <- first$result_file[[1]]
  checksum <- unname(tools::md5sum(path))
  recipe <- hs_recipe(list(list(method = "smooth", args = list(window = 5))))
  failed <- hs_batch(manifest, recipe, out_dir = output)
  expect_equal(failed$status, "failed")
  expect_match(failed$error, "exceeds")
  expect_identical(unname(tools::md5sum(path)), checksum)
  expect_equal(hs_batch(manifest, out_dir = output)$status, "resumed")
})

test_that("TIVITA resume tracks consumed sidecar metadata and reference membership", {
  skip_if_not_installed("tivis.r")
  dir <- withr::local_tempdir()
  path <- file.path(dir, "2020_01_02_03_04_05_SpecCube.dat")
  file.copy(tivis.r::tivis_example_file(), path)
  log <- sub("_SpecCube[.]dat$", "_meta.log", path)
  manifest <- data.frame(id = "synthetic", path = path)
  output <- file.path(dir, "results")
  first <- hs_batch(manifest, out_dir = output)
  expect_equal(first$status, "complete")
  expect_equal(hs_batch(manifest, out_dir = output)$status, "resumed")
  for (exposure in c(10, 20)) {
    writeLines(c("[Camera]", paste("Exposure =", exposure)), log)
    run <- hs_batch(manifest, out_dir = output)
    expect_equal(run$status, "complete")
    saved <- readRDS(run$result_file)
    expect_equal(saved$result$metadata$integration_time, exposure)
    expect_true(log %in% names(saved$input_checksums))
    expect_equal(hs_batch(manifest, out_dir = output)$status, "resumed")
  }
  unlink(log)
  run <- hs_batch(manifest, out_dir = output)
  expect_equal(run$status, "complete")
  expect_true(is.na(readRDS(run$result_file)$result$metadata$integration_time))
  # Only image paths are consumed by this reader; image contents are not decoded.
  png <- file.path(dir, "2020_01_02_03_04_05_RGB.png")
  writeBin(charToRaw("reference bytes are not read"), png)
  run <- hs_batch(manifest, out_dir = output)
  expect_equal(run$status, "complete")
  references <- unname(readRDS(run$result_file)$input_references)
  expect_equal(normalizePath(references, winslash = "/", mustWork = TRUE),
               normalizePath(png, winslash = "/", mustWork = TRUE))
  writeBin(charToRaw("different bytes, same path"), png)
  expect_equal(hs_batch(manifest, out_dir = output)$status, "resumed")
  unlink(png)
  expect_equal(hs_batch(manifest, out_dir = output)$status, "complete")
})
