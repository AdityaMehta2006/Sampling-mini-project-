# =============================================================================
# common.R — shared settings and helpers used by every script
#
# Every script starts with  source("analysis/common.R")  and is run from the
# project folder, e.g.      Rscript analysis/02_stratified.R
# Only base R is needed for the analysis.
#
# Lint settings (.lintr): statistical notation such as N, S2 and W_h is allowed,
# and lines may be up to 120 characters.
# =============================================================================

options(scipen = 8) # print 2880548, not 2.880548e+06

# ---- Data files ---------------------------------------------------------------
RAW_CSV <- "data/karnataka_ec6_raw.csv" # export of the Nesstar file (300 MB, not in git)
FRAME_RDS <- "data/frame_karnataka.rds" # cleaned sampling frame (2.4 MB, in git)
SHARED <- "output/_shared" # results passed between scripts
dir.create(SHARED, recursive = TRUE, showWarnings = FALSE)

# ---- Survey design constants (the same for every method) -----------------------
SEED <- 2026 # makes every random draw reproducible
ALPHA <- 0.05 # 95% confidence, 5% level of significance
Z <- qnorm(1 - ALPHA / 2) # 1.959964
D_PROP <- 0.03 # required margin of error for P: 3 percentage points
N_SAMPLE <- 748 # common sample size n (justified in 01_srs.R)
K_SYS <- 3851 # sampling interval k, since N = n k = 748 x 3851

# Karnataka's four revenue divisions (district codes of the census file)
DIVISIONS <- list(
  Bengaluru = c(12, 13, 14, 17, 18, 27, 28, 29, 30),
  Mysuru = c(15, 16, 19, 20, 21, 22, 23, 24),
  Belagavi = c(1, 2, 3, 7, 8, 9, 10),
  Kalaburagi = c(4, 5, 6, 11, 25, 26)
)

# ---- Loading shared inputs -------------------------------------------------------
load_frame <- function() {
  if (!file.exists(FRAME_RDS)) stop("Run analysis/01_srs.R first to build ", FRAME_RDS)
  readRDS(FRAME_RDS)
}

load_shared <- function(name) {
  path <- file.path(SHARED, paste0(name, ".rds"))
  if (!file.exists(path)) stop("Missing ", path, " - run the earlier scripts first (analysis/run_all.R).")
  readRDS(path)
}

save_shared <- function(object, name) saveRDS(object, file.path(SHARED, paste0(name, ".rds")))

# ---- True population values -------------------------------------------------------
# We have the full census, so the true values are known and the actual error of
# every estimate can be measured.
pop_params <- function(fr) {
  list(
    N = nrow(fr),
    Ybar = mean(fr$Y), # population mean
    Ytot = sum(fr$Y), # population total
    S2 = var(fr$Y), # population variance S^2 (divisor N - 1)
    P = mean(fr$female), # population proportion
    A = sum(fr$female) # number of female-owned establishments
  )
}

# ---- Results of one design ---------------------------------------------------------
# est    : the estimate
# v_hat  : ESTIMATED variance, computed from the sample only
# truth  : true population value
# v_true : EXACT variance of the estimator, computed from the whole population
# df     : degrees of freedom for the CI (Inf: z = 1.96; finite: t distribution)
result_row <- function(design, parameter, est, v_hat, truth, v_true = NA, df = Inf) {
  se <- sqrt(v_hat)
  crit <- if (is.finite(df)) qt(1 - ALPHA / 2, df) else Z
  lo <- est - crit * se
  hi <- est + crit * se
  data.frame(
    design = design, parameter = parameter, estimate = est, var_hat = v_hat, se = se,
    ci_low = lo, ci_high = hi, truth = truth, abs_error = abs(est - truth),
    covers_truth = truth >= lo & truth <= hi, var_true = v_true, stringsAsFactors = FALSE
  )
}

# Mean, Total and Proportion rows together (Total = N x Mean, so Var = N^2 x Var).
three_rows <- function(design, N, ybar, v_ybar, p, v_p, pp, v_true_mean = NA, v_true_p = NA, df = Inf) {
  rbind(
    result_row(design, "Mean", ybar, v_ybar, pp$Ybar, v_true_mean, df),
    result_row(design, "Total", N * ybar, N^2 * v_ybar, pp$Ytot, N^2 * v_true_mean, df),
    result_row(design, "Proportion", p, v_p, pp$P, v_true_p, df)
  )
}

# ---- One-way ANOVA from group sums ----------------------------------------------------
# Works for any number of groups (even 100,000 clusters) without a model matrix.
#   SST = SSB + SSW,   F = MSB / MSW  with (g - 1, N - g) degrees of freedom
anova_oneway <- function(y, g) {
  g <- as.factor(g)
  N <- length(y)
  G <- nlevels(g)
  ni <- tabulate(g, G)
  mi <- as.numeric(rowsum(y, g)) / ni
  SST <- sum((y - mean(y))^2)
  SSB <- sum(ni * (mi - mean(y))^2)
  SSW <- SST - SSB
  MSB <- SSB / (G - 1)
  MSW <- SSW / (N - G)
  Fv <- MSB / MSW
  data.frame(
    Source = c("Between groups", "Within groups", "Total"),
    df = c(G - 1, N - G, N - 1),
    `Sum of squares` = c(SSB, SSW, SST),
    `Mean square` = c(MSB, MSW, NA),
    F = c(Fv, NA, NA),
    `p-value` = c(pf(Fv, G - 1, N - G, lower.tail = FALSE), NA, NA),
    check.names = FALSE
  )
}

# ---- Rounding an allocation so that it adds up to n (largest remainder) ----------------
round_allocation <- function(x, n) {
  base <- floor(x)
  left <- n - sum(base)
  if (left > 0) {
    idx <- order(x - base, decreasing = TRUE)[seq_len(left)]
    base[idx] <- base[idx] + 1
  }
  base
}

# =============================================================================
# Reports
# Each script writes one folder  output/<name>/  containing
#   README.md   the readable report (opens automatically on GitHub)
#   tables/     every table as CSV with full precision
#   figures/    PNG charts
#   samples/    the units selected (for the Annexure)
# =============================================================================
.report <- new.env()

report_open <- function(name, title) {
  .report$dir <- file.path("output", name)
  dir.create(file.path(.report$dir, "tables"), recursive = TRUE, showWarnings = FALSE)
  .report$file <- file.path(.report$dir, "README.md")
  cat("# ", title, "\n\n",
    "> Population: all 2,880,548 establishments in Karnataka, Sixth Economic Census 2012-13 (MoSPI).  \n",
    "> Generated by `analysis/", name, ".R` on ", format(Sys.Date()), ". Re-run the script to update; ",
    "do not edit by hand.\n\n",
    "<!-- contents -->\n\n",
    sep = "", file = .report$file
  )
}

# Adds a table of contents built from the "## " headings, then closes the report.
report_close <- function() {
  lines <- readLines(.report$file, encoding = "UTF-8")
  heads <- sub("^## ", "", grep("^## ", lines, value = TRUE))
  anchor <- gsub(" ", "-", gsub("[^a-z0-9 -]", "", tolower(heads)))
  toc <- c("**Contents**", "", paste0("- [", heads, "](#", anchor, ")"), "")
  i <- which(lines == "<!-- contents -->")
  writeLines(c(lines[seq_len(i - 1)], toc, lines[-seq_len(i)]), .report$file)
  pdf <- file.path(.report$dir, paste0(basename(.report$dir), ".pdf"))
  markdown_to_pdf(.report$file, pdf)
  cat("\nReport written to", .report$file, if (file.exists(pdf)) paste("and", pdf), "\n")
}

# ---- PDF version of a Markdown file ----------------------------------------------
# Markdown -> HTML (R package commonmark) -> PDF (Google Chrome / Chromium, headless).
# If either is missing, the PDF is skipped and everything else still works.
REPORT_CSS <- "
@page { size: A4; margin: 15mm 13mm 17mm 13mm;
  @bottom-center { content: 'Page ' counter(page) ' of ' counter(pages); font: 8.5pt sans-serif; color: #777; } }
body { font-family: 'DejaVu Sans', Arial, sans-serif; font-size: 10pt; line-height: 1.45; color: #222; }
h1 { font-size: 19pt; color: #1f3b63; border-bottom: 2px solid #1f3b63; padding-bottom: 4px; margin-top: 0; }
h2 { font-size: 13.5pt; color: #1f3b63; border-bottom: 1px solid #c9d2e3; margin-top: 22px; break-after: avoid; }
h3 { font-size: 11.5pt; color: #1f3b63; break-after: avoid; }
p:has(+ table), p:has(+ pre) { break-after: avoid; }
table { border-collapse: collapse; width: 100%; font-size: 8.4pt; margin: 4px 0 14px; }
th { background: #1f3b63; color: #fff; padding: 4px 6px; font-weight: 600; }
td { padding: 3px 6px; border-bottom: 1px solid #dfe4ee; vertical-align: top; }
tr:nth-child(even) td { background: #f4f6fa; }
tr { break-inside: avoid; }
img { max-width: 92%; max-height: 92mm; display: block; margin: 6px auto 2px; break-inside: avoid; }
blockquote { color: #555; border-left: 3px solid #c9d2e3; margin: 0 0 12px; padding: 2px 10px; font-size: 9pt; }
code { font-family: 'DejaVu Sans Mono', monospace; font-size: 8.6pt; background: #f1f3f6; padding: 0 3px; }
pre { background: #f6f8fb; padding: 8px 10px; font-size: 8.4pt; white-space: pre-wrap; break-inside: avoid; }
pre code { background: none; padding: 0; }
a { color: #1f3b63; text-decoration: none; }
"

find_chrome <- function() {
  found <- Sys.which(c("google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "microsoft-edge"))
  found <- found[found != ""]
  if (length(found) == 0) NA_character_ else unname(found[1])
}

markdown_to_pdf <- function(md_file, pdf_file) {
  chrome <- find_chrome()
  if (!requireNamespace("commonmark", quietly = TRUE) || is.na(chrome)) {
    message("PDF skipped (needs the R package 'commonmark' and Google Chrome or Chromium).")
    return(invisible(FALSE))
  }
  md <- paste(readLines(md_file, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  body <- commonmark::markdown_html(md, extensions = TRUE)
  # give every heading an id so the Contents links work inside the PDF
  heads <- regmatches(body, gregexpr("<h[23]>[^<]*</h[23]>", body))[[1]]
  for (h in unique(heads)) {
    txt <- gsub("<[^>]+>", "", h)
    id <- gsub(" ", "-", gsub("[^a-z0-9 -]", "", tolower(txt)))
    body <- sub(h, sub("^<h([23])>", paste0("<h\\1 id=\"", id, "\">"), h), body, fixed = TRUE)
  }
  title <- sub("^# ", "", strsplit(md, "\n")[[1]][1])
  html <- paste0(
    "<!doctype html><html><head><meta charset='utf-8'><title>", title, "</title><style>",
    REPORT_CSS, "</style></head><body>", body, "</body></html>"
  )
  html_file <- file.path(dirname(md_file), ".report_tmp.html") # same folder, so image paths work
  writeLines(html, html_file, useBytes = TRUE)
  system2(chrome, c(
    "--headless=new", "--disable-gpu", "--no-sandbox", "--no-pdf-header-footer",
    paste0("--print-to-pdf=", shQuote(normalizePath(pdf_file, mustWork = FALSE))),
    shQuote(paste0("file://", normalizePath(html_file)))
  ), stdout = FALSE, stderr = FALSE)
  unlink(html_file)
  invisible(file.exists(pdf_file))
}

header <- function(txt) {
  cat("\n", strrep("=", 78), "\n ", txt, "\n", strrep("=", 78), "\n", sep = "")
  cat("## ", txt, "\n\n", sep = "", file = .report$file, append = TRUE)
}

report_text <- function(...) {
  txt <- paste0(...)
  cat(gsub("\\*\\*", "", txt), "\n")
  cat(txt, "\n\n", sep = "", file = .report$file, append = TRUE)
}

# ---- Number formatting for people ---------------------------------------------------
# 2880548 -> "2,880,548";  720.3949 -> "720.4";  0.98765 -> "0.9877";  0.000205 -> "0.0002053"
fmt_num <- function(x, digits = 4) {
  vapply(x, function(v) {
    if (is.na(v)) {
      return("")
    }
    if (v != 0 && abs(v) < 1e-4) {
      return(formatC(v, format = "e", digits = 2)) # e.g. 3.47e-07
    }
    if (v == round(v) && abs(v) < 1e15) {
      return(formatC(v, format = "d", big.mark = ","))
    }
    if (abs(v) >= 100) {
      return(formatC(v, format = "f", digits = 1, big.mark = ","))
    }
    trimws(formatC(signif(v, digits), format = "fg", digits = digits, flag = "#"))
  }, character(1))
}

fmt_p <- function(p) ifelse(is.na(p), "", ifelse(p < 1e-4, "< 0.0001", formatC(p, format = "f", digits = 4)))

fmt_fixed <- function(x, dp) trimws(formatC(x, format = "f", digits = dp, big.mark = ","))

md_table <- function(df, digits = 4) {
  cells <- Map(function(col, nm) {
    if (grepl("p-value", nm, fixed = TRUE)) {
      fmt_p(col)
    } else if (is.numeric(col)) {
      fmt_num(col, digits)
    } else if (is.logical(col)) {
      ifelse(col, "yes", "no")
    } else {
      as.character(col)
    }
  }, df, names(df))
  looks_numeric <- function(x) all(grepl("^[0-9.,<%\\[\\] -]*$", x, perl = TRUE))
  right <- vapply(cells, looks_numeric, logical(1)) | vapply(df, is.numeric, logical(1))
  c(
    paste("|", paste(names(df), collapse = " | "), "|"),
    paste("|", paste(ifelse(right, "---:", ":---"), collapse = " | "), "|"),
    paste("|", do.call(paste, c(cells, sep = " | ")), "|")
  )
}

# Writes the table to the report (readable) and to tables/<name>.csv (full precision).
# `csv` lets a script save raw numbers while showing a formatted version.
save_table <- function(df, name, caption, csv = df, digits = 4) {
  write.csv(csv, file.path(.report$dir, "tables", paste0(name, ".csv")), row.names = FALSE)
  cat("\n", caption, "\n", sep = "")
  print(df, row.names = FALSE, digits = 5)
  cat("**", caption, "**\n\n", sep = "", file = .report$file, append = TRUE)
  cat(md_table(df, digits), "", sep = "\n", file = .report$file, append = TRUE)
}

# Readable version of a results table (estimate, SE, 95% CI, truth, error).
pretty_results <- function(res) {
  dp <- ifelse(res$parameter == "Total", 0, ifelse(res$parameter == "Mean", 3, 4))
  f <- function(x) mapply(fmt_fixed, x, dp)
  data.frame(
    Design = res$design,
    Parameter = res$parameter,
    Estimate = f(res$estimate),
    Variance = fmt_num(res$var_hat, 4),
    SE = f(res$se),
    `95% CI` = paste0("[", f(res$ci_low), ", ", f(res$ci_high), "]"),
    `True value` = f(res$truth),
    `Abs. error` = f(res$abs_error),
    `CI covers truth` = ifelse(res$covers_truth, "yes", "no"),
    `Exact SE` = f(sqrt(res$var_true)),
    check.names = FALSE, stringsAsFactors = FALSE
  )
}

save_results <- function(res, name, caption) save_table(pretty_results(res), name, caption, csv = res)

save_sample <- function(rows, name) {
  dir.create(file.path(.report$dir, "samples"), showWarnings = FALSE)
  write.csv(rows, file.path(.report$dir, "samples", paste0(name, ".csv")), row.names = FALSE)
}

# ---- Figures --------------------------------------------------------------------------
PALETTE <- c(blue = "#4C72B0", light = "#A6BDDB", red = "#C44E52", green = "#55A868", grey = "#8C8C8C")

fig_open <- function(name, width = 1800, height = 1100) {
  .report$fig <- name
  dir.create(file.path(.report$dir, "figures"), showWarnings = FALSE)
  png(file.path(.report$dir, "figures", paste0(name, ".png")), width = width, height = height, res = 200)
  par(mar = c(4.5, 4.8, 3.2, 1), las = 1, cex.main = 1.05, family = "sans")
}

fig_close <- function(caption) {
  dev.off()
  cat("![", caption, "](figures/", .report$fig, ".png)\n\n*", caption, "*\n\n",
    sep = "", file = .report$file, append = TRUE
  )
}
