# =============================================================================
# 00_data_verification.R — MEMBER 1: export the data and prove nothing was lost
#
# Step 1  Export Karnataka (dataset 62 of the official MoSPI Nesstar file) to CSV
#         with the open-source R package nesstarR.
# Step 2  Compare the CSV with the official per-variable pages MoSPI published on
#         the same DVD (generated in 2016 from the original data with the IHSN
#         Microdata Management Toolkit): valid cases, every category count, and
#         min / max / mean / SD of numeric variables.
# The script stops with an error if anything does not match.
# Output: output/00_data_verification/README.md
# =============================================================================
source("analysis/common.R")
report_open("00_data_verification", "Data export and verification")

DVD <- "dataset_archives/DVD_EC_6th_ECONOMIC_CENSUS_2012_v3_lud_23june2016/survey0"
NESSTAR <- file.path(DVD, "data/EC_2012_13_6TH_ECONOMIC_CENSUS.Nesstar")
VAR_PAGES <- file.path(DVD, "dataSet/dataFiles/dataFile27") # dataFile27 = EC6A_ST29_KARNATAKA
DATASET_NO <- 62 # Karnataka inside the Nesstar file

# -----------------------------------------------------------------------------
header("Step 1: Export from the Nesstar file")
# -----------------------------------------------------------------------------
if (!file.exists(RAW_CSV)) {
  if (!requireNamespace("nesstarR", lib.loc = "r_libs", quietly = TRUE)) {
    stop(
      "Install nesstarR first:\n  Rscript -e 'install.packages(\"nesstarR\", lib=\"r_libs\", ",
      "repos=c(\"https://cran.r-universe.dev\",\"https://cloud.r-project.org\"))'"
    )
  }
  library(nesstarR, lib.loc = "r_libs")
  nesstar <- nesstar_parse(NESSTAR)
  dir.create("data", showWarnings = FALSE)
  write.csv(nesstar_read_dataset(nesstar, DATASET_NO), RAW_CSV, row.names = FALSE)
}
raw <- read.csv(RAW_CSV, colClasses = "character")
report_text(
  "Exported **", format(nrow(raw), big.mark = ","), " establishments x ", ncol(raw), " variables** ",
  "for Karnataka (dataset ", DATASET_NO, " of the MoSPI Nesstar file) using the open-source R package `nesstarR`."
)

# -----------------------------------------------------------------------------
header("Step 2: Comparison with the official MoSPI figures")
# -----------------------------------------------------------------------------
strip_html <- function(s) trimws(gsub("\\s+", " ", gsub("<[^>]+>", " ", s)))

read_official_page <- function(path) {
  h <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  grab <- function(label) {
    m <- regmatches(h, regexpr(paste0(label, ": *[-0-9.]+"), h))
    if (length(m) == 0) NA_character_ else sub(".*: *", "", m)
  }
  rows <- regmatches(h, gregexpr("(?s)<tr>\\s*<td class=\"varCatgry\">.*?</tr>", h, perl = TRUE))[[1]]
  cats <- lapply(rows, function(r) {
    cells <- strip_html(regmatches(r, gregexpr("(?s)<td class=\"varCatgry\">.*?</td>", r, perl = TRUE))[[1]])
    data.frame(value = cells[1], cases = as.numeric(cells[3]))
  })
  list(
    name = sub(".*Variable ([A-Za-z0-9_]+) :.*", "\\1", strip_html(h)),
    stats = c(
      valid = grab("Valid case\\(s\\)"), min = grab("Minimum"), max = grab("Maximum"),
      mean = grab("Mean"), sd = grab("Standard deviation")
    ),
    cats = do.call(rbind, cats)
  )
}

# A computed value matches when it equals the official value at the precision shown.
same_as_shown <- function(value, shown) {
  value <- unname(value)
  shown <- unname(shown)
  dec <- if (grepl("\\.", shown)) nchar(sub(".*\\.", "", shown)) else 0
  isTRUE(all.equal(round(value, dec), as.numeric(shown)))
}

checks <- list()
add_check <- function(variable, check, official, ours, ok) {
  pretty <- function(x) {
    x <- unname(as.character(x))
    if (grepl("^[0-9]+$", x)) format(as.numeric(x), big.mark = ",") else x
  }
  official <- pretty(official)
  ours <- pretty(ours)
  checks[[length(checks) + 1]] <<- data.frame(
    Variable = variable, Check = check, `Official (MoSPI)` = as.character(official),
    `Our export` = as.character(ours), Match = ok, check.names = FALSE
  )
}

pages <- list.files(VAR_PAGES, pattern = "^var[0-9]+\\.html$", full.names = TRUE)
for (page in pages[order(as.integer(gsub("\\D", "", basename(pages))))]) {
  ref <- read_official_page(page)
  v <- ref$name
  if (!v %in% names(raw)) next # label-only columns (Tahsil, Village_or_Town) are not data
  col <- trimws(raw[[v]])
  if (!is.na(ref$stats["valid"])) {
    ours <- sum(col != "")
    add_check(v, "valid cases", ref$stats["valid"], ours, as.numeric(ref$stats["valid"]) == ours)
  }
  if (!is.na(ref$stats["mean"])) {
    x <- as.numeric(col)
    ours <- c(min = min(x), max = max(x), mean = mean(x), sd = sd(x))
    for (s in names(ours)) add_check(v, s, ref$stats[s], signif(ours[s], 6), same_as_shown(ours[s], ref$stats[s]))
  }
  if (!is.null(ref$cats) && nrow(ref$cats) > 0) {
    counts <- as.numeric(table(col)[ref$cats$value])
    counts[is.na(counts)] <- 0
    add_check(
      v, paste0("count in each of ", nrow(ref$cats), " categories"),
      paste0(format(sum(ref$cats$cases), big.mark = ","), " cases"),
      paste0(format(sum(counts), big.mark = ","), " cases"),
      all(counts == ref$cats$cases)
    )
  }
}
checks <- do.call(rbind, checks)
report_text(
  "Each row compares one official MoSPI figure with our export. Means and SDs are compared at the ",
  "precision MoSPI displays (e.g. 2.5). A category check passes only if **every** category count matches."
)
save_table(checks, "export_verification", "Table 0.1: Our export vs the official MoSPI figures")

if (!all(checks$Match)) stop("VERIFICATION FAILED - do not use this export.")
report_text(
  "**Result: ", nrow(checks), " of ", nrow(checks), " checks passed.** The export matches every official ",
  "figure, so no values were lost or changed. (The DVD also lists two label-only columns, `Tahsil` and ",
  "`Village_or_Town`, which are text copies of location codes that are present in the data.)"
)
report_close()
