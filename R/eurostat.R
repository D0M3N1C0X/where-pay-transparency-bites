# Eurostat dissemination API (JSON-stat 2.0), with a local snapshot of every response.
#
# fetch_dataset() is the only function that touches the network. It writes the raw response to
# data/raw/<code>.json together with the URL and the retrieval date, and the analysis reads
# those snapshots only - so every figure can be rebuilt from the repository, offline.

EUROSTAT_API <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

EU27 <- c("BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV",
          "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE")

raw_path <- function(code, root = ".") file.path(root, "data", "raw", paste0(code, ".json"))

fetch_dataset <- function(code, filters = list(), root = ".") {
  req <- httr2::request(paste0(EUROSTAT_API, code)) |>
    httr2::req_url_query(format = "JSON", lang = "EN") |>
    httr2::req_url_query(!!!filters, .multi = "explode") |>
    httr2::req_retry(max_tries = 4) |>
    httr2::req_timeout(120)
  resp <- httr2::req_perform(req)
  body <- httr2::resp_body_string(resp)
  parsed <- jsonlite::fromJSON(body, simplifyVector = FALSE)
  snapshot <- list(
    code = code,
    url = req$url,
    retrieved = format(Sys.Date()),
    updated = parsed$updated,
    response = parsed
  )
  dir.create(dirname(raw_path(code, root)), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(snapshot, raw_path(code, root), auto_unbox = TRUE, digits = NA, pretty = FALSE)
  invisible(raw_path(code, root))
}

# JSON-stat stores a cube as one flat vector in row-major order: the last dimension varies
# fastest. expand.grid() varies its first argument fastest, so the dimensions go in reversed.
parse_jsonstat <- function(j) {
  dims <- unlist(j$id)
  codes <- lapply(dims, function(d) {
    index <- unlist(j$dimension[[d]]$category$index)
    names(sort(index))
  })
  names(codes) <- dims
  grid <- expand.grid(rev(codes), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)[dims]
  n <- nrow(grid)
  pick <- function(x) {
    out <- rep(NA, n)
    if (length(x) == 0) return(out)
    if (is.null(names(x))) {
      out[seq_along(x)] <- unlist(lapply(x, function(v) if (is.null(v)) NA else v))
    } else {
      out[as.integer(names(x)) + 1] <- unlist(x)
    }
    out
  }
  grid$value <- as.numeric(pick(j$value))
  grid$flag <- as.character(pick(j$status))
  tibble::as_tibble(grid)
}

read_dataset <- function(code, root = ".") {
  path <- raw_path(code, root)
  if (!file.exists(path)) stop("No snapshot for ", code, ": run scripts/fetch.R first")
  snapshot <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  data <- parse_jsonstat(snapshot$response)
  attr(data, "source") <- snapshot[c("code", "url", "retrieved", "updated")]
  data
}

dataset_label <- function(code, root = ".") {
  jsonlite::fromJSON(raw_path(code, root), simplifyVector = FALSE)$response$label
}
