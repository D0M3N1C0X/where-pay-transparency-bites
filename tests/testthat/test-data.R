# These run on the committed snapshots: they are the evidence behind the article's claims.
withr::local_dir(testthat::test_path("..", ".."))

a <- run_analysis()

test_that("sector cells rebuild the published 2022 gap for all 27 countries", {
  sector <- a$decomposition |> dplyr::filter(cells == "sector", geo %in% EU27)
  expect_equal(nrow(sector), 27)
  expect_true(all(sector$usable))
  expect_lte(max(abs(sector$difference)), RECONCILE_MAX)
})

test_that("the rebuilt EU-27 gap matches the published one", {
  eu <- a$headline_decomposition |> dplyr::filter(geo == "EU27_2020")
  expect_equal(eu$countries, 27)
  expect_lt(abs(eu$gap - eu$official), 0.1)
  expect_lt(abs(a$eu_check$value[2] - a$eu_check$value[1]), 0.1)
})

test_that("finer cells are used only where they cover the workforce", {
  finer <- a$decomposition |> dplyr::filter(cells != "sector", usable)
  expect_true(all(finer$coverage >= COVERAGE_MIN))
})

test_that("every country has a complete split by enterprise size", {
  expect_true(all(a$exposure$complete))
  expect_true(all(a$exposure$share_250 + a$exposure$share_50_249 + a$exposure$share_10_49 - 1 < 1e-9))
})
