#' TIVITA-Style Clinical Panel Display
#'
#' Generates a side-by-side panel display of RGB image plus clinical tissue
#' indices (StO2, NPI, THI, TWI), matching the established surgical HSI
#' visualization paradigm.
#'
#' @param cube An [hsi_cube] object with reflectance data.
#' @param indices Character vector. Which indices to display.
#'   Default `c("sto2", "npi", "thi")`. TWI is included only if wavelengths
#'   permit.
#' @param mask_background Logical. Mask non-tissue pixels. Default `TRUE`.
#' @param threshold Numeric. Masking threshold on mean reflectance. Default `0.05`.
#' @param ncol Integer. Number of panel columns. Default `NULL` (auto).
#'
#' @return A `patchwork` composite [ggplot2::ggplot] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' hs_plot_clinical(cube)
#'
#' @export
hs_plot_clinical <- function(cube, indices = c("sto2", "npi", "thi"),
                             mask_background = TRUE, threshold = 0.05,
                             ncol = NULL) {
  .validate_cube(cube)

  # Create background mask
  bg_mask <- NULL
  if (mask_background) {
    mean_ref <- rowMeans(cube$data, dims = 2L)
    bg_mask <- mean_ref > threshold
  }

  plots <- list()

  # RGB panel
  plots[[1]] <- hs_plot_rgb(cube) +
    ggplot2::ggtitle("RGB")

  # Index panels
  index_funs <- list(
    sto2 = list(fn = hs_sto2, title = "StO2 (%)", palette = "sto2"),
    npi = list(fn = hs_npi, title = "NPI (%)", palette = "perfusion"),
    thi = list(fn = hs_thi, title = "THI (%)", palette = "hemoglobin"),
    twi = list(fn = hs_twi, title = "TWI (%)", palette = "water")
  )

  for (idx_name in indices) {
    if (!idx_name %in% names(index_funs)) {
      cli::cli_warn("Unknown index: {.val {idx_name}}. Skipping.")
      next
    }
    idx_info <- index_funs[[idx_name]]
    idx_mat <- suppressWarnings(idx_info$fn(cube))

    if (all(is.na(idx_mat))) {
      cli::cli_warn("{idx_name} returned all NA values. Skipping panel.")
      next
    }

    plots[[length(plots) + 1L]] <- hs_plot_index(
      idx_mat, title = idx_info$title,
      palette = idx_info$palette, mask = bg_mask
    )
  }

  if (is.null(ncol)) ncol <- min(length(plots), 4L)

  patchwork::wrap_plots(plots, ncol = ncol) +
    patchwork::plot_annotation(
      title = "Clinical HSI Panel",
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(size = 14, face = "bold",
                                           hjust = 0.5)
      )
    )
}

#' Plot Index Map with Clinical Color Scale
#'
#' Displays a single tissue index as a pseudocolor spatial map with
#' clinically meaningful color scales.
#'
#' @param index_matrix Numeric matrix (rows x cols) from an index function.
#' @param title Character. Map title (e.g., "StO2 (%)"). Default `""`.
#' @param palette Character. `"sto2"` (blue-red diverging),
#'   `"perfusion"` (viridis), `"hemoglobin"` (magma), `"water"` (mako).
#'   Default `"sto2"`.
#' @param range Numeric vector of length 2. Display range. Default `c(0, 100)`.
#' @param mask Logical matrix. Pixels to mask (FALSE = masked). Default `NULL`.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @examples
#' cube <- hs_example_cube()
#' sto2 <- hs_sto2(cube)
#' hs_plot_index(sto2, title = "StO2 (%)", palette = "sto2")
#'
#' @export
hs_plot_index <- function(index_matrix, title = "", palette = "sto2",
                          range = c(0, 100), mask = NULL) {
  if (!is.matrix(index_matrix)) {
    cli::cli_abort("{.arg index_matrix} must be a numeric matrix.")
  }

  if (!is.null(mask)) {
    index_matrix[!mask] <- NA_real_
  }

  d <- dim(index_matrix)
  df <- expand.grid(x = seq_len(d[2]), y = seq_len(d[1]))
  df$value <- as.vector(index_matrix)

  pal_colors <- .clinical_palette(palette)

  ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$y, fill = .data$value)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_gradientn(
      colors = pal_colors,
      limits = range,
      na.value = "black",
      oob = scales::squish
    ) +
    ggplot2::scale_y_reverse() +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "Column", y = "Row", fill = "", title = title) +
    theme_hsi()
}

#' @importFrom scales squish
NULL

#' Get Clinical Color Palette
#' @noRd
.clinical_palette <- function(palette) {
  switch(palette,
    sto2 = c("#2166AC", "#4393C3", "#92C5DE", "#D1E5F0",
             "#FDDBC7", "#F4A582", "#D6604D", "#B2182B"),
    perfusion = viridisLite::viridis(256),
    hemoglobin = viridisLite::magma(256),
    water = viridisLite::mako(256),
    viridisLite::viridis(256)
  )
}
