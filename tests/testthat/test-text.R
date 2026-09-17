# The abstract and the README quote figures by hand; these tests keep them honest.
withr::local_dir(testthat::test_path("..", ".."))

f <- facts(run_analysis())
abstract <- paste(readLines("paper/paper.qmd"), collapse = " ")

test_that("the paper's abstract quotes current figures", {
  for (x in c(paste0("gap in ", f$within_above, " countries"), paste0("is ", f$eu_within, " for the EU"),
              paste0("published ", f$eu_2022))) {
    expect_true(grepl(x, abstract, fixed = TRUE), info = x)
  }
})

test_that("the README quotes current figures", {
  readme <- paste(readLines("README.md"), collapse = " ")
  expected <- c(
    paste0("was ", f$eu_2022, " in 2022; inside the same sector it was ", f$eu_within),
    paste0("in ", f$within_above, " of the ", f$countries, " Member States"),
    paste0("Italy publishes ", f$it$gap, " and has ", f$it$within),
    paste0("Poland ", f$pl$gap, " against ", f$pl$within),
    paste0("Romania ", f$ro$gap, " against ", f$ro$within),
    paste0(f$eu_250, " of employees"),
    paste0("In all ", f$size_countries, " countries"),
    paste0(f$pl_large, " against ", f$pl_small, " in Poland"),
    paste0("largest difference ", f$max_diff, " points"),
    paste0("would give ", f$pooled)
  )
  for (x in expected) expect_true(grepl(x, readme, fixed = TRUE), info = x)
})
