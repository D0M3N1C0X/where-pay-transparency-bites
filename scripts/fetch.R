# Refreshes every Eurostat snapshot in data/raw/. This is the only step that needs a network
# connection; everything else runs from the snapshots.
#
#   Rscript scripts/fetch.R

source("R/eurostat.R")

geo <- c(EU27, "EU27_2020")

DATASETS <- list(
  # Gender pay gap in unadjusted form, 2010 onwards (Structure of Earnings Survey methodology)
  earn_gr_gpgr2   = list(geo = geo, unit = "PC"),                 # by economic activity
  earn_gr_gpgr2ct = list(geo = geo, unit = "PC"),                 # by public / private control
  earn_gr_gpgr2ag = list(geo = geo, unit = "PC"),                 # by age
  # Structure of Earnings Survey 2022
  earn_ses22_02   = list(geo = geo, age = "TOTAL"),               # employees by sex and activity
  earn_ses22_13   = list(geo = geo, age = "TOTAL", indic_se = "ERN", unit = "EUR"),  # hourly earnings
  earn_ses22_54   = list(geo = geo),                              # employees by sex, activity, occupation
  earn_ses22_47   = list(geo = geo, indic_se = "ERN", unit = "EUR"),                 # hourly earnings
  earn_ses22_53   = list(geo = geo),                              # employees by sex, occupation, size
  earn_ses22_18   = list(geo = geo, indic_se = "ERN", unit = "EUR")                  # hourly earnings
)

for (code in names(DATASETS)) {
  path <- fetch_dataset(code, DATASETS[[code]])
  message(sprintf("%-16s %6.0f KB  %s", code, file.size(path) / 1024, dataset_label(code)))
}
