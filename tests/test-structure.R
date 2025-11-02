library(testthat)

skip_if_not_installed("jsonlite")

source_test_helpers <- function() {
  helper <- file.path("tests", "helpers", "parity.R")
  if (file.exists(helper)) {
    source(helper, local = TRUE)
  }
}

source_test_helpers()


test_that("placeholder ARD structure test", {
  expect_true(file.exists("docs/ARD_spec.md"))
})
