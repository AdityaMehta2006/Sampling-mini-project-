# =============================================================================
# 05_comparison.R — comparison of designs, F-tests, simulation
#
# Part A  Master comparison table: every design, estimate, SE, CI, RE, error
# Part B  F-tests comparing the variances of two designs
# Part C  Monte Carlo simulation: every design repeated 500 times
# Part D  Recommended design
# Output: output/05_comparison/README.md
# =============================================================================
source("analysis/common.R")
source("analysis/designs.R")
report_open("05_comparison", paste0("Comparison of designs, F-tests and simulation (", TEAM$name[5], ")"))

frame <- load_frame()
pp <- load_shared("population")
srs <- load_shared("srs")
strat <- load_shared("stratified")
sys <- load_shared("systematic")
clu <- load_shared("cluster")
N <- pp$N
n <- N_SAMPLE

all_res <- rbind(srs, strat$results, sys$results, clu$results)
designs <- unique(all_res$design)
base_var <- all_res$var_true[all_res$design == "SRSWOR"]
names(base_var) <- all_res$parameter[all_res$design == "SRSWOR"]
all_res$RE <- base_var[all_res$parameter] / all_res$var_true

# -----------------------------------------------------------------------------
header("Part A: Master comparison table")
# -----------------------------------------------------------------------------
report_text(
  "One sample of about n = 748 establishments was drawn by every design (Units 1-4). ",
  "**RE** = exact variance of SRSWOR / exact variance of the design (above 1 = more precise than SRS). ",
  "Absolute error = |estimate - true value|; the true value is known from the census."
)
master <- pretty_results(all_res)[, c("Parameter", "Design", "Estimate", "SE", "95% CI", "True value", "Abs. error")]
master$`RE vs SRSWOR` <- sprintf("%.3f", all_res$RE)
master$`CI covers truth` <- ifelse(all_res$covers_truth, "yes", "no")
ord <- order(match(all_res$parameter, c("Mean", "Total", "Proportion")))
save_table(master[ord, ], "master_comparison",
  "Table 5.1: Master comparison - every design, estimate, SE, 95% CI, absolute error and RE against SRS",
  csv = all_res[ord, ]
)

fig_open("confidence_intervals", width = 2200, height = 1200)
par(mfrow = c(1, 2), mar = c(4.5, 13, 3, 1))
for (param in c("Mean", "Proportion")) {
  r <- all_res[all_res$parameter == param, ]
  y <- rev(seq_len(nrow(r)))
  plot(r$estimate, y,
    xlim = range(r$ci_low, r$ci_high), ylim = c(0.5, nrow(r) + 0.5), pch = 19,
    col = ifelse(r$covers_truth, PALETTE["blue"], PALETTE["red"]), yaxt = "n", ylab = "",
    xlab = param, main = paste("95% CI for the", tolower(param))
  )
  segments(r$ci_low, y, r$ci_high, y, lwd = 3, col = ifelse(r$covers_truth, PALETTE["blue"], PALETTE["red"]))
  axis(2, at = y, labels = r$design, cex.axis = 0.8)
  abline(v = r$truth[1], lty = 2, lwd = 1.5)
}
fig_close("Figure 5.1: One sample per design (dashed = true value; red = CI misses the truth)")

fig_open("relative_efficiency", width = 2000)
re_mat <- rbind(
  Mean = all_res$RE[all_res$parameter == "Mean"],
  Proportion = all_res$RE[all_res$parameter == "Proportion"]
)
colnames(re_mat) <- sub(" (", "\n(", designs, fixed = TRUE)
par(mar = c(5, 4.8, 3, 1))
bars <- barplot(re_mat,
  beside = TRUE, col = c(PALETTE["blue"], PALETTE["green"]), border = NA, ylim = c(0, 1.45),
  names.arg = rep("", ncol(re_mat)), ylab = "Relative efficiency vs SRSWOR", main = "Which design is most precise?"
)
axis(1, at = colMeans(bars), labels = colnames(re_mat), tick = FALSE, padj = 0.5, cex.axis = 0.8)
abline(h = 1, lty = 2)
text(bars, pmin(re_mat, 1.4), sprintf("%.2f", re_mat), pos = 3, cex = 0.7)
legend("topright", c("Mean", "Proportion"), fill = c(PALETTE["blue"], PALETTE["green"]), bty = "n")
fig_close("Figure 5.2: Relative efficiency of each design (above the dashed line = better than SRS)")

# -----------------------------------------------------------------------------
header("Part B: F-tests comparing the variances of two designs")
# -----------------------------------------------------------------------------
report_text(
  "For two designs A and B: H0: the two estimators have equal variance. H1: the one with the larger ",
  "estimated variance really is less precise. F = larger variance / smaller variance; reject H0 at the 5% level ",
  "if p < 0.05. The F-test assumes the estimates are roughly normal."
)
df_of <- c(
  "SRSWOR" = n - 1, "SRSWR" = n - 1, "Stratified (Proportional)" = n - 4, "Stratified (Neyman)" = n - 4,
  "Systematic" = n - 1, "Cluster" = clu$n_c - 1
)
exact_var <- function(d, param) all_res$var_true[all_res$design == d & all_res$parameter == param]
f_test <- function(a, b, param, va, vb, dfa, dfb, source) {
  big <- if (va >= vb) a else b
  exact_big <- if (exact_var(a, param) >= exact_var(b, param)) a else b
  Fv <- max(va, vb) / min(va, vb)
  d1 <- if (va >= vb) dfa else dfb
  d2 <- if (va >= vb) dfb else dfa
  p <- pf(Fv, d1, d2, lower.tail = FALSE)
  data.frame(
    Comparison = paste(a, "vs", b), Parameter = param, Based = source, `Larger variance` = big,
    F = Fv, df = paste0("(", d1, ", ", d2, ")"), `p-value` = p,
    Decision = ifelse(p < ALPHA, paste("Reject H0:", big, "is less precise"), "Do not reject H0"),
    `Same direction as exact variances?` = ifelse(big == exact_big, "yes", "NO"),
    check.names = FALSE
  )
}
pairs <- list(c("SRSWOR", "Stratified (Neyman)"), c("SRSWOR", "Systematic"), c("SRSWOR", "Cluster"))
single <- do.call(rbind, lapply(pairs, function(pr) {
  do.call(rbind, lapply(c("Mean", "Proportion"), function(param) {
    va <- all_res$var_hat[all_res$design == pr[1] & all_res$parameter == param]
    vb <- all_res$var_hat[all_res$design == pr[2] & all_res$parameter == param]
    f_test(pr[1], pr[2], param, va, vb, df_of[[pr[1]]], df_of[[pr[2]]], "one sample each")
  }))
}))
save_table(single, "f_tests_single_sample", "Table 5.2: F-tests using the estimated variances of the single samples")
report_text(
  "**Caution:** each single-sample variance estimate is itself very noisy for the mean (it depends on whether ",
  "the sample happened to contain a giant establishment), so these tests can point the wrong way. ",
  "Part C repeats every design 500 times and tests the variances properly."
)

# -----------------------------------------------------------------------------
header("Part C: Monte Carlo simulation - every design repeated 500 times")
# -----------------------------------------------------------------------------
R <- 500
info <- strat$info
ct <- cluster_table(frame)
set.seed(SEED + 100)
one_round <- function() {
  rbind(
    est_srswor(frame, n, pp),
    est_srswr(frame, n, pp),
    est_stratified(frame, info, strat$nh_prop, pp, "Stratified (Proportional)"),
    est_stratified(frame, info, strat$nh_ney, pp, "Stratified (Neyman)"),
    est_systematic(frame, K_SYS, sample.int(K_SYS, 1), pp, sys$v_mean, sys$v_prop),
    est_cluster(ct, clu$n_c, pp)
  )
}
sim <- do.call(rbind, lapply(seq_len(R), function(i) cbind(rep = i, one_round())))
sim <- sim[sim$parameter != "Total", ]
save_shared(sim, "simulation")

skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
summ <- do.call(rbind, lapply(c("Mean", "Proportion"), function(param) {
  do.call(rbind, lapply(designs, function(d) {
    s <- sim[sim$design == d & sim$parameter == param, ]
    data.frame(
      Parameter = param, Design = d, `Average estimate` = mean(s$estimate), `True value` = s$truth[1],
      `Empirical SE` = sd(s$estimate), `Exact SE` = sqrt(s$var_true[1]),
      `95% CIs containing truth (%)` = 100 * mean(s$covers_truth),
      `Skewness of estimates` = skew(s$estimate), check.names = FALSE
    )
  }))
}))
save_table(summ, "simulation_summary", "Table 5.3: 500 repeated samples per design")
ratio <- summ$`Empirical SE` / summ$`Exact SE`
is_p <- summ$Parameter == "Proportion"
report_text(
  "**Reading Table 5.3.** *Proportion:* the average estimate equals the true value and the empirical SE is ",
  "within ", round(100 * max(abs(ratio[is_p] - 1))), "% of the exact SE for every design, confirming the variance ",
  "formulas. 95% CIs contain the truth about 95% of the time, except for cluster sampling (",
  round(summ$`95% CIs containing truth (%)`[is_p & summ$Design == "Cluster"]), "%), whose estimates are skewed ",
  "and based on only ", clu$n_c, " clusters. *Mean:* the empirical SE ranges from ", sprintf("%.1f", min(ratio[!is_p])),
  " to ", sprintf("%.1f", max(ratio[!is_p])), " times the exact SE, and only about 60% of CIs contain the truth. ",
  "The estimates are extremely skewed: each sample includes a given giant establishment with probability n/N = ",
  "1 in ", format(round(N / n), big.mark = ","), ", so 500 repetitions are far too few for the spread of the ",
  "estimates to settle down. **For the mean, the exact variances in Table 5.1 are the reliable comparison.**"
)

sim_f <- do.call(rbind, lapply(pairs, function(pr) {
  do.call(rbind, lapply(c("Mean", "Proportion"), function(param) {
    ea <- sim$estimate[sim$design == pr[1] & sim$parameter == param]
    eb <- sim$estimate[sim$design == pr[2] & sim$parameter == param]
    f_test(pr[1], pr[2], param, var(ea), var(eb), R - 1, R - 1, "500 repeated samples")
  }))
}))
save_table(sim_f, "f_tests_simulation", "Table 5.4: F-tests using the variances of the 500 repeated estimates")
agree <- tapply(sim_f$`Same direction as exact variances?` == "yes", sim_f$Parameter, all)
report_text(
  "**Normality and what to trust.** The proportion's estimates are close to normal (skewness near 0), and ",
  if (agree[["Proportion"]]) "every F-test for the proportion agrees with the exact variances: " else
    "the F-tests for the proportion mostly agree with the exact variances: ",
  "Neyman allocation (optimised for the mean) is less precise for P, systematic is more precise, and cluster ",
  "sampling is far less precise. The mean's estimates are strongly right-skewed, which violates the F-test's ",
  "assumption; ",
  if (agree[["Mean"]]) {
    "the directions agree with the exact variances, but the F values are unreliable."
  } else {
    paste0(
      "some of its tests even point the **wrong way** (last column). ",
      "This is a direct demonstration of why the normality assumption matters."
    )
  }
)

for (param in c("Mean", "Proportion")) {
  fig_open(paste0("simulation_", tolower(param)), width = 2200, height = 1300)
  par(mfrow = c(2, 3), mar = c(4, 4, 3, 1))
  s_all <- sim[sim$parameter == param, ]
  cap <- if (param == "Mean") quantile(s_all$estimate, 0.99) else max(s_all$estimate)
  brks <- seq(min(s_all$estimate), cap, length.out = 40)
  for (d in designs) {
    e <- pmin(s_all$estimate[s_all$design == d], cap)
    hist(e,
      breaks = brks, col = PALETTE["light"], border = "white", main = d,
      xlab = paste("Estimated", tolower(param)), ylab = "Samples"
    )
    abline(v = pp[[if (param == "Mean") "Ybar" else "P"]], col = PALETTE["red"], lwd = 2)
  }
  extra <- if (param == "Mean") " (top 1% shown at the right edge)" else ""
  fig_close(sprintf("Figure 5.%d: 500 estimates of the %s from each design%s; red = true value",
    if (param == "Mean") 3 else 4, tolower(param), extra))
}

# -----------------------------------------------------------------------------
header("Part D: Recommended design")
# -----------------------------------------------------------------------------
re_of <- function(d, param) all_res$RE[all_res$design == d & all_res$parameter == param]
rec <- data.frame(
  Design = designs,
  `RE, mean` = sprintf("%.3f", vapply(designs, re_of, numeric(1), param = "Mean")),
  `RE, proportion` = sprintf("%.3f", vapply(designs, re_of, numeric(1), param = "Proportion")),
  `Cost and convenience` = c(
    "Needs the full list; units scattered across the state (high travel cost)",
    "As SRSWOR, and may visit the same unit twice",
    "Needs the division of each unit (known); 4 separate random samples",
    "Needs stratum SDs from a previous census; 4 separate random samples",
    "One random number; easy to carry out on an ordered list; spread evenly over the state",
    "Cheapest fieldwork: 27 compact areas, no full list needed, only lists of blocks"
  ),
  check.names = FALSE, row.names = NULL
)
save_table(rec, "recommendation", "Table 5.5: Precision, cost and convenience of each design")
best_p <- designs[which.max(vapply(designs, re_of, numeric(1), param = "Proportion"))]
best_m <- designs[which.max(vapply(designs, re_of, numeric(1), param = "Mean"))]
report_text(
  "**Recommendation: systematic sampling from the census list ordered by location.** ",
  "It is the most precise design for the proportion (RE ", sprintf("%.2f", re_of("Systematic", "Proportion")),
  ") and as good as SRS for the mean (RE ", sprintf("%.2f", re_of("Systematic", "Mean")), "). It needs only one ",
  "random number, and walking down a geographically ordered list spreads the sample over every district. ",
  "If the mean number of workers were the main target, Neyman-allocated stratified sampling (best for the mean, ",
  "RE ", sprintf("%.2f", re_of(best_m, "Mean")), ") would be preferred. Cluster sampling is cheapest in the field ",
  "but loses most of its precision (RE ", sprintf("%.2f", re_of("Cluster", "Proportion")), " for the proportion) ",
  "because businesses in the same block are alike."
)
stopifnot(best_p == "Systematic", best_m == "Stratified (Neyman)") # the text above assumes this

report_close()
