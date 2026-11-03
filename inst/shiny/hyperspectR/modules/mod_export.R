# Module: Export & Reporting

mod_export_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_columns(
    col_widths = c(6, 6),
    bslib::card(
        bslib::card_header("Export Viewer Image or Cube"),
      bslib::card_body(
        shiny::selectInput(ns("export_format"), "Format",
                           choices = c("PNG (current viewer)" = "png", "ENVI (whole cube)" = "envi")),
        shiny::downloadButton(ns("download_image"), "Download",
                              class = "btn-primary")
      )
    ),
    bslib::card(
      bslib::card_header("Export Data"),
      bslib::card_body(
        shiny::selectInput(ns("data_format"), "Format",
                           choices = c("CSV (mean spectrum)" = "csv_mean",
                                       "CSV (all pixels)" = "csv_all")),
        shiny::downloadButton(ns("download_data"), "Download",
                              class = "btn-primary")
      )
    )
  )
}

mod_export_server <- function(id, cube_rv, viewer_plot) {
  shiny::moduleServer(id, function(input, output, session) {

    output$download_image <- shiny::downloadHandler(
      filename = function() {
        ext <- if (input$export_format == "png") "png" else "zip"
        paste0("hyperspectR_export_", Sys.Date(), ".", ext)
      },
      content = function(file) {
        cube <- cube_rv$cube
        shiny::req(cube)

        if (input$export_format == "png") {
          plot <- viewer_plot()
          shiny::req(plot)
          ggplot2::ggsave(file, plot = plot, device = "png", width = 7.2,
                          height = 5.4, dpi = 150, bg = "white")
        } else {
          .write_envi_archive(cube, file)
        }
      }
    )

    output$download_data <- shiny::downloadHandler(
      filename = function() {
        paste0("hyperspectR_data_", Sys.Date(), ".csv")
      },
      content = function(file) {
        cube <- cube_rv$cube
        shiny::req(cube)

        if (input$data_format == "csv_mean") {
          df <- hyperspectR::hs_roi_stats(cube, matrix(TRUE, dim(cube$data)[1], dim(cube$data)[2]))
          utils::write.csv(df, file, row.names = FALSE)
        } else {
          df <- as.data.frame(cube, long = TRUE)
          utils::write.csv(df, file, row.names = FALSE)
        }
      }
    )
  })
}
