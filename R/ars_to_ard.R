#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(argparse); library(jsonlite); library(readr)
  library(dplyr); library(tidyr); library(rlang)
})

`%||%` <- function(x, y) if (is.null(x)) y else x

stat_fun <- function(x, s) switch(
  s,
  N=sum(!is.na(x)),
  MEAN=mean(x, na.rm=TRUE),
  SD=sd(x, na.rm=TRUE),
  MEDIAN=median(x, na.rm=TRUE),
  Q1=quantile(x, .25, na.rm=TRUE, names=FALSE),
  Q3=quantile(x, .75, na.rm=TRUE, names=FALSE),
  MIN=min(x, na.rm=TRUE),
  MAX=max(x, na.rm=TRUE),
  SE=sd(x, na.rm=TRUE)/sqrt(sum(!is.na(x))),
  CV=100*sd(x, na.rm=TRUE)/mean(x, na.rm=TRUE),
  stop(paste("Unsupported STAT:", s))
)

compute_one <- function(adsl, spec){
  pop <- dplyr::filter(adsl, !!rlang::parse_expr(spec$population$filter))
  gvars <- spec$group_by
  if (length(gvars) == 0) { pop$.ALL <- "ALL"; gvars <- ".ALL" }
  v <- spec$variable$name

  agg <- pop %>%
    group_by(across(all_of(gvars))) %>%
    summarise(
      N      = stat_fun(.data[[v]], "N"),
      MEAN   = stat_fun(.data[[v]], "MEAN"),
      SD     = stat_fun(.data[[v]], "SD"),
      MEDIAN = stat_fun(.data[[v]], "MEDIAN"),
      Q1     = stat_fun(.data[[v]], "Q1"),
      Q3     = stat_fun(.data[[v]], "Q3"),
      MIN    = stat_fun(.data[[v]], "MIN"),
      MAX    = stat_fun(.data[[v]], "MAX"),
      SE     = stat_fun(.data[[v]], "SE"),
      CV     = stat_fun(.data[[v]], "CV"),
      .groups = "drop"
    )

  out <- agg %>%
    pivot_longer(cols = c(N,MEAN,SD,MEDIAN,Q1,Q3,MIN,MAX,SE,CV),
                 names_to = "STAT", values_to = "VALUE") %>%
    mutate(
      ANALYSISID = spec$analysis_id,
      PARAMCD    = spec$variable$name,
      PARAM      = spec$variable$label %||% spec$variable$name
    )

  dec <- spec$presentation$rounding$decimals %||% NA
  if (!is.na(dec)) out$VALUE <- ifelse(is.finite(out$VALUE), round(out$VALUE, dec), out$VALUE)

  out
}

parser <- ArgumentParser()
parser$add_argument("--ars", required=TRUE)
parser$add_argument("--adsl", required=TRUE)
parser$add_argument("--out", default="out")
args <- parser$parse_args()

ars  <- jsonlite::read_json(args$ars, simplifyVector=TRUE)
adsl <- readr::read_csv(args$adsl, show_col_types=FALSE)

all <- bind_rows(lapply(ars$analyses, \(sp) compute_one(adsl, sp)))
dir.create(args$out, recursive = TRUE, showWarnings = FALSE)

for (aid in unique(all$ANALYSISID)) {
  dat <- dplyr::filter(all, ANALYSISID == aid) %>%
    mutate(
      ENGINE="R",
      ENGINE_VERSION=paste0(R.version$major,".",R.version$minor),
      RUN_DATETIME=format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
    )
  readr::write_csv(dat, file.path(args$out, paste0("ARD_", aid, ".csv")))
}
cat("R engine →", args$out, "\n")
