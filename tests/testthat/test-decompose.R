cells_from <- function(n_M, n_F, w_M, w_F, geo = "XX") {
  k <- length(n_M)
  tibble::tibble(
    geo = geo, cell = rep(paste0("c", seq_len(k)), 2), sex = rep(c("M", "F"), each = k),
    n = c(n_M, n_F), wage = c(w_M, w_F)
  )
}

test_that("between and within add up to the gap exactly", {
  set.seed(42)
  for (i in 1:25) {
    k <- sample(2:12, 1)
    cells <- cells_from(runif(k, 1, 100), runif(k, 1, 100), runif(k, 10, 40), runif(k, 10, 40))
    g <- decompose_gap(cells)$by_geo
    expect_equal(g$between + g$within, g$gap, tolerance = 1e-10)
  }
})

test_that("equal pay inside every cell leaves only the between part", {
  g <- decompose_gap(cells_from(c(80, 20), c(20, 80), c(30, 15), c(30, 15)))$by_geo
  expect_equal(g$within, 0)
  expect_equal(g$gap, 100 * (27 - 18) / 27)
})

test_that("identical distributions leave only the within part", {
  g <- decompose_gap(cells_from(c(50, 50), c(50, 50), c(30, 20), c(27, 18)))$by_geo
  expect_equal(g$between, 0)
  expect_equal(g$within, 10)
})

test_that("a cell with no women adds nothing within", {
  g <- decompose_gap(cells_from(c(50, 50), c(0, 100), c(40, 20), c(NA, 18)))$by_cell
  expect_equal(g$within[g$cell == "c1"], 0)
})

test_that("a suppressed wage drops the cell for both sexes and lowers coverage", {
  cells <- cells_from(c(50, 50), c(50, 50), c(40, 20), c(NA, 18))
  out <- decompose_gap(cells, tibble::tibble(geo = "XX", total_M = 100, total_F = 100))$by_geo
  expect_equal(out$cells, 1)
  expect_equal(out$coverage, 0.5)
})

test_that("the EU figure is the employee-weighted mean", {
  tab <- tibble::tibble(gap = c(10, 20), employees = c(3, 1))
  expect_equal(weighted_eu(tab, "employees", "gap")[["gap"]], 12.5)
})

test_that("the one-sided splits also add up, and bracket the symmetric one", {
  set.seed(7)
  cells <- cells_from(runif(6, 1, 100), runif(6, 1, 100), runif(6, 10, 40), runif(6, 10, 40))
  c <- decompose_gap(cells)$by_cell
  g <- decompose_gap(cells)$by_geo
  expect_equal(sum(c$between_men_wages) + g$within_men_wages, g$gap, tolerance = 1e-10)
  expect_equal(sum(c$between_women_wages) + g$within_women_wages, g$gap, tolerance = 1e-10)
  expect_equal((g$within_men_wages + g$within_women_wages) / 2, g$within, tolerance = 1e-10)
})
