
# R: ARS JSON -> ARD (AGE by ARM)
suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(tidyr)
})

# Paths
root <- normalizePath(".", winslash = "/", mustWork = FALSE)
ars_path <- file.path(root, "ars.json")
adsl_path <- file.path(root, "data", "ADSL.csv")
out_path <- file.path(root, "ARD_DM_AGE.csv")

# Load ARS
ars <- jsonlite::fromJSON(ars_path, simplifyVector = TRUE)
a <- ars$analyses[[1]]

# Load ADSL
ADSL <- read.csv(adsl_path, stringsAsFactors = FALSE)

# Simple population filter (evaluate the 'where' string in data context)
adsl_pop <- subset(ADSL, eval(parse(text = a$population$where)))

# Compute stats
group_var <- a$grouping[[1]]$variable
var_name  <- a$variables[[1]]$name

summ <- adsl_pop |>
  group_by(.data[[group_var]]) |>
  summarise(
    N = sum(!is.na(.data[[var_name]])),
    MEAN = mean(.data[[var_name]], na.rm = TRUE),
    SD = sd(.data[[var_name]], na.rm = TRUE),
    MEDIAN = median(.data[[var_name]], na.rm = TRUE),
    P25 = quantile(.data[[var_name]], 0.25, na.rm = TRUE, names = FALSE),
    P75 = quantile(.data[[var_name]], 0.75, na.rm = TRUE, names = FALSE),
    MIN = min(.data[[var_name]], na.rm = TRUE),
    MAX = max(.data[[var_name]], na.rm = TRUE),
    .groups = "drop"
  ) |>
  rename(group1_level = !!group_var)

# Shape to ARD
ard <- summ |>
  pivot_longer(cols = -group1_level, names_to = "stat_name", values_to = "stat") |>
  mutate(
    analysis_id  = a$analysis_id,
    dataset      = a$dataset,
    variable     = var_name,
    group1       = group_var,
    population   = "SAFETY",
    method       = "Descriptive statistics",
    studyid      = a$traceability$studyid,
    sap_section  = a$traceability$sap_section,
    inputs_ver   = a$traceability$inputs_version
  ) |>
  relocate(analysis_id, group1, group1_level, variable, stat_name, stat)

# Write ARD
write.csv(ard, out_path, row.names = FALSE)

message("Wrote: ", out_path)
