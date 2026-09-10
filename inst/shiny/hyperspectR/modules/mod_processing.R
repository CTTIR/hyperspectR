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
      shiny::actionButton(ns("cancel"), "Cancel"),
      shiny::textOutput(ns("job_status")),
      shiny::actionButton(ns("reset"), "Reset to Original", class = "btn-outline-secondary btn-sm")
    ),
    shiny::plotOutput(ns("before_after"), height = "500px")
  )
}

mod_processing_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    job <- .app_job(session, function(value) cube_rv$cube <- value)
    output$job_status <- shiny::renderText(job$status())
    shiny::observeEvent(input$cancel, job$cancel())
    shiny::observeEvent(list(cube_rv$cube, input$method, input$sg_window, input$sg_poly), job$cancel(), priority = 100)
    shiny::observeEvent(input$apply, {
      cube <- cube_rv$cube
      shiny::req(cube)

      method <- switch(input$method, smooth = "hs_smooth", snv = "hs_snv", msc = "hs_msc", deriv1 = "hs_derivative", deriv2 = "hs_derivative")
      args <- list(cube = cube)
      if (input$method == "smooth") { args$window <- input$sg_window; args$poly <- input$sg_poly }
      if (input$method %in% c("deriv1", "deriv2")) args$order <- if (input$method == "deriv1") 1L else 2L
      job$start(method, args)
    })

    shiny::observeEvent(input$reset, {
      job$cancel()
      cube_rv$cube <- cube_rv$original_cube
    })

    output$before_after <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)
      hyperspectR::hs_plot_spectra(cube, pixels = "mean", show_sd = TRUE)
    })
  })
}
