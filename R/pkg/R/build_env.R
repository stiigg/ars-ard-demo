build_run_env <- function(spec_path, input_dir, seed) {
  list(
    spec_path = spec_path,
    input_dir = input_dir,
    seed = seed,
    inputs = character(),
    data_hashes = character()
  )
}

eval_where_dsl <- function(df, where, domain) {
  df
}
