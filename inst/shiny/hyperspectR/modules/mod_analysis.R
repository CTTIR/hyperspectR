# Module: Analysis — PCA, SAM, Beer-Lambert

mod_analysis_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Analysis Controls",
      width = 300,
      shiny::selectInput(ns("analysis_type"), "Analysis",
                         choices = c("PCA" = "pca", "MNF" = "mnf",
                                     "Beer-Lambert" = "beer_lambert")),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] %in% c('pca', 'mnf')", ns("analysis_type")),
        shiny::numericInput(ns("n_components"), "Components", value = 5, min = 1, max = 20)
      ),
      shiny::actionButton(ns("run"), "Run Analysis", class = "btn-primary")
    ),
    shiny::plotOutput(ns("result_plot"), height = "500px"),
    shiny::verbatimTextOutput(ns("result_info"))
  )
}

mod_analysis_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {
    analysis_result <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$run, {
      cube <- cube_rv$cube
      shiny::req(cube)

      result <- switch(input$analysis_type,
        pca = hyperspectR::hs_pca(cube, n_components = input$n_components),
        mnf = hyperspectR::hs_mnf(cube, n_components = input$n_components),
        beer_lambert = hyperspectR::hs_beer_lambert(cube)
      )
      analysis_result(result)
    })

    output$result_plot <- shiny::renderPlot({
      res <- analysis_result()
      shiny::req(res)

      if (inherits(res, "hsi_pca") || inherits(res, "hsi_mnf")) {
        # Plot first 3 component score maps
        d <- dim(res$scores)
        n_show <- min(d[3], 3L)
        plots <- list()
        for (i in seq_len(n_show)) {
          df <- expand.grid(x = seq_len(d[2]), y = seq_len(d[1]))
          df$value <- as.vector(res$scores[, , i])
          plots[[i]] <- ggplot2::ggplot(df, ggplot2::aes(
            x = .data$x, y = .data$y, fill = .data$value)) +
            ggplot2::geom_raster() +
            ggplot2::scale_fill_gradientn(colors = viridisLite::viridis(256)) +
            ggplot2::scale_y_reverse() +
            ggplot2::coord_equal() +
            ggplot2::labs(title = paste("Component", i),
                          fill = "") +
            hyperspectR::theme_hsi()
        }
        patchwork::wrap_plots(plots, ncol = n_show)
      } else if (inherits(res, "hsi_chromophore_fit")) {
        hyperspectR::hs_plot_index(res$sto2, title = "StO2 (Beer-Lambert)",
                                   palette = "sto2")
      }
    })

    output$result_info <- shiny::renderText({
      res <- analysis_result()
      shiny::req(res)

      if (inherits(res, "hsi_pca") || inherits(res, "hsi_mnf")) {
        ve <- round(res$variance_explained * 100, 2)
        paste0("Variance explained:\n",
               paste(paste0("  PC", seq_along(ve), ": ", ve, "%"), collapse = "\n"),
               "\n  Total: ", round(sum(ve), 2), "%")
      } else if (inherits(res, "hsi_chromophore_fit")) {
        paste0("Beer-Lambert Fitting\n",
               "StO2 range: ", round(min(res$sto2, na.rm = TRUE), 1), "-",
               round(max(res$sto2, na.rm = TRUE), 1), "%\n",
               "Mean RMSE: ", round(mean(res$rmse, na.rm = TRUE), 6))
      } else {
        ""
      }
    })
  })
}
