#' Linear Spectral Unmixing via NNLS
#'
#' Solves the linear mixing model per pixel using non-negative least squares.
#'
#' @param cube An [hsi_cube] object (reflectance or absorbance).
#' @param endmembers Numeric matrix. Columns = endmember spectra. Rows = bands.
#'   Column names become abundance map labels.
#' @param sum_to_one Logical. Apply sum-to-one constraint. Default `FALSE`.
#'
#' @param backend Explicit solver: `"builtin"` (default) or `"nnls"`.
#' @param keep_residuals Logical. Retain the full residual cube.
#' @param chunk_size Positive integer. Number of pixels per processing block.
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
hs_unmix_nnls <- function(cube, endmembers, sum_to_one = FALSE,
                          backend = c("builtin", "nnls"), keep_residuals = TRUE,
                          chunk_size = 10000L) {
  .validate_cube(cube)
  backend <- match.arg(backend)
  if (is.data.frame(endmembers)) endmembers <- as.matrix(endmembers)
  if (!is.matrix(endmembers) || !is.numeric(endmembers) || !ncol(endmembers) || any(!is.finite(endmembers))) {
    cli::cli_abort("Endmembers must be a finite numeric matrix with at least one column.")
  }
  if (nrow(endmembers) != dim(cube$data)[3L]) cli::cli_abort("Endmember rows must match cube bands.")
  if (length(chunk_size) != 1L || !is.finite(chunk_size) || chunk_size < 1 || chunk_size != as.integer(chunk_size)) cli::cli_abort("chunk_size must be a positive integer.")
  if (length(sum_to_one) != 1L || !is.logical(sum_to_one) || is.na(sum_to_one)) cli::cli_abort("sum_to_one must be TRUE or FALSE.")
  if (backend == "nnls") rlang::check_installed("nnls")
  if (is.null(colnames(endmembers))) colnames(endmembers) <- paste0("endmember_", seq_len(ncol(endmembers)))
  rank <- qr(endmembers)$rank
  if (rank < ncol(endmembers)) cli::cli_warn("Endmembers are rank deficient; individual abundances may be non-identifiable.")
  condition <- kappa(endmembers)
  if (rank == ncol(endmembers) && condition > 1e8) cli::cli_warn("Endmember design is ill-conditioned; coefficients may be unstable.")
  d <- dim(cube$data)
  n <- prod(d[1:2])
  valid <- .valid_pixels(cube)
  abundances <- matrix(NA_real_, n, ncol(endmembers))
  residuals <- if (keep_residuals) matrix(NA_real_, n, d[3]) else NULL
  rmse <- rep(NA_real_, n)
  status <- rep("invalid", n)
  # Global scaling preserves the equality constraint while conditioning the objective.
  magnitude <- max(abs(endmembers))
  if (!is.finite(magnitude) || magnitude == 0) cli::cli_abort("Endmembers must contain non-zero spectra.")
  design <- endmembers / magnitude
  pixels <- matrix(cube$data, nrow = n)
  ids <- which(valid)
  for (start in seq.int(1L, max(1L, length(ids)), by = chunk_size)) {
    if (!length(ids)) break
    block <- ids[seq.int(start, min(length(ids), start + chunk_size - 1L))]
    for (i in block) {
      y <- pixels[i, ] / magnitude
      x <- if (sum_to_one) .simplex_ls(design, y) else if (backend == "nnls") nnls::nnls(design, y)$x else .nnls_fallback(design, y)
      if (any(!is.finite(x))) { status[i] <- "nonconverged"; next }
      gradient <- as.vector(crossprod(design, design %*% x - y))
      active <- x > 1e-9 * max(1, max(x))
      multiplier <- if (sum_to_one && any(active)) -mean(gradient[active]) else 0
      kkt <- gradient + multiplier
      tolerance <- 1e-7 * max(1, max(abs(crossprod(design, y))))
      converged <- all(is.finite(x)) && min(x) >= -tolerance &&
        (!any(active) || max(abs(kkt[active])) <= tolerance) &&
        (!any(!active) || min(kkt[!active]) >= -tolerance) &&
        (!sum_to_one || abs(sum(x) - 1) <= tolerance)
      if (!converged) { status[i] <- "nonconverged"; next }
      abundances[i, ] <- x
      error <- pixels[i, ] - as.vector(endmembers %*% x)
      rmse[i] <- sqrt(mean(error^2))
      if (keep_residuals) residuals[i, ] <- error
      status[i] <- "ok"
    }
  }
  if (any(status == "nonconverged")) cli::cli_warn("Some unmixing fits did not converge; their outputs are NA. Inspect status.")
  result <- list(abundances = array(abundances, c(d[1:2], ncol(endmembers))),
    residuals = if (keep_residuals) array(residuals, d) else NULL,
    rmse = .spatial_map(rmse, cube), endmember_names = colnames(endmembers),
    status = .spatial_map(status, cube), rank = rank, condition_number = condition,
    active_constraints = array(abundances <= 1e-10, c(d[1:2], ncol(endmembers))),
    backend = if (sum_to_one) "builtin_equality" else backend, sum_to_one = sum_to_one,
    wavelengths = cube$wavelengths, endmembers = endmembers)
  class(result) <- "hsi_unmix"
  result
}

# Active-set quadratic least squares on the probability simplex.
.simplex_ls <- function(A, b, tolerance = 1e-10, max_iter = 1000L) {
  n <- ncol(A)
  if (n == 1L) return(1)
  Q <- crossprod(A)
  c <- as.vector(crossprod(A, b))
  x <- rep(1 / n, n)
  free <- rep(TRUE, n)
  for (iteration in seq_len(max_iter)) {
    ids <- which(free)
    system <- rbind(cbind(Q[ids, ids, drop = FALSE], 1), c(rep(1, length(ids)), 0))
    solution <- .ls_solve(system, c(c[ids], 1))
    candidate <- numeric(n)
    candidate[ids] <- solution[seq_along(ids)]
    if (any(candidate[ids] < -tolerance)) {
      negative <- ids[candidate[ids] < -tolerance]
      alpha <- min(x[negative] / (x[negative] - candidate[negative]))
      x <- x + alpha * (candidate - x)
      free[free & x <= tolerance] <- FALSE
      x[!free] <- 0
    } else {
      x <- pmax(candidate, 0)
      reduced <- as.vector(Q %*% x - c) + solution[length(solution)]
      if (all(free) || min(reduced[!free]) >= -tolerance) return(x)
      inactive <- which(!free)
      free[inactive[which.min(reduced[inactive])]] <- TRUE
    }
  }
  rep(NA_real_, n)
}

#' Beer-Lambert Chromophore Fitting
#'
#' Fits decadic absorbance to reference extinction coefficients with NNLS.
#' Without a known optical pathlength, coefficients are concentration-pathlength
#' products. The hemoglobin fraction is a research model estimate; diffuse tissue
#' scattering and camera response can bias it.
#'
#' @param cube An [hsi_cube] object with an explicit reflectance or absorbance domain.
#' @param chromophores Character vector. Default `c("HbO2", "Hb")`.
#' @param wavelength_range Numeric vector of length 2. Fitting range.
#'   Default `c(500, 600)` (Hb Q-band region for best contrast).
#'
#' @param input `"auto"` reads the declared processing mode, or explicitly
#'   specify `"reflectance"` or `"absorbance"`. Values never determine the domain.
#' @param pathlength_cm Positive scalar optical pathlength, or NULL (unknown).
#' @param response `"point"` (default) samples band centers; `"gaussian"`
#'   integrates reference coefficients using cube FWHM as Gaussian widths.
#' @param keep_residuals Logical. Retain spectral residuals. Default FALSE.
#' @return A list with class `"hsi_chromophore_fit"`:
#' \describe{
#'   \item{coefficients}{Named matrices of concentration-pathlength products (mol/L * cm).}
#'   \item{concentrations}{Named matrices in mol/L when pathlength is supplied; otherwise NULL.}
#'   \item{sto2}{Matrix of oxygen saturation = HbO2 / (HbO2 + Hb) * 100.}
#'   \item{total_hb}{Sum of HbO2 and Hb concentration-pathlength products.}
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
                            wavelength_range = c(500, 600),
                            input = c("auto", "reflectance", "absorbance"),
                            pathlength_cm = NULL, response = c("point", "gaussian"),
                            keep_residuals = FALSE) {
  .validate_cube(cube)
  .require_wavelengths(cube)
  input <- match.arg(input)
  response <- match.arg(response)
  if (input == "auto") input <- cube$metadata$processing_mode %||% "unknown"
  if (!input %in% c("reflectance", "absorbance")) cli::cli_abort("Declare input='reflectance' or input='absorbance'; the cube domain is unknown or incompatible.")
  if (length(wavelength_range) != 2L || any(!is.finite(wavelength_range)) || wavelength_range[1] >= wavelength_range[2]) cli::cli_abort("Provide an increasing finite fitting wavelength range.")
  if (!length(chromophores) || anyDuplicated(chromophores) || any(!chromophores %in% c("HbO2", "Hb"))) cli::cli_abort("Quantitative reference fitting supports unique HbO2/Hb chromophores only.")
  if (!is.null(pathlength_cm) && (length(pathlength_cm) != 1L || !is.finite(pathlength_cm) || pathlength_cm <= 0)) cli::cli_abort("pathlength_cm must be positive and finite.")
  if (input == "reflectance") {
    cube$metadata$processing_mode <- "reflectance"
    abs_cube <- hs_absorbance(cube)
  } else abs_cube <- cube
  wl_idx <- which(cube$wavelengths >= wavelength_range[1] & cube$wavelengths <= wavelength_range[2])
  if (length(wl_idx) < max(2L, length(chromophores))) cli::cli_abort("Need at least 2 bands and at least as many bands as chromophores within wavelength range for fitting.")
  fit_wl <- cube$wavelengths[wl_idx]
  reference <- .hemoglobin_reference()
  if (min(fit_wl) < min(reference$wavelength) || max(fit_wl) > max(reference$wavelength)) cli::cli_abort("Fitting wavelengths exceed reference coverage (250-1000 nm).")
  em <- matrix(NA_real_, length(wl_idx), length(chromophores), dimnames = list(NULL, chromophores))
  if (response == "gaussian" && is.null(cube$fwhm)) cli::cli_abort("Gaussian response requires FWHM metadata.")
  for (j in seq_along(chromophores)) {
    if (response == "point") em[, j] <- stats::approx(reference$wavelength, reference[[chromophores[j]]], xout = fit_wl)$y else {
      sigma <- cube$fwhm[wl_idx] / (2 * sqrt(2 * log(2)))
      if (any(fit_wl - 4 * sigma < min(reference$wavelength) | fit_wl + 4 * sigma > max(reference$wavelength))) cli::cli_abort("Gaussian response support exceeds reference coverage.")
      em[, j] <- vapply(seq_along(fit_wl), function(k) {
        weights <- stats::dnorm(reference$wavelength, fit_wl[k], sigma[k])
        sum(reference[[chromophores[j]]] * weights) / sum(weights)
      }, numeric(1))
    }
  }
  if (qr(em)$rank < ncol(em)) cli::cli_abort("Reference design is rank deficient in the fitting range.")
  fit <- hs_unmix_nnls(abs_cube[, , wl_idx], em, keep_residuals = keep_residuals)
  products <- stats::setNames(lapply(seq_along(chromophores), function(j) .spatial_map(fit$abundances[, , j], cube)), chromophores)
  concentrations <- if (is.null(pathlength_cm)) NULL else lapply(products, function(x) x / pathlength_cm)
  sto2 <- total_hb <- NULL
  if (all(c("HbO2", "Hb") %in% chromophores)) {
    total_hb <- products$HbO2 + products$Hb
    sto2 <- 100 * products$HbO2 / total_hb
    sto2[!is.finite(sto2) | total_hb <= 0] <- NA_real_
    fit$status[is.finite(total_hb) & total_hb <= 0] <- "no_hemoglobin_signal"
  }
  result <- list(coefficients = products, concentrations = concentrations,
    coefficient_units = "mol/L * cm", concentration_units = if (!is.null(pathlength_cm)) "mol/L" else NULL,
    pathlength_cm = pathlength_cm, sto2 = sto2, total_hb = total_hb, rmse = fit$rmse,
    residuals = fit$residuals, status = fit$status, rank = fit$rank, condition_number = fit$condition_number,
    wavelength_range = range(fit_wl), wavelengths = fit_wl, chromophores = chromophores,
    reference_id = "prahl-hemoglobin-v1", reference_checksum = "52710fd13196ed4aeaa00e3a32c0ac02", response = response, input_domain = input,
    interpretation = "Research hemoglobin fraction under the stated Beer-Lambert model; not a validated tissue oxygenation measurement.")
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
