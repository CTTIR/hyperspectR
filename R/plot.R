#' Plot an hsi_cube Object
#'
#' Creates a ggplot2 visualization of a hyperspectral cube. Supports RGB
#' composite, single-band images, and spectral profile plots.
#'
#' @param object An [hsi_cube] object.
#' @param type Character. Plot type: `"rgb"` (default), `"band"`, or `"spectra"`.
#' @param band Integer. Band index for single-band display. Used when
#'   `type = "band"`.
#' @param wavelength Numeric. Wavelength (nm) for single-band display.
#'   Alternative to `band`.
#' @param r,g,b Numeric. Wavelengths for RGB channels. Defaults: 640, 550, 460.
#' @param ... Additional arguments passed to internal plot functions.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' ggplot2::autoplot(cube, type = "rgb")
#'
#' @importFrom ggplot2 autoplot
#' @export
autoplot.hsi_cube <- function(object, type = c("rgb", "band", "spectra"),
                              band = NULL, wavelength = NULL,
                              r = NULL, g = NULL, b = NULL, ...) {
  type <- match.arg(type)

  switch(type,
    rgb = hs_plot_rgb(object, r = r %||% 640, g = g %||% 550, b = b %||% 460),
    band = {
      if (is.null(wavelength) && is.null(band)) wavelength <- 550
      hs_plot_image(object, wavelength = wavelength, band = band)
    },
    spectra = hs_plot_spectra(object, ...)
  )
}

#' Plot Spectral Profiles
#'
#' Displays spectral profiles from an HSI cube. Can show mean spectrum,
#' random pixel spectra, or spectra from specific pixel locations.
#'
#' @param cube An [hsi_cube] object.
#' @param pixels Character or data.frame. `"mean"` for spatial mean,
#'   `"random"` for random pixel sample, or a data.frame with columns
#'   `x` and `y`. Default `"mean"`.
#' @param n Integer. Number of random spectra if `pixels = "random"`. Default `100`.
#' @param show_sd Logical. Show mean +/- SD ribbon. Default `TRUE` when
#'   `pixels = "mean"`.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' hs_plot_spectra(cube)
#'
#' @export
hs_plot_spectra <- function(cube, pixels = "mean", n = 100L,
                            show_sd = TRUE) {
  .validate_cube(cube)

  d <- dim(cube$data)
  wl <- cube$wavelengths

  if (is.character(pixels) && pixels == "mean") {
    pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])
    mean_spec <- colMeans(pixel_mat, na.rm = TRUE)
    sd_spec <- apply(pixel_mat, 2L, stats::sd, na.rm = TRUE)

    df <- tibble::tibble(wavelength = wl, value = mean_spec)

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength, y = .data$value))

    if (show_sd) {
      ribbon_df <- tibble::tibble(
        wavelength = wl,
        ymin = mean_spec - sd_spec,
        ymax = mean_spec + sd_spec
      )
      p <- p + ggplot2::geom_ribbon(
        data = ribbon_df,
        ggplot2::aes(x = .data$wavelength, ymin = .data$ymin, ymax = .data$ymax),
        alpha = 0.3, fill = "#2E86AB", inherit.aes = FALSE
      )
    }

    p <- p +
      ggplot2::geom_line(color = "#2E86AB", linewidth = 0.8) +
      ggplot2::labs(x = "Wavelength (nm)", y = "Reflectance",
                    title = "Mean Spectrum") +
      theme_hsi()

  } else if (is.character(pixels) && pixels == "random") {
    n <- min(n, d[1] * d[2])
    idx <- sample(d[1] * d[2], n)
    pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

    df <- tidyr::pivot_longer(
      tibble::as_tibble(
        cbind(
          pixel_id = seq_len(n),
          as.data.frame(pixel_mat[idx, , drop = FALSE])
        ),
        .name_repair = "minimal"
      ),
      cols = -1L,
      names_to = "band",
      values_to = "value"
    )
    df$wavelength <- rep(wl, each = n)

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength, y = .data$value,
                                           group = .data$pixel_id)) +
      ggplot2::geom_line(alpha = 0.2, color = "#2E86AB") +
      ggplot2::labs(x = "Wavelength (nm)", y = "Reflectance",
                    title = paste(n, "Random Spectra")) +
      theme_hsi()

  } else {
    # Specific pixel locations
    if (is.data.frame(pixels)) {
      specs <- list()
      for (i in seq_len(nrow(pixels))) {
        specs[[i]] <- tibble::tibble(
          wavelength = wl,
          value = cube$data[pixels$y[i], pixels$x[i], ],
          pixel_id = paste0("(", pixels$x[i], ",", pixels$y[i], ")")
        )
      }
      df <- do.call(rbind, specs)

      p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$wavelength, y = .data$value,
                                             color = .data$pixel_id)) +
        ggplot2::geom_line(linewidth = 0.8) +
        ggplot2::labs(x = "Wavelength (nm)", y = "Reflectance",
                      title = "Pixel Spectra", color = "Pixel") +
        theme_hsi()
    } else {
      cli::cli_abort("{.arg pixels} must be 'mean', 'random', or a data.frame with x/y columns.")
    }
  }

  p
}

#' Plot Single-Band Spatial Image
#'
#' Displays a single spectral band as a spatial image using a pseudocolor palette.
#'
#' @param cube An [hsi_cube] object.
#' @param wavelength Numeric. Center wavelength to display (nearest band selected).
#'   Default `NULL`.
#' @param band Integer. Band index. Alternative to `wavelength`. Default `NULL`.
#' @param palette Character. Color palette name. Default `"viridis"`.
#'
#' @return A [ggplot2::ggplot] object using [ggplot2::geom_raster()].
#'
#' @examples
#' cube <- hs_example_cube()
#' hs_plot_image(cube, wavelength = 550)
#'
#' @export
hs_plot_image <- function(cube, wavelength = NULL, band = NULL,
                          palette = "viridis") {
  .validate_cube(cube)

  if (is.null(wavelength) && is.null(band)) {
    band <- ceiling(dim(cube$data)[3] / 2)
  }

  if (!is.null(wavelength)) {
    band <- .band_index(cube$wavelengths, wavelength)
    actual_wl <- round(cube$wavelengths[band])
    title <- paste0("Band at ", actual_wl, " nm")
  } else {
    actual_wl <- round(cube$wavelengths[band])
    title <- paste0("Band ", band, " (", actual_wl, " nm)")
  }

  img <- cube$data[, , band]
  d <- dim(img)

  df <- expand.grid(x = seq_len(d[2]), y = seq_len(d[1]))
  df$value <- as.vector(img)

  pal_fun <- switch(palette,
    viridis = viridisLite::viridis,
    magma = viridisLite::magma,
    inferno = viridisLite::inferno,
    plasma = viridisLite::plasma,
    viridisLite::viridis
  )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y, fill = .data$value)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_gradientn(colors = pal_fun(256)) +
    ggplot2::scale_y_reverse() +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Column", y = "Row", fill = "Value", title = title) +
    theme_hsi()
}

#' Synthesize RGB Image from Spectral Cube
#'
#' Creates a pseudo-color RGB composite by mapping three wavelength bands
#' to the red, green, and blue channels.
#'
#' @param cube An [hsi_cube] object.
#' @param r,g,b Numeric. Center wavelengths for R, G, B channels.
#'   Defaults: r=640, g=550, b=460.
#' @param stretch Character. Histogram stretch: `"linear"` (default), `"none"`.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' hs_plot_rgb(cube)
#'
#' @export
hs_plot_rgb <- function(cube, r = 640, g = 550, b = 460,
                        stretch = "linear") {
  .validate_cube(cube)

  r_idx <- .band_index(cube$wavelengths, r)
  g_idx <- .band_index(cube$wavelengths, g)
  b_idx <- .band_index(cube$wavelengths, b)

  r_band <- cube$data[, , r_idx]
  g_band <- cube$data[, , g_idx]
  b_band <- cube$data[, , b_idx]

  if (stretch == "linear") {
    r_band <- .linear_stretch(r_band)
    g_band <- .linear_stretch(g_band)
    b_band <- .linear_stretch(b_band)
  }

  d <- dim(r_band)

  # Build RGB matrix
  rgb_array <- array(0, dim = c(d[1], d[2], 3))
  rgb_array[, , 1] <- r_band
  rgb_array[, , 2] <- g_band
  rgb_array[, , 3] <- b_band

  # Convert to hex colors
  hex_matrix <- matrix(
    grDevices::rgb(as.vector(r_band), as.vector(g_band), as.vector(b_band)),
    nrow = d[1], ncol = d[2]
  )

  df <- expand.grid(x = seq_len(d[2]), y = seq_len(d[1]))
  df$color <- as.vector(hex_matrix)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_raster(fill = df$color) +
    ggplot2::scale_y_reverse() +
    ggplot2::coord_equal() +
    ggplot2::labs(
      x = "Column", y = "Row",
      title = paste0("RGB (R=", round(cube$wavelengths[r_idx]),
                     " G=", round(cube$wavelengths[g_idx]),
                     " B=", round(cube$wavelengths[b_idx]), " nm)")
    ) +
    theme_hsi()
}
