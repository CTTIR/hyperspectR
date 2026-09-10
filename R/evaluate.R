#' Evaluate Classification with Entire Groups Held Out
#'
#' Splits by subject (or another independent sampling unit), fits preprocessing
#' only on training spectra, and predicts held-out groups. Hyperparameters must
#' be chosen before evaluation; this function does not tune on validation data.
#' Group accuracy is conditional on valid predictions; prediction coverage and
#' unevaluated group counts are reported separately. Per-class recall treats
#' withheld predictions as missed labels. Accuracy intervals resample whole
#' groups, not pixels. These intervals summarize
#' out-of-fold predictions and do not include uncertainty from refitting models.
#' @param spectra Numeric matrix, observations in rows and wavelengths in columns.
#' @param wavelengths Numeric band centers in nm.
#' @param labels Character class labels for each observation.
#' @param groups Independent group identifiers, usually subject identifiers.
#' @param folds Optional named integer vector mapping every group to a fold.
#' @param n_folds Number of folds when no mapping is supplied. Default 5.
#' @param method Classifier, `"svm"` or `"rf"`.
#' @param recipe Processing recipe. Learned references are fitted inside each fold.
#' @param model_args Named list of fixed classifier parameters.
#' @param seed Random seed for fold assignment and model fitting.
#' @param bootstrap Number of group bootstrap samples for the accuracy interval.
#' @return List of out-of-fold predictions, group metrics, confusion matrix,
#'   group-mean accuracy and interval, fold assignments and fitted recipes.
#' @export
hs_grouped_evaluate <- function(spectra, wavelengths, labels, groups, folds = NULL,
                                n_folds = 5L, method = c("svm", "rf"),
                                recipe = hs_recipe(), model_args = list(),
                                seed = 1L, bootstrap = 1000L) {
  method <- match.arg(method)
  if (!is.matrix(spectra) || !is.numeric(spectra) || nrow(spectra) != length(labels) ||
      length(groups) != length(labels) || anyNA(groups) || anyNA(labels)) cli::cli_abort("Spectra, labels and non-missing groups must describe the same observations.")
  if (!is.list(model_args) || any(names(model_args) %in% c("cube", "training_labels", "training_mask"))) cli::cli_abort("model_args must not override training data.")
  .validate_components(n_folds)
  .validate_components(bootstrap)
  previous_seed <- .preserve_seed(seed)
  on.exit(previous_seed(), add = TRUE)
  groups <- as.character(groups)
  labels <- as.character(labels)
  group_ids <- unique(groups)
  if (length(group_ids) < 2L) cli::cli_abort("At least two independent groups are required.")
  if (is.null(folds)) {
    n_folds <- min(n_folds, length(group_ids))
    if (n_folds < 2L) cli::cli_abort("At least two folds are required.")
    folds <- stats::setNames(rep(seq_len(n_folds), length.out = length(group_ids)), sample(group_ids))
  }
  if (is.null(names(folds)) || anyDuplicated(names(folds)) || !setequal(names(folds), group_ids) ||
      anyNA(folds) || any(folds != as.integer(folds)) || length(unique(folds)) < 2L) cli::cli_abort("folds must map every unique group to exactly one of at least two integer folds.")
  cube <- hsi_cube(array(spectra, c(nrow(spectra), 1L, ncol(spectra))), wavelengths)
  row_fold <- unname(folds[groups])
  predictions <- rep(NA_character_, nrow(spectra))
  fitted_recipes <- list()
  splits <- list()
  for (fold in sort(unique(row_fold))) {
    train <- which(row_fold != fold)
    test <- which(row_fold == fold)
    training <- hs_process(cube[train, , ], recipe, learn = TRUE)
    testing <- hs_process(cube[test, , ], training$recipe, learn = FALSE)
    classifier <- if (method == "svm") hs_classify_svm else hs_classify_rf
    model <- do.call(classifier, c(list(cube = training$cube,
      training_labels = matrix(labels[train], length(train), 1L)), model_args))
    predictions[test] <- as.vector(hs_predict(model, testing$cube))
    fitted_recipes[[as.character(fold)]] <- training$recipe
    splits[[as.character(fold)]] <- list(train_groups = unique(groups[train]), test_groups = unique(groups[test]),
      train_class_counts = table(labels[train][.valid_pixels(training$cube)]), test_class_counts = table(labels[test]))
  }
  rows <- data.frame(group = groups, fold = row_fold, observed = labels, predicted = predictions)
  group_metrics <- do.call(rbind, lapply(group_ids, function(group) {
    selected <- groups == group
    valid <- selected & !is.na(predictions)
    data.frame(group = group, n = sum(selected), n_predicted = sum(valid),
      accuracy = if (any(valid)) mean(predictions[valid] == labels[valid]) else NA_real_)
  }))
  metrics <- do.call(rbind, lapply(sort(unique(labels)), function(label) {
    tp <- sum(labels == label & !is.na(predictions) & predictions == label)
    actual <- sum(labels == label)
    predicted <- sum(predictions == label, na.rm = TRUE)
    data.frame(class = label, n_true = actual, n_predicted = predicted,
      precision = if (predicted) tp / predicted else NA_real_, recall = tp / actual,
      f1 = 2 * tp / (actual + predicted))
  }))
  interval <- .group_mean_interval(group_metrics$accuracy, bootstrap)
  list(predictions = rows, group_metrics = group_metrics,
    confusion = table(observed = labels, predicted = predictions, useNA = "ifany"),
    accuracy = interval$estimate, accuracy_interval = interval$interval,
    prediction_coverage = mean(!is.na(predictions)),
    n_groups = length(group_ids), n_groups_evaluated = sum(is.finite(group_metrics$accuracy)),
    class_metrics = metrics, macro_f1 = mean(metrics$f1), balanced_accuracy = mean(metrics$recall),
    folds = folds, splits = splits, fitted_recipes = fitted_recipes,
    method = method, model_args = model_args, seed = seed,
    inference_unit = "group", environment = .analysis_environment())
}

#' Summarize Repeated ROI Measurements with Group-Level Uncertainty
#'
#' First averages observations within each independent group, then computes an
#' equally weighted mean across groups. Bootstrap samples resample whole groups.
#' Pixel or repeated-recording counts do not inflate the independent sample size.
#' @param data Data frame containing a numeric outcome and a group identifier.
#' @param value Column name containing the outcome.
#' @param group Column name identifying independent subjects or sampling units.
#' @param bootstrap Number of bootstrap samples. Default 1000.
#' @param seed Random seed. Default 1.
#' @return List containing group means, independent group count, overall estimate,
#'   percentile interval and number of excluded nonfinite observations.
#' @export
hs_group_summary <- function(data, value = "value", group = "subject_id",
                             bootstrap = 1000L, seed = 1L) {
  if (!is.data.frame(data) || !all(c(value, group) %in% names(data)) ||
      !is.numeric(data[[value]]) || anyNA(data[[group]])) cli::cli_abort("Supply a numeric value column and non-missing group identifiers.")
  .validate_components(bootstrap)
  restore <- .preserve_seed(seed)
  on.exit(restore(), add = TRUE)
  valid <- is.finite(data[[value]])
  grouped <- split(data[[value]][valid], as.character(data[[group]][valid]))
  means <- vapply(grouped, mean, numeric(1))
  inference <- .group_mean_interval(means, bootstrap)
  list(group_means = data.frame(group = names(means), mean = unname(means)),
    n_groups = length(means), estimate = inference$estimate,
    interval = inference$interval, excluded = sum(!valid),
    inference_unit = group, seed = seed, bootstrap = bootstrap)
}

.group_mean_interval <- function(values, bootstrap) {
  values <- values[is.finite(values)]
  if (!length(values)) return(list(estimate = NA_real_, interval = c(NA_real_, NA_real_)))
  interval <- if (length(values) < 2L) c(NA_real_, NA_real_) else {
    draws <- replicate(bootstrap, mean(values[sample.int(length(values), length(values), replace = TRUE)]))
    unname(stats::quantile(draws, c(.025, .975)))
  }
  list(estimate = mean(values), interval = interval)
}

.preserve_seed <- function(seed) {
  if (length(seed) != 1L || !is.finite(seed) || seed < 0 || seed != as.integer(seed)) cli::cli_abort("seed must be a non-negative integer.")
  existed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  previous <- if (existed) get(".Random.seed", envir = .GlobalEnv) else NULL
  set.seed(seed)
  function() {
    if (existed) assign(".Random.seed", previous, envir = .GlobalEnv) else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }
}
