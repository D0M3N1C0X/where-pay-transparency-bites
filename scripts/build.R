# Runs the analysis from the snapshots and writes every output: tidy tables, the README
# figures and the dashboard's data. Deterministic: same snapshots, same files.
#
#   Rscript scripts/build.R

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

a <- run_analysis()
nm <- function(geo) unname(a$names[geo])
dir.create("outputs", showWarnings = FALSE)

write_out <- function(df, name) {
  df <- df |> mutate(across(where(is.double), \(x) round(x, 4)))
  readr::write_csv(df, file.path("outputs", paste0(name, ".csv")), na = "")
}

# Tables ------------------------------------------------------------------------------------
write_out(a$headline |> select(geo, year, gap, flag) |> arrange(geo, year), "gap_series")
write_out(a$latest |> arrange(geo), "gap_latest")
write_out(a$by_sector_latest |> select(geo, nace, year, gap, flag) |> arrange(geo, nace), "gap_by_sector_latest")
write_out(a$control |> select(geo, control, year, gap, flag) |> arrange(geo, control), "gap_by_control_latest")
write_out(a$age |> select(geo, age, year, gap, flag) |> arrange(geo, age), "gap_by_age_latest")
write_out(a$decomposition |> select(cells, geo, gap, official, difference, between, within, coverage, usable) |>
            arrange(cells, geo), "decomposition_2022")
write_out(a$headline_decomposition |> select(geo, gap, official, between, within, usable, countries) |> arrange(geo),
          "decomposition_sector_2022")
write_out(a$sector_contributions |> arrange(geo, nace), "sector_contributions_2022")
write_out(a$exposure |> arrange(geo), "size_exposure_2022")
write_out(a$size_gap |> arrange(geo, band), "gap_by_size_2022")
write_out(a$eu_check, "eu_aggregate_check")

# Figures for the README ---------------------------------------------------------------------
save_svg(fig_hidden(a), "figures/01_hidden_gap.svg", width = 8, height = 7.5)
save_svg(fig_bites(a), "figures/02_where_it_bites.svg", width = 8, height = 6)
save_svg(fig_size(a), "figures/03_gap_by_size.svg", width = 8, height = 3.8)
save_svg(fig_trend(a), "figures/04_trend.svg", width = 8, height = 4.2)
save_svg(fig_control(a), "figures/05_public_private.svg", width = 8, height = 6.2)
save_svg(fig_age(a), "figures/06_age.svg", width = 8, height = 4.2)

# Dashboard data -----------------------------------------------------------------------------
records <- function(df) purrr::transpose(df |> mutate(across(where(is.double), \(x) round(x, 3))))
dashboard <- list(
  meta = list(
    latest_year = a$latest_year,
    retrieved = unique(vapply(a$sources, \(s) s$retrieved, "")),
    coverage_min = COVERAGE_MIN,
    reconcile_max = RECONCILE_MAX
  ),
  countries = records(tibble(geo = c(EU27, "EU27_2020"), name = nm(c(EU27, "EU27_2020")))),
  sections = records(tibble(code = SECTIONS, name = unname(labels_of("earn_ses22_02", "nace_r2")[SECTIONS]))),
  series = records(a$headline |> select(geo, year, gap)),
  decomposition = records(a$headline_decomposition |> filter(usable) |> select(geo, official, gap, between, within)),
  finer = records(a$decomposition |> filter(usable, cells != "sector", geo %in% EU27) |> select(cells, geo, gap, between, within)),
  exposure = records(a$exposure |> select(geo, share_250, share_50_249, share_10_49)),
  size_gap = records(a$size_gap),
  sectors = records(a$sector_contributions |> select(geo, nace, share_M, share_F, gap, between, within)),
  sector_latest = records(a$by_sector_latest |> filter(!is.na(gap)) |> select(geo, nace, gap)),
  control = records(a$control |> select(geo, control, gap)),
  age = records(a$age |> select(geo, age, gap))
)
json <- jsonlite::toJSON(dashboard, auto_unbox = TRUE, digits = NA, pretty = FALSE)
json <- gsub("</", "<\\/", json, fixed = TRUE)   # never close the <script> element early
template <- paste(readLines("dashboard/template.html", encoding = "UTF-8"), collapse = "\n")
page <- sub("/*DATA*/", json, template, fixed = TRUE)
writeLines(page, "dashboard/index.html", useBytes = TRUE)

message("outputs/: ", length(list.files("outputs")), " tables; figures/: ", length(list.files("figures")),
        " charts; dashboard/index.html (", round(file.size("dashboard/index.html") / 1024), " KB)")
