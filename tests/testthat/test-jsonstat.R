test_that("a JSON-stat cube is read in row-major order, last dimension fastest", {
  j <- list(
    id = list("sex", "geo"),
    size = list(2, 3),
    dimension = list(
      sex = list(category = list(index = list(M = 0, F = 1))),
      geo = list(category = list(index = list(IT = 0, PL = 1, DE = 2)))
    ),
    value = list(`0` = 10, `1` = 11, `2` = 12, `3` = 20, `5` = 22),
    status = list(`4` = "c")
  )
  d <- parse_jsonstat(j)
  expect_equal(nrow(d), 6)
  expect_equal(d$value[d$sex == "M" & d$geo == "PL"], 11)
  expect_equal(d$value[d$sex == "F" & d$geo == "DE"], 22)
  expect_true(is.na(d$value[d$sex == "F" & d$geo == "PL"]))
  expect_equal(d$flag[d$sex == "F" & d$geo == "PL"], "c")
})

test_that("a dense value array is read too", {
  j <- list(
    id = list("geo"), size = list(2),
    dimension = list(geo = list(category = list(index = list(IT = 0, PL = 1)))),
    value = list(1.5, NULL), status = list()
  )
  d <- parse_jsonstat(j)
  expect_equal(d$value, c(1.5, NA))
})
