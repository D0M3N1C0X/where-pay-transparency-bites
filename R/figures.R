# Every chart, built from run_analysis() output. The article, the paper and the README use the
# same functions, so a figure cannot differ between them.

country_label <- function(a, geo) unname(a$names[geo])

dumbbell <- function(data, left, right, left_label, right_label, highlight = NULL, limits = NULL) {
  p <- ggplot2::ggplot(data, ggplot2::aes(y = country))
  if (!is.null(highlight) && length(highlight)) {
    p <- p + ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = highlight - 0.5, ymax = highlight + 0.5,
                               fill = "#f0efec")
  }
  values <- stats::setNames(c(PALETTE$between, PALETTE$within), c(left_label, right_label))
  p +
    ggplot2::geom_segment(ggplot2::aes(x = .data[[left]], xend = .data[[right]], yend = country),
                          colour = PALETTE$context, linewidth = 0.6) +
    ggplot2::geom_point(ggplot2::aes(x = .data[[left]], colour = left_label), size = 2.4) +
    ggplot2::geom_point(ggplot2::aes(x = .data[[right]], colour = right_label), size = 2.4) +
    ggplot2::scale_colour_manual(values = values, breaks = c(left_label, right_label)) +
    ggplot2::scale_x_continuous(labels = \(x) paste0(x, "%"), limits = limits) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_bites()
}

fig_trend <- function(a) {
  national <- a$headline |> dplyr::filter(geo %in% EU27, year >= 2010L)
  band <- national |>
    dplyr::group_by(year) |>
    dplyr::summarise(lo = stats::quantile(gap, 0.25), hi = stats::quantile(gap, 0.75), .groups = "drop")
  eu <- a$headline |> dplyr::filter(geo == "EU27_2020", year >= 2010L)
  ends <- eu |> dplyr::filter(year %in% range(year))
  label_at <- band |> dplyr::filter(year == 2021L)
  ggplot2::ggplot() +
    ggplot2::geom_ribbon(data = band, ggplot2::aes(x = year, ymin = lo, ymax = hi), fill = PALETTE$within, alpha = 0.1) +
    ggplot2::geom_line(data = eu, ggplot2::aes(x = year, y = gap), colour = PALETTE$within, linewidth = 0.9) +
    ggplot2::geom_point(data = ends, ggplot2::aes(x = year, y = gap), colour = PALETTE$within, size = 2.6) +
    ggplot2::geom_text(data = ends, ggplot2::aes(x = year, y = gap, label = pct_label(gap)),
                       vjust = -1, colour = PALETTE$ink, size = 3.4) +
    ggplot2::annotate("text", x = 2021, y = label_at$hi + 0.9, label = "Middle half of the 27 countries",
                      colour = PALETTE$ink2, size = 3) +
    ggplot2::scale_y_continuous(labels = \(x) paste0(x, "%"), limits = c(0, NA)) +
    ggplot2::scale_x_continuous(breaks = seq(2010, a$latest_year, 2)) +
    ggplot2::labs(title = sprintf("The EU gap fell from %s in 2010 to %s in %d", pct_label(ends$gap[1]),
                                  pct_label(ends$gap[2]), a$latest_year),
                  subtitle = "Unadjusted gender pay gap, EU-27, enterprises with 10+ employees",
                  x = NULL, y = NULL, caption = "Source: Eurostat, earn_gr_gpgr2 (NACE B-S excluding O).") +
    theme_bites()
}

fig_hidden <- function(a) {
  dec <- a$headline_decomposition |>
    dplyr::filter(usable) |>
    dplyr::mutate(country = country_label(a, geo)) |>
    dplyr::arrange(within) |>
    dplyr::mutate(country = factor(country, levels = country))
  dumbbell(dec, "gap", "within", "Published gap, 2022", "Gap within the same sector",
           highlight = which(levels(dec$country) == "EU-27")) +
    ggplot2::labs(title = "The published gap understates the gap inside sectors",
                  subtitle = "Gender pay gap on mean hourly earnings, enterprises with 10+ employees, 2022",
                  caption = "Within-sector part of a symmetric two-fold decomposition over 17 NACE sections.\nSource: Eurostat SES 2022.")
}

fig_bites <- function(a) {
  bites <- a$headline_decomposition |>
    dplyr::filter(usable, geo %in% EU27) |>
    dplyr::left_join(a$exposure, by = "geo")
  eu <- a$headline_decomposition |> dplyr::filter(geo == "EU27_2020") |> dplyr::left_join(a$exposure, by = "geo")
  ggplot2::ggplot(bites, ggplot2::aes(x = within, y = 100 * share_250)) +
    ggplot2::geom_vline(xintercept = eu$within, colour = PALETTE$grid, linewidth = 0.6) +
    ggplot2::geom_hline(yintercept = 100 * eu$share_250, colour = PALETTE$grid, linewidth = 0.6) +
    ggplot2::annotate("text", x = eu$within, y = min(100 * bites$share_250) - 1.5, label = " EU-27", hjust = 0,
                      colour = PALETTE$muted, size = 2.8) +
    ggplot2::annotate("text", x = max(bites$within), y = 100 * eu$share_250, label = "EU-27", vjust = -0.5,
                      hjust = 1, colour = PALETTE$muted, size = 2.8) +
    ggplot2::geom_point(colour = PALETTE$within, size = 2.6) +
    ggrepel::geom_text_repel(ggplot2::aes(label = geo), colour = PALETTE$ink2, size = 3, seed = 1,
                             point.padding = 0.2, box.padding = 0.25, min.segment.length = 0.3,
                             segment.colour = PALETTE$context) +
    ggplot2::annotate("text", x = max(bites$within), y = max(100 * bites$share_250) + 3, hjust = 1,
                      label = "Where it bites: wide gaps inside sectors,\nmost employees in annual reporters",
                      colour = PALETTE$ink, size = 3.3, fontface = "bold", lineheight = 0.95) +
    ggplot2::scale_x_continuous(labels = \(x) paste0(x, "%")) +
    ggplot2::scale_y_continuous(labels = \(x) paste0(x, "%")) +
    ggplot2::labs(title = "Where pay transparency bites",
                  subtitle = "Within-sector gender pay gap (x) and share of employees\nin enterprises of 250 or more (y), 2022",
                  x = "Gender pay gap within the same sector", y = "Employees in enterprises of 250+",
                  caption = paste("Eurostat country codes (EL = Greece). Enterprises with 10+ employees,",
                                  "NACE B-S excluding O.\nSource: Eurostat SES 2022.")) +
    theme_bites()
}

fig_size <- function(a) {
  size <- a$size_gap |>
    dplyr::mutate(country = country_label(a, geo)) |>
    tidyr::pivot_wider(names_from = band, values_from = gap) |>
    dplyr::arrange(`250 or more`) |>
    dplyr::mutate(country = factor(country, levels = country))
  dumbbell(size, "10 to 249", "250 or more", "Enterprises of 10 to 249", "Enterprises of 250 or more",
           limits = c(0, NA)) +
    ggplot2::labs(title = "The gap is wider in the employers that report every year",
                  subtitle = "Gender pay gap on mean hourly earnings by enterprise size, 2022",
                  caption = "Only countries where Eurostat publishes every size class. Source: Eurostat SES 2022.")
}

fig_control <- function(a) {
  ctl <- a$control |>
    dplyr::select(geo, control, gap) |>
    tidyr::pivot_wider(names_from = control, values_from = gap) |>
    dplyr::filter(!is.na(PUB), !is.na(PRV)) |>
    dplyr::mutate(country = country_label(a, geo)) |>
    dplyr::arrange(PRV) |>
    dplyr::mutate(country = factor(country, levels = country))
  dumbbell(ctl, "PUB", "PRV", "Public control", "Private control",
           highlight = which(levels(ctl$country) == "EU-27")) +
    ggplot2::labs(title = "The private sector carries the wider gap",
                  subtitle = sprintf("Unadjusted gender pay gap by economic control of the enterprise, %d", a$latest_year),
                  caption = "Countries publishing both figures. Source: Eurostat, earn_gr_gpgr2ct.")
}

AGE_LABELS <- c(Y_LT25 = "Under 25", `Y25-34` = "25-34", `Y35-44` = "35-44", `Y45-54` = "45-54",
                `Y55-64` = "55-64", Y_GE65 = "65+")

fig_age <- function(a) {
  age <- a$age |>
    dplyr::filter(geo %in% EU27) |>
    dplyr::group_by(age) |>
    dplyr::summarise(median = stats::median(gap), lo = stats::quantile(gap, 0.25),
                     hi = stats::quantile(gap, 0.75), n = dplyr::n(), .groups = "drop") |>
    dplyr::mutate(age = factor(AGE_LABELS[age], levels = AGE_LABELS))
  ggplot2::ggplot(age, ggplot2::aes(x = age, y = median)) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = lo, ymax = hi), colour = PALETTE$within, alpha = 0.35, linewidth = 5) +
    ggplot2::geom_point(colour = PALETTE$within, size = 2.8) +
    ggplot2::geom_text(ggplot2::aes(label = pct_label(median)), vjust = -1.2, colour = PALETTE$ink, size = 3.2) +
    ggplot2::scale_y_continuous(labels = \(x) paste0(x, "%")) +
    ggplot2::labs(title = "The gap opens with age",
                  subtitle = sprintf("Unadjusted gender pay gap by age group, %d: median country and middle half of countries",
                                     a$latest_year),
                  x = NULL, y = NULL, caption = "Source: Eurostat, earn_gr_gpgr2ag.") +
    theme_bites()
}
