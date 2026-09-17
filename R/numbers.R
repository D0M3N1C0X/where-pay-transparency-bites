# The figures quoted in the article and the paper, computed once. Text never carries a number
# typed by hand.

fmt_pct <- function(x, digits = 1) paste0(formatC(x, format = "f", digits = digits), "%")
fmt_pp <- function(x, digits = 1) paste0(formatC(x, format = "f", digits = digits), " points")
fmt_share <- function(x, digits = 0) paste0(formatC(100 * x, format = "f", digits = digits), "%")

number_word <- function(n) {
  words <- c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve")
  if (n >= 1 && n <= length(words)) words[n] else as.character(n)
}

facts <- function(a) {
  nm <- function(geo) unname(a$names[geo])
  dec <- a$headline_decomposition
  national <- dec |> dplyr::filter(geo %in% EU27)
  eu <- dec |> dplyr::filter(geo == "EU27_2020")
  latest <- a$latest
  eu_latest <- latest |> dplyr::filter(geo == "EU27_2020")
  change <- latest |> dplyr::filter(geo %in% EU27, !is.na(gap_2010)) |> dplyr::mutate(change = latest_gap - gap_2010)
  hidden <- national |> dplyr::mutate(hidden = within - gap) |> dplyr::arrange(dplyr::desc(hidden))
  exposure <- a$exposure
  eu_exp <- exposure |> dplyr::filter(geo == "EU27_2020")
  nat_exp <- exposure |> dplyr::filter(geo %in% EU27) |> dplyr::arrange(share_250)
  size <- a$size_gap |> tidyr::pivot_wider(names_from = band, values_from = gap)
  ctl <- a$control |> dplyr::select(geo, control, gap) |>
    tidyr::pivot_wider(names_from = control, values_from = gap) |> dplyr::filter(!is.na(PUB), !is.na(PRV))
  quadrant <- national |>
    dplyr::left_join(exposure, by = "geo") |>
    dplyr::filter(within > eu$within, share_250 > eu_exp$share_250)
  high_within_small <- national |>
    dplyr::left_join(exposure, by = "geo") |>
    dplyr::filter(within > eu$within, share_250 <= eu_exp$share_250) |>
    dplyr::arrange(dplyr::desc(within))
  finer <- a$decomposition |> dplyr::filter(cells != "sector", usable, geo %in% EU27)
  # The symmetric split is the mean of the two one-sided ones, so one number bounds both.
  ref_dev <- max(abs(national$within_men_wages - national$within))
  it <- a$sector_contributions |> dplyr::filter(geo == "IT")
  age <- a$age |> dplyr::filter(geo %in% EU27) |> dplyr::group_by(age) |> dplyr::summarise(m = stats::median(gap))
  country <- function(code) {
    r <- national |> dplyr::filter(geo == code)
    list(name = nm(code), gap = fmt_pct(r$gap), within = fmt_pct(r$within), between = fmt_pp(r$between))
  }

  list(
    year = a$latest_year,
    eu_2010 = fmt_pct(eu_latest$gap_2010),
    eu_latest = fmt_pct(eu_latest$latest_gap),
    narrowed = sum(change$change < 0),
    widened = paste(nm(change$geo[change$change > 0]), collapse = " and "),
    compared = nrow(change),
    lowest = nm(latest$geo[latest$geo %in% EU27][which.min(latest$latest_gap[latest$geo %in% EU27])]),
    highest = nm(latest$geo[latest$geo %in% EU27][which.max(latest$latest_gap[latest$geo %in% EU27])]),
    lowest_gap = fmt_pct(min(latest$latest_gap[latest$geo %in% EU27])),
    highest_gap = fmt_pct(max(latest$latest_gap[latest$geo %in% EU27])),

    eu_2022 = fmt_pct(eu$gap),
    eu_within = fmt_pct(eu$within),
    eu_between = fmt_pp(eu$between),
    within_above = sum(national$within > national$gap),
    within_above_men = sum(national$within_men_wages > national$gap),
    within_above_women = sum(national$within_women_wages > national$gap),
    between_negative = sum(national$between < 0),
    countries = nrow(national),
    max_diff = formatC(max(abs(national$difference)), format = "f", digits = 2),
    pooled = fmt_pct(a$eu_check$value[3]),
    it = country("IT"), pl = country("PL"), ro = country("RO"), de = country("DE"), lu = country("LU"),
    hidden_top = paste(nm(hidden$geo[1:5]), collapse = ", "),
    # published gap below the EU figure, and at least 5 points more inside sectors
    low_but_hidden = {
      h <- hidden |> dplyr::filter(gap < eu$gap, hidden >= 5)
      paste0(paste(nm(h$geo[-nrow(h)]), collapse = ", "), " and ", nm(h$geo[nrow(h)]))
    },
    it_education = fmt_share(it$share_F[it$nace == "P"]),
    it_education_m = fmt_share(it$share_M[it$nace == "P"]),
    it_health = fmt_share(it$share_F[it$nace == "Q"]),
    it_health_m = fmt_share(it$share_M[it$nace == "Q"]),
    ref_dev = fmt_pp(ref_dev),

    finer_occ = nrow(finer |> dplyr::filter(cells == "occupation")),
    finer_so = nrow(finer |> dplyr::filter(cells == "sector x occupation")),
    finer_min = fmt_pct(min(finer$within)), finer_max = fmt_pct(max(finer$within)),

    eu_250 = fmt_share(eu_exp$share_250),
    eu_50 = fmt_share(eu_exp$share_50_249),
    min_250 = nm(nat_exp$geo[1]), min_250_share = fmt_share(nat_exp$share_250[1]),
    max_250 = nm(nat_exp$geo[nrow(nat_exp)]), max_250_share = fmt_share(nat_exp$share_250[nrow(nat_exp)]),
    size_countries = nrow(size),
    size_wider = sum(size$`250 or more` > size$`10 to 249`),
    size_names = paste(nm(size$geo), collapse = ", "),
    pl_small = fmt_pct(size$`10 to 249`[size$geo == "PL"]),
    pl_large = fmt_pct(size$`250 or more`[size$geo == "PL"]),
    de_small = fmt_pct(size$`10 to 249`[size$geo == "DE"]),
    de_large = fmt_pct(size$`250 or more`[size$geo == "DE"]),

    quadrant = paste(nm(quadrant$geo), collapse = " and "),
    quadrant_n = nrow(quadrant),
    high_within_small = paste(nm(high_within_small$geo), collapse = ", "),
    high_within_small_n = nrow(high_within_small),

    public_lower = sum(ctl$PUB < ctl$PRV),
    public_compared = nrow(ctl),
    public_exception = paste(nm(ctl$geo[ctl$PUB >= ctl$PRV]), collapse = ", "),
    age_young = fmt_pct(age$m[age$age == "Y_LT25"]),
    age_peak = fmt_pct(max(age$m)),
    age_peak_group = AGE_LABELS[[age$age[which.max(age$m)]]],
    retrieved = unique(vapply(a$sources, \(s) s$retrieved, ""))
  )
}
