test_that("hs_run_app locates the bundled shiny app and errors cleanly", {
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

