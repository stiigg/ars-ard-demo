dispatch_stats <- function(df, analysis) {
  var <- analysis$variable
  stats <- analysis$statistics %||% c("N","MEAN","SD","MEDIAN","Q1","Q3","MIN","MAX","SE","CV")
  groups <- analysis$group_by %||% character(0)
  if (length(groups) == 0) {
    df$.ALL <- "ALL"
    groups <- ".ALL"
  }
  df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
    dplyr::summarise(
      N = if ("N" %in% stats) sum(!is.na(.data[[var]])) else NA_real_,
      MEAN = if ("MEAN" %in% stats) mean(.data[[var]], na.rm = TRUE) else NA_real_,
      SD = if ("SD" %in% stats) stats::sd(.data[[var]], na.rm = TRUE) else NA_real_,
      MEDIAN = if ("MEDIAN" %in% stats) stats::median(.data[[var]], na.rm = TRUE) else NA_real_,
      Q1 = if ("Q1" %in% stats) stats::quantile(.data[[var]], 0.25, na.rm = TRUE, names = FALSE) else NA_real_,
      Q3 = if ("Q3" %in% stats) stats::quantile(.data[[var]], 0.75, na.rm = TRUE, names = FALSE) else NA_real_,
      MIN = if ("MIN" %in% stats) min(.data[[var]], na.rm = TRUE) else NA_real_,
      MAX = if ("MAX" %in% stats) max(.data[[var]], na.rm = TRUE) else NA_real_,
      SE = if ("SE" %in% stats) stats::sd(.data[[var]], na.rm = TRUE) / sqrt(sum(!is.na(.data[[var]]))) else NA_real_,
      CV = if ("CV" %in% stats) 100 * stats::sd(.data[[var]], na.rm = TRUE) / mean(.data[[var]], na.rm = TRUE) else NA_real_,
      .groups = "drop"
    ) |>
    dplyr::select(dplyr::all_of(groups), dplyr::any_of(stats))
}
