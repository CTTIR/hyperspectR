# Tests for hs_read_cubert. The real cuvis.r path requires the Cubert CUVIS
# SDK, so the success path is exercised via mocked cuvis.r bindings.

test_that("hs_read_cubert errors when cuvis.r is unavailable", {
  # rlang::check_installed aborts when the package can't be loaded.
  testthat::local_mocked_bindings(
    is_installed = function(...) FALSE,
    .package = "rlang"
  )
  expect_error(
    suppressMessages(hs_read_cubert("anything.cu3s", verbose = FALSE))
  )
})

test_that("hs_read_cubert errors on missing file when cuvis.r present", {
  testthat::local_mocked_bindings(
    is_installed = function(...) TRUE,
    .package = "rlang"
  )
  expect_error(
    hs_read_cubert("definitely_missing.cu3s", verbose = FALSE),
    "File not found"
  )
})

test_that("hs_read_cubert reads via mocked cuvis.r (reflectance scaling)", {
  skip_if_not_installed("cuvis.r")
  skip_if_not_installed("withr")

  dir <- withr::local_tempdir()
  fake <- file.path(dir, "session.cu3s")
  writeLines("x", fake)

  wl <- seq(500, 540, by = 10)
  raw_cube <- array(5000, dim = c(3, 4, length(wl)))  # uint16 scaled by 10000
  attr(raw_cube, "wavelengths") <- wl

  testthat::local_mocked_bindings(
    is_installed = function(...) TRUE,
    .package = "rlang"
  )
  testthat::local_mocked_bindings(
    cuvis_init = function(...) invisible(NULL),
    cuvis_shutdown = function(...) invisible(NULL),
    cuvis_session = function(...) list(1),
    cuvis_get_measurement = function(...) "mesu",
    cuvis_get_metadata = function(...) list(
      product_name = "FakeCam", serial_number = "SN1",
      integration_time = 10, name = "m1"
    ),
    cuvis_processing_context = function(...) "ctx",
    cuvis_reprocess = function(...) invisible(NULL),
    cuvis_get_cube = function(...) raw_cube,
    .package = "cuvis.r"
  )

  cube <- hs_read_cubert(fake, verbose = FALSE)
  expect_s3_class(cube, "hsi_cube")
  expect_equal(dim(cube), c(3, 4, length(wl)))
  # 5000 / 10000 = 0.5 in reflectance mode
  expect_equal(unique(as.vector(cube$data)), 0.5)
  expect_equal(cube$metadata$camera, "FakeCam")
  expect_equal(cube$metadata$processing_mode, "reflectance")
})

test_that("hs_read_cubert raw mode skips reflectance scaling and is verbose", {
  skip_if_not_installed("cuvis.r")
  skip_if_not_installed("withr")

  dir <- withr::local_tempdir()
  fake <- file.path(dir, "session.cu3s")
  writeLines("x", fake)

  wl <- seq(500, 520, by = 10)
  raw_cube <- array(5000, dim = c(2, 2, length(wl)))
  attr(raw_cube, "wavelengths") <- wl

  testthat::local_mocked_bindings(
    is_installed = function(...) TRUE,
    .package = "rlang"
  )
  testthat::local_mocked_bindings(
    cuvis_init = function(...) invisible(NULL),
    cuvis_shutdown = function(...) invisible(NULL),
    cuvis_session = function(...) list(1),
    cuvis_get_measurement = function(...) "mesu",
    cuvis_get_metadata = function(...) list(
      product_name = "FakeCam", serial_number = "SN1",
      integration_time = 10, name = "m1"
    ),
    cuvis_processing_context = function(...) "ctx",
    cuvis_reprocess = function(...) invisible(NULL),
    cuvis_get_cube = function(...) raw_cube,
    .package = "cuvis.r"
  )

  expect_message(
    cube <- hs_read_cubert(fake, mode = "raw", verbose = TRUE),
    "Reading Cubert"
  )
  expect_equal(unique(as.vector(cube$data)), 5000)
  expect_equal(cube$metadata$processing_mode, "raw")
})
