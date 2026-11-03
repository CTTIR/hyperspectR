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
      shiny::helpText("PNG export uses this viewer selection. RGB requires measured wavelengths."),
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
        known <- !identical(cube$metadata$wavelengths_known, FALSE)
        positions <- if (known) wl else seq_along(wl)
        shiny::updateSliderInput(session, "band_slider",
                                 label = if (known) "Wavelength (nm)" else "Band index (wavelength unknown)",
                                 min = min(positions), max = max(positions),
                                 value = positions[ceiling(length(positions) / 2)],
                                 step = if (length(positions) > 1L) min(diff(positions)) else 1)
        if (!known) shiny::updateSelectInput(session, "display_mode", selected = "band")
      }
    })

    viewer_plot <- shiny::reactive({
      cube <- cube_rv$cube
      shiny::req(cube)
      shiny::req(input$display_mode)
      known <- !identical(cube$metadata$wavelengths_known, FALSE)

      if (input$display_mode == "band") {
        selected <- input$band_slider
        positions <- if (known) cube$wavelengths else seq_along(cube$wavelengths)
        shiny::validate(shiny::need(is.numeric(selected) && length(selected) == 1L &&
          is.finite(selected) && selected >= min(positions) && selected <= max(positions) &&
          (known || selected == floor(selected)), "Select a band within the current cube."))
        if (known) {
          hyperspectR::hs_plot_image(cube, wavelength = selected, palette = input$palette)
        } else {
          hyperspectR::hs_plot_image(cube, band = selected, palette = input$palette)
        }
      } else {
        shiny::validate(shiny::need(known, "RGB requires measured wavelengths; select a single band."))
        hyperspectR::hs_plot_rgb(cube, r = input$r_wl, g = input$g_wl,
                                 b = input$b_wl)
      }
    })
    output$image_plot <- shiny::renderPlot(viewer_plot(), alt = function() {
      cube <- cube_rv$cube
      shiny::req(cube, input$display_mode)
      description <- if (input$display_mode == "rgb") {
        "Pseudo-color RGB composite from the selected measured-wavelength channels."
      } else if (identical(cube$metadata$wavelengths_known, FALSE)) {
        "Single-band spatial image selected by band index; measured wavelengths are unknown."
      } else "Single-band spatial image selected by measured wavelength."
      paste(description, "Columns run horizontally and rows vertically. Masked and nonfinite selected pixels are excluded.")
    })

    output$cube_info <- shiny::renderText({
      cube <- cube_rv$cube
      shiny::req(cube)
      d <- dim(cube$data)
      known <- !identical(cube$metadata$wavelengths_known, FALSE)
      source <- cube$metadata$source_file
      if (is.null(source)) source <- cube$metadata$file
      if (is.null(source)) source <- "Supplied or example cube"
      domain <- cube$metadata$processing_mode
      if (is.null(domain)) domain <- "unknown"
      values <- utils::getFromNamespace(".pixel_matrix", "hyperspectR")(cube)
      values <- values[is.finite(values)]
      paste0(
        "Source: ", basename(source), "\n",
        "Dimensions: ", d[1], " x ", d[2], " x ", d[3], "\n",
        if (known) paste0("Wavelengths: ", min(cube$wavelengths), "-",
                          max(cube$wavelengths), " nm\n") else
          paste0("Band indices: 1-", d[3], " (wavelengths unknown)\n"),
        "Input values: ", domain, "\n",
        if (length(values)) paste0("Valid data range: [", round(min(values), 4), ", ",
                                  round(max(values), 4), "]") else "No finite unmasked values"
      )
    })
    viewer_plot
  })
}
