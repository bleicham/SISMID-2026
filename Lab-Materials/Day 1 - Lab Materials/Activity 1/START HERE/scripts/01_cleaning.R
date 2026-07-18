# =============================================================================
# 01_cleaning.R
#
# Data Cleaning Agent: clean_flu_admissions
#
# Turns the raw NHSN HRD influenza CSV into a tidy, three-column dataset
# (week, location, value) and produces a US influenza-admissions epicurve.
#
# Implements the rules defined in agents.md / rules.md.
# =============================================================================

library(readr)

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
base_dir     <- file.path("Lab-Materials", "Day 1 - Lab Materials", "Activity 1", "START HERE")
input_csv    <- file.path(base_dir, "data",
                          "Weekly Hospital Respiratory Data (HRD) Metrics by Jurisdiction.csv")
output_data_dir <- file.path(base_dir, "output", "data", "01_cleaning")
output_fig_dir  <- file.path(base_dir, "output", "figures", "01_cleaning")
output_csv   <- file.path(output_data_dir, "cleaned_flu_admissions.csv")
output_fig   <- file.path(output_fig_dir, "epicurve_us_flu_admissions.png")

# Create output directories if they do not exist
dir.create(output_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_fig_dir,  recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# Step 3 (helper): Detect the target influenza admissions column
# -----------------------------------------------------------------------------
allowed_flu_cols <- c("Total.Influenza.Admissions", "Total Influenza Admissions")

# Peek at the header only, so we can pick the right column before a full read.
header <- names(read_csv(input_csv, n_max = 0, show_col_types = FALSE))

flu_col <- allowed_flu_cols[allowed_flu_cols %in% header]
if (length(flu_col) == 0) {
  stop(
    "Could not find an influenza admissions column. Expected one of: ",
    paste(allowed_flu_cols, collapse = ", "),
    call. = FALSE
  )
}
flu_col <- flu_col[1]

# -----------------------------------------------------------------------------
# Step 1: Load the data (only required columns, read as character first)
# -----------------------------------------------------------------------------
required_cols <- c("Week Ending Date", "Geographic aggregation", flu_col)

raw <- read_csv(
  input_csv,
  col_select = all_of(required_cols),
  col_types  = cols(.default = col_character()),
  show_col_types = FALSE
)

# -----------------------------------------------------------------------------
# Step 2: Filter to US only
# -----------------------------------------------------------------------------
raw <- raw[raw[["Geographic aggregation"]] == "USA", , drop = FALSE]

# -----------------------------------------------------------------------------
# Step 4: Reshape to exactly three columns: week, location, value
# -----------------------------------------------------------------------------
cleaned <- data.frame(
  week     = raw[["Week Ending Date"]],
  location = "US",
  value    = parse_number(raw[[flu_col]]),   # handles comma-formatted counts
  stringsAsFactors = FALSE
)

# -----------------------------------------------------------------------------
# Step 5: Format dates and sort ascending by week
# -----------------------------------------------------------------------------
cleaned$week <- as.Date(cleaned$week, format = "%Y-%m-%d")
cleaned <- cleaned[order(cleaned$week), , drop = FALSE]
cleaned <- cleaned[, c("week", "location", "value")]  # enforce column order

# -----------------------------------------------------------------------------
# Step 8: Validation checks (stop execution on failure)
# -----------------------------------------------------------------------------
if (nrow(cleaned) == 0) {
  stop("Validation failed: cleaned data has 0 rows.", call. = FALSE)
}
if (!identical(names(cleaned), c("week", "location", "value"))) {
  stop("Validation failed: columns must be exactly 'week', 'location', 'value' in that order.",
       call. = FALSE)
}
if (!all(cleaned$location == "US")) {
  stop("Validation failed: 'location' must always be 'US'.", call. = FALSE)
}
if (!inherits(cleaned$week, "Date")) {
  stop("Validation failed: 'week' must inherit class 'Date'.", call. = FALSE)
}
if (!is.numeric(cleaned$value)) {
  stop("Validation failed: 'value' must be numeric.", call. = FALSE)
}
if (any(is.na(cleaned$value))) {
  stop("Validation failed: 'value' contains NA after parsing.", call. = FALSE)
}

# -----------------------------------------------------------------------------
# Step 6: Save the cleaned data
# -----------------------------------------------------------------------------
write_csv(cleaned, output_csv)

# -----------------------------------------------------------------------------
# Step 7: Generate the epicurve figure
# -----------------------------------------------------------------------------
png(output_fig, width = 1000, height = 600)
# Wider left/bottom margins; mgp pushes the y-axis title away from the tick labels
par(mar = c(7, 6, 4, 2) + 0.1, mgp = c(4, 1, 0))
barplot(
  height    = as.numeric(cleaned$value),
  names.arg = format(cleaned$week, "%Y-%m-%d"),
  main      = "US Weekly Influenza Admissions Epicurve",
  xlab      = "",
  ylab      = "Total Influenza Admissions",
  col       = "steelblue",
  border    = NA,
  las       = 2,
  cex.names = 0.8
)
title(xlab = "Week", line = 5)
dev.off()

# -----------------------------------------------------------------------------
# Step 8 (cont.): Confirm output files exist
# -----------------------------------------------------------------------------
if (!file.exists(output_csv)) {
  stop("Validation failed: output CSV was not created at ", output_csv, call. = FALSE)
}
if (!file.exists(output_fig)) {
  stop("Validation failed: epicurve figure was not created at ", output_fig, call. = FALSE)
}

message("Cleaning complete. ", nrow(cleaned), " rows written to ", output_csv)
message("Epicurve saved to ", output_fig)
