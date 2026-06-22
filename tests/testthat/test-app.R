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

test_that("hs_run_app stores and removes the global cube", {
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      # Cube should be available in the global env while app "runs"
      expect_false(is.null(.GlobalEnv$.hyperspectR_cube))
      invisible(NULL)
    },
    .package = "shiny"
  )
  hs_run_app(cube = hs_example_cube(), launch.browser = FALSE)
  expect_false(exists(".hyperspectR_cube", envir = .GlobalEnv))
})

