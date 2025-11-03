# Parity Policy

- **Numeric:** `abs(x - y) <= 1e-12 or rel <= 1e-8`
- **Strings:** exact match; normalize whitespace (`\s+` → single space)
- **Ordering:** canonical sort by all grouping keys, then statistic name
