# Splitting a gender pay gap into "where women and men work" and "how they are paid there".
#
# For cells c (sectors, occupations...), with employee shares s and mean hourly earnings w:
#
#   W_M - W_F = sum_c (s_Mc - s_Fc) * (w_Mc + w_Fc) / 2      between cells (composition)
#             + sum_c (s_Mc + s_Fc) / 2 * (w_Mc - w_Fc)      within cells
#
# The symmetric weights make the two parts add up to the total exactly, with no choice of a
# reference sex (the index-number problem of the classic Oaxaca split). Both parts are
# expressed in percentage points of men's mean hourly earnings, so they sum to the gap.

# cells: one row per geo x cell x sex, with columns geo, cell, sex ("M"/"F"), n, wage.
# A cell is dropped for both sexes when either sex has an unknown count, or has workers but a
# suppressed wage; coverage then says how much employment that loses.
decompose_gap <- function(cells, totals = NULL) {
  incomplete <- cells |>
    dplyr::filter(is.na(n) | (n > 0 & is.na(wage))) |>
    dplyr::distinct(geo, cell)
  wide <- cells |>
    dplyr::anti_join(incomplete, by = c("geo", "cell")) |>
    dplyr::select(geo, cell, sex, n, wage) |>
    tidyr::pivot_wider(names_from = sex, values_from = c(n, wage)) |>
    dplyr::mutate(
      n_M = dplyr::coalesce(n_M, 0), n_F = dplyr::coalesce(n_F, 0),
      # A cell with no workers of one sex has no wage for them: borrow the other sex's wage,
      # so the cell adds nothing to the within part and weighs in the between part only.
      wage_M = dplyr::if_else(n_M == 0 | is.na(wage_M), wage_F, wage_M),
      wage_F = dplyr::if_else(n_F == 0 | is.na(wage_F), wage_M, wage_F)
    ) |>
    dplyr::filter(!is.na(wage_M), !is.na(wage_F))

  by_cell <- wide |>
    dplyr::group_by(geo) |>
    dplyr::mutate(
      s_M = n_M / sum(n_M), s_F = n_F / sum(n_F),
      mean_M = sum(s_M * wage_M), mean_F = sum(s_F * wage_F),
      between = 100 * (s_M - s_F) * (wage_M + wage_F) / 2 / mean_M,
      within = 100 * (s_M + s_F) / 2 * (wage_M - wage_F) / mean_M,
      # The two classic one-sided splits, kept as a sensitivity check.
      between_men_wages = 100 * (s_M - s_F) * wage_M / mean_M,
      within_men_wages = 100 * s_F * (wage_M - wage_F) / mean_M,
      between_women_wages = 100 * (s_M - s_F) * wage_F / mean_M,
      within_women_wages = 100 * s_M * (wage_M - wage_F) / mean_M
    ) |>
    dplyr::ungroup()

  by_geo <- by_cell |>
    dplyr::group_by(geo) |>
    dplyr::summarise(
      employees_M = sum(n_M), employees_F = sum(n_F),
      mean_M = dplyr::first(mean_M), mean_F = dplyr::first(mean_F),
      gap = 100 * (mean_M - mean_F) / mean_M,
      between = sum(between), within = sum(within),
      within_men_wages = sum(within_men_wages), within_women_wages = sum(within_women_wages),
      cells = dplyr::n(),
      .groups = "drop"
    )

  if (!is.null(totals)) {
    by_geo <- by_geo |>
      dplyr::left_join(totals, by = "geo") |>
      dplyr::mutate(coverage = pmin((employees_M) / total_M, (employees_F) / total_F)) |>
      dplyr::select(-total_M, -total_F)
  }
  list(by_geo = by_geo, by_cell = by_cell)
}

# Eurostat compiles the EU gap "as the weighted mean of the gender pay gaps in EU Member States,
# where the numbers of employees in Member States are weights" (metadata earn_grgpg2_esms), not
# as the gap of pooled EU earnings, which would mix countries' wage levels. Aggregate the same way.
weighted_eu <- function(by_geo, weight, columns) {
  w <- by_geo[[weight]]
  vapply(columns, function(col) sum(by_geo[[col]] * w) / sum(w), numeric(1))
}
