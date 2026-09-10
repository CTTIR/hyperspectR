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
  .validate_components(n_components)

  d <- dim(cube$data)
  n_components <- min(n_components, d[3])

  valid <- .valid_pixels(cube)
  pixel_mat <- .pixel_matrix(cube)[valid, , drop = FALSE]

  if (nrow(pixel_mat) < 2L) cli::cli_abort("PCA needs at least two valid pixels.")
  n_components <- min(n_components, nrow(pixel_mat) - as.integer(center))
  pca_result <- stats::prcomp(pixel_mat, center = center, scale. = scale,
                               rank. = n_components)

  positive <- sum(pca_result$sdev > max(pca_result$sdev) * max(dim(pixel_mat)) * .Machine$double.eps)
  n_components <- min(n_components, positive)
  if (n_components < 1L) cli::cli_abort("PCA data have no non-zero spectral variance.")
  scores_mat <- matrix(NA_real_, prod(d[1:2]), n_components)
  scores_mat[valid, ] <- pca_result$x[, seq_len(n_components), drop = FALSE]
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
    wavelengths = cube$wavelengths, feature_contract = .feature_contract(cube)
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
  .validate_components(n_components)

  d <- dim(cube$data)
  n_components <- min(n_components, d[3])

  valid <- .valid_pixels(cube)
  pixel_mat <- .pixel_matrix(cube)[valid, , drop = FALSE]

  if (nrow(pixel_mat) < 3L) cli::cli_abort("MNF needs at least three valid pixels.")
  ids <- matrix(seq_len(prod(d[1:2])), d[1], d[2])
  pairs <- matrix(integer(), ncol = 2)
  if (d[2] > 1L) pairs <- rbind(pairs, cbind(as.vector(ids[, -d[2], drop = FALSE]), as.vector(ids[, -1L, drop = FALSE])))
  if (d[1] > 1L) pairs <- rbind(pairs, cbind(as.vector(ids[-d[1], , drop = FALSE]), as.vector(ids[-1L, , drop = FALSE])))
  pairs <- pairs[valid[pairs[, 1]] & valid[pairs[, 2]], , drop = FALSE]
  if (nrow(pairs) < 2L) cli::cli_abort("MNF needs at least two valid adjacent pixel pairs.")
  pixels <- .pixel_matrix(cube)
  noise <- pixels[pairs[, 1], , drop = FALSE] - pixels[pairs[, 2], , drop = FALSE]
  noise_cov <- stats::cov(noise) / 2
  eig_noise <- eigen(noise_cov, symmetric = TRUE)
  ridge <- max(max(eig_noise$values) * 1e-8, .Machine$double.eps)
  whitening <- eig_noise$vectors %*% diag(1 / sqrt(pmax(eig_noise$values, ridge)), nrow = d[3]) %*% t(eig_noise$vectors)
  center <- colMeans(pixel_mat)
  centered <- sweep(pixel_mat, 2L, center)
  eig <- eigen(crossprod(whitening, stats::cov(centered) %*% whitening), symmetric = TRUE)
  eigenvalues <- pmax(eig$values, 0)
  rank <- sum(eigenvalues > max(eigenvalues) * 1e-10)
  n_components <- min(n_components, nrow(pixel_mat) - 1L, rank)
  if (n_components < 1L) cli::cli_abort("MNF data have no non-zero spectral variance.")
  loadings <- whitening %*% eig$vectors[, seq_len(n_components), drop = FALSE]
  scores_mat <- matrix(NA_real_, prod(d[1:2]), n_components)
  scores_mat[valid, ] <- centered %*% loadings
  scores <- array(scores_mat, dim = c(d[1], d[2], n_components))
  var_explained <- eigenvalues[seq_len(n_components)] / sum(eigenvalues)

  result <- list(
    scores = scores,
    loadings = loadings,
    variance_explained = var_explained,
    center = center,
    noise_covariance = noise_cov,
    noise_regularization = ridge,
    noise_pairs = nrow(pairs),
    scale = FALSE,
    wavelengths = cube$wavelengths, feature_contract = .feature_contract(cube)
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
#' @param seed Integer random seed. Default 1; the caller's random state is restored.
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
                    min_dist = 0.1, pca_pre = 20L, seed = 1L) {
  .validate_cube(cube)

  if (!requireNamespace("uwot", quietly = TRUE)) {
    cli::cli_abort(c(
      "!" = "Package {.pkg uwot} is required for UMAP.",
      "i" = "Install with {.code install.packages('uwot')}."
    ))
  }

  .validate_components(n_components)
  restore <- .preserve_seed(seed)
  on.exit(restore(), add = TRUE)
  d <- dim(cube$data)
  valid <- .valid_pixels(cube)
  pixel_mat <- .pixel_matrix(cube)[valid, , drop = FALSE]

  # PCA pre-reduction if needed
  if (!is.null(pca_pre) && d[3] > pca_pre) {
    pca <- stats::prcomp(pixel_mat, center = TRUE, rank. = min(pca_pre, nrow(pixel_mat) - 1L))
    input_mat <- pca$x
  } else {
    input_mat <- pixel_mat
  }

  if (nrow(input_mat) <= n_neighbors) cli::cli_abort("UMAP needs more valid pixels than n_neighbors.")
  valid_embedding <- uwot::umap(input_mat,
                           n_components = as.integer(n_components),
                           n_neighbors = as.integer(n_neighbors),
                           min_dist = min_dist, n_threads = 1, n_sgd_threads = 1)
  embedding <- matrix(NA_real_, prod(d[1:2]), n_components)
  embedding[valid, ] <- valid_embedding

  result <- list(
    embedding = embedding,
    scores = array(embedding, dim = c(d[1], d[2], n_components)),
    n_components = n_components, seed = seed,
    dims = d[1:2]
  )

  class(result) <- "hsi_umap"
  result
}

.validate_components <- function(n) {
  if (length(n) != 1L || !is.finite(n) || n < 1 || n != as.integer(n)) cli::cli_abort("n_components must be a positive integer.")
  invisible(n)
}

#' Apply a Fitted Spectral Transform to Another Cube
#'
#' Applies saved PCA/MNF centering, scaling and loadings without refitting.
#' @param model Result from [hs_pca()] or [hs_mnf()].
#' @param cube New [hsi_cube] with the same wavelength grid.
#' @return Score array with spatial dimensions of the new cube; invalid pixels are NA.
#' @export
hs_transform <- function(model, cube) {
  .validate_cube(cube)
  if (!inherits(model, c("hsi_pca", "hsi_mnf"))) cli::cli_abort("Model must be a fitted PCA or MNF transform.")
  if (!isTRUE(all.equal(model$wavelengths, cube$wavelengths, tolerance = 1e-8))) cli::cli_abort("Prediction wavelengths must match the fitted transform.")
  if (!isTRUE(all.equal(model$feature_contract, .feature_contract(cube)))) cli::cli_abort("Prediction preprocessing and band response must match the fitted transform.")
  pixels <- .pixel_matrix(cube)
  if (!identical(model$center, FALSE)) pixels <- sweep(pixels, 2L, model$center)
  if (!identical(model$scale, FALSE)) pixels <- sweep(pixels, 2L, model$scale, "/")
  array(pixels %*% model$loadings, c(dim(cube$data)[1:2], ncol(model$loadings)))
}
