# population: list with 'where' (DSL AST or string)
apply_filters <- function(doms, population) {
  if (is.null(population) || is.null(population$where)) return(doms)
  purrr::imap(doms, ~ eval_where_dsl(.x, population$where, domain = .y))
}
