# =============================================================================
# 06_slides.R — builds the presentation from the verified results
#
# Fills presentation/template.html with numbers read from the results that
# scripts 00-05 wrote (output/*/tables/*.csv and output/_shared/*.rds), so the
# slides always match the analysis. Every qualitative claim on the slides is
# checked with stopifnot(): if a re-run changed a conclusion, this script stops
# instead of producing wrong slides.
# Output: presentation/slides.html and presentation/slides.pdf
# =============================================================================
source("analysis/common.R")
source("analysis/designs.R")

tab <- function(folder, name) read.csv(file.path("output", folder, "tables", paste0(name, ".csv")), check.names = FALSE)
row_value <- function(df, pattern, col = 2) df[[col]][grep(pattern, df[[1]], fixed = TRUE)[1]]
f <- function(x, d) formatC(x, format = "f", digits = d, big.mark = ",")
int <- function(x) formatC(round(x), format = "d", big.mark = ",")
pval <- function(p) if (p < 1e-4) "&lt; 0.0001" else f(p, if (p < 0.01) 4 else 3)
decide <- function(p) if (p < ALPHA) "reject H<sub>0</sub>" else "do not reject H<sub>0</sub>"
td <- function(x, num = TRUE) paste0("<td", if (num) " class=\"n\"", ">", x, "</td>")
tr <- function(cells, highlight = FALSE) {
  paste0("<tr", if (highlight) " class=\"hl\"", ">", paste(cells, collapse = ""), "</tr>")
}

v <- list() # placeholder name -> text
frame <- load_frame()
pp <- load_shared("population")
srs <- load_shared("srs")
strat <- load_shared("stratified")
sys <- load_shared("systematic")
clu <- load_shared("cluster")
N <- pp$N
n <- N_SAMPLE

# ---- Common ---------------------------------------------------------------------
checks <- tab("00_data_verification", "export_verification")
v$checks_pass <- sum(checks$Match)
v$checks_total <- nrow(checks)
stopifnot(all(checks$Match))
v$N <- int(N)
v$n <- n
v$k <- int(K_SYS)
v$Ybar <- f(pp$Ybar, 3)
v$P <- f(pp$P, 4)
v$P_pct <- f(100 * pp$P, 1)
v$median <- int(median(frame$Y))
v$maxY <- int(max(frame$Y))
ct <- cluster_table(frame)
v$Nc <- int(nrow(ct))
v$n_c <- clu$n_c

# ---- Member 1 -------------------------------------------------------------------
v$m1_single_pct <- f(100 * mean(frame$Y == 1), 0)
v$m1_cv <- f(sqrt(pp$S2) / pp$Ybar, 1)
suspect <- frame$Y >= 10000 & frame$ownership == "2"
v$m1_suspect <- sum(suspect)
v$m1_exact <- sum(frame$Y[suspect] %in% c(10001, 10002))
sens <- tab("01_srs", "sensitivity_large_values")
v$m1_sd_all <- f(sens[["SD of workers"]][1], 1)
v$m1_sd_wo <- f(sens[["SD of workers"]][2], 1)
size <- tab("01_srs", "sample_size")
v$m1_d <- f(row_value(size, "Required margin"), 2)
v$m1_n0 <- f(row_value(size, "n0 = "), 1)
v$m1_nreq <- int(row_value(size, "n = n0"))
v$m1_nchosen <- int(row_value(size, "Chosen n"))
v$m1_dach <- f(row_value(size, "actually achieved"), 3)
v$m1_nmean10 <- int(row_value(size, "within 10%"))
stopifnot(row_value(size, "Chosen n") == n)
res_row <- function(res, d, p) res[res$design == d & res$parameter == p, ]
srs_cells <- function(d, p, dp) {
  r <- res_row(srs, d, p)
  ci <- paste0("[", f(r$ci_low, dp), ", ", f(r$ci_high, dp), "]")
  tr(c(td(d, FALSE), td(p, FALSE), td(f(r$estimate, dp)), td(f(r$se, dp)), td(ci), td(f(sqrt(r$var_true), dp))))
}
v$m1_srs_rows <- paste(
  srs_cells("SRSWOR", "Mean", 3), srs_cells("SRSWR", "Mean", 3),
  srs_cells("SRSWOR", "Proportion", 4), srs_cells("SRSWR", "Proportion", 4),
  sep = "\n"
)
stopifnot(all(srs$covers_truth[srs$parameter != "Total"])) # slide says both CIs contain the truth
v$m1_fpc <- f(1 - n / N, 4)
v$m1_ratio <- f((N - 1) / (N - n), 5)
v$m1_ratio_pct <- f(100 * ((N - 1) / (N - n) - 1), 3)
v$m1_exact_se <- f(sqrt(res_row(srs, "SRSWOR", "Mean")$var_true), 2)

# ---- Member 2 -------------------------------------------------------------------
info <- strat$info
v$m2_strata_rows <- paste(vapply(seq_len(nrow(info)), function(i) {
  tr(c(
    td(info$stratum[i], FALSE), td(int(info$N_h[i])), td(f(info$Ybar_h[i], 3)), td(f(info$S_h[i], 2)),
    td(f(info$P_h[i], 3)), td(strat$nh_prop[i]), td(strat$nh_ney[i])
  ))
}, character(1)), collapse = "\n")
v$m2_mean_range <- paste(f(min(info$Ybar_h), 1), "to", f(max(info$Ybar_h), 1))
v$m2_sd_range <- paste(f(min(info$S_h), 0), "to", f(max(info$S_h), 0))
blr <- info$stratum == "Bengaluru"
v$m2_blr_prop <- strat$nh_prop[blr]
v$m2_blr_ney <- strat$nh_ney[blr]
gain <- tab("02_stratified", "gain_in_precision")
v$m2_re_prop_mean <- f(gain[["RE proportional"]][1], 3)
v$m2_re_ney_mean <- f(gain[["RE Neyman"]][1], 3)
v$m2_re_prop_p <- f(gain[["RE proportional"]][2], 3)
v$m2_re_ney_p <- f(gain[["RE Neyman"]][2], 3)
v$m2_gain_ney <- f(gain[["Gain % Neyman"]][1], 0)
stopifnot(gain[["RE Neyman"]][1] > 1, gain[["RE Neyman"]][2] < 1)
dec <- tab("02_stratified", "variance_decomposition")
v$m2_share_pct <- f(100 * row_value(dec, "Share of S^2"), 2)
v$m2_vdiff <- f(row_value(dec, "(2) V(prop) - V(Neyman), by"), 3)
spq <- sqrt(info$P_h * (1 - info$P_h))
nh_neyP <- pmax(round_allocation(n * info$N_h * spq / sum(info$N_h * spq), n), 2)
v$m2_re_neyP <- f(vtrue_srswor_p(pp, n) / vtrue_strat_p(info, nh_neyP), 2)
an <- tab("02_stratified", "anova_sample")
v$m2_F <- f(an$F[1], 3)
v$m2_p <- pval(an[["p-value"]][1])
v$m2_decision <- decide(an[["p-value"]][1])
norm <- tab("02_stratified", "normality_check")
v$m2_skew <- f(row_value(norm, "Skewness"), 0)
kw_p <- row_value(norm, "Kruskal-Wallis p-value")
v$m2_kw <- f(row_value(norm, "Kruskal-Wallis chi-squared"), 2)
v$m2_kw_p <- pval(kw_p)
v$m2_kw_decision <- decide(kw_p)
basis <- tab("02_stratified", "basis_comparison")
v$m2_act_re_p <- f(basis[["RE proportion, proportional"]][2], 2)
v$m2_act_range <- basis[["Range of P_h"]][2]
stopifnot(basis[["RE proportion, proportional"]][2] > basis[["RE proportion, proportional"]][1])

# ---- Member 3 -------------------------------------------------------------------
setup <- tab("03_systematic", "setup")
v$m3_r <- row_value(setup, "Random start")
sy <- sys$results
v$m3_mean <- f(res_row(sy, "Systematic", "Mean")$estimate, 3)
v$m3_mean_se <- f(res_row(sy, "Systematic", "Mean")$se, 3)
v$m3_p <- f(res_row(sy, "Systematic", "Proportion")$estimate, 4)
v$m3_p_se <- f(res_row(sy, "Systematic", "Proportion")$se, 4)
starts <- tab("03_systematic", "all_starts")
v$m3_cover_mean <- f(row_value(starts, "% of starts"), 0)
v$m3_cover_p <- f(row_value(starts, "% of starts", 3), 0)
stopifnot(abs(row_value(starts, "Average of all") - pp$Ybar) < 1e-9) # unbiasedness claim
cmp <- tab("03_systematic", "comparison")
v$m3_cmp_rows <- paste(vapply(seq_len(nrow(cmp)), function(i) {
  tr(c(td(cmp$Design[i], FALSE), td(f(cmp[["RE mean"]][i], 3)), td(f(cmp[["RE proportion"]][i], 3))),
    highlight = cmp$Design[i] == "Systematic"
  )
}, character(1)), collapse = "\n")
v$m3_re_p <- f(cmp[["RE proportion"]][cmp$Design == "Systematic"], 3)
v$m3_gain_p <- f(100 * (cmp[["RE proportion"]][cmp$Design == "Systematic"] - 1), 0)
stopifnot(which.max(cmp[["RE proportion"]]) == which(cmp$Design == "Systematic"))
a_y <- tab("03_systematic", "anova_mean")
a_p <- tab("03_systematic", "anova_proportion")
v$m3_F_mean <- f(a_y$F[1], 3)
v$m3_p_mean <- pval(a_y[["p-value"]][1])
v$m3_F_prop <- f(a_p$F[1], 3)
v$m3_p_prop <- pval(a_p[["p-value"]][1])
stopifnot(a_y[["p-value"]][1] >= ALPHA, a_p[["p-value"]][1] >= ALPHA) # "start does not matter"
lo <- tab("03_systematic", "list_order")
v$m3_order_rows <- paste(vapply(seq_len(nrow(lo)), function(i) {
  label <- sub(" (used above)", " (used)", lo[[1]][i], fixed = TRUE)
  tr(c(td(label, FALSE), td(f(lo[[2]][i], 3)), td(f(lo[[3]][i], 3))),
    highlight = i == 1
  )
}, character(1)), collapse = "\n")
ek <- tab("03_systematic", "effect_of_k")
v$m3_k_range <- paste(f(min(ek[[4]]), 2), "to", f(max(ek[[4]]), 2))
stopifnot(all(ek[[4]] > 1))

# ---- Member 4 -------------------------------------------------------------------
v$m4_Mbar <- f(nrow(frame) / nrow(ct), 1)
v$m4_units <- int(clu$n_c * nrow(frame) / nrow(ct))
v$m4_maxM <- int(max(ct$M))
cr <- clu$results
v$m4_cl_rows <- paste(
  tr(c(td("Mean workers", FALSE), td(f(cr$estimate[1], 3)), td(f(cr$se[1], 3)), td(f(sqrt(cr$var_true[1]), 3)),
    td(f(pp$Ybar, 3)))),
  tr(c(td("Proportion", FALSE), td(f(cr$estimate[3], 4)), td(f(cr$se[3], 4)), td(f(sqrt(cr$var_true[3]), 4)),
    td(f(pp$P, 4)))),
  sep = "\n"
)
v$m4_df <- clu$n_c - 1
v$m4_fpc <- f(1 - clu$n_c / nrow(ct), 4)
icc <- tab("04_cluster", "icc_design_effect")
aw <- tab("04_cluster", "anova_workers")
af <- tab("04_cluster", "anova_female")
v$m4_F_y <- paste0(f(aw$F[1], 2), " (", pval(aw[["p-value"]][1]), ")")
v$m4_F_p <- paste0(f(af$F[1], 2), " (", pval(af[["p-value"]][1]), ")")
stopifnot(aw[["p-value"]][1] < ALPHA, af[["p-value"]][1] < ALPHA)
get_icc <- function(pattern, col) row_value(icc, pattern, col)
v$m4_icc_y <- f(get_icc("Intraclass", 2), 3)
v$m4_icc_p <- f(get_icc("Intraclass", 3), 3)
v$m4_icc_p2 <- f(get_icc("Intraclass", 3), 2)
v$m4_deff_f_y <- f(get_icc("by formula", 2), 1)
v$m4_deff_f_p <- f(get_icc("by formula", 3), 1)
v$m4_deff_a_y <- f(get_icc("Actual design effect V", 2), 1)
v$m4_deff_a_p <- f(get_icc("Actual design effect V", 3), 1)
v$m4_re_y <- f(get_icc("Relative efficiency vs SRS", 2), 2)
v$m4_re_p <- f(get_icc("Relative efficiency vs SRS", 3), 2)
v$m4_re_p_pct <- f(100 * get_icc("Relative efficiency vs SRS", 3), 0)
v$m4_re_y_pct <- f(100 * get_icc("Relative efficiency vs SRS", 2), 0)
v$m4_worth <- f((nrow(frame) / nrow(ct)) / get_icc("Actual design effect V", 3), 1)
cs <- tab("04_cluster", "cluster_size_effect")
v$m4_size_rows <- paste(vapply(seq_len(nrow(cs)), function(i) {
  tr(c(td(cs$Cluster[i], FALSE), td(f(cs[["Average size"]][i], 0)), td(int(cs[["Design effect, female"]][i]))),
    highlight = i == 1
  )
}, character(1)), collapse = "\n")
stopifnot(!is.unsorted(cs[["Design effect, female"]])) # "bigger clusters, bigger loss"
v$m4_nonprop_pct <- f(100 * mean(frame$ownership != "2"), 1)

# ---- Member 5 -------------------------------------------------------------------
all_res <- tab("05_comparison", "master_comparison")
designs <- unique(all_res$design)
short <- c(
  "SRSWOR" = "SRSWOR", "SRSWR" = "SRSWR", "Stratified (Proportional)" = "Strat. proportional",
  "Stratified (Neyman)" = "Strat. Neyman", "Systematic" = "Systematic", "Cluster" = "Cluster"
)
get_r <- function(d, p) all_res[all_res$design == d & all_res$parameter == p, ]
best_m <- designs[which.max(sapply(designs, function(d) get_r(d, "Mean")$RE))]
best_p <- designs[which.max(sapply(designs, function(d) get_r(d, "Proportion")$RE))]
worst_m <- designs[which.min(sapply(designs, function(d) get_r(d, "Mean")$RE))]
worst_p <- designs[which.min(sapply(designs, function(d) get_r(d, "Proportion")$RE))]
stopifnot(best_m == "Stratified (Neyman)", best_p == "Systematic", worst_m == "Cluster", worst_p == "Cluster")
v$m5_master_rows <- paste(vapply(designs, function(d) {
  m <- get_r(d, "Mean")
  p <- get_r(d, "Proportion")
  re_m <- f(m$RE, 3)
  re_p <- f(p$RE, 3)
  if (d == best_m) re_m <- paste0("<b>", re_m, "</b>")
  if (d == best_p) re_p <- paste0("<b>", re_p, "</b>")
  tr(c(
    td(short[[d]], FALSE), td(paste0(f(m$estimate, 3), " (", f(m$abs_error, 3), ")")),
    td(paste0(f(p$estimate, 3), " (", f(p$abs_error, 3), ")")), td(re_m), td(re_p)
  ))
}, character(1)), collapse = "\n")
v$m5_re_best_p <- f(get_r(best_p, "Proportion")$RE, 2)
v$m5_gain_best_p <- f(100 * (get_r(best_p, "Proportion")$RE - 1), 0)
v$m5_gain_best_m <- f(100 * (get_r(best_m, "Mean")$RE - 1), 0)
v$m5_re_sys_mean <- f(get_r("Systematic", "Mean")$RE, 2)
v$m5_re_cl_p <- f(get_r("Cluster", "Proportion")$RE, 2)
sf <- tab("05_comparison", "f_tests_simulation")
sfp <- sf[sf$Parameter == "Proportion", ]
v$m5_f_rows <- paste(vapply(seq_len(nrow(sfp)), function(i) {
  tr(c(
    td(sfp$Comparison[i], FALSE),
    td(paste0(f(sfp$F[i], if (sfp$F[i] > 10) 1 else 2), " (", pval(sfp[["p-value"]][i]), ")")),
    td(sfp[["Same direction as exact variances?"]][i])
  ))
}, character(1)), collapse = "\n")
stopifnot(all(sfp[["Same direction as exact variances?"]] == "yes"))
wrong <- sum(sf[["Same direction as exact variances?"]][sf$Parameter == "Mean"] == "NO")
v$m5_wrong <- c("none of the F-tests", "one F-test even", "two F-tests even", "three F-tests even")[wrong + 1]
ss <- tab("05_comparison", "simulation_summary")
is_p <- ss$Parameter == "Proportion"
v$m5_se_within <- f(100 * max(abs(ss[["Empirical SE"]][is_p] / ss[["Exact SE"]][is_p] - 1)), 0)
cov_col <- "95% CIs containing truth (%)"
v$m5_cov_p <- paste(f(min(ss[[cov_col]][is_p & ss$Design != "Cluster"]), 0), "to",
  f(max(ss[[cov_col]][is_p & ss$Design != "Cluster"]), 0))
v$m5_cov_p_cl <- f(ss[[cov_col]][is_p & ss$Design == "Cluster"], 0)
v$m5_cov_mean <- paste(f(min(ss[[cov_col]][!is_p]), 0), "to", f(max(ss[[cov_col]][!is_p]), 0))

# ---- Fill the template --------------------------------------------------------------
html <- paste(readLines("presentation/template.html", encoding = "UTF-8", warn = FALSE), collapse = "\n")
for (key in names(v)) html <- gsub(paste0("{{", key, "}}"), as.character(v[[key]]), html, fixed = TRUE)
left <- regmatches(html, gregexpr("\\{\\{[a-z0-9_]+\\}\\}", html, perl = TRUE))[[1]]
if (length(left) > 0) stop("Template placeholders without a value: ", paste(unique(left), collapse = ", "))
html <- sub(
  "<!-- generated -->",
  paste0(
    "<!-- Generated by analysis/06_slides.R on ", Sys.Date(),
    " from the verified results. Edit template.html, not this file. -->"
  ),
  html,
  fixed = TRUE
)
writeLines(html, "presentation/slides.html", useBytes = TRUE)
message("Slides written to presentation/slides.html (", length(v), " values filled from the results)")

chrome <- find_chrome()
if (!is.na(chrome)) {
  system2(chrome, c(
    "--headless=new", "--disable-gpu", "--no-sandbox", "--no-pdf-header-footer",
    paste0("--print-to-pdf=", shQuote(normalizePath("presentation/slides.pdf", mustWork = FALSE))),
    shQuote(paste0("file://", normalizePath("presentation/slides.html")))
  ), stdout = FALSE, stderr = FALSE)
  message("PDF copy: presentation/slides.pdf")
}
