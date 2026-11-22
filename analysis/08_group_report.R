# =============================================================================
# 08_group_report.R — the group report (one PDF for the whole group)
#
# Follows the assignment's report format: cover with every member's role,
# Introduction, Population and Frame, Method-wise Analysis (Units 1-4),
# Comparison and Interpretation, Errors, Official Statistics Link, Conclusion,
# References, and the Annexure (dataset, selected sample units, R work).
# Every number is read from the verified results (analysis/summary_values.R and
# output/*/tables). At the end the report is checked against the assignment's
# rubric (page limit, sections, references, annexure, roles on page 1).
#
# Needs: pdflatex (cover), Google Chrome/Chromium (body), qpdf (merge).
# Output: group_report.pdf (project root) and reports/rubric_check.md
# =============================================================================
source("analysis/summary_values.R")

for (tool in c("pdflatex", "qpdf")) {
  if (!nzchar(Sys.which(tool))) stop(tool, " is needed to build the group report.")
}
if (is.na(find_chrome())) stop("Google Chrome or Chromium is needed to build the group report.")

ROOT <- normalizePath(".")
BUILD <- file.path(tempdir(), "group_report")
dir.create(BUILD, showWarnings = FALSE)
dir.create("reports", showWarnings = FALSE)
OUT_PDF <- "group_report.pdf"

pp <- load_shared("population")
srs <- load_shared("srs")
strat <- load_shared("stratified")
sys <- load_shared("systematic")
clu <- load_shared("cluster")

# ---- Small helpers ----------------------------------------------------------------
csv <- function(folder, name) read.csv(file.path("output", folder, "tables", paste0(name, ".csv")), check.names = FALSE)
n_tab <- 0
n_fig <- 0
table_md <- function(df, caption, digits = 4) {
  n_tab <<- n_tab + 1
  c(paste0("**Table ", n_tab, ": ", caption, "**"), "", md_table(df, digits), "")
}
figure_md <- function(path, caption) {
  n_fig <<- n_fig + 1
  c(paste0("![", caption, "](file://", file.path(ROOT, path),
    ")"), "", paste0("*Figure ", n_fig, ": ", caption, "*"), "")
}
credit <- function(i) paste0("<p class=\"credit\">Prepared by ", TEAM$name[i], " (", TEAM$reg[i], ")</p>")
results_md <- function(res, caption) {
  tab <- pretty_results(res)[, c("Design", "Parameter",
    "Estimate", "Variance", "SE", "95% CI", "True value", "Exact SE")]
  table_md(tab, caption)
}
fmt_row <- function(df, digits = 3) {
  df[] <- lapply(df, function(x) if (is.numeric(x)) fmt_num(x, digits) else x)
  df
}

# A section of a TEAM note ("## 8." ...), with cross-references pointed at this report.
team_section <- function(file, heading_start, number) {
  lines <- readLines(file.path("TEAM", file), encoding = "UTF-8")
  a <- which(startsWith(lines, heading_start))[1]
  nxt <- which(startsWith(lines, "## ") & seq_along(lines) > a)
  body <- lines[(a + 1):(if (length(nxt)) nxt[1] - 1 else length(lines))]
  body <- body[!startsWith(body, "> ")]
  heading <- grepl("^\\*\\*8\\.[0-9]+ [^*]+\\*\\*", body)
  body[heading] <- sub(
    "^\\*\\*8\\.([0-9]+ [^*]+?)\\.?\\*\\*\\s*(.*)$", paste0("#### ", number, ".\\1\n\n\\2"), body[heading],
    perl = TRUE
  )
  body <- gsub("(see K Suraj Das's report, Tables 1.3-1.4)", "(Section 2.2)", body, fixed = TRUE)
  body <- gsub("(see K Suraj Das's report, Table 1.3)", "(Section 2.2)", body, fixed = TRUE)
  body <- gsub("(see K Suraj Das's report, Table 0.1)", "(Annexure A)", body, fixed = TRUE)
  body <- gsub("Akash Kumar's simulation", "The simulation in Section 4", body, fixed = TRUE)
  body
}

# =============================================================================
# Main report
# =============================================================================
md <- c()
add <- function(...) md <<- c(md, ...)

# ---- Contents and abstract ---------------------------------------------------------
add(
  "<h2 class=\"front\">Abstract</h2>", "",
  paste0(
    "We applied simple random sampling (with and without replacement), stratified, systematic and single-stage ",
    "cluster sampling to a real population: all ", v$N, " establishments in Karnataka listed in the Sixth Economic ",
    "Census 2012-13 of the Ministry of Statistics and Programme Implementation (MoSPI). For each design we estimated ",
    "the mean and total number of persons employed per establishment and the proportion of female-owned ",
    "establishments, with variances, standard errors, 95% confidence intervals and finite population corrections, ",
    "using a common sample size n = ", v$n, ". Because the full census is available, every estimate was compared ",
    "with the true value and every design's exact variance was computed. Systematic sampling on the location-ordered ",
    "list was the most efficient design for the proportion (RE ", v$cmp_re_best_p, "), Neyman-allocated stratified ",
    "sampling the most efficient for the mean (", v$cmp_gain_best_m,
    "% gain), and cluster sampling the least efficient ",
    "because of strong intraclass correlation. The extreme skewness of employment limited the gains of every design ",
    "for the mean. We recommend systematic sampling on the location-ordered census list."
  ), "",
  "<h2 class=\"front\">Contents</h2>", "",
  "1. Introduction", "2. Population and Frame", "3. Method-wise Analysis (Units 1 to 4)",
  "4. Comparison and Interpretation", "5. Sampling and Non-sampling Errors",
  "6. Link to India's Official Statistical System",
  "7. Conclusion", "8. References", "Annexure A: Dataset · Annexure B: Selected sample units · Annexure C: R work", ""
)

# ---- 1 Introduction ----------------------------------------------------------------
add(
  "# 1. Introduction", "",
  paste0(
    "The objective of this project is to design and carry out sample surveys of one real population with the four ",
    "sampling techniques of the syllabus, to estimate a mean, a total and a proportion with each of them, and to ",
    "compare how precise and how practical the designs are. The work also links the data to India's official ",
    "statistical system, which produced it."
  ), "",
  paste0(
    "The project was divided by method, following the role split of the assignment: ",
    paste0(TEAM$name, " (", sub(";.*", "", TEAM$role), ")", collapse = "; "),
    ". Charts and visuals were coordinated by ", TEAM$name[3], ", the error analysis was written by ", TEAM$name[4],
    ", and the comparison, official statistics link and report compilation by ", TEAM$name[5],
    ". The author of each part is named at the start of its section. All analysis was carried out in R; the code, ",
    "tables, figures and selected samples are available at <", GITHUB_URL, ">."
  ), ""
)

# ---- 2 Population and frame -------------------------------------------------------------
design <- csv("01_srs", "survey_design")
truth <- csv("01_srs", "population_truth")
size <- csv("01_srs", "sample_size")
add(
  "# 2. Population and Frame", credit(1), "",
  "## 2.1 Population and data source", "",
  paste0(
    "The population is the **", v$N, " establishments in Karnataka** enumerated in the Sixth Economic Census ",
    "2012-13 (MoSPI, <", MOSPI_URL, ">). An establishment is a unit engaged in producing or distributing goods or ",
    "services not only for its own use. The microdata are distributed by MoSPI in Nesstar format; we exported the ",
    "Karnataka file with the open-source R package nesstarR and compared the export with the official summary ",
    "pages that MoSPI published for every variable (valid cases, every category count, minimum, maximum, mean and ",
    "SD). **All ", v$checks_total, " checks matched** (Annexure A), so no value was lost or altered."
  ), "",
  "## 2.2 Data cleaning", "",
  paste0(
    "No record had missing values, zero workers or an inconsistent total (TOTAL_WORKER always equals the sum of male ",
    "and female, hired and not hired workers), so the whole census list is used as the frame. ", v$srs_suspect,
    " single-owner establishments report 10,000 or more workers, ", v$srs_exact, " of them exactly 10,001 or 10,002, ",
    "a pattern typical of a data-entry code. They were kept, because the project must use the official data, and ",
    "their effect was measured: the mean changes only from 2.481 to 2.456, but the SD from ", v$srs_sd_all, " to ",
    v$srs_sd_wo, "."
  ), "",
  "## 2.3 Survey design", "",
  table_md(design, "Survey design (the same for every method)"),
  "## 2.4 The population", "",
  table_md(fmt_row(truth[c(1, 2, 3, 5, 6, 7, 8, 9), ], 5), "True population values, known from the census"),
  figure_md("output/01_srs/figures/distribution_of_workers.png",
    "Workers per establishment: most establishments have one worker, a few have thousands"),
  paste0(
    "The study variable is extremely right-skewed (median ", v$median, ", maximum ", v$maxY, ", coefficient of ",
    "variation ", v$srs_cv, "). This shapes every result: the mean is hard to estimate, the proportion is not."
  ), "",
  "## 2.5 Sample size", "",
  paste0(
    "One sample size is used for every method. For a proportion with margin of error d at 95% confidence (Cochran), ",
    "n<sub>0</sub> = z<sup>2</sup>PQ/d<sup>2</sup> and n = n<sub>0</sub>/(1 + (n<sub>0</sub> - 1)/N). With P = ", v$P,
    " (from the census; in practice from the previous census or a pilot) and d = 0.03 this gives n = ", v$srs_nreq,
    ". We use **n = ", v$n, "**, the smallest number above ", v$srs_nreq, " that divides N exactly (", v$n, " x ",
    v$k, " = ", v$N, "), as linear systematic sampling with N = nk requires. The mean would need ", v$srs_nmean10,
    " establishments for 10% precision, which is why the designs are compared on how much they improve on SRS."
  ), "",
  table_md(fmt_row(size, 5), "Sample size determination")
)

# ---- 3 Method-wise analysis -----------------------------------------------------------
add("# 3. Method-wise Analysis (Units 1 to 4)", "")

# 3.1 SRS
cmp_wr <- csv("01_srs", "wor_vs_wr")
add(
  "## 3.1 Unit 1: SRSWOR and SRSWR", credit(1), "",
  paste0(
    "**Formulas.** SRSWOR: ybar = Σy<sub>i</sub>/n, v(ybar) = (1 - f)s<sup>2</sup>/n, v(p) = (1 - f)pq/(n - 1), with ",
    paste(
      "f = n/N. SRSWR: v(ybar) = s<sup>2</sup>/n, v(p) = pq/(n -",
      "1). Total = N x mean, with variance N<sup>2</sup> x v(ybar). "
    ),
    "95% CI = estimate ± 1.96 SE. Here f = n/N = ",
    signif(N_SAMPLE / pp$N, 3), " and the fpc (1 - f) = ", v$srs_fpc, "."
  ), "",
  results_md(srs, "SRSWOR and SRSWR estimates (exact SE from the census)"),
  table_md(fmt_row(cmp_wr, 6), "Exact variances of SRSWOR and SRSWR"),
  paste0(
    "**Interpretation.** Both confidence intervals contain the true values. The two samples' SEs for the mean differ ",
    "greatly (", fmt_fixed(srs$se[1], 3), " and ", fmt_fixed(srs$se[4],
    3), ") although the exact SE is ", v$srs_exact_se,
    paste(
      " for both: with such skewed data, whether a sample",
      "includes one very large establishment dominates s<sup>2</sup>. "
    ),
    "SRSWR is less precise by the factor (N - 1)/(N - n) = ", v$srs_ratio, ", only ", v$srs_ratio_pct, "%, because ",
    "the sampling fraction is tiny; the probability that a given establishment is selected is n/N = ",
    signif(N_SAMPLE / pp$N, 3), "."
  ), ""
)

# 3.2 Stratified
info <- strat$info
alloc <- data.frame(
  Stratum = info$stratum, N_h = info$N_h, W_h = info$W_h, `Mean Ybar_h` = info$Ybar_h, `SD S_h` = info$S_h,
  `P_h` = info$P_h, `n_h proportional` = strat$nh_prop, `n_h Neyman` = strat$nh_ney, check.names = FALSE
)
gain <- csv("02_stratified", "gain_in_precision")
an2 <- csv("02_stratified", "anova_sample")
add(
  "## 3.2 Unit 2: Stratified random sampling", credit(2), "",
  paste0(
    "**Strata.** Karnataka's four revenue divisions (Bengaluru, Mysuru, Belagavi, Kalaburagi), known for every ",
    "establishment from its district code. Within each stratum an SRSWOR of n<sub>h</sub> units is drawn. ",
    paste(
      "**Formulas:** ybar<sub>st</sub> =",
      "ΣW<sub>h</sub>ybar<sub>h</sub>, v(ybar<sub>st</sub>) = ΣW<sub>h</sub><sup>2</sup>"
    ),
    "(1 - f<sub>h</sub>)s<sub>h</sub><sup>2</sup>/n<sub>h</sub>, p<sub>st</sub> = ΣW<sub>h</sub>p<sub>h</sub>, ",
    "v(p<sub>st</sub>) = ΣW<sub>h</sub><sup>2</sup>(1 - f<sub>h</sub>)p<sub>h</sub>q<sub>h</sub>/(n<sub>h</sub> - 1). ",
    paste(
      "Proportional allocation n<sub>h</sub> = nN<sub>h</sub>/N;",
      "Neyman allocation n<sub>h</sub> = nN<sub>h</sub>S<sub>h</sub>/"
    ),
    "ΣN<sub>h</sub>S<sub>h</sub>. Every f<sub>h</sub> is below 0.0004, so the fpc is practically 1."
  ), "",
  table_md(fmt_row(alloc, 4), "Strata in the population and the allocation of n = 748"),
  results_md(strat$results, "Stratified estimates under both allocations"),
  table_md(fmt_row(gain[, c(1, 5, 6, 7, 8)], 4),
    "Relative efficiency against SRSWOR and gain in precision (exact variances)"),
  paste0(
    "**Why.** Cochran's decomposition explains the gains exactly. V<sub>SRS</sub> - V<sub>prop</sub> ≈ (1 - f)/n · ",
    "ΣW<sub>h</sub>(Ybar<sub>h</sub> - Ybar)<sup>2</sup>: the stratum means explain only ", v$strat_share_pct,
    paste(
      "% of S<sup>2</sup>, so proportional allocation gains",
      "nothing for the mean. V<sub>prop</sub> - V<sub>Neyman</sub> = "
    ),
    "(1/n)ΣW<sub>h</sub>(S<sub>h</sub> - Sbar)<sup>2</sup> = ", v$strat_vdiff, ": the stratum SDs differ (",
    v$strat_sd_range, "), so Neyman allocation gains ", v$strat_gain_ney, "%. Neyman allocation, optimised for the ",
    "mean, is worse for the proportion (RE ", v$strat_re_ney_p, "); the allocation optimal for P gives RE ",
    v$strat_re_neyP, ". Activity type would be the better basis for the proportion (RE ", v$strat_act_re_p, ")."
  ), "",
  figure_md("output/02_stratified/figures/allocation.png", "Proportional and Neyman allocation of n = 748"),
  paste0(
    "**ANOVA with strata as groups** (proportional sample; H<sub>0</sub>: all stratum means equal; 5% level): ",
    "SSB = ", fmt_num(an2[1, 3], 4), ", SSW = ", fmt_num(an2[2,
    3], 6), ", F(3, 744) = ", v$strat_F, ", p = ", v$strat_p,
    ", so we **", v$strat_decision, "**. Normality fails (skewness ", v$strat_skew, "); the rank-based Kruskal-Wallis ",
    "test gives p = ", v$strat_kw_p, " and we ", v$strat_kw_decision, ": the typical establishment does differ ",
    "between divisions, but a few huge values hide this from the F-test."
  ), ""
)

# 3.3 Systematic
starts <- csv("03_systematic", "all_starts")
order_tab <- csv("03_systematic", "list_order")
k_tab <- csv("03_systematic", "effect_of_k")
add(
  "## 3.3 Unit 3: Systematic sampling", credit(3), "",
  paste0(
    "**Design.** The frame is ordered by location code (district, tehsil, town/village, ward, enumeration block). ",
    "With N = nk, k = ", v$k, " and a random start r = ", v$sys_r, ", the sample is units r, r + k, ..., ",
    paste(
      "r + (n - 1)k. ybar<sub>sy</sub> is the sample mean. A",
      "single systematic sample has no unbiased variance estimator, "
    ),
    "so v = (1 - f)s<sup>2</sup>/n (SRS approximation) is reported, and the exact variance ",
    "V(ybar<sub>sy</sub>) = (1/k)Σ(ybar<sub>r</sub> - Ybar)<sup>2</sup> is computed from all ",
    v$k, " possible samples."
  ), "",
  results_md(sys$results, "Systematic sample estimates (start r = 975)"),
  table_md(fmt_row(starts[c(1, 3, 5, 6, 7, 8, 9), ], 4), "Effect of the starting point: all 3,851 possible samples"),
  figure_md("output/03_systematic/figures/all_starts_histogram.png",
    "Estimates from every possible starting point (red = true value, blue = our sample)"),
  table_md(fmt_row(rbind(
    data.frame(Setting = paste0("k = ", fmt_num(k_tab$k), " (n = ", k_tab$n, ")"),
      `RE mean` = k_tab[[3]], `RE proportion` = k_tab[[4]], check.names = FALSE),
    data.frame(Setting = paste0("List order: ", order_tab[[1]]),
      `RE mean` = order_tab[[2]], `RE proportion` = order_tab[[3]], check.names = FALSE)
  ), 4), "Effect of the interval k and of the list order (relative efficiency against SRSWOR)"),
  paste0(
    "**ANOVA with the ", v$k,
    " systematic samples as groups** (H<sub>0</sub>: the possible samples have equal means): ",
    "F = ", v$sys_F_mean, " (p = ", v$sys_p_mean, ") for workers and F = ", v$sys_F_prop, " (p = ", v$sys_p_prop,
    ") for female ownership, so we **do not reject H<sub>0</sub>**: the starting point makes no systematic difference ",
    "and there is no trend or periodicity in the list. The within-sample variance equals the population variance for ",
    "workers and is slightly larger for female ownership, which is why systematic sampling beats SRS for the ",
    "proportion (RE ", v$sys_re_p, ", better than stratification by division) but not for the mean: each sample is ",
    paste(
      "spread over every district and town, an implicit",
      "stratification by location. On a shuffled list the gain disappears."
    )
  ), ""
)

# 3.4 Cluster
icc <- csv("04_cluster", "icc_design_effect")
size_tab <- csv("04_cluster", "cluster_size_effect")
add(
  "## 3.4 Unit 4: Single-stage cluster sampling", credit(4), "",
  paste0(
    "**Design.** Clusters are the ", v$Nc, " census enumeration blocks (average size Mbar = ", v$clu_Mbar, "). ",
    v$n_c, " blocks were selected by SRSWOR and every establishment in them was included (about ", v$clu_units,
    " establishments). Because block sizes vary from 1 to ", v$clu_maxM, ", the ratio estimator ybar<sub>cl</sub> = ",
    "Σy<sub>i</sub>/ΣM<sub>i</sub> is used, with v(ybar<sub>cl</sub>) = (1 - f)/(n<sub>c</sub>Mbar<sup>2</sup>) · ",
    "Σ(y<sub>i</sub> - ybar<sub>cl</sub>M<sub>i</sub>)<sup>2</sup>/(n<sub>c</sub> - 1); the unbiased estimator ",
    "N<sub>c</sub>Σy<sub>i</sub>/(n<sub>c</sub>N) is shown for comparison. CIs use t with ", v$clu_df,
    " df; fpc = ", v$clu_fpc, "."
  ), "",
  results_md(rbind(clu$results, clu$unbiased), "Cluster sample estimates (ratio and unbiased estimators)"),
  table_md(fmt_row(icc[c(1, 2, 4, 5, 6, 7), ], 4), "ANOVA mean squares, intraclass correlation and design effect"),
  paste0(
    "**ANOVA with clusters as groups** (H<sub>0</sub>: no clustering): F = ", v$clu_F_y, " for workers and ",
    v$clu_F_p, " for female ownership, so we **reject H<sub>0</sub>** for both. The intraclass correlation ",
    "ρ = (MSB - MSW)/(MSB + (m<sub>0</sub> - 1)MSW) is ", v$clu_icc_y, " for workers and ", v$clu_icc_p,
    " for female ownership: establishments in the same block are alike. The design effect is ", v$clu_deff_a_y,
    " for the mean and ", v$clu_deff_a_p, " for the proportion (the formula 1 + (Mbar - 1)ρ, which assumes equal ",
    "clusters, gives ", v$clu_deff_f_y, " and ", v$clu_deff_f_p, "), so cluster sampling is only ", v$clu_re_y_pct,
    "% and ", v$clu_re_p_pct, "% as efficient as SRS."
  ), "",
  figure_md("output/04_cluster/figures/female_share_by_cluster.png",
    "Female ownership by block is far more spread out than it would be without clustering"),
  table_md(fmt_row(size_tab[, c(1, 2, 3, 6, 7)], 4), "Larger clusters, larger design effect (same total sample size)"),
  paste0(
    "**Interpretation.** Small clusters are the only workable choice; wards and whole towns or villages are far ",
    "worse. Cluster sampling is chosen for its low field cost (", v$n_c, " compact areas, and only a list of blocks ",
    "is needed), not for precision."
  ), ""
)

# ---- 4 Comparison and interpretation ------------------------------------------------------
master <- csv("05_comparison", "master_comparison")
master_tab <- pretty_results(master)[, c("Parameter", "Design", "Estimate", "SE", "95% CI", "Abs. error")]
master_tab$`RE vs SRSWOR` <- fmt_fixed(master$RE, 3)
sf <- csv("05_comparison", "f_tests_simulation")
sim <- csv("05_comparison", "simulation_summary")
rec <- csv("05_comparison", "recommendation")
anovas <- data.frame(
  Design = c("Stratified (sample, n = 748)", "Systematic (all 3,851 samples)", "Systematic (all 3,851 samples)",
             "Cluster (all 105,624 blocks)", "Cluster (all 105,624 blocks)"),
  Variable = c("Workers", "Workers", "Female ownership", "Workers", "Female ownership"),
  F = c(an2$F[1], csv("03_systematic", "anova_mean")$F[1], csv("03_systematic", "anova_proportion")$F[1],
        csv("04_cluster", "anova_workers")$F[1], csv("04_cluster", "anova_female")$F[1]),
  `p-value` = c(an2[["p-value"]][1], csv("03_systematic", "anova_mean")[["p-value"]][1],
                csv("03_systematic", "anova_proportion")[["p-value"]][1],
                csv("04_cluster", "anova_workers")[["p-value"]][1], csv("04_cluster", "anova_female")[["p-value"]][1]),
  check.names = FALSE
)
anovas$Decision <- ifelse(anovas[["p-value"]] < ALPHA, "Reject H0", "Do not reject H0")
add(
  "# 4. Comparison and Interpretation", credit(5), "",
  paste0(
    "Every design was applied to the same population with about the same sample size. RE = exact variance of ",
    "SRSWOR / exact variance of the design (above 1 = more precise than SRS); the absolute error is measured against ",
    "the census value."
  ), "",
  table_md(master_tab, "Comparison of all designs: estimate, SE, 95% CI, absolute error and relative efficiency"),
  figure_md("output/05_comparison/figures/relative_efficiency.png",
    "Relative efficiency of each design against SRSWOR"),
  "## 4.1 ANOVA: where the variance comes from", "",
  table_md(anovas, "The three ANOVAs (5% level of significance)"),
  paste0(
    "Stratification removes between-group variance and gains when groups differ; clustering is hurt by it. Here the ",
    "strata hardly differ in mean, the clusters do, and the systematic samples do not differ from each other, which ",
    "matches the efficiencies in Table ", n_tab - 1, ". All three tests assume roughly normal data; employment is ",
    "extremely skewed, so the tests for workers are approximate, while the 0/1 female-ownership variable behaves well ",
    "with these sample sizes."
  ), "",
  "## 4.2 F-tests comparing the variances of two designs", "",
  paste0(
    "For two designs, H<sub>0</sub>: their estimators have equal variance; H<sub>1</sub>: the one with the larger ",
    paste(
      "variance is less precise; F = larger variance/smaller",
      "variance; reject at the 5% level if p < 0.05. Single-sample "
    ),
    "variance estimates are very noisy for skewed data, so each design was repeated 500 times and the variances of ",
    "the 500 estimates were compared, F(499, 499)."
  ), "",
  table_md(sf[, c("Comparison", "Parameter", "Larger variance", "F", "p-value", "Decision")],
    "F-tests on 500 repeated samples per design"),
  paste0(
    "For the proportion every test agrees with the exact variances: systematic sampling is significantly more precise ",
    "than SRS, while Neyman allocation (optimised for the mean) and cluster sampling are significantly less precise. ",
    "For the mean the estimates are strongly right-skewed, the F-test's normality assumption fails, and ",
    v$cmp_wrong, " points the wrong way, a direct demonstration of why the assumption matters."
  ), "",
  "## 4.3 Simulation (optional extension)", "",
  table_md(fmt_row(sim[, c(1, 2, 3, 5, 6, 7)], 4), "500 repetitions of every design: bias, spread and CI coverage"),
  figure_md("output/05_comparison/figures/simulation_proportion.png",
    "500 estimates of the proportion from each design"),
  paste0(
    "For the proportion, every design is unbiased, the simulated SE agrees with the exact SE, and 95% CIs contain the ",
    "truth about 95% of the time (", v$cmp_cov_p, "%; cluster ",
    v$cmp_cov_p_cl, "%). For the mean only ", v$cmp_cov_mean,
    "% do, because most samples miss the rare very large establishments."
  ), "",
  "## 4.4 Recommended design", "",
  table_md(rec, "Precision, cost and convenience of each design"),
  paste0(
    "**We recommend systematic sampling on the census list ordered by location.** It is the most precise design for ",
    "the proportion (RE ", v$cmp_re_best_p, ") and as good as SRS for the mean (RE ", v$cmp_re_sys_mean, "); it needs ",
    "one random number, is easy to carry out, and spreads the sample over every district. If the mean were the main ",
    "target, Neyman-allocated stratified sampling would be preferred. Cluster sampling is cheapest in the field but ",
    "loses most of its precision (RE ", v$cmp_re_cl_p, " for the proportion)."
  ), ""
)

# ---- 5 Errors, 6 Official statistics ---------------------------------------------------
add("# 5. Sampling and Non-sampling Errors", credit(4), "", team_section("cluster.md", "## 8.", 5), "")
add("# 6. Link to India's Official Statistical System", credit(5), "", team_section("comparison.md", "## 8.", 6), "")

# ---- 7 Conclusion ----------------------------------------------------------------------
add(
  "# 7. Conclusion", "",
  paste0("- The population of ", v$N, " establishments was verified against ", v$checks_total,
         " official MoSPI figures; n = ", v$n, " estimates P within about 3 percentage points."),
  paste0("- SRSWOR and SRSWR are practically equivalent here (variance ratio ", v$srs_ratio, ")."),
  paste0("- Stratification by division: proportional allocation gains nothing for the mean, Neyman gains ",
         v$strat_gain_ney, "%, because the strata differ in spread, not in mean."),
  paste0("- Systematic sampling on the location-ordered list is ", v$sys_gain_p,
         "% more efficient than SRS for the proportion; the starting point does not matter."),
  paste0("- Cluster sampling suffers from intraclass correlation (", v$clu_icc_p, " for female ownership): RE ",
         v$clu_re_p, " for the proportion."),
  paste(
    "- With extremely skewed data no design estimates the mean much better than SRS;",
    "single-sample SEs and F-tests can mislead, and exact variances and simulation are the reliable comparison."
  ),
  "- **Recommended design: systematic sampling on the location-ordered census list.**",
  "",
  paste0(
    "**Limitations.** The prior value of P for the sample size and the stratum SDs for Neyman allocation were taken ",
    "from the census itself; a real survey would take them from a previous census or a pilot. The frame dates from ",
    "2013 and excludes some activities (Section 5)."
  ), ""
)

# ---- 8 References ----------------------------------------------------------------------
add(
  "# 8. References", "",
  paste(
    "1. Ministry of Statistics and Programme Implementation, Central Statistics",
    "Office. *All India Report of Sixth Economic Census*. New Delhi: Government of India."
  ),
  paste(
    "2. Ministry of Statistics and Programme Implementation. *Instruction",
    "Manual, Sixth Economic Census 2012-2013*. New Delhi: Government of India."
  ),
  paste0(
    "3. Ministry of Statistics and Programme Implementation. *Sixth Economic Census 2012-13 microdata*. ",
    "National Data Archive, ", MOSPI_URL, " (accessed November 2026)."
  ),
  paste0("4. Ministry of Statistics and Programme Implementation, <", MOSPI_HOME, ">."),
  "5. Cochran, W. G. (2008). *Sampling Techniques*, 3rd ed. New York: John Wiley and Sons.",
  paste(
    "6. Gupta, S. C. and Kapoor, V. K. (2018). *Fundamentals of",
    "Applied Statistics*, 4th ed. New Delhi: Sultan Chand and Sons."
  ),
  paste0("7. Choudhary, S. *nesstarR: read Nesstar files in R*, <", NESSTARR_URL, ">."),
  paste0("8. Project repository (code, tables, figures and samples), <", GITHUB_URL, ">."),
  ""
)

# =============================================================================
# Annexure
# =============================================================================
ann <- c()
adda <- function(...) ann <<- c(ann, ...)
verify <- csv("00_data_verification", "export_verification")
frame_cols <- data.frame(
  Column = c("unit_id", "DT, district", "division", "activity", "sector", "ownership", "cluster_id", "Y", "female"),
  Meaning = c("position in the location-ordered frame (1 to N)", "district code and name", "revenue division (strata)",
              "broad activity group", "rural / urban", "type of ownership code", "enumeration block (clusters)",
              "persons employed (TOTAL_WORKER)", "1 if the owner is a woman (SEX = 2)")
)
adda(
  "# Annexure A: Dataset", "",
  paste0(
    "**Source:** Sixth Economic Census 2012-13, MoSPI (<", MOSPI_URL, ">), Karnataka file, ", v$N, " establishments ",
    "x 25 variables. The cleaned frame used by every method is `data/frame_karnataka.rds` in the project repository ",
    "(<", GITHUB_URL, ">); its columns are listed below. The full table cannot be printed (2.9 million rows)."
  ), "",
  table_md(frame_cols, "Columns of the sampling frame"),
  table_md(verify, "Verification of the export against the official MoSPI variable pages"),
  "# Annexure B: Sample units selected under each method", "",
  paste0(
    "The complete lists of selected establishments are in the repository: `output/01_srs/samples/`, ",
    "`output/02_stratified/samples/`, `output/03_systematic/samples/` and `output/04_cluster/samples/`. ",
    "The first ten units of each sample are shown here, with the 27 selected enumeration blocks in full."
  ), ""
)
sample_files <- list(
  "SRSWOR" = "output/01_srs/samples/srswor_sample.csv",
  "SRSWR" = "output/01_srs/samples/srswr_sample.csv",
  "Stratified, proportional allocation" = "output/02_stratified/samples/stratified_proportional_sample.csv",
  "Stratified, Neyman allocation" = "output/02_stratified/samples/stratified_neyman_sample.csv",
  "Systematic (start r = 975, every 3,851st unit)" = "output/03_systematic/samples/systematic_sample.csv"
)
for (nm in names(sample_files)) {
  s <- read.csv(sample_files[[nm]])
  head_tab <- s[1:10, c("unit_id", "district", "division", "activity", "cluster_id", "Y", "female")]
  names(head_tab) <- c("Unit", "District", "Division", "Activity", "Enumeration block", "Workers", "Female-owned")
  adda(table_md(head_tab, paste0(nm, ": first 10 of ", nrow(s), " units")))
}
sel <- csv("04_cluster", "selected_clusters")
adda(table_md(fmt_row(sel, 4),
  "Cluster sampling: the 27 selected enumeration blocks (every establishment in them was taken)"))
scripts <- data.frame(
  Script = c("common.R", "designs.R", "00_data_verification.R", "01_srs.R", "02_stratified.R", "03_systematic.R",
             "04_cluster.R", "05_comparison.R", "06_slides.R", "07_reports.R", "08_group_report.R", "run_all.R"),
  Purpose = c("settings (n, seed), team, helpers: ANOVA, tables, figures, PDFs",
              "the estimators and exact variances of every design",
              "export from the Nesstar file and check against MoSPI", "frame, sample size, SRSWOR and SRSWR",
              "stratified sampling", "systematic sampling", "cluster sampling",
              "comparison, F-tests, simulation, recommendation", "presentation slides",
              "individual reports", "this report", "runs everything in order"),
  Author = c("", "", TEAM$name[1], TEAM$name[1], TEAM$name[2], TEAM$name[3], TEAM$name[4], TEAM$name[5], "", "", "", "")
)
adda(
  "# Annexure C: R work", "",
  paste0(
    "All work was done in R (base R only; nesstarR for the data export). The scripts are in the `analysis/` folder ",
    "of <", GITHUB_URL, ">; `Rscript analysis/run_all.R` reproduces every number, table and figure (seed 2026). ",
    "The estimators of all designs, as used by every script, are listed below."
  ), "",
  table_md(scripts, "R scripts"),
  "**analysis/designs.R**", "",
  "```r", readLines("analysis/designs.R", encoding = "UTF-8"), "```", ""
)

# =============================================================================
# Build: cover (LaTeX) + main (Chrome) + annexure (Chrome), merged with qpdf
# =============================================================================
REPORT_EXTRA_CSS <- "
body { font-size: 9.6pt; line-height: 1.38; }
h1 { font-size: 15pt; margin-top: 18px; }
h2 { font-size: 12pt; margin-top: 14px; }
h2.front { border: none; margin-top: 4px; }
h4 { font-size: 10pt; margin: 10px 0 4px; color: #1f3b63; }
table { font-size: 7.9pt; margin-bottom: 10px; }
img { max-height: 70mm; max-width: 80%; }
p.credit { font-style: italic; color: #555; margin: -6px 0 8px; font-size: 9pt; }
pre { font-size: 6.9pt; line-height: 1.25; white-space: pre-wrap; break-inside: auto; }
"
main_md <- file.path(BUILD, "main.md")
ann_md <- file.path(BUILD, "annexure.md")
writeLines(md, main_md, useBytes = TRUE)
writeLines(ann, ann_md, useBytes = TRUE)
main_pdf <- file.path(BUILD, "main.pdf")
ann_pdf <- file.path(BUILD, "annexure.pdf")
markdown_to_pdf(main_md, main_pdf, extra_css = paste0(REPORT_EXTRA_CSS,
  paste(
    "@page { @bottom-center { content: 'Page ' counter(page); }",
    "} h1 { break-before: page; } h2.front + p { margin-top: 0; }"
  ),
  " h1:first-of-type { break-before: page; }"))
markdown_to_pdf(ann_md, ann_pdf, extra_css = paste0(REPORT_EXTRA_CSS,
  "@page { @bottom-center { content: 'Annexure, page ' counter(page); } } ",
  "h1 { break-before: page; } h1:first-of-type { break-before: auto; }"))

tex <- readLines("reports/template/front_group.tex", encoding = "UTF-8")
tex <- gsub("@@LOGO@@", file.path(ROOT, "reports/template/christ_logo.png"), tex, fixed = TRUE)
rows <- paste0(TEAM$name, " & ", TEAM$reg, " & ", gsub("&", "\\\\&", TEAM$role), " \\\\ \\hline", collapse = "\n")
tex <- gsub("@@TEAM_ROWS@@", rows, tex, fixed = TRUE)
stopifnot(!any(grepl("@@", tex[!startsWith(trimws(tex), "%")])))
front_tex <- file.path(BUILD, "front.tex")
writeLines(tex, front_tex)
status <- system2("pdflatex", c("-interaction=nonstopmode", "-halt-on-error",
  paste0("-output-directory=", shQuote(BUILD)), shQuote(front_tex)), stdout = FALSE, stderr = FALSE)
if (status != 0) stop("pdflatex failed; see ", file.path(BUILD, "front.log"))

system2("qpdf", c("--empty", "--pages", shQuote(file.path(BUILD, "front.pdf")), shQuote(main_pdf), shQuote(ann_pdf),
  "--", shQuote(OUT_PDF)))
message("Written ", OUT_PDF)

# =============================================================================
# Rubric check (assignment: report format and marking scheme)
# =============================================================================
pages <- function(f) as.integer(sub(".*: *", "", grep("^Pages:",
  system2("pdfinfo", shQuote(f), stdout = TRUE), value = TRUE)))
n_main <- 1 + pages(main_pdf) # cover + body, without the annexure
cover_txt <- paste(system2("pdftotext", c(shQuote(file.path(BUILD, "front.pdf")), "-"), stdout = TRUE), collapse = " ")
heads <- sub("^# ", "", grep("^# ", md, value = TRUE))
required <- c("Introduction", "Population and Frame", "Method-wise Analysis", "Comparison and Interpretation",
              "Errors", "Official Statistic", "Conclusion", "References")
refs <- grep("^[0-9]+\\. ", md[seq(which(md == "# 8. References"), length(md))], value = TRUE)
units_ok <- all(sapply(c("Unit 1", "Unit 2", "Unit 3", "Unit 4"), function(u) any(grepl(u, md, fixed = TRUE))))
checks <- data.frame(
  Requirement = c(
    "15 to 20 pages (cover + report, without annexure)",
    "Each member's name and role on the first page",
    "Sections in the required order",
    "Method-wise analysis for Units 1 to 4",
    "Comparison table with estimate, SE, CI, RE and absolute error",
    "At least one chart",
    "ANOVA for stratified, cluster and systematic designs",
    "F-test comparing two designs, with H0, H1, 5% level, F, p and decision",
    "Recommended design with reasons",
    "Sampling and non-sampling errors discussed",
    "Official statistics link (about 2 pages)",
    "At least 3 references, at least 2 official",
    "Annexure: dataset, sample units of each method, R work"
  ),
  Status = c(
    n_main >= 15 && n_main <= 20,
    all(sapply(TEAM$name, grepl, cover_txt, fixed = TRUE)) && grepl("Role", cover_txt),
    all(diff(sapply(required, function(r) grep(r, heads, fixed = TRUE)[1])) > 0),
    units_ok,
    any(grepl("Comparison of all designs", md, fixed = TRUE)),
    n_fig >= 1,
    all(c("Stratified", "Systematic", "Cluster") %in% sub(" .*", "", anovas$Design)),
    any(grepl("F-tests on 500 repeated samples", md, fixed = TRUE)) && any(grepl("H<sub>0</sub>", md, fixed = TRUE)),
    any(grepl("We recommend", md, fixed = TRUE)),
    any(grepl("Sampling and Non-sampling Errors", heads, fixed = TRUE)),
    any(grepl("Official Statistical System", heads, fixed = TRUE)),
    length(refs) >= 3 && sum(grepl("Ministry of Statistics", refs)) >= 2,
    all(c("# Annexure A: Dataset",
      "# Annexure B: Sample units selected under each method", "# Annexure C: R work") %in% ann)
  ),
  Where = c(
    paste0(n_main, " pages + ", pages(ann_pdf), " annexure pages"),
    "Cover: Name, Register No., Role", "Sections 1-8", "Section 3.1-3.4", "Section 4", paste0(n_fig, " figures"),
    "Sections 3.2-3.4, Section 4.1", "Section 4.2", "Section 4.4", "Section 5", "Section 6",
    paste0(length(refs), " references, ", sum(grepl("Ministry of Statistics", refs)), " official"), "Annexures A-C"
  )
)
checks$Status <- ifelse(checks$Status, "met", "NOT MET")
writeLines(c(
  "# Rubric check: group report", "",
  paste0("Generated by `analysis/08_group_report.R` for `", OUT_PDF, "` on ", Sys.Date(), "."), "",
  md_table(checks), "",
  "## Marking scheme coverage", "",
  md_table(data.frame(
    Component = c("Survey design: population, frame, strata, clusters, sample size (5)",
                  "Own-method estimation: formulas, variance, SE, CI (10)",
                  "Own-method interpretation: precision, efficiency, ICC or gain (5)",
                  "Comparison table, ANOVA and variance comparison, charts, recommended design (8)",
                  "Conclusion, limitations, sampling and non-sampling errors (4)",
                  "Official statistics link (4)"),
    Section = c("2.3-2.5", "3.1-3.4 (formulas, estimate tables with variance, SE, CI, fpc)",
                "3.1-3.4 (interpretation paragraphs; gain 3.2, ICC 3.4)", "4, 4.1-4.4", "5, 7", "6")
  ))
), "reports/rubric_check.md")
print(checks, row.names = FALSE)
if (any(checks$Status != "met")) warning("Some rubric requirements are not met; see reports/rubric_check.md")
