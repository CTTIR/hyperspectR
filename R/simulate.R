#' Generate a Synthetic HSI Cube for Testing and Examples
#'
#' Creates a realistic synthetic tissue hyperspectral cube with known ground
#' truth. Simulates a tissue scene with regions of varying oxygenation,
#' hemoglobin concentration, and a background (non-tissue) region.
#'
#' @param rows Integer. Spatial rows. Default `50`.
#' @param cols Integer. Spatial columns. Default `50`.
#' @param wavelengths Numeric vector. Wavelength grid in nm.
#'   Default: `seq(430, 910, by = 8)` matching Cubert Ultris X MR.
#' @param n_regions Integer. Number of distinct tissue regions. Default `4`.
#' @param sto2_range Numeric vector of length 2. Range of StO2 values (0 to 1).
#'   Default `c(0.3, 0.95)`.
#' @param noise_sd Numeric. Gaussian noise standard deviation. Default `0.01`.
#' @param seed Integer. Random seed for reproducibility. Default `42`.
#'
#' @return An [hsi_cube] object with metadata including ground-truth `region_map`.
#'
#' @examples
#' cube <- hs_simulate_cube(rows = 20, cols = 20)
#' dim(cube)
#'
#' @export
hs_simulate_cube <- function(rows = 50L, cols = 50L,
                             wavelengths = seq(430, 910, by = 8),
                             n_regions = 4L, sto2_range = c(0.3, 0.95),
                             noise_sd = 0.01, seed = 42L) {
  rows <- as.integer(rows)
  cols <- as.integer(cols)
  n_regions <- as.integer(n_regions)
  n_bands <- length(wavelengths)

  set.seed(seed)

  # Get chromophore spectra at the target wavelengths
  hbo2 <- .hbo2_spectrum(wavelengths)
  hb <- .hb_spectrum(wavelengths)

  # Normalize to [0, 1] range for reflectance simulation
  hbo2_norm <- hbo2 / max(hbo2)
  hb_norm <- hb / max(hb)

  # Create region map (spatial partitioning)
  region_map <- matrix(0L, nrow = rows, ncol = cols)
  sto2_values <- seq(sto2_range[1], sto2_range[2], length.out = n_regions)

  # Divide spatially into quadrant-like regions
  row_breaks <- round(seq(1, rows + 1, length.out = ceiling(sqrt(n_regions)) + 1))
  col_breaks <- round(seq(1, cols + 1, length.out = ceiling(n_regions / ceiling(sqrt(n_regions))) + 1))

  region_id <- 1L
  for (ri in seq_len(length(row_breaks) - 1L)) {
    for (ci in seq_len(length(col_breaks) - 1L)) {
      if (region_id > n_regions) break
      r_idx <- row_breaks[ri]:(row_breaks[ri + 1L] - 1L)
      c_idx <- col_breaks[ci]:(col_breaks[ci + 1L] - 1L)
      r_idx <- r_idx[r_idx <= rows]
      c_idx <- c_idx[c_idx <= cols]
      if (length(r_idx) > 0L && length(c_idx) > 0L) {
        region_map[r_idx, c_idx] <- region_id
        region_id <- region_id + 1L
      }
    }
  }
  # Fill any remaining zeros
  region_map[region_map == 0L] <- n_regions

  # Build reflectance cube
  data <- array(0, dim = c(rows, cols, n_bands))

  for (reg in seq_len(n_regions)) {
    pixels <- which(region_map == reg, arr.ind = TRUE)
    if (nrow(pixels) == 0L) next

    sto2 <- sto2_values[reg]

    # Simulate reflectance from Beer-Lambert model (simplified)
    # Higher absorption = lower reflectance
    absorption <- sto2 * hbo2_norm + (1 - sto2) * hb_norm
    # Convert absorption to reflectance-like values
    # Add scattering baseline that increases with wavelength
    scattering <- 0.3 + 0.2 * (wavelengths - min(wavelengths)) /
      (max(wavelengths) - min(wavelengths))
    reflectance <- scattering * exp(-2.5 * absorption)

    # Scale to reasonable reflectance range [0.05, 0.7]
    reflectance <- 0.05 + 0.65 * (reflectance - min(reflectance)) /
      (max(reflectance) - min(reflectance) + 1e-10)

    for (p in seq_len(nrow(pixels))) {
      data[pixels[p, 1], pixels[p, 2], ] <- reflectance
    }
  }

  # Add noise
  if (noise_sd > 0) {
    noise <- array(stats::rnorm(rows * cols * n_bands, sd = noise_sd),
                   dim = c(rows, cols, n_bands))
    data <- data + noise
  }

  # Clamp to [0, 1]
  data[data < 0] <- 0
  data[data > 1] <- 1

  # Create mask (all valid)
  mask <- matrix(TRUE, nrow = rows, ncol = cols)

  hsi_cube(
    data = data,
    wavelengths = wavelengths,
    fwhm = rep(25, n_bands),
    metadata = list(
      camera = "simulated",
      processing_mode = "reflectance",
      acquisition_time = Sys.time(),
      region_map = region_map,
      sto2_ground_truth = sto2_values,
      seed = seed
    ),
    mask = mask
  )
}

#' Get Example HSI Cube
#'
#' Generates a small pre-configured synthetic cube for quick examples and
#' documentation. The cube simulates a 30x30 pixel tissue scene with four
#' regions of varying oxygenation (healthy, ischemic, hyperemic, background).
#'
#' @return An [hsi_cube] object (30 x 30 x 61 bands, 430-910 nm).
#'
#' @examples
#' cube <- hs_example_cube()
#' print(cube)
#' dim(cube)
#'
#' @export
hs_example_cube <- function() {
  hs_simulate_cube(rows = 30L, cols = 30L, seed = 42L)
}

#' Write Example ENVI Files to a Temporary Directory
#'
#' Writes a minimal ENVI header + binary pair for testing I/O functions.
#'
#' @param dir Character. Directory to write to. Default [tempdir()].
#'
#' @return Character. Path to the written `.hdr` file (invisibly).
#'
#' @examples
#' hdr_path <- hs_example_files()
#' file.exists(hdr_path)
#'
#' @export
hs_example_files <- function(dir = tempdir()) {
  cube <- hs_simulate_cube(rows = 10L, cols = 10L,
                           wavelengths = seq(430, 510, by = 8),
                           seed = 42L)
  path <- file.path(dir, "example")
  hs_write_envi(cube, path, verbose = FALSE)
  invisible(paste0(path, ".hdr"))
}
