#' @importFrom rlang .data .env
#' @importFrom stats sd median
#' @importFrom grDevices as.raster
NULL

# Declare global variables used in tidy evaluation to suppress R CMD check NOTEs
utils::globalVariables(c(

  "wavelength", "value", "x", "y", "pixel_id", "name",
  "mean_value", "sd_value", "min_value", "max_value", "median_value",
  "n_pixels", "component", "loading", "variance_explained",
  "class_label", "abundance", "concentration"
))
