test_that("hs_run_app locates the bundled shiny app and errors cleanly", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  # Don't actually launch; mock shiny::runApp to capture the resolved dir.
  captured <- NULL
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      captured <<- appDir
      invisible(NULL)
    },
    .package = "shiny"
  )
  hs_run_app(cube = hs_example_cube(), launch.browser = FALSE)
  expect_true(nzchar(captured))
  expect_true(dir.exists(captured))
})

test_that("hs_run_app hands the cube to the app via shinyOptions", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  # The cube is passed through Shiny's own option mechanism. It must NOT be
  # written to the global environment: CRAN policy forbids that, and the app
  # reads it back with getShinyOption().
  seen <- NULL
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      seen <<- shiny::getShinyOption("hyperspectR_cube", default = NULL)
      invisible(NULL)
    },
    .package = "shiny"
  )
  hs_run_app(cube = hs_example_cube(), launch.browser = FALSE)

  expect_s3_class(seen, "hsi_cube")
  expect_false(exists(".hyperspectR_cube", envir = .GlobalEnv))
})

test_that("launcher restores previous cube and request options after return or failure", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("callr")
  original <- shiny::getShinyOption("hyperspectR_cube", default = NULL)
  withr::defer(shiny::shinyOptions(hyperspectR_cube = original))
  previous <- hs_example_cube()[1:2, 1:3, ]
  supplied <- hs_example_cube()[1:3, 1:4, ]
  shiny::shinyOptions(hyperspectR_cube = previous)
  request_size <- getOption("shiny.maxRequestSize")
  testthat::local_mocked_bindings(runApp = function(...) {
    expect_equal(shiny::getShinyOption("hyperspectR_cube"), supplied)
    invisible(NULL)
  }, .package = "shiny")
  hs_run_app(supplied, launch.browser = FALSE, max_upload_mb = 1)
  expect_equal(shiny::getShinyOption("hyperspectR_cube"), previous)
  expect_equal(getOption("shiny.maxRequestSize"), request_size)
  testthat::local_mocked_bindings(runApp = function(...) stop("launch failed"), .package = "shiny")
  expect_error(hs_run_app(supplied, launch.browser = FALSE), "launch failed")
  expect_equal(shiny::getShinyOption("hyperspectR_cube"), previous)
  expect_equal(getOption("shiny.maxRequestSize"), request_size)
  expect_error(hs_run_app(list(), launch.browser = FALSE), "hsi_cube")
  expect_equal(shiny::getShinyOption("hyperspectR_cube"), previous)
})

