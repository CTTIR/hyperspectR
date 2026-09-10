# hyperspectR Shiny Application
# No library() calls — use namespace qualification throughout

# Source modules
for (mod_file in list.files(
  system.file("shiny", "hyperspectR", "modules", package = "hyperspectR"),
  full.names = TRUE, pattern = "\\.R$")) {
  source(mod_file, local = TRUE)
}

ui <- bslib::page_navbar(
  title = "hyperspectR Explorer",
  id = "main_nav",
  theme = bslib::bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2E86AB",
    "navbar-bg" = "#1B4965"
  ),
  header = shiny::tags$head(
    shiny::tags$link(rel = "stylesheet", href = "custom.css")
  ),
  bslib::nav_panel("Viewer",     mod_viewer_ui("viewer")),
  bslib::nav_panel("Spectra",    mod_spectra_ui("spectra")),
  bslib::nav_panel("Indices",    mod_indices_ui("indices")),
  bslib::nav_panel("Processing", mod_processing_ui("processing")),
  bslib::nav_panel("Analysis",   mod_analysis_ui("analysis")),
  bslib::nav_panel("Export",     mod_export_ui("export"))
)

server <- function(input, output, session) {
  cube_rv <- shiny::reactiveValues(
    cube = NULL,
    original_cube = NULL
  )

  # Initialize once; subsequent processing and uploads own the session state.
  obj <- shiny::getShinyOption("hyperspectR_cube", default = NULL)
  if (is.null(obj)) obj <- hyperspectR::hs_example_cube()
  stopifnot(inherits(obj, "hsi_cube"))
  cube_rv$cube <- obj
  cube_rv$original_cube <- obj

  shiny::exportTestValues(cube_dim = dim(cube_rv$cube$data),
    cube_domain = cube_rv$cube$metadata$processing_mode,
    cube_first = cube_rv$cube$data[1, 1, ])

  mod_viewer_server("viewer", cube_rv)
  mod_spectra_server("spectra", cube_rv)
  mod_indices_server("indices", cube_rv)
  mod_processing_server("processing", cube_rv)
  mod_analysis_server("analysis", cube_rv)
  mod_export_server("export", cube_rv)
}

shiny::shinyApp(ui, server)
