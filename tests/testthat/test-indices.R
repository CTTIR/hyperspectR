test_that("hs_sto2 returns correct dimensions", {
  cube <- hs_example_cube()
  sto2 <- hs_sto2(cube)
  expect_true(is.matrix(sto2))
  expect_equal(dim(sto2), dim(cube)[1:2])
  expect_true(all(sto2 >= 0 & sto2 <= 100, na.rm = TRUE))
})

test_that("hs_npi returns correct dimensions", {
  cube <- hs_example_cube()
  npi <- hs_npi(cube)
  expect_true(is.matrix(npi))
  expect_equal(dim(npi), dim(cube)[1:2])
})

test_that("hs_thi returns correct dimensions", {
  cube <- hs_example_cube()
  thi <- hs_thi(cube)
  expect_true(is.matrix(thi))
  expect_equal(dim(thi), dim(cube)[1:2])
})

test_that("hs_twi handles missing wavelengths gracefully", {
  cube <- hs_example_cube()
  twi <- suppressWarnings(hs_twi(cube))
  expect_true(is.matrix(twi))
})

test_that("hs_ndi produces values in [-1, 1]", {
  cube <- hs_example_cube()
  ndi <- hs_ndi(cube, band1 = 540, band2 = 660)
  expect_true(all(ndi >= -1 & ndi <= 1, na.rm = TRUE))
})

test_that("hs_clinical_indices returns named list", {
  cube <- hs_example_cube()
  indices <- suppressWarnings(hs_clinical_indices(cube))
  expect_type(indices, "list")
  expect_true("sto2" %in% names(indices))
  expect_true("npi" %in% names(indices))
  expect_true("thi" %in% names(indices))
})
