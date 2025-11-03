#' Parse and validate ARS spec JSON
#' @keywords internal
parse_spec <- function(path) {
  stopifnot(file.exists(path))
  spec <- jsonlite::read_json(path, simplifyVector = TRUE)
  validate_spec_types(spec)  # custom typed checks
  spec
}
