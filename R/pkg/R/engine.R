#' Top-level runner
#' @param spec_path path to ARS JSON
#' @param input_dir directory containing input sources
#' @param output_dir directory to write ARD CSVs
#' @param seed integer for determinism
#' @export
run_ars <- function(spec_path, input_dir, output_dir, seed = 123) {
  set.seed(seed)
  spec  <- parse_spec(spec_path)
  env   <- build_run_env(spec_path, input_dir, seed)
  data  <- load_sources(spec, input_dir)             # list of tibbles by domain
  data  <- apply_filters(data, spec$population)      # DSL over domains
  data  <- apply_joins(data, spec$joins)             # left/inner/full
  out   <- group_and_summarize(data, spec$analyses)  # list of ARD tibbles
  out   <- format_and_round(out, spec$presentation)  # rounding/labels/order
  emit_ard(out, output_dir, metadata = build_metadata(env, spec))
  invisible(TRUE)
}
