test_that("resampling preserves QC on its source grid without duplication", {
  wavelengths <- seq(500, 540, 10)
  cube <- hsi_cube(array(seq_len(30) / 30, c(2, 3, 5)), wavelengths,
                   mask = matrix(c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE), 2, 3))
  cube <- hs_calibrate(cube, array(0, c(2, 3, 5)), array(.8, c(2, 3, 5)))
  cube <- hs_absorbance(cube)
  fields <- c("calibration_invalid", "calibration_clipped",
              "calibration_saturated", "absorbance_clipped")
  original_flags <- cube$metadata[fields]
  result <- hs_resample(cube, c(505, 515, 525, 535))
  expect_false(any(fields %in% names(result$metadata)))
  expect_length(result$metadata$source_spectral_qc, 1)
  record <- result$metadata$source_spectral_qc[[1]]
  expect_equal(record$wavelengths, wavelengths)
  expect_identical(record$flags, original_flags)
  expect_identical(result$mask, cube$mask)
  expect_true(all(is.na(result$data[2, 1, ])))
  second <- hs_resample(result, c(510, 520, 530))
  expect_identical(second$metadata$source_spectral_qc, result$metadata$source_spectral_qc)
  expect_warning(subset <- second[2:1, c(3, 1), c(3, 1)], "sorting")
  archived <- subset$metadata$source_spectral_qc[[1]]
  expect_identical(archived$wavelengths, wavelengths)
  for (field in fields) {
    expect_identical(archived$flags[[field]], original_flags[[field]][2:1, c(3, 1), , drop = FALSE])
  }
  file <- tempfile(fileext = ".rds")
  withr::defer(unlink(file))
  saveRDS(subset, file)
  restored <- readRDS(file)
  expect_identical(restored, subset)
  expect_s3_class(hs_resample(restored, 520), "hsi_cube")
  expect_identical(cube$metadata[fields], original_flags)
})

test_that("new flags produce a separate source-grid QC record", {
  cube <- hsi_cube(array(.5, c(2, 1, 5)), seq(500, 540, 10))
  cube$metadata$calibration_clipped <- array(FALSE, c(2, 1, 5))
  first <- hs_resample(cube, c(505, 515, 525, 535))
  first$metadata$absorbance_clipped <- array(c(TRUE, rep(FALSE, 7)), c(2, 1, 4))
  second <- hs_resample(first, c(510, 520, 530))
  records <- second$metadata$source_spectral_qc
  expect_length(records, 2)
  expect_identical(records[[1]], first$metadata$source_spectral_qc[[1]])
  expect_identical(records[[2]]$wavelengths, first$wavelengths)
  expect_identical(records[[2]]$flags$absorbance_clipped, first$metadata$absorbance_clipped)
  expect_null(second$metadata$absorbance_clipped)
  cube$metadata$calibration_clipped <- array(FALSE, c(2, 1, 4))
  expect_error(hs_resample(cube, c(510, 520)), "QC flags must match")
})
