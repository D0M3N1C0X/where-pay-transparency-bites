# One look for every chart, the portfolio identity (brand/tokens.css in d0m3n1c0x.github.io): Apple blue and
# orange, a neutral grey for everything that is not the point, hairline grid, system sans.

PALETTE <- list(
  within = "#0071e3",     # slot 1: the gap inside sectors
  between = "#ff9500",    # slot 2: where women and men work
  highlight = "#0071e3",
  context = "#d2d2d7",
  ink = "#1d1d1f",
  ink2 = "#424245",
  muted = "#6e6e73",
  grid = "#e8e8ed",
  surface = "#ffffff"
)

theme_bites <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size, base_family = "sans") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = PALETTE$surface, colour = NA),
      panel.background = ggplot2::element_rect(fill = PALETTE$surface, colour = NA),
      panel.grid.major = ggplot2::element_line(colour = PALETTE$grid, linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      text = ggplot2::element_text(colour = PALETTE$ink2),
      axis.text = ggplot2::element_text(colour = PALETTE$muted),
      plot.title = ggplot2::element_text(colour = PALETTE$ink, face = "bold", size = base_size * 1.3),
      plot.subtitle = ggplot2::element_text(colour = PALETTE$ink2, margin = ggplot2::margin(b = 8)),
      plot.caption = ggplot2::element_text(colour = PALETTE$muted, hjust = 0, size = base_size * 0.8),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(12, 16, 10, 12)
    )
}

pct_label <- function(x, digits = 1) paste0(formatC(x, format = "f", digits = digits), "%")

save_svg <- function(plot, path, width = 8, height = 5) {
  if (nzchar(Sys.getenv("BITES_PREVIEW"))) {
    ggplot2::ggsave(file.path(Sys.getenv("BITES_PREVIEW"), sub("[.]svg$", ".png", basename(path))), plot,
                    width = width, height = height, dpi = 110, bg = PALETTE$surface)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(path, plot, width = width, height = height, device = svglite::svglite, bg = PALETTE$surface)
}
