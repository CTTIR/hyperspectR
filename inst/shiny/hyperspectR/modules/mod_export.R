# Module: Export & Reporting

mod_export_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_columns(
    col_widths = c(6, 6),
    bslib::card(
      bslib::card_header("Export Image"),
      bslib::card_body(
        shiny::selectInput(ns("export_format"), "Format",
                           choices = c("PNG" = "png", "ENVI" = "envi")),
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

mod_export_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {

    output$download_image <- shiny::downloadHandler(
      filename = function() {
        ext <- if (input$export_format == "png") "png" else "hdr"
        paste0("hyperspectR_export_", Sys.Date(), ".", ext)
      },
      content = function(file) {
        cube <- cube_rv$cube
        shiny::req(cube)

        if (input$export_format == "png") {
          mid_band <- ceiling(dim(cube$data)[3] / 2)
          hyperspectR::hs_export_png(cube$data[, , mid_band], file)
        } else {
          base <- tools::file_path_sans_ext(file)
          hyperspectR::hs_write_envi(cube, base, verbose = FALSE)
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
          d <- dim(cube$data)
          pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])
          df <- data.frame(
            wavelength = cube$wavelengths,
            mean = colMeans(pixel_mat, na.rm = TRUE),
            sd = apply(pixel_mat, 2, stats::sd, na.rm = TRUE)
          )
          utils::write.csv(df, file, row.names = FALSE)
        } else {
          df <- as.data.frame(cube, long = TRUE)
          utils::write.csv(df, file, row.names = FALSE)
        }
      }
    )
  })
}
