.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "hyperspectR v", utils::packageVersion("hyperspectR"),
    " - Hyperspectral Imaging Analysis for Biomedical Applications"
  )
}
