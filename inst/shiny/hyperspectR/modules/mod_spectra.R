# Module: Spectral Profile Explorer

mod_spectra_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Spectra Controls",
      width = 300,
      shiny::selectInput(ns("spectra_mode"), "Mode",
                         choices = c("Mean Spectrum" = "mean",
                                     "Random Pixels" = "random",
                                     "Click on Image" = "click")),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'random'", ns("spectra_mode")),
        shiny::numericInput(ns("n_random"), "Number of spectra", value = 50,
                            min = 5, max = 500)
      ),
      shiny::checkboxInput(ns("show_sd"), "Show +/- SD ribbon", value = TRUE),
      shiny::hr(),
      shiny::downloadButton(ns("export_csv"), "Export as CSV",
                          class = "btn-primary btn-sm"),
      shiny::helpText("CSV contains the displayed random/clicked pixels with coordinates, or mean statistics when no pixels are selected.")
    ),
    shiny::plotOutput(ns("spectra_plot"), height = "400px"),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] == 'click'", ns("spectra_mode")),
      shiny::plotOutput(ns("click_image"), height = "300px",
                        click = ns("image_click"))
    )
  )
}

mod_spectra_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    clicked_pixels <- shiny::reactiveVal(data.frame(x = integer(), y = integer()))

    shiny::observeEvent(cube_rv$cube, {
      clicked_pixels(data.frame(x = integer(), y = integer()))
    }, priority = 100)
    selected_pixels <- shiny::reactive({
      cube <- cube_rv$cube
      shiny::req(cube, input$spectra_mode)
      if (input$spectra_mode == "random") {
        n <- input$n_random
        shiny::validate(shiny::need(is.numeric(n) && length(n) == 1L &&
          is.finite(n) && n >= 1 && n == floor(n), "Choose a positive integer number of spectra."))
        valid <- which(utils::getFromNamespace(".valid_pixels", "hyperspectR")(cube))
        shiny::validate(shiny::need(length(valid) > 0L, "No valid spectra to plot or export."))
        selected <- valid[sample.int(length(valid), min(n, length(valid)))]
        rows <- dim(cube$data)[1L]
        data.frame(x = (selected - 1L) %/% rows + 1L,
                   y = (selected - 1L) %% rows + 1L)
      } else if (input$spectra_mode == "click") {
        clicked_pixels()
      } else data.frame(x = integer(), y = integer())
    })
    spectra_data <- shiny::reactive({
      cube <- cube_rv$cube
      shiny::req(cube)
      pixels <- selected_pixels()
      if (nrow(pixels)) {
        do.call(rbind, lapply(seq_len(nrow(pixels)), function(i) {
          df <- as.data.frame(cube[pixels$y[i], pixels$x[i], ], long = TRUE)
          df$x <- pixels$x[i]
          df$y <- pixels$y[i]
          df
        }))
      } else hyperspectR::hs_roi_stats(cube, matrix(TRUE, dim(cube$data)[1], dim(cube$data)[2]))
    })
    output$export_csv <- shiny::downloadHandler(
      filename = function() "spectra.csv",
      content = function(file) {
        utils::write.csv(spectra_data(), file, row.names = FALSE)
      }
    )
    output$spectra_plot <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)

      px <- selected_pixels()
      if (!nrow(px)) {
        hyperspectR::hs_plot_spectra(cube, pixels = "mean",
                                     show_sd = input$show_sd)
      } else {
        plot <- hyperspectR::hs_plot_spectra(cube, pixels = px)
        if (input$spectra_mode == "random") plot <- plot +
          ggplot2::labs(title = paste(nrow(px), "Random Spectra"))
        plot
      }
    }, alt = function() {
      cube <- cube_rv$cube
      shiny::req(cube)
      pixels <- selected_pixels()
      description <- if (!nrow(pixels)) {
        if (isTRUE(input$show_sd)) "Spatial mean spectrum with a sample standard deviation ribbon." else "Spatial mean spectrum."
      } else if (input$spectra_mode == "random") {
        "Random complete pixel spectra; the CSV export contains the same sampled coordinates and values."
      } else "Spectra at selected image coordinates; the CSV export contains the same coordinates and values."
      paste(description, .app_spectral_axis(cube), "Vertical axis: spectral value.")
    })

    output$click_image <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)
      if (identical(cube$metadata$wavelengths_known, FALSE)) {
        hyperspectR::hs_plot_image(cube)
      } else hyperspectR::hs_plot_rgb(cube)
    }, alt = function() {
      cube <- cube_rv$cube
      shiny::req(cube)
      if (identical(cube$metadata$wavelengths_known, FALSE)) {
        "Single-band spatial image for selecting pixel coordinates; measured wavelengths are unknown. Columns run horizontally and rows vertically."
      } else "RGB spatial image for selecting pixel coordinates. Columns run horizontally and rows vertically."
    })

    shiny::observeEvent(input$image_click, {
      click <- input$image_click
      if (!is.null(click) && is.numeric(click$x) && length(click$x) == 1L &&
          is.finite(click$x) && is.numeric(click$y) && length(click$y) == 1L &&
          is.finite(click$y)) {
        new_px <- data.frame(x = round(click$x), y = round(click$y))
        cube <- cube_rv$cube
        if (new_px$x >= 1 && new_px$x <= dim(cube$data)[2] && new_px$y >= 1 && new_px$y <= dim(cube$data)[1]) clicked_pixels(unique(rbind(clicked_pixels(), new_px)))
      }
    })
  })
}
