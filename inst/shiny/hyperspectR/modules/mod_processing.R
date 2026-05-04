# Module: Preprocessing Pipeline

mod_processing_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Processing Controls",
      width = 300,
      shiny::selectInput(ns("method"), "Method",
                         choices = c("Savitzky-Golay Smoothing" = "smooth",
                                     "SNV" = "snv",
                                     "MSC" = "msc",
                                     "First Derivative" = "deriv1",
                                     "Second Derivative" = "deriv2")),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'smooth'", ns("method")),
        shiny::sliderInput(ns("sg_window"), "Window Size", min = 3, max = 21,
                           value = 5, step = 2),
        shiny::sliderInput(ns("sg_poly"), "Polynomial Order", min = 1, max = 5,
                           value = 2, step = 1)
      ),
      shiny::actionButton(ns("apply"), "Apply", class = "btn-primary"),
      shiny::actionButton(ns("reset"), "Reset to Original", class = "btn-outline-secondary btn-sm")
    ),
    shiny::plotOutput(ns("before_after"), height = "500px")
  )
}

mod_processing_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observeEvent(input$apply, {
      cube <- cube_rv$cube
      shiny::req(cube)

      processed <- switch(input$method,
        smooth = hyperspectR::hs_smooth(cube, window = input$sg_window,
                                         poly = input$sg_poly),
        snv = hyperspectR::hs_snv(cube),
        msc = hyperspectR::hs_msc(cube),
        deriv1 = hyperspectR::hs_derivative(cube, order = 1L),
        deriv2 = hyperspectR::hs_derivative(cube, order = 2L)
      )
      cube_rv$cube <- processed
    })

    shiny::observeEvent(input$reset, {
      cube_rv$cube <- cube_rv$original_cube
    })

    output$before_after <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)
      hyperspectR::hs_plot_spectra(cube, pixels = "mean", show_sd = TRUE)
    })
  })
}
