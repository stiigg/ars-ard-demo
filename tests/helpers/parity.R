compare_ard <- function(a, b, tol = 1e-8) {
  key <- c("ANALYSISID", "PARAMCD", "STAT", "POPNAME", "ANLGRP")
  stopifnot(all(key %in% names(a)), all(key %in% names(b)))
  merged <- merge(a, b, by = key, suffixes = c(".r", ".sas"), all = TRUE)
  merged$delta <- abs(merged$VALUE.r - merged$VALUE.sas)
  bad <- subset(merged, delta > tol | is.na(VALUE.r) | is.na(VALUE.sas))
  list(ok = nrow(bad) == 0, bad = bad)
}
