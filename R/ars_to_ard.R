
# R: ARS JSON -> ARD (supports multiple analyses)
suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
  library(rlang)
})

`%||%` <- function(x, y) {
  if (
    is.null(x) ||
      (is.character(x) && length(x) == 1 && (is.na(x) || !nzchar(x)))
  ) y else x
}

slugify <- function(x) {
  slug <- gsub("[^A-Za-z0-9]+", "_", x)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) "ARD" else toupper(slug)
}

method_label <- function(method) {
  label <- method$label
  if (!is.null(label) && nzchar(label)) {
    return(label)
  }

  type <- tolower(method$type %||% "descriptive")
  switch(
    type,
    descriptive = "Descriptive statistics",
    time_to_event = "Time-to-event analysis",
    binary = "Binary analysis",
    categorical = "Categorical analysis",
    type
  )
}

default_statistics <- function(method) {
  type <- tolower(method$type %||% "descriptive")
  switch(
    type,
    descriptive = c("n", "mean", "sd", "median", "min", "max"),
    categorical = c("n"),
    binary = c("n", "mean"),
    time_to_event = c("n", "median"),
    c("n")
  )
}

parse_population_expr <- function(expr) {
  if (!nzchar(expr)) {
    return(NULL)
  }

  tryCatch(
    rlang::parse_expr(expr),
    error = function(e) {
      stop(
        "Failed to parse population filter '",
        expr,
        "': ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
}

statistic_expression <- function(var_sym, stat, raw_stat) {
  switch(
    stat,
    n = rlang::expr(sum(!is.na(!!var_sym))),
    n_non_missing = rlang::expr(sum(!is.na(!!var_sym))),
    n_missing = rlang::expr(sum(is.na(!!var_sym))),
    missing = rlang::expr(sum(is.na(!!var_sym))),
    mean = rlang::expr(mean(!!var_sym, na.rm = TRUE)),
    arithmetic_mean = rlang::expr(mean(!!var_sym, na.rm = TRUE)),
    sd = rlang::expr(stats::sd(!!var_sym, na.rm = TRUE)),
    stddev = rlang::expr(stats::sd(!!var_sym, na.rm = TRUE)),
    std = rlang::expr(stats::sd(!!var_sym, na.rm = TRUE)),
    se = rlang::expr(stats::sd(!!var_sym, na.rm = TRUE) / sqrt(sum(!is.na(!!var_sym)))),
    stderr = rlang::expr(stats::sd(!!var_sym, na.rm = TRUE) / sqrt(sum(!is.na(!!var_sym)))),
    var = rlang::expr(stats::var(!!var_sym, na.rm = TRUE)),
    variance = rlang::expr(stats::var(!!var_sym, na.rm = TRUE)),
    median = rlang::expr(stats::median(!!var_sym, na.rm = TRUE)),
    min = rlang::expr(min(!!var_sym, na.rm = TRUE)),
    max = rlang::expr(max(!!var_sym, na.rm = TRUE)),
    range = rlang::expr(max(!!var_sym, na.rm = TRUE) - min(!!var_sym, na.rm = TRUE)),
    stop(
      "Unsupported statistic requested in ARS: ",
      raw_stat,
      call. = FALSE
    )
  )
}

normalise_stat_keyword <- function(stat) {
  stat <- tolower(stat)

  if (identical(stat, "n")) {
    return("n")
  }

  aliases <- c(
    count = "n",
    nnonmiss = "n_non_missing",
    n_nonmiss = "n_non_missing",
    n_non_missing = "n_non_missing",
    nonmissing = "n_non_missing",
    non_missing = "n_non_missing",
    nmiss = "n_missing",
    missing = "missing",
    missing_count = "missing",
    mean = "mean",
    arithmetic_mean = "arithmetic_mean",
    sd = "sd",
    stddev = "stddev",
    std = "std",
    std_dev = "std",
    se = "se",
    stderr = "stderr",
    var = "var",
    variance = "variance",
    median = "median",
    q2 = "median",
    min = "min",
    max = "max",
    range = "range",
    iqr = "iqr"
  )

  if (stat %in% names(aliases)) {
    return(aliases[[stat]])
  }

  if (grepl("^p\\d+$", stat)) {
    return(stat)
  }

  if (grepl("^q[1-4]$", stat)) {
    quartile <- substring(stat, 2)
    pct <- switch(quartile, "1" = 25, "2" = 50, "3" = 75, "4" = 100)
    return(paste0("p", pct))
  }

  if (stat == "iqr") {
    return("iqr")
  }

  stat
}

quantile_expression <- function(var_sym, prob) {
  rlang::expr(stats::quantile(!!var_sym, !!prob, na.rm = TRUE, names = FALSE))
}

summarise_stats <- function(data, var_name, stats) {
  if (is.null(stats) || !length(stats)) {
    stop("No statistics requested for variable '", var_name, "'", call. = FALSE)
  }

  stats <- unique(vapply(stats, normalise_stat_keyword, character(1)))
  var_sym <- rlang::sym(var_name)

  stat_list <- list()

  for (stat in stats) {
    if (grepl("^p\\d+$", stat)) {
      prob <- as.numeric(substring(stat, 2)) / 100
      if (is.na(prob) || prob < 0 || prob > 1) {
        stop("Unsupported percentile statistic: ", stat, call. = FALSE)
      }
      stat_list[[toupper(stat)]] <- quantile_expression(var_sym, prob)
    } else if (identical(stat, "iqr")) {
      stat_list[["IQR"]] <- rlang::expr(stats::IQR(!!var_sym, na.rm = TRUE))
    } else {
      stat_list[[toupper(stat)]] <- statistic_expression(var_sym, stat, stat)
    }
  }

  dplyr::summarise(data, !!!stat_list, .groups = "drop")
}

collect_statistics <- function(variable, method) {
  stats <- variable$statistics
  if (!is.null(stats) && length(stats)) {
    return(unlist(stats, use.names = FALSE))
  }

  method_stats <- method$statistics
  if (!is.null(method_stats) && length(method_stats)) {
    return(unlist(method_stats, use.names = FALSE))
  }

  default_statistics(method)
}

select_method_for_variable <- function(methods, variable) {
  if (is.data.frame(methods)) {
    methods <- lapply(seq_len(nrow(methods)), function(i) as.list(methods[i, , drop = FALSE]))
  }

  if (is.null(methods) || !length(methods)) {
    return(list())
  }

  var_name <- variable$name %||% ""

  find_target <- function(method) {
    target <- method$target
    if (is.null(target)) {
      return(NULL)
    }

    if (is.character(target)) {
      return(target)
    }

    if (is.list(target)) {
      target$variable %||% target$name %||% ""
    } else {
      NULL
    }
  }

  for (method in methods) {
    target <- find_target(method)
    if (!is.null(target) && nzchar(target) && identical(target, var_name)) {
      return(method)
    }

    variables <- method$variables
    if (!is.null(variables) && length(variables)) {
      if (is.data.frame(variables)) {
        variables <- lapply(seq_len(nrow(variables)), function(i) as.list(variables[i, , drop = FALSE]))
      }
      vars <- unlist(lapply(variables, function(v) v$name %||% v$variable %||% ""))
      if (var_name %in% vars) {
        return(method)
      }
    }
  }

  methods[[1]]
}

# Paths
root <- normalizePath(".", winslash = "/", mustWork = FALSE)
ars_path <- file.path(root, "ars.json")
data_dir <- file.path(root, "data")

if (!file.exists(ars_path)) {
  stop("Could not locate ARS file at ", ars_path)
}

if (!dir.exists(data_dir)) {
  stop("Could not locate data directory at ", data_dir)
}

# Load ARS
ars <- jsonlite::fromJSON(ars_path, simplifyVector = FALSE)

analyses <- ars$analyses
if (is.null(analyses) || length(analyses) == 0) {
  stop("No analyses were found in ", ars_path)
}

# Load all CSV data in ./data for lookup by dataset name
data_files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)
dataset_list <- setNames(
  lapply(data_files, read.csv, stringsAsFactors = FALSE),
  tools::file_path_sans_ext(basename(data_files))
)

if (length(dataset_list) == 0) {
  stop("No CSV files were located in ", data_dir)
}

for (analysis in analyses) {
  dataset_name <- analysis$dataset %||% stop("Analysis is missing a 'dataset' entry")
  if (!dataset_name %in% names(dataset_list)) {
    stop(
      "Dataset '", dataset_name, "' not found in data directory. Available: ",
      paste(names(dataset_list), collapse = ", ")
    )
  }

  data <- dataset_list[[dataset_name]]

  population <- analysis$population
  if (is.null(population)) {
    population <- list()
  }

  pop_where <- population$where %||% ""
  pop_expr <- parse_population_expr(pop_where)
  pop_label <- population$label %||% population$id %||%
    if (nzchar(pop_where)) pop_where else "All"

  if (!is.null(pop_expr)) {
    data <- dplyr::filter(data, !!pop_expr)
  }

  if (!nrow(data)) {
    stop(
      "Population filter for analysis '",
      analysis$analysis_id,
      " produced an empty dataset"
    )
  }

  grouping <- analysis$grouping
  if (is.data.frame(grouping)) {
    grouping <- lapply(seq_len(nrow(grouping)), function(i) as.list(grouping[i, , drop = FALSE]))
  }

  group_vars <- if (is.null(grouping)) character(0) else {
    vapply(grouping, function(g) g$variable %||% g$name %||% "", character(1))
  }
  group_vars <- group_vars[nzchar(group_vars)]

  missing_group_vars <- setdiff(group_vars, names(data))
  if (length(missing_group_vars)) {
    stop(
      "Grouping variables not found in dataset '",
      dataset_name,
      "': ",
      paste(missing_group_vars, collapse = ", ")
    )
  }

  variables <- analysis$variables
  if (is.null(variables) || length(variables) == 0) {
    stop("Analysis is missing a 'variables' entry")
  }

  if (is.data.frame(variables)) {
    variables <- lapply(seq_len(nrow(variables)), function(i) as.list(variables[i, , drop = FALSE]))
  }

  variables <- Filter(function(x) !is.null(x) && length(x), variables)

  if (!length(variables)) {
    stop("No valid variable definitions found for analysis")
  }

  grouped <- if (length(group_vars)) {
    dplyr::group_by(data, dplyr::across(dplyr::all_of(group_vars)))
  } else {
    data
  }

  traceability <- analysis$traceability
  if (is.null(traceability)) {
    traceability <- list()
  }

  ard_list <- lapply(variables, function(variable) {
    var_name <- variable$name %||% stop("Analysis variable is missing a name")
    if (!var_name %in% names(data)) {
      stop(
        "Variable '",
        var_name,
        "' for analysis '",
        analysis$analysis_id,
        "' not found in dataset '",
        dataset_name,
        "'"
      )
    }

    method <- select_method_for_variable(analysis$methods, variable)

    stats <- summarise_stats(grouped, var_name, collect_statistics(variable, method))

    rename_map <- setNames(group_vars, paste0("group", seq_along(group_vars), "_level"))
    if (length(rename_map)) {
      stats <- dplyr::rename(stats, !!!rename_map)
    }

    id_cols <- names(rename_map)
    ard <- if (length(id_cols)) {
      tidyr::pivot_longer(
        stats,
        cols = -tidyselect::all_of(id_cols),
        names_to = "stat_name",
        values_to = "stat"
      )
    } else {
      tidyr::pivot_longer(
        stats,
        cols = tidyselect::everything(),
        names_to = "stat_name",
        values_to = "stat"
      )
    }

    ard <- dplyr::mutate(
      ard,
      analysis_id = analysis$analysis_id,
      dataset = dataset_name,
      variable = var_name,
      variable_label = variable$label %||% NA_character_,
      population = pop_label,
      method = method_label(method),
      studyid = traceability$studyid %||% NA_character_,
      sap_section = traceability$sap_section %||% NA_character_,
      inputs_ver = traceability$inputs_version %||% NA_character_
    )

    if (length(group_vars)) {
      group_name_map <- setNames(as.list(group_vars), paste0("group", seq_along(group_vars)))
      ard <- dplyr::mutate(ard, !!!group_name_map)
    }

    relocate_cols <- c(
      "analysis_id",
      if (length(group_vars)) paste0("group", seq_along(group_vars)),
      if (length(group_vars)) paste0("group", seq_along(group_vars), "_level"),
      "variable",
      "variable_label",
      "stat_name",
      "stat"
    )

    dplyr::relocate(ard, tidyselect::any_of(relocate_cols))
  })

  ard <- dplyr::bind_rows(ard_list)

  out_name_base <- analysis$analysis_id %||% paste(dataset_name, "SUMMARY", sep = "_")
  out_path <- file.path(root, paste0("ARD_", slugify(out_name_base), ".csv"))

  utils::write.csv(ard, out_path, row.names = FALSE)
  message("Wrote: ", out_path)
}
