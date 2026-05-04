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
      shiny::actionButton(ns("export_csv"), "Export as CSV",
                          class = "btn-primary btn-sm")
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

    output$spectra_plot <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)

      if (input$spectra_mode == "mean") {
        hyperspectR::hs_plot_spectra(cube, pixels = "mean",
                                     show_sd = input$show_sd)
      } else if (input$spectra_mode == "random") {
        hyperspectR::hs_plot_spectra(cube, pixels = "random",
                                     n = input$n_random)
      } else {
        px <- clicked_pixels()
        if (nrow(px) > 0) {
          hyperspectR::hs_plot_spectra(cube, pixels = px)
        } else {
          hyperspectR::hs_plot_spectra(cube, pixels = "mean")
        }
      }
    })

    output$click_image <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)
      hyperspectR::hs_plot_rgb(cube)
    })

    shiny::observeEvent(input$image_click, {
      click <- input$image_click
      if (!is.null(click)) {
        new_px <- data.frame(x = round(click$x), y = round(click$y))
        clicked_pixels(rbind(clicked_pixels(), new_px))
      }
    })
  })
}
