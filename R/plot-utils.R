#' Wavelength-to-Color Scale for Spectral Plots
#'
#' Maps wavelength values to approximate visible light colors for spectral
#' line coloring. Returns a ggplot2 continuous color scale.
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
#'   scale_color_wavelength()
#'
#' @export
scale_color_wavelength <- function(...) {
  wl_seq <- seq(380, 780, by = 5)
  colors <- .wavelength_to_color(wl_seq)

  ggplot2::scale_color_gradientn(
    colors = colors,
    values = scales::rescale(wl_seq),
    ...
  )
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
