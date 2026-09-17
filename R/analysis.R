# Every result in the article, the paper and the dashboard comes from run_analysis().

COVERAGE_MIN <- 0.95   # share of each sex's employees the cells must cover
RECONCILE_MAX <- 0.5   # percentage points between the rebuilt and the published 2022 gap

usable <- function(by_geo, official) {
  by_geo |>
    dplyr::left_join(official, by = "geo") |>
    dplyr::mutate(
      difference = gap - official,
      usable = !is.na(coverage) & coverage >= COVERAGE_MIN & abs(difference) <= RECONCILE_MAX
    )
}

with_eu <- function(tab, weights) {
  national <- tab |> dplyr::filter(geo %in% EU27, usable) |> dplyr::left_join(weights, by = "geo")
  eu <- weighted_eu(national, "employees", c("gap", "between", "within"))
  dplyr::bind_rows(
    tab |> dplyr::filter(geo %in% EU27),
    tibble::tibble(geo = "EU27_2020", gap = eu[["gap"]], between = eu[["between"]], within = eu[["within"]],
                   official = tab$official[tab$geo == "EU27_2020"][1], usable = TRUE,
                   countries = nrow(national))
  )
}

run_analysis <- function() {
  names <- country_names()
  official <- official_2022()
  totals <- totals_2022()
  weights <- totals |> dplyr::transmute(geo, employees = total_M + total_F)

  # 1. Published gap, 2010 onwards
  series <- gap_series()
  headline <- series |> dplyr::filter(nace == "B-S_X_O", !is.na(gap))
  latest_year <- max(headline$year)
  latest <- headline |>
    dplyr::group_by(geo) |>
    dplyr::slice_max(year, n = 1) |>
    dplyr::ungroup() |>
    dplyr::select(geo, latest_year = year, latest_gap = gap)
  first <- headline |>
    dplyr::filter(year == 2010L) |>
    dplyr::select(geo, gap_2010 = gap)

  by_sector_latest <- series |>
    dplyr::filter(nace %in% SECTIONS, year == latest_year, geo %in% c(EU27, "EU27_2020"))

  control <- gap_by_control() |>
    dplyr::filter(year == latest_year, control %in% c("PUB", "PRV"), !is.na(gap))
  age <- gap_by_age() |>
    dplyr::filter(year == latest_year, !is.na(gap))

  # 2. Decompositions of the 2022 gap
  sector <- decompose_gap(sector_cells(), totals)
  occupation <- decompose_gap(occupation_cells(), totals)
  sector_occupation <- decompose_gap(sector_occupation_cells(), totals)

  decomposition <- dplyr::bind_rows(
    usable(sector$by_geo, official) |> dplyr::mutate(cells = "sector"),
    usable(occupation$by_geo, official) |> dplyr::mutate(cells = "occupation"),
    usable(sector_occupation$by_geo, official) |> dplyr::mutate(cells = "sector x occupation")
  )
  headline_decomposition <- with_eu(decomposition |> dplyr::filter(cells == "sector"), weights)

  sector_contributions <- sector$by_cell |>
    dplyr::filter(geo %in% EU27) |>
    dplyr::semi_join(headline_decomposition |> dplyr::filter(usable), by = "geo") |>
    dplyr::transmute(geo, nace = cell, share_M = s_M, share_F = s_F, wage_M, wage_F,
                     gap = 100 * (wage_M - wage_F) / wage_M, between, within)

  # 3. Who reports every year from June 2027
  exposure <- size_exposure()
  size_gap <- gap_by_size() |> dplyr::filter(geo %in% EU27)

  # The EU aggregates Eurostat publishes, next to the ones rebuilt here
  eu_check <- tibble::tibble(
    measure = c("Published EU-27 gap, 2022", "Employee-weighted mean of the published national gaps",
                "Gap of pooled EU earnings (not the published method)"),
    value = c(official$official[official$geo == "EU27_2020"],
              weighted_eu(official |> dplyr::filter(geo %in% EU27) |> dplyr::left_join(weights, by = "geo"),
                          "employees", "official")[["official"]],
              sector$by_geo$gap[sector$by_geo$geo == "EU27_2020"])
  )

  list(
    names = names,
    latest_year = latest_year,
    headline = headline,
    latest = latest |> dplyr::left_join(first, by = "geo"),
    by_sector_latest = by_sector_latest,
    control = control,
    age = age,
    decomposition = decomposition,
    headline_decomposition = headline_decomposition,
    sector_contributions = sector_contributions,
    exposure = exposure,
    size_gap = size_gap,
    eu_check = eu_check,
    sources = lapply(c("earn_gr_gpgr2", "earn_gr_gpgr2ct", "earn_gr_gpgr2ag", "earn_ses22_02", "earn_ses22_13",
                       "earn_ses22_47", "earn_ses22_54", "earn_ses22_18", "earn_ses22_53"),
                     function(code) attr(read_dataset(code), "source"))
  )
}
