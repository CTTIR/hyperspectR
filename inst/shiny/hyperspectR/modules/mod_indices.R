# Module: Clinical Index Maps

mod_indices_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Index Controls",
      width = 300,
      shiny::selectInput(ns("index_type"), "Index",
                         choices = c("StO2" = "sto2", "NPI" = "npi",
                                     "THI" = "thi", "TWI" = "twi",
                                     "Clinical Panel" = "panel",
                                     "Custom NDI" = "ndi")),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'ndi'", ns("index_type")),
        shiny::numericInput(ns("ndi_band1"), "Band 1 (nm)", value = 540),
        shiny::numericInput(ns("ndi_band2"), "Band 2 (nm)", value = 660)
      ),
      shiny::sliderInput(ns("display_range"), "Display Range",
                         min = 0, max = 100, value = c(0, 100)),
      shiny::actionButton(ns("compute"), "Compute", class = "btn-primary")
    ),
    shiny::plotOutput(ns("index_plot"), height = "500px")
  )
}

mod_indices_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    index_result <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$compute, {
      cube <- cube_rv$cube
      shiny::req(cube)

      result <- switch(input$index_type,
        sto2 = hyperspectR::hs_sto2(cube),
        npi = hyperspectR::hs_npi(cube),
        thi = hyperspectR::hs_thi(cube),
        twi = suppressWarnings(hyperspectR::hs_twi(cube)),
        ndi = hyperspectR::hs_ndi(cube, band1 = input$ndi_band1,
                                   band2 = input$ndi_band2),
        panel = NULL
      )
      index_result(result)
    })

    output$index_plot <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)

      if (input$index_type == "panel") {
        hyperspectR::hs_plot_clinical(cube)
      } else {
        idx <- index_result()
        shiny::req(idx)

        palette <- switch(input$index_type,
          sto2 = "sto2", npi = "perfusion",
          thi = "hemoglobin", twi = "water", "viridis"
        )
        title <- switch(input$index_type,
          sto2 = "StO2 (%)", npi = "NPI (%)",
          thi = "THI (%)", twi = "TWI (%)", ndi = "NDI"
        )

        rng <- if (input$index_type == "ndi") c(-1, 1) else input$display_range
        hyperspectR::hs_plot_index(idx, title = title, palette = palette,
                                   range = rng)
      }
    })
  })
}
