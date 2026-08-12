#' Linear Spectral Unmixing via NNLS
#'
#' Solves the linear mixing model per pixel using non-negative least squares.
#'
#' @param cube An [hsi_cube] object (reflectance or absorbance).
#' @param endmembers Numeric matrix. Columns = endmember spectra. Rows = bands.
#'   Column names become abundance map labels.
#' @param sum_to_one Logical. Apply sum-to-one constraint. Default `FALSE`.
#'
#' @return A list with class `"hsi_unmix"`:
#' \describe{
#'   \item{abundances}{3D array (rows x cols x n_endmembers) of abundance maps.}
#'   \item{residuals}{3D array of reconstruction residuals.}
#'   \item{rmse}{Numeric matrix of per-pixel RMSE.}
#'   \item{endmember_names}{Character vector.}
#' }
#'
#' @examples
#' cube <- hs_example_cube()
#' # Create simple endmembers
#' em <- cbind(
#'   tissue = cube$data[5, 5, ],
#'   background = cube$data[25, 25, ]
#' )
#' result <- hs_unmix_nnls(cube, em)
#' dim(result$abundances)
#'
#' @export
hs_unmix_nnls <- function(cube, endmembers, sum_to_one = FALSE) {
  .validate_cube(cube)

  if (is.data.frame(endmembers)) endmembers <- as.matrix(endmembers)

  if (nrow(endmembers) != dim(cube$data)[3L]) {
    cli::cli_abort(
      "Endmember rows ({nrow(endmembers)}) must match cube bands ({dim(cube$data)[3L]})."
    )
  }

  if (is.null(colnames(endmembers))) {
    colnames(endmembers) <- paste0("endmember_", seq_len(ncol(endmembers)))
  }

  d <- dim(cube$data)
  n_em <- ncol(endmembers)
  pixel_mat <- matrix(cube$data, nrow = d[1] * d[2], ncol = d[3])

  use_nnls <- requireNamespace("nnls", quietly = TRUE)

  abundances_mat <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = n_em)
  residuals_mat <- matrix(NA_real_, nrow = nrow(pixel_mat), ncol = d[3])

  if (sum_to_one) {
    # Add constraint row: sum of abundances = 1
    em_constrained <- rbind(endmembers, rep(1, n_em))
  }

  for (i in seq_len(nrow(pixel_mat))) {
    y <- pixel_mat[i, ]

    if (sum_to_one) {
      y_c <- c(y, 1)
      abundances_mat[i, ] <- if (use_nnls) {
        nnls::nnls(em_constrained, y_c)$x
      } else {
        .nnls_fallback(em_constrained, y_c)
      }
    } else {
      abundances_mat[i, ] <- if (use_nnls) {
        nnls::nnls(endmembers, y)$x
      } else {
        .nnls_fallback(endmembers, y)
      }
    }

    residuals_mat[i, ] <- y - endmembers %*% abundances_mat[i, ]
  }

  rmse <- sqrt(rowMeans(residuals_mat^2))

  result <- list(
    abundances = array(abundances_mat, dim = c(d[1], d[2], n_em)),
    residuals = array(residuals_mat, dim = d),
    rmse = matrix(rmse, nrow = d[1], ncol = d[2]),
    endmember_names = colnames(endmembers)
  )

  class(result) <- "hsi_unmix"
  result
}

#' Beer-Lambert Chromophore Fitting
#'
#' Estimates pixel-wise concentrations of tissue chromophores by fitting
#' absorbance spectra to published extinction coefficient spectra using NNLS.
#'
#' @param cube An [hsi_cube] object. If reflectance, automatically converted
#'   to absorbance internally.
#' @param chromophores Character vector. Default `c("HbO2", "Hb")`.
#' @param wavelength_range Numeric vector of length 2. Fitting range.
#'   Default `c(500, 600)` (Hb Q-band region for best contrast).
#'
#' @return A list with class `"hsi_chromophore_fit"`:
#' \describe{
#'   \item{concentrations}{Named list of matrices (one per chromophore).}
#'   \item{sto2}{Matrix of oxygen saturation = HbO2 / (HbO2 + Hb) * 100.}
#'   \item{total_hb}{Matrix of total hemoglobin = HbO2 + Hb.}
#'   \item{rmse}{Matrix of fit residuals.}
#' }
#'
#' @examples
#' cube <- hs_example_cube()
#' fit <- hs_beer_lambert(cube)
#' range(fit$sto2, na.rm = TRUE)
#'
#' @export
hs_beer_lambert <- function(cube, chromophores = c("HbO2", "Hb"),
                            wavelength_range = c(500, 600)) {
  .validate_cube(cube)

  # Convert to absorbance if needed
  if (all(cube$data >= 0, na.rm = TRUE) && max(cube$data, na.rm = TRUE) <= 1.5) {
    abs_cube <- hs_absorbance(cube)
  } else {
    abs_cube <- cube
  }

  # Get wavelength indices within fitting range
  wl_idx <- which(abs_cube$wavelengths >= wavelength_range[1] &
                    abs_cube$wavelengths <= wavelength_range[2])

  if (length(wl_idx) < 2L) {
    cli::cli_abort("Need at least 2 bands within wavelength range for fitting.")
  }

  fit_wl <- abs_cube$wavelengths[wl_idx]

  # Get chromophore spectra at fitting wavelengths
  chrom_data <- hs_chromophore_data(chromophores, wavelength_range)

  # Interpolate to exact cube wavelengths
  em <- matrix(NA_real_, nrow = length(wl_idx), ncol = length(chromophores))
  for (c_idx in seq_along(chromophores)) {
    em[, c_idx] <- stats::approx(chrom_data$wavelength,
                                  chrom_data[[chromophores[c_idx]]],
                                  xout = fit_wl, rule = 2)$y
  }

  colnames(em) <- chromophores

  # Subset cube to fitting range and unmix
  fit_cube <- abs_cube[, , wl_idx]
  unmix_result <- hs_unmix_nnls(fit_cube, em)

  d <- dim(cube$data)
  concentrations <- list()
  for (c_idx in seq_along(chromophores)) {
    concentrations[[chromophores[c_idx]]] <- unmix_result$abundances[, , c_idx]
  }

  # Compute StO2 if both HbO2 and Hb are present
  sto2 <- NULL
  total_hb <- NULL
  if ("HbO2" %in% chromophores && "Hb" %in% chromophores) {
    hbo2 <- concentrations[["HbO2"]]
    hb <- concentrations[["Hb"]]
    total_hb <- hbo2 + hb
    sto2 <- (hbo2 / (total_hb + 1e-10)) * 100
    sto2[total_hb < 1e-10] <- NA_real_
  }

  result <- list(
    concentrations = concentrations,
    sto2 = sto2,
    total_hb = total_hb,
    rmse = unmix_result$rmse,
    wavelength_range = wavelength_range,
    chromophores = chromophores
  )

  class(result) <- "hsi_chromophore_fit"
  result
}


# Non-negative least squares without the nnls package.
#
# The previous fallback minimised the residual with optim(method = "L-BFGS-B")
# from a fixed start. That fails badly on chromophore fitting: extinction
# coefficients are on the order of 1e5 while absorbance is around 0.5, so the
# optimum lies near 1e-5 and the optimiser collapses onto the lower bound.
# Every abundance came back as zero, which propagated to an all-NA sto2 in
# hs_beer_lambert() -- silently, and specifically on machines without the
# optional nnls package, which is exactly what CRAN's noSuggests flavour runs.
#
# This is the Lawson-Hanson active-set algorithm, which solves the problem
# exactly rather than approximately, and is scale-free.
.nnls_fallback <- function(A, b, tol = NULL, max_iter = NULL) {
  A <- as.matrix(A)
  b <- as.numeric(b)
  n <- ncol(A)

  if (is.null(tol)) tol <- 10 * .Machine$double.eps * max(1, max(abs(A))) * n
  if (is.null(max_iter)) max_iter <- 3L * n

  x <- numeric(n)
  passive <- logical(n)          # P: indices allowed to be non-zero
  w <- crossprod(A, b - A %*% x) # negative gradient

  iter <- 0L
  while (any(!passive) && max(w[!passive]) > tol && iter < max_iter) {
    iter <- iter + 1L

    # move the most promising index into the passive set
    idx <- which(!passive)
    j <- idx[which.max(w[idx])]
    passive[j] <- TRUE

    s <- numeric(n)
    s[passive] <- .ls_solve(A[, passive, drop = FALSE], b)

    # inner loop: retreat until the passive solution is feasible
    inner <- 0L
    while (any(s[passive] <= 0) && inner < max_iter) {
      inner <- inner + 1L
      neg <- passive & s <= 0
      ratio <- x[neg] / (x[neg] - s[neg])
      alpha <- min(ratio[is.finite(ratio)], 1)
      x <- x + alpha * (s - x)
      passive[passive & abs(x) < tol] <- FALSE
      s <- numeric(n)
      if (any(passive)) s[passive] <- .ls_solve(A[, passive, drop = FALSE], b)
    }

    x <- s
    w <- crossprod(A, b - A %*% x)
  }

  x[x < 0] <- 0
  as.numeric(x)
}


# Least squares for one sub-problem, tolerating rank deficiency.
.ls_solve <- function(A, b) {
  fit <- tryCatch(qr.solve(A, b), error = function(e) NULL)
  if (is.null(fit) || anyNA(fit)) {
    # fall back to the pseudo-inverse via SVD when columns are collinear
    sv <- svd(A)
    keep <- sv$d > max(dim(A)) * .Machine$double.eps * max(sv$d)
    if (!any(keep)) return(rep(0, ncol(A)))
    fit <- sv$v[, keep, drop = FALSE] %*%
      ((t(sv$u[, keep, drop = FALSE]) %*% b) / sv$d[keep])
  }
  as.numeric(fit)
}
