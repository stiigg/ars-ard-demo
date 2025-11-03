# Filter DSL

## Grammar (EBNF)

```
expr      := or_expr
or_expr   := and_expr { "or" and_expr }
and_expr  := not_expr { "and" not_expr }
not_expr  := [ "not" ] comp_expr
comp_expr := atom (comp_op atom)?
comp_op   := "==" | "!=" | ">" | "<" | ">=" | "<=" | "in" | "between" | "like"
atom      := IDENT | STRING | NUMBER | "(" expr ")"
```

## Semantics & Safety

- String literals must be quoted.
- `in` takes a list: `ARM in ["A","B"]`
- `between` is inclusive: `AGE between 18 65`
- `like` uses wildcard `%` (SAS) / regex anchor (R/Python implement as `grepl`/`str.contains`).

## Examples

- `SAFFL == "Y" and ARM in ["A", "B"]`
- `AGE >= 65 or (CNSR == 0 and AVISITN between 1 5)`
- `not (TRTEMFL == "Y")`
