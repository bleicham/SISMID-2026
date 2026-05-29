#!/usr/bin/env Rscript
library(readr)
library(dplyr)
library(jsonlite)

dir.create('output', showWarnings = FALSE)

target_path <- 'target-hospital-admissions.csv'
ts_path <- 'time-series.csv'

target <- read_csv(target_path, col_types = cols())
ts_sample <- read_csv('sample_time-series_head.csv', col_types = cols())

summary_target <- list(
  file = target_path,
  rows = nrow(target),
  columns = names(target),
  us_rows = sum(target$location == 'US'),
  na_value = sum(is.na(target$value) | target$value == ''),
  min_date = as.character(min(as.Date(target$date))),
  max_date = as.character(max(as.Date(target$date)))
)

summary_ts <- list(
  file = ts_path,
  sample_rows = nrow(ts_sample),
  columns = names(ts_sample),
  distinct_as_of = length(unique(ts_sample$as_of)),
  distinct_target_end_date = length(unique(ts_sample$target_end_date)),
  na_observation = sum(is.na(ts_sample$observation) | ts_sample$observation == '')
)

write_json(list(target = summary_target, time_series_sample = summary_ts), 'output/data_summary.json', pretty = TRUE, auto_unbox = TRUE)
write_csv(as_tibble(summary_target), 'output/target_summary.csv')
write_csv(as_tibble(summary_ts), 'output/time_series_sample_summary.csv')

cat('Wrote output/data_summary.json and CSV summaries.\n')
