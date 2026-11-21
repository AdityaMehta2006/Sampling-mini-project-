# =============================================================================
# 07_member_reports.R — one report (PDF) per member
#
# Each report = page 1: cover in the department format (5 fillable name /
# register-number lines) + page 2: student details (fillable name and register
# number) + the body: introduction, the member's own method (from output/),
# comparison with the other designs, member-specific chapters, conclusion and
# sources. Numbers come from the verified results (analysis/summary_values.R).
#
# Needs: pdflatex (front pages), Google Chrome/Chromium (body), qpdf (merge).
# Output: reports/MemberN_<method>.pdf
# =============================================================================
source("analysis/summary_values.R")

for (tool in c("pdflatex", "qpdf")) {
  if (!nzchar(Sys.which(tool))) stop(tool, " is needed to build the member reports.")
}
if (is.na(find_chrome())) stop("Google Chrome or Chromium is needed to build the member reports.")

ROOT <- normalizePath(".")
BUILD <- file.path(tempdir(), "member_reports")
dir.create(BUILD, showWarnings = FALSE)
dir.create("reports", showWarnings = FALSE)

# The group, printed on every cover as "Name – Register number"
TEAM_MEMBERS <- data.frame(
  name = c("Abhinaba Das", "Aditya Mehta", "Akash Kumar", "K Suraj Das", "Rithesh K R"),
  reg = c("2440203", "2440204", "2440206", "2440224", "2440233")
)
# Who takes which member role, where known (pre-fills page 2; still editable in the PDF)
ROLE_HOLDER <- c("2" = "Rithesh K R")

MEMBERS <- list(
  list(no = 1, file = "Member1_SRSWOR_SRSWR", method = "SRSWOR and SRSWR, sample size",
       also = "Data cleaning and frame preparation", folders = c("00_data_verification", "01_srs"),
       chapter = "Simple random sampling (SRSWOR and SRSWR)"),
  list(no = 2, file = "Member2_Stratified_Sampling", method = "Stratified sampling",
       also = "Allocation comparison", folders = "02_stratified", chapter = "Stratified random sampling"),
  list(no = 3, file = "Member3_Systematic_Sampling", method = "Systematic sampling",
       also = "Charts and visuals", folders = "03_systematic", chapter = "Systematic sampling"),
  list(no = 4, file = "Member4_Cluster_Sampling", method = "Cluster sampling",
       also = "Intraclass correlation and efficiency; errors", folders = "04_cluster",
       chapter = "Single-stage cluster sampling"),
  list(no = 5, file = "Member5_Comparison_and_Official_Statistics",
       method = "Comparison of designs and official statistics link", also = "Report compilation",
       folders = "05_comparison", chapter = "Comparison of designs, F-tests and simulation")
)

# ---- Pieces of the body ----------------------------------------------------------
# The body of a results report, without its title, contents list and sources, with
# image paths made absolute so the figures load from anywhere.
unit_body <- function(folder) {
  lines <- readLines(file.path("output", folder, "README.md"), encoding = "UTF-8")
  first <- which(startsWith(lines, "## "))[1]
  stop_at <- which(lines == "## Sources")
  lines <- lines[first:(if (length(stop_at)) stop_at - 1 else length(lines))]
  fig_dir <- paste0("file://", file.path(ROOT, "output", folder, "figures"), "/")
  gsub("](figures/", paste0("](", fig_dir), lines, fixed = TRUE)
}

# One section of a TEAM note, from its "## N." heading up to the next "## " heading.
team_section <- function(file, heading_start) {
  lines <- readLines(file.path("TEAM", file), encoding = "UTF-8")
  a <- which(startsWith(lines, heading_start))[1]
  nxt <- which(startsWith(lines, "## ") & seq_along(lines) > a)
  b <- if (length(nxt)) nxt[1] - 1 else length(lines)
  body <- lines[(a + 1):b]
  body <- body[!startsWith(body, "> ")] # drop editorial notes
  # "**8.1 Title.** text..." -> a "### 8.1 Title" sub-heading followed by its paragraph
  heading <- grepl("^\\*\\*8\\.[0-9]+ [^*]+\\*\\*", body)
  body[heading] <- sub(
    "^\\*\\*(8\\.[0-9]+ [^*]+?)\\.?\\*\\*\\s*(.*)$", "### \\1\n\n\\2", body[heading],
    perl = TRUE
  )
  body
}

table_block <- function(folder, caption_start) {
  lines <- readLines(file.path("output", folder, "README.md"), encoding = "UTF-8")
  a <- which(startsWith(lines, paste0("**", caption_start)))[1]
  b <- a + 1
  while (b < length(lines) && !(lines[b] == "" && startsWith(lines[b - 1], "|"))) b <- b + 1
  lines[a:b]
}

intro <- function(m) {
  design <- read.csv("output/01_srs/tables/survey_design.csv", check.names = FALSE)
  c(
    "# Chapter 1: Introduction", "",
    "## 1.1 Objective", "",
    paste0(
      "The group project applies simple random, stratified, systematic and cluster sampling to one real ",
      "population and compares how efficient the designs are. This report presents the work on **",
      tolower(substr(m$method, 1, 1)), substr(m$method, 2, nchar(m$method)), "**."
    ), "",
    "## 1.2 Population and data source", "",
    paste0(
      "The population is all **", v$N, " establishments in Karnataka** enumerated in the Sixth Economic Census ",
      "2012-13 of the Ministry of Statistics and Programme Implementation (MoSPI). The microdata were exported from ",
      "MoSPI's official Nesstar file and checked against MoSPI's published summary figures: **", v$checks_pass,
      " of ", v$checks_total, " checks matched**, so the data are genuine and complete. Data source: <", MOSPI_URL, ">."
    ), "",
    "## 1.3 Survey design", "",
    "**Table 1.A: Survey design used by every member**", "", md_table(design), "",
    paste0(
      "The study variable is extremely skewed: the mean is ", v$Ybar, " workers per establishment, the median is ",
      v$median, " and the largest establishment reports ", v$maxY, " workers. The proportion of female-owned ",
      "establishments is P = ", v$P, ". The common sample size n = ", v$n, " gives a margin of error of about ",
      v$m1_dach, " for P, and ", v$n, " x ", v$k, " = ", v$N, " exactly, as systematic sampling requires."
    ), ""
  )
}

comparison <- function(m) {
  fig <- paste0("file://", file.path(ROOT, "output/05_comparison/figures/relative_efficiency.png"))
  where <- switch(m$no,
    paste0(
      "SRSWOR is the benchmark (RE = 1). SRSWR is practically as precise (RE ", v$m1_ratio,
      " in variance terms), because n is a tiny fraction of N."
    ),
    paste0(
      "Neyman-allocated stratified sampling is the most precise design for the **mean** (RE ", v$m2_re_ney_mean,
      "), while proportional allocation is no better than SRS (RE ", v$m2_re_prop_mean, ")."
    ),
    paste0(
      "Systematic sampling is the most precise design for the **proportion** (RE ", v$m3_re_p,
      ") and about as good as SRS for the mean."
    ),
    paste0(
      "Cluster sampling is the least precise design (RE ", v$m4_re_y, " for the mean and ", v$m4_re_p,
      " for the proportion), the price of its low field cost."
    )
  )
  c(
    "# Chapter 3: Comparison with the other designs", "",
    "Every design was applied to the same population with about the same sample size.", "",
    table_block("05_comparison", "Table 5.1"),
    paste0("![Relative efficiency](", fig, ")"), "",
    "*Figure 3.A: Relative efficiency of every design against SRSWOR (above 1 = more precise than SRS)*", "",
    paste0("**Where this design stands.** ", where), ""
  )
}

conclusion <- function(m) {
  txt <- switch(m$no,
    c(
      paste0("- The Karnataka data were exported and verified against ", v$checks_total, " official MoSPI figures."),
      paste0("- n = ", v$m1_nreq, " estimates P within 3 percentage points; n = ", v$n, " was used so that N = nk."),
      paste0("- The mean would need ", v$m1_nmean10, " units for 10% precision because the data are very skewed."),
      paste0(
        "- SRSWR is only ", v$m1_ratio_pct,
        "% less precise than SRSWOR; with n/N this small they are equivalent."
      ),
      paste0(
        "- ", v$m1_suspect,
        " single-owner establishments reporting 10,000+ workers are probable recording errors."
      )
    ),
    c(
      paste0("- The four revenue divisions explain only ", v$m2_share_pct, "% of the variance, so proportional ",
             "allocation gains nothing for the mean (RE ", v$m2_re_prop_mean, ")."),
      paste0("- Their standard deviations differ (", v$m2_sd_range, "), so Neyman allocation gains about ",
             v$m2_gain_ney, "% (RE ", v$m2_re_ney_mean, "), exactly as Cochran's formulas predict."),
      paste0("- Neyman allocation optimised for the mean is worse for the proportion (RE ", v$m2_re_ney_p,
             "); an allocation optimised for P gives RE ", v$m2_re_neyP, "."),
      paste0("- ANOVA on the sample: F = ", v$m2_F, ", p = ", v$m2_p, " (", v$m2_decision, "); Kruskal-Wallis p = ",
             v$m2_kw_p, " (", v$m2_kw_decision, "). Normality fails (skewness ", v$m2_skew, ")."),
      paste0("- Activity type would be the better basis for the proportion (RE ", v$m2_act_re_p, ").")
    ),
    c(
      paste0("- With k = ", v$k, " and random start r = ", v$m3_r, ", the estimator is unbiased (checked over all ",
             v$k, " starts)."),
      paste0("- The start does not matter: ANOVA F = ", v$m3_F_mean, " (p = ", v$m3_p_mean, ") for the mean and F = ",
             v$m3_F_prop, " (p = ", v$m3_p_prop, ") for the proportion; no trend or periodicity."),
      paste0("- Systematic sampling is ", v$m3_gain_p, "% more efficient than SRS for the proportion (implicit ",
             "stratification by location) and equal to SRS for the mean."),
      paste0("- The gain disappears on a shuffled list, so the order of the frame is part of the design.")
    ),
    c(
      paste0("- ", v$n_c, " of ", v$Nc, " enumeration blocks were sampled (about ", v$m4_units, " establishments)."),
      paste0("- Intraclass correlation: ", v$m4_icc_y, " for workers and ", v$m4_icc_p, " for female ownership."),
      paste0("- Design effect ", v$m4_deff_a_y, " (mean) and ", v$m4_deff_a_p, " (proportion): RE ", v$m4_re_y,
             " and ", v$m4_re_p, "."),
      "- Larger clusters (wards, towns) are far worse. Cluster sampling is chosen for cost, not precision."
    ),
    c(
      paste0("- Best design for the proportion: systematic (RE ", v$m5_re_best_p, "); for the mean: Neyman ",
             "stratified (", v$m5_gain_best_m, "% better than SRS); cluster sampling is the least precise."),
      paste0("- In 500 repetitions, CIs for P contained the truth ", v$m5_cov_p, "% of the time (cluster ",
             v$m5_cov_p_cl, "%), but CIs for the mean only ", v$m5_cov_mean, "%."),
      paste(
        "- F-tests agree with the exact variances for the proportion;",
        "for the skewed mean the normality assumption fails."
      ),
      "- Recommended design: systematic sampling on the location-ordered census list."
    )
  )
  c(paste0("# Chapter ", if (m$no %in% 4:5) 5 else 4, ": Conclusion"), "", txt, "")
}

sources <- function(m, chapter_no) {
  folder_links <- paste0("<", GITHUB_URL, "/tree/main/output/", m$folders, ">", collapse = " and ")
  c(
    paste0("# Chapter ", chapter_no, ": Sources and references"), "",
    "## Sources", "",
    paste0("- Data: Sixth Economic Census 2012-13 microdata, MoSPI, National Data Archive: <", MOSPI_URL, ">"),
    paste0("- Ministry of Statistics and Programme Implementation: <", MOSPI_HOME, ">"),
    paste0("- Code, tables and figures of this project: <", GITHUB_URL, ">"),
    paste0("- Results of this member's part: ", folder_links),
    paste0("- Export of the Nesstar file: R package nesstarR, <", NESSTARR_URL, ">"), "",
    "## References", "",
    paste(
      "1. Ministry of Statistics and Programme Implementation, Central Statistics Office.",
      "*All India Report of Sixth Economic Census*. Government of India."
    ),
    paste(
      "2. Ministry of Statistics and Programme Implementation.",
      "*Instruction Manual, Sixth Economic Census 2012-2013*. Government of India."
    ),
    paste0(
      "3. Ministry of Statistics and Programme Implementation. *Sixth Economic Census 2012-13 microdata*. ",
      "National Data Archive, ", MOSPI_URL, " (accessed November 2026)."
    ),
    "4. Cochran, W. G. (2008). *Sampling Techniques*, 3rd ed. New York: John Wiley and Sons.",
    paste(
      "5. Gupta, S. C. and Kapoor, V. K. (2018). *Fundamentals of Applied Statistics*, 4th ed.",
      "New Delhi: Sultan Chand and Sons."
    ),
    ""
  )
}

# ---- Build one report ----------------------------------------------------------------
build_report <- function(m) {
  body <- intro(m)
  body <- c(body, paste0("# Chapter 2: ", m$chapter), "")
  for (f in m$folders) body <- c(body, unit_body(f))
  next_ch <- 3
  if (m$no <= 4) {
    body <- c(body, comparison(m))
    next_ch <- 4
  }
  if (m$no == 4) {
    body <- c(body, "# Chapter 4: Sampling and non-sampling errors", "",
      team_section("member4_cluster.md", "## 8."))
  }
  if (m$no == 5) {
    body <- c(body, "# Chapter 3: Link to India's official statistical system", "",
      team_section("member5_comparison.md", "## 8."))
    next_ch <- 4
  }
  body <- c(body, conclusion(m))
  body <- c(body, sources(m, if (m$no %in% 4:5) 6 else 5))

  md <- file.path(BUILD, paste0(m$file, ".md"))
  writeLines(body, md, useBytes = TRUE)
  body_pdf <- file.path(BUILD, paste0(m$file, "_body.pdf"))
  markdown_to_pdf(md, body_pdf, extra_css = "h1 { break-before: page; } h1:first-of-type { break-before: auto; }")

  tex <- readLines("reports/template/front.tex", encoding = "UTF-8")
  tex <- gsub("@@LOGO@@", file.path(ROOT, "reports/template/christ_logo.png"), tex, fixed = TRUE)
  tex <- gsub("@@METHOD@@", m$method, tex, fixed = TRUE)
  tex <- gsub("@@ALSO@@", m$also, tex, fixed = TRUE)
  cover <- paste0(TEAM_MEMBERS$name, " -- ", TEAM_MEMBERS$reg, collapse = "\\\\[4pt]\n")
  tex <- gsub("@@COVER_NAMES@@", cover, tex, fixed = TRUE)
  holder <- ROLE_HOLDER[as.character(m$no)]
  holder_reg <- if (is.na(holder)) "" else TEAM_MEMBERS$reg[TEAM_MEMBERS$name == holder]
  tex <- gsub("@@STUDENT_NAME@@", if (is.na(holder)) "" else holder, tex, fixed = TRUE)
  tex <- gsub("@@STUDENT_REG@@", holder_reg, tex, fixed = TRUE)
  for (i in 1:5) {
    who <- ROLE_HOLDER[as.character(i)]
    tex <- gsub(paste0("@@ROLE_NAME_", i, "@@"), if (is.na(who)) "" else who, tex, fixed = TRUE)
  }
  stopifnot(!any(grepl("@@", tex[!startsWith(trimws(tex), "%")])))  # every placeholder filled
  front_tex <- file.path(BUILD, paste0(m$file, "_front.tex"))
  writeLines(tex, front_tex)
  status <- system2("pdflatex", c("-interaction=nonstopmode", "-halt-on-error",
    paste0("-output-directory=", shQuote(BUILD)), shQuote(front_tex)), stdout = FALSE, stderr = FALSE)
  if (status != 0) stop("pdflatex failed for ", m$file, "; see ", sub("\\.tex$", ".log", front_tex))

  out <- file.path("reports", paste0(m$file, ".pdf"))
  system2("qpdf", c("--empty", "--pages", shQuote(sub("\\.tex$", ".pdf", front_tex)), shQuote(body_pdf),
    "--", shQuote(out)))
  message("Written ", out)
}

for (m in MEMBERS) build_report(m)
