# Data Cleaning Agent — `clean_flu_admissions`

## Purpose
Turn the raw NHSN HRD influenza CSV into a tidy, three-column dataset and
produce an epicurve figure. This agent implements the cleaning rules defined in
`rules.md` as a reproducible, self-validating R script (`01_cleaning.R`).

## Inputs
- `data/Weekly Hospital Respiratory Data (HRD) Metrics by Jurisdiction.csv`
  (NHSN Weekly Hospital Respiratory Data, read with **readr**)

## Outputs
- `output/data/01_cleaning/cleaned_flu_admissions.csv`
- `output/figures/01_cleaning/epicurve_us_flu_admissions.png`

## Tools / libraries
- **readr** for reading and parsing (`read_csv()`, `parse_number()`)
- Base R (`as.Date()`, `barplot()`) or **ggplot2** for the epicurve

## Steps (execute in order)

1. **Load the data**
   - Read the CSV from the `data/` folder with `readr::read_csv()`.
   - Import **only** the required columns, and read them as `character` first to
     avoid parsing warnings from unrelated fields:
     - `Week Ending Date`
     - `Geographic aggregation`
     - One of the allowed influenza admissions columns (see Step 3)
   - Parse / convert explicitly after loading.

2. **Filter to US only**
   - Keep only rows where `Geographic aggregation == "USA"`.

3. **Select the target column**
   - Use the influenza admissions column from one of these allowed names
     (in order of preference):
     1. `Total.Influenza.Admissions`
     2. `Total Influenza Admissions`
   - If **neither** column exists, stop with a clear, actionable error.

4. **Reshape to three columns**
   - Produce exactly these columns, in this order:
     1. `week`
     2. `location` — set every row to the string `"US"`
     3. `value`
   - Parse `value` with `readr::parse_number()` so comma-formatted counts parse
     correctly (e.g. `"1,110"` → `1110`). Do **not** call `parse_double()`
     directly on comma-formatted strings.

5. **Format dates**
   - Convert `Week Ending Date` into an R `Date` object stored in `week`.
   - Sort the data ascending by `week`.

6. **Save the cleaned data**
   - Write `cleaned_flu_admissions.csv` to `output/data/01_cleaning/`.
   - Create the output directory if it does not already exist.

7. **Generate the epicurve**
   - Save to `output/figures/01_cleaning/epicurve_us_flu_admissions.png`.
   - Plot specs:
     - X-axis: `week`
     - Y-axis: `value`
     - Ensure the plotting input is a numeric vector (e.g. `as.numeric(value)`)
       so `barplot()` does not fail with height-type errors.
   - Create the figures directory if it does not already exist.

## Validation checks (must STOP execution on failure)
The script must include checks that halt with a clear diagnostic if any fail:

- Row count is greater than 0 after cleaning.
- Column names are exactly `week`, `location`, `value`, in that order.
- Every value in `location` is the string `"US"`.
- `week` inherits class `Date`.
- `value` is numeric.
- `value` contains no `NA` after parsing.
- Output CSV exists at `output/data/01_cleaning/cleaned_flu_admissions.csv`.
- Epicurve exists at `output/figures/01_cleaning/epicurve_us_flu_admissions.png`.

## Failure behavior
- On any failed validation, stop execution (e.g. `stop()`) and print a message
  stating **which** check failed and **why**, so it is actionable.

## Implementation notes / best practices
- Read required columns as `character` first, then parse/convert explicitly
  (`readr::parse_number()`, `as.Date()` with an appropriate format).
- Create output directories (`dir.create(..., recursive = TRUE)`) before writing.
- Keep error messages user-friendly and specific.
- Ensure plotting input is numeric to avoid `height` errors in bar plots.

## Pseudocode outline
1. Read CSV, selecting the minimal set of columns as character.
2. Detect the influenza admissions column; error if none of the allowed names exist.
3. Filter to `Geographic aggregation == "USA"`.
4. Build a data frame with `week`, `location` (`"US"`), `value`.
5. Parse numbers (`parse_number`) and dates (`as.Date`), then sort by `week`.
6. Run all validation checks.
7. Write the CSV and save the epicurve figure.

---

Generated from `rules.md` to guide an automated agent (or serve as a human
checklist) when implementing `01_cleaning.R`.
