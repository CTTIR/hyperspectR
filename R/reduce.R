#' PCA on Hyperspectral Cube
#'
#' Performs Principal Component Analysis on the spectral dimension of an HSI
#' cube. Reduces the spectral bands to a smaller number of orthogonal
#' components ordered by explained variance.
#'
#' @param cube An [hsi_cube] object.
#' @param n_components Integer. Number of components to retain. Default `5`.
#' @param center Logical. Center bands before PCA. Default `TRUE`.
#' @param scale Logical. Scale bands to unit variance. Default `FALSE`.
#'
#' @return A list with class `"hsi_pca"`:
#' \describe{
#'   \item{scores}{3D array (rows x cols x n_components) of component score maps.}
#'   \item{loadings}{Matrix (bands x n_components) of spectral loadings.}
#'   \item{variance_explained}{Numeric vector of proportion of variance per component.}
#'   \item{center}{Centering vector used (or `FALSE`).}
#'   \item{scale}{Scaling vector used (or `FALSE`).}
#'   \item{wavelengths}{Wavelength vector from input cube.}
#' }
#'
#' @examples
#' cube <- hs_example_cube()
#' pca <- hs_pca(cube, n_components = 3)
#' pca$variance_explained
#'
#' @export
hs_pca <- function(cube, n_components = 5L, center = TRUE, scale = FALSE) {
  .validate_cube(cube)
  n_components <- as.integer(n_components)

  d <- dim(cube$data)
  n_components <- min(n_components, d[3])

  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  pca_result <- stats::prcomp(pixel_mat, center = center, scale. = scale,
                               rank. = n_components)

  scores_mat <- pca_result$x[, seq_len(n_components), drop = FALSE]
  scores <- array(scores_mat, dim = c(d[1], d[2], n_components))

  loadings <- pca_result$rotation[, seq_len(n_components), drop = FALSE]

  total_var <- sum(pca_result$sdev^2)
  var_explained <- pca_result$sdev[seq_len(n_components)]^2 / total_var

  result <- list(
    scores = scores,
    loadings = loadings,
    variance_explained = var_explained,
    center = pca_result$center,
    scale = pca_result$scale,
    wavelengths = cube$wavelengths
  )

  class(result) <- "hsi_pca"
  result
}

#' Minimum Noise Fraction Transform
#'
#' Orders components by signal-to-noise ratio rather than variance.
#' Estimates noise covariance from spatial first-differences.
#'
#' @param cube An [hsi_cube] object.
#' @param n_components Integer. Number of components. Default `5`.
#'
#' @return A list with class `"hsi_mnf"` (same structure as [hs_pca()]).
#'
#' @examples
#' cube <- hs_example_cube()
#' mnf <- hs_mnf(cube, n_components = 3)
#' dim(mnf$scores)
#'
#' @export
hs_mnf <- function(cube, n_components = 5L) {
  .validate_cube(cube)
  n_components <- as.integer(n_components)

  d <- dim(cube$data)
  n_components <- min(n_components, d[3])

  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  # Estimate noise from spatial first-differences (horizontal)
  noise_mat <- matrix(0, nrow = d[1] * (d[2] - 1L), ncol = d[3])
  for (b in seq_len(d[3])) {
    diff_band <- cube$data[, -1L, b] - cube$data[, -d[2], b]
    noise_mat[, b] <- as.vector(diff_band)
  }

  # Noise covariance
  noise_cov <- stats::cov(noise_mat) / 2

  # Data covariance
  centered <- scale(pixel_mat, center = TRUE, scale = FALSE)
  data_cov <- stats::cov(centered)

  # Solve generalized eigenvalue problem: data_cov * v = lambda * noise_cov * v
  noise_cov_inv <- tryCatch(
    solve(noise_cov),
    error = function(e) {
      # Add regularization if singular
      solve(noise_cov + diag(1e-6, d[3]))
    }
  )

  eig <- eigen(noise_cov_inv %*% data_cov, symmetric = FALSE)

  # Take real parts and sort by decreasing eigenvalue
  eigenvalues <- Re(eig$values)
  eigenvectors <- Re(eig$vectors)
  ord <- order(eigenvalues, decreasing = TRUE)

  loadings <- eigenvectors[, ord[seq_len(n_components)], drop = FALSE]
  scores_mat <- centered %*% loadings
  scores <- array(scores_mat, dim = c(d[1], d[2], n_components))

  total_snr <- sum(eigenvalues)
  var_explained <- eigenvalues[ord[seq_len(n_components)]] / total_snr

  result <- list(
    scores = scores,
    loadings = loadings,
    variance_explained = var_explained,
    center = colMeans(pixel_mat),
    scale = FALSE,
    wavelengths = cube$wavelengths
  )

  class(result) <- "hsi_mnf"
  result
}

#' UMAP Embedding of Spectral Data
#'
#' Computes a UMAP (Uniform Manifold Approximation and Projection) embedding
#' of the spectral data. Requires the `uwot` package.
#'
#' @param cube An [hsi_cube] object.
#' @param n_components Integer. UMAP dimensions. Default `2`.
#' @param n_neighbors Integer. Default `15`.
#' @param min_dist Numeric. Default `0.1`.
#' @param pca_pre Integer or NULL. PCA pre-reduction dimensionality. Default `20`.
#'
#' @return A list with class `"hsi_umap"` containing embedding matrix and
#'   spatial coordinates.
#'
#' @examples
#' \donttest{
#' # Requires uwot package
#' cube <- hs_example_cube()
#' if (requireNamespace("uwot", quietly = TRUE)) {
#'   umap_result <- hs_umap(cube, n_components = 2)
#' }
#' }
#'
#' @export
hs_umap <- function(cube, n_components = 2L, n_neighbors = 15L,
                    min_dist = 0.1, pca_pre = 20L) {
  .validate_cube(cube)

  if (!requireNamespace("uwot", quietly = TRUE)) {
    cli::cli_abort(c(
      "!" = "Package {.pkg uwot} is required for UMAP.",
      "i" = "Install with {.code install.packages('uwot')}."
    ))
  }

  d <- dim(cube$data)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  # PCA pre-reduction if needed
  if (!is.null(pca_pre) && d[3] > pca_pre) {
    pca <- stats::prcomp(pixel_mat, center = TRUE, rank. = pca_pre)
    input_mat <- pca$x
  } else {
    input_mat <- pixel_mat
  }

  embedding <- uwot::umap(input_mat,
                           n_components = as.integer(n_components),
                           n_neighbors = as.integer(n_neighbors),
                           min_dist = min_dist)

  result <- list(
    embedding = embedding,
    scores = array(embedding, dim = c(d[1], d[2], n_components)),
    n_components = n_components,
    dims = d[1:2]
  )

  class(result) <- "hsi_umap"
  result
}
