#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(argparse); library(jsonlite); library(readr); library(dplyr); library(tidyr); library(rlang)
})

`%||%` <- function(x, y) if (is.null(x)) y else x

compute_one <- function(adsl, spec) {
  pop <- dplyr::filter(adsl, !!parse_expr(spec$population$filter))
  gvars <- if (length(spec$group_by) == 0) {
    pop$.ALL <- "ALL"; ".ALL"
  } else spec$group_by
  v <- spec$variable$name

  stat_fun <- function(x, s) switch(
    s, N=sum(!is.na(x)), MEAN=mean(x, na.rm=TRUE), SD=sd(x, na.rm=TRUE),
    MEDIAN=median(x, na.rm=TRUE), Q1=quantile(x, .25, na.rm=TRUE, names=FALSE),
    Q3=quantile(x, .75, na.rm=TRUE, names=FALSE), MIN=min(x, na.rm=TRUE),
    MAX=max(x, na.rm=TRUE), SE=sd(x, na.rm=TRUE)/sqrt(sum(!is.na(x))),
    CV=100*sd(x, na.rm=TRUE)/mean(x, na.rm=TRUE),
    stop(paste("Unsupported STAT:", s))
  )

  out <- pop |>
    group_by(across(all_of(gvars))) |>
    reframe(bind_rows(lapply(spec$statistics, \(s) tibble(STAT=s, VALUE=stat_fun(.data[[v]], s)))), .groups="drop") |>
    mutate(
      ANALYSISID = spec$analysis_id,
      PARAMCD    = spec$variable$name,
      PARAM      = spec$variable$label %||% spec$variable$name
    )

  if (!is.null(spec$presentation$rounding$decimals)) {
    out <- out |> mutate(VALUE = ifelse(is.finite(VALUE), round(VALUE, spec$presentation$rounding$decimals), VALUE))
  }

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
dir.create(args$out, recursive=TRUE, showWarnings=FALSE)
for (aid in unique(all$ANALYSISID)) {
  dat <- filter(all, ANALYSISID==aid) |>
    mutate(ENGINE="R", ENGINE_VERSION=paste0(R.version$major,".",R.version$minor),
           RUN_DATETIME=format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
  readr::write_csv(dat, file.path(args$out, paste0("ARD_", aid, ".csv")))
}
cat("R engine →", args$out, "\n")
