#' Wavelength-to-Color Scale for Spectral Plots
#'
#' Maps wavelength values to approximate visible light colors for spectral
#' line coloring. The default scale is fixed at 380-780 nm, so a wavelength
#' retains its colour when the plotted range changes. Values outside the
#' display limits use the scale's missing-value colour. Numeric increasing
#' `limits` supplied in `...` may restrict or extend the displayed range while
#' preserving the wavelength mapping.
#'
#' @param ... Additional arguments passed to [ggplot2::scale_color_gradientn()].
#'
#' @return A [ggplot2::Scale] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' library(ggplot2)
#' df <- data.frame(
#'   wavelength = cube$wavelengths,
#'   value = cube$data[15, 15, ]
#' )
#' ggplot(df, aes(wavelength, value, color = wavelength)) +
#'   geom_line() +
#'   scale_color_wavelength() +
#'   labs(x = "Wavelength (nm)", y = "Reflectance", color = "Wavelength (nm)")
#'
#' @export
scale_color_wavelength <- function(...) {
  wl_seq <- seq(380, 780, by = 5)
  colors <- .wavelength_to_color(wl_seq)
  args <- list(...)
  limits <- args$limits %||% c(380, 780)
  if (!is.numeric(limits) || length(limits) != 2L ||
      any(!is.finite(limits)) || limits[1L] >= limits[2L]) {
    cli::cli_abort("Wavelength colour limits must be two finite increasing wavelengths.")
  }
  args$limits <- limits
  do.call(ggplot2::scale_color_gradientn, c(list(
    colors = colors,
    values = scales::rescale(wl_seq, from = limits)
  ), args))
}

#' @rdname scale_color_wavelength
#' @export
scale_colour_wavelength <- scale_color_wavelength

#' Minimalist HSI Theme
#'
#' A clean ggplot2 theme designed for hyperspectral image display.
#' Uses minimal styling with a white background.
#'
#' @param base_size Numeric. Base font size. Default `11`.
#'
#' @return A [ggplot2::theme] object.
#'
#' @examples
#' library(ggplot2)
#' ggplot(data.frame(x = 1:10, y = 1:10), aes(x, y)) +
#'   geom_point() +
#'   theme_hsi()
#'
#' @export
theme_hsi <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 2,
                                          hjust = 0.5),
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(fill = NA, color = "grey70",
                                            linewidth = 0.5),
      legend.position = "right",
      axis.title = ggplot2::element_text(size = base_size),
      strip.text = ggplot2::element_text(face = "bold")
    )
}

# Axis labels shared by the spectral plots.
.wavelength_label <- function(cube) {
  if (identical(cube$metadata$wavelengths_known, FALSE)) "Band index" else "Wavelength (nm)"
}

.value_label <- function(cube) {
  mode <- cube$metadata$processing_mode
  if (!is.character(mode) || length(mode) != 1L || is.na(mode) || !nzchar(mode) ||
      identical(mode, "unknown")) {
    return("Spectral value")
  }
  known <- c(
    reflectance = "Reflectance", absorbance = "Absorbance", raw = "Raw signal",
    spectral_radiance = "Spectral radiance", dark_subtract = "Dark-corrected signal",
    dark_corrected = "Dark-corrected signal", snv = "SNV-scaled value",
    msc = "MSC-corrected value", derivative = "Spectral derivative",
    continuum_removed = "Continuum-removed value"
  )
  if (mode %in% names(known)) return(unname(known[mode]))
  label <- gsub("_", " ", mode, fixed = TRUE)
  paste0(toupper(substring(label, 1L, 1L)), substring(label, 2L))
}

# Colour-blind-safe colours for `n` categories: the Okabe-Ito palette shipped
# with grDevices for up to eight (yellow last, as it is the weakest on white),
# viridis beyond that.
.qualitative_colors <- function(n) {
  if (n <= 8L) {
    okabe_ito <- unname(grDevices::palette.colors(8L, palette = "Okabe-Ito"))
    okabe_ito[c(1L, 2L, 3L, 4L, 6L, 7L, 8L, 5L)][seq_len(n)]
  } else {
    viridisLite::viridis(n, end = 0.95)
  }
}
