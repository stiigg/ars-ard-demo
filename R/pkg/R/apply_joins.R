apply_joins <- function(doms, joins) {
  if (is.null(joins) || length(joins) == 0) return(doms)
  # returns a named list with a composite 'ANALYSIS' table by convention
  out <- doms
  for (j in joins) {
    left  <- out[[j$left$source]]
    right <- out[[j$right$source]]
    out[["ANALYSIS"]] <- dplyr::full_join(left, right, by = j$on, relationship = "many-to-many")
    # support left/inner/full via j$type
  }
  out
}
