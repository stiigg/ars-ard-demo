group_and_summarize <- function(doms, analyses) {
  # analyses: list of analysis blocks, each with grouping, vars, stats
  purrr::map(analyses, function(a) {
    df <- doms[[a$source %||% "ANALYSIS"]]
    g  <- a$group_by %||% character()
    stat_df <- dispatch_stats(df, a)
    dplyr::arrange(stat_df, dplyr::across(dplyr::all_of(g)))
  })
}
