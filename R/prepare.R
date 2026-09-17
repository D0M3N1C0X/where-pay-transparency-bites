# Tidy tables built from the snapshots. Scope follows the official gap: enterprises with 10 or
# more employees (size class GE10), economic activities B to S excluding O.

SECTIONS <- c("B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "P", "Q", "R", "S")
OCCUPATIONS <- paste0("OC", 0:9)
SIZE_CLASSES <- c("10-49", "50-249", "250-499", "500-999", "GE1000")
REPORTING_ANNUAL <- c("250-499", "500-999", "GE1000")   # 250 workers or more: yearly from 2027

labels_of <- function(code, dim) {
  j <- jsonlite::fromJSON(raw_path(code), simplifyVector = FALSE)$response
  unlist(j$dimension[[dim]]$category$label)
}

country_names <- function() {
  lab <- labels_of("earn_ses22_02", "geo")
  lab[["EU27_2020"]] <- "EU-27"
  lab[["DE"]] <- "Germany"       # Eurostat labels carry historical qualifiers
  lab
}

# Official gap series ------------------------------------------------------------------------

gap_series <- function() {
  read_dataset("earn_gr_gpgr2") |>
    dplyr::transmute(geo, nace = nace_r2, year = as.integer(time), gap = value, flag)
}

gap_by_control <- function() {
  read_dataset("earn_gr_gpgr2ct") |>
    dplyr::transmute(geo, control = owner, year = as.integer(time), gap = value, flag)
}

gap_by_age <- function() {
  read_dataset("earn_gr_gpgr2ag") |>
    dplyr::transmute(geo, age, year = as.integer(time), gap = value, flag)
}

official_2022 <- function() {
  gap_series() |> dplyr::filter(nace == "B-S_X_O", year == 2022L) |> dplyr::select(geo, official = gap)
}

# SES 2022 cells -----------------------------------------------------------------------------

totals_2022 <- function() {
  read_dataset("earn_ses22_02") |>
    dplyr::filter(sizeclas == "GE10", nace_r2 == "B-S_X_O", sex %in% c("M", "F")) |>
    dplyr::select(geo, sex, value) |>
    tidyr::pivot_wider(names_from = sex, values_from = value, names_prefix = "total_")
}

sector_cells <- function() {
  wages <- read_dataset("earn_ses22_13") |>
    dplyr::filter(sizeclas == "GE10", sex %in% c("M", "F"), nace_r2 %in% SECTIONS) |>
    dplyr::select(geo, cell = nace_r2, sex, wage = value)
  counts <- read_dataset("earn_ses22_02") |>
    dplyr::filter(sizeclas == "GE10", sex %in% c("M", "F"), nace_r2 %in% SECTIONS) |>
    dplyr::select(geo, cell = nace_r2, sex, n = value)
  dplyr::inner_join(counts, wages, by = c("geo", "cell", "sex"))
}

occupation_cells <- function() {
  wages <- read_dataset("earn_ses22_47") |>
    dplyr::filter(sizeclas == "GE10", nace_r2 == "B-S_X_O", sex %in% c("M", "F"), isco08 %in% OCCUPATIONS) |>
    dplyr::select(geo, cell = isco08, sex, wage = value)
  counts <- read_dataset("earn_ses22_54") |>
    dplyr::filter(sizeclas == "GE10", nace_r2 == "B-S_X_O", sex %in% c("M", "F"), isco08 %in% OCCUPATIONS) |>
    dplyr::select(geo, cell = isco08, sex, n = value)
  dplyr::inner_join(counts, wages, by = c("geo", "cell", "sex"))
}

sector_occupation_cells <- function() {
  wages <- read_dataset("earn_ses22_47") |>
    dplyr::filter(sizeclas == "GE10", nace_r2 %in% SECTIONS, sex %in% c("M", "F"), isco08 %in% OCCUPATIONS) |>
    dplyr::transmute(geo, cell = paste(nace_r2, isco08, sep = ":"), sex, wage = value)
  counts <- read_dataset("earn_ses22_54") |>
    dplyr::filter(sizeclas == "GE10", nace_r2 %in% SECTIONS, sex %in% c("M", "F"), isco08 %in% OCCUPATIONS) |>
    dplyr::transmute(geo, cell = paste(nace_r2, isco08, sep = ":"), sex, n = value)
  dplyr::inner_join(counts, wages, by = c("geo", "cell", "sex"))
}

# Enterprise size: who reports every year from June 2027 ------------------------------------

size_exposure <- function() {
  read_dataset("earn_ses22_53") |>
    dplyr::filter(isco08 == "TOTAL", sex == "T", sizeclas %in% SIZE_CLASSES) |>
    dplyr::group_by(geo) |>
    dplyr::summarise(
      complete = all(!is.na(value)),
      employees = sum(value),
      share_250 = sum(value[sizeclas %in% REPORTING_ANNUAL]) / employees,
      share_50_249 = sum(value[sizeclas == "50-249"]) / employees,
      share_10_49 = sum(value[sizeclas == "10-49"]) / employees,
      .groups = "drop"
    )
}

# The gap inside employers of 250 or more, where earnings by size class are published.
gap_by_size <- function() {
  wages <- read_dataset("earn_ses22_18") |>
    dplyr::filter(isco08 == "TOTAL", sex %in% c("M", "F"), sizeclas %in% SIZE_CLASSES) |>
    dplyr::select(geo, sizeclas, sex, wage = value)
  counts <- read_dataset("earn_ses22_53") |>
    dplyr::filter(isco08 == "TOTAL", sex %in% c("M", "F"), sizeclas %in% SIZE_CLASSES) |>
    dplyr::select(geo, sizeclas, sex, n = value)
  dplyr::inner_join(counts, wages, by = c("geo", "sizeclas", "sex")) |>
    dplyr::mutate(band = dplyr::if_else(sizeclas %in% REPORTING_ANNUAL, "250 or more", "10 to 249")) |>
    dplyr::group_by(geo) |>
    dplyr::filter(all(!is.na(wage)), all(!is.na(n))) |>
    dplyr::group_by(geo, band, sex) |>
    dplyr::summarise(mean = sum(n * wage) / sum(n), .groups = "drop") |>
    tidyr::pivot_wider(names_from = sex, values_from = mean) |>
    dplyr::mutate(gap = 100 * (M - F) / M) |>
    dplyr::select(geo, band, gap)
}
