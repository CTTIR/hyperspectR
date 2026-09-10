# Module: Cube Viewer — file upload, band selection, RGB composite, spatial display

mod_viewer_ui <- function(id) {
  ns <- shiny::NS(id)

  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      title = "Viewer Controls",
      width = 300,
      shiny::fileInput(ns("file_upload"), "Load Cube",
                       accept = c(".hdr", ".dat", ".img", ".raw", ".bsq", ".bil", ".bip", ".tif", ".tiff", ".cu3s"), multiple = TRUE,
                       placeholder = "ENVI pair / TIFF / .cu3s / TIVITA"),
      shiny::textInput(ns("wavelengths"), "TIFF wavelengths (nm, comma separated)"),
      shiny::selectInput(ns("domain"), "Input values", choices = c("Use file metadata" = "auto", "Reflectance" = "reflectance", "Absorbance" = "absorbance", "Raw counts" = "raw")),
      shiny::actionButton(ns("load_example"), "Load Example Cube",
                          class = "btn-outline-secondary btn-sm mb-3"),
      shiny::hr(),
      shiny::selectInput(ns("display_mode"), "Display Mode",
                         choices = c("Single Band" = "band", "RGB Composite" = "rgb")),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'band'", ns("display_mode")),
        shiny::sliderInput(ns("band_slider"), "Wavelength (nm)",
                           min = 430, max = 910, value = 550, step = 8)
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] == 'rgb'", ns("display_mode")),
        shiny::numericInput(ns("r_wl"), "Red (nm)", value = 640, min = 430, max = 910),
        shiny::numericInput(ns("g_wl"), "Green (nm)", value = 550, min = 430, max = 910),
        shiny::numericInput(ns("b_wl"), "Blue (nm)", value = 460, min = 430, max = 910)
      ),
      shiny::selectInput(ns("palette"), "Palette",
                         choices = c("viridis", "magma", "inferno", "plasma")),
      shiny::hr(),
      shiny::verbatimTextOutput(ns("cube_info"))
    ),
    shiny::plotOutput(ns("image_plot"), height = "500px",
                      click = ns("plot_click"),
                      brush = shiny::brushOpts(id = ns("plot_brush")))
  )
}

mod_viewer_server <- function(id, cube_rv) {
  shiny::moduleServer(id, function(input, output, session) {

    # File upload handler
    shiny::observeEvent(input$file_upload, {
      file_info <- input$file_upload
      shiny::req(file_info)

      cube <- .app_try(.read_uploaded_cube(file_info, input$wavelengths, input$domain))

      if (!is.null(cube)) {
        cube_rv$cube <- cube
        cube_rv$original_cube <- cube
        shiny::showNotification(
          paste("Loaded:", paste(file_info$name, collapse = ", ")),
          type = "message", duration = 4
        )
      }
    })

    # Load example cube
    shiny::observeEvent(input$load_example, {
      cube_rv$cube <- hyperspectR::hs_example_cube()
      cube_rv$original_cube <- cube_rv$cube
      shiny::showNotification("Loaded example cube (30x30x61)", type = "message",
                              duration = 3)
    })

    # Update slider range when cube changes
    shiny::observe({
      cube <- cube_rv$cube
      if (!is.null(cube)) {
        wl <- cube$wavelengths
        shiny::updateSliderInput(session, "band_slider",
                                 min = round(min(wl)), max = round(max(wl)),
                                 value = round(stats::median(wl)),
                                 step = if (length(wl) > 1L) min(diff(wl)) else 1)
      }
    })

    output$image_plot <- shiny::renderPlot({
      cube <- cube_rv$cube
      shiny::req(cube)

      if (input$display_mode == "band") {
        hyperspectR::hs_plot_image(cube, wavelength = input$band_slider,
                                   palette = input$palette)
      } else {
        hyperspectR::hs_plot_rgb(cube, r = input$r_wl, g = input$g_wl,
                                 b = input$b_wl)
      }
    })

    output$cube_info <- shiny::renderText({
      cube <- cube_rv$cube
      shiny::req(cube)
      d <- dim(cube$data)
      paste0(
        "Dimensions: ", d[1], " x ", d[2], " x ", d[3], "\n",
        "Wavelengths: ", round(min(cube$wavelengths)), "-",
        round(max(cube$wavelengths)), " nm\n",
        "Data range: [", round(min(cube$data, na.rm = TRUE), 4), ", ",
        round(max(cube$data, na.rm = TRUE), 4), "]"
      )
    })
  })
}
