format_and_round <- function(lst, presentation) {
  # apply rounding rules, label mapping, column order
  lst
}

build_metadata <- function(env, spec) {
  tibble::tibble(
    ENGINE = "R",
    ENGINE_VERSION = as.character(getRversion()),
    RUN_DATETIME = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    GIT_SHA = Sys.getenv("GITHUB_SHA", unset = NA),
    INPUTS = paste(env$inputs, collapse = ";"),
    ARS_SPEC_VERSION = spec$version %||% NA,
    DATA_HASHES = paste(env$data_hashes, collapse = ";"),
    SEED = env$seed
  )
}

emit_ard <- function(lst, output_dir, metadata) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  purrr::iwalk(lst, function(df, nm) {
    out <- df
    # attach metadata as first rows or write separate *_meta.json
    readr::write_csv(out, file.path(output_dir, paste0(nm, ".csv")))
  })
}
