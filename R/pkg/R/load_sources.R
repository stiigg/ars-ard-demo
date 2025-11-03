#' Load study domains referenced in spec$sources
#' @keywords internal
load_sources <- function(spec, input_dir) {
  purrr::map(setNames(spec$sources$name, spec$sources$name), function(nm) {
    p <- file.path(input_dir, paste0(nm, ".csv"))
    readr::read_csv(p, show_col_types = FALSE)
  })
}
