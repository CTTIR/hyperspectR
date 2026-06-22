test_that("hs_chromophore_data returns default HbO2/Hb tibble", {
  d <- hs_chromophore_data()
  expect_s3_class(d, "tbl_df")
  expect_true(all(c("wavelength", "HbO2", "Hb") %in% names(d)))
  expect_true(all(d$HbO2 > 0))
  expect_true(all(d$Hb > 0))
})

test_that("hs_chromophore_data supports all chromophores", {
  d <- hs_chromophore_data(c("HbO2", "Hb", "water", "melanin", "metHb"))
  expect_true(all(c("water", "melanin", "metHb") %in% names(d)))
  expect_true(all(d$water >= 0))
  expect_true(all(d$melanin > 0))
})

test_that("hs_chromophore_data respects wavelength range", {
  d <- hs_chromophore_data("HbO2", wavelength_range = c(450, 470))
  expect_equal(min(d$wavelength), 450)
  expect_equal(max(d$wavelength), 470)
})

test_that("hs_chromophore_data rejects unknown chromophore", {
  expect_error(hs_chromophore_data("unobtainium"))
})

test_that("oxy- and deoxy-hemoglobin spectra differ", {
  d <- hs_chromophore_data(c("HbO2", "Hb"), wavelength_range = c(600, 700))
  expect_false(isTRUE(all.equal(d$HbO2, d$Hb)))
})

test_that("chromophore spectra are regression-stable", {
  d <- hs_chromophore_data(c("HbO2", "Hb"), wavelength_range = c(500, 600))
  expect_snapshot_value(round(d$HbO2, 1), style = "json2")
})
