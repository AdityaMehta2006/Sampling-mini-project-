# =============================================================================
# 03_systematic.R — MEMBER 3: linear systematic sampling (N = n k)
#
# Part A  Set-up: interval k, random start r, the selected units
# Part B  Estimates (mean, total, proportion): variance, SE, 95% CI, fpc
# Part C  Effect of the starting point: all k = 3,851 possible samples
# Part D  Comparison with SRS and stratified sampling
# Part E  One-way ANOVA with the k systematic samples as groups
# Part F  Effect of k (different sample sizes)
# Part G  Extra: how the ORDER of the list changes precision
# Output: output/03_systematic/README.md
# =============================================================================
source("analysis/common.R")
source("analysis/designs.R")
report_open("03_systematic", "Unit 3: Systematic sampling (Member 3)")

frame <- load_frame()
pp <- load_shared("population")
strat <- load_shared("stratified")
N <- pp$N
n <- N_SAMPLE
k <- K_SYS

# -----------------------------------------------------------------------------
header("Part A: Set-up")
# -----------------------------------------------------------------------------
set.seed(SEED + 4)
r <- sample.int(k, 1) # random start between 1 and k
selected <- seq(r, N, by = k)
setup <- data.frame(
  Quantity = c(
    "Population size N", "Sample size n", "Sampling interval k = N / n", "Random start r (1 to k)",
    "Selected unit numbers", "Number of possible systematic samples (= k)"
  ),
  Value = c(
    format(N, big.mark = ","), n, format(k, big.mark = ","), r,
    paste0(paste(trimws(format(head(selected, 4), big.mark = ",")), collapse = ", "), ", ..., ",
      trimws(format(tail(selected, 1), big.mark = ","))),
    format(k, big.mark = ",")
  )
)
save_table(setup, "setup", "Table 3.1: Systematic sample set-up")
report_text(
  "The frame is listed by location code (District > Tehsil > Town/Village > Ward > Enumeration block), ",
  "so one establishment is taken every 3,851 places down the list, starting at a random place r. ",
  "Because N = n k exactly, every start gives exactly n = 748 units and the sample mean is unbiased."
)

# -----------------------------------------------------------------------------
header("Part B: Estimates from the selected systematic sample")
# -----------------------------------------------------------------------------
v_sys_y <- vtrue_sys(frame$Y, k)
v_sys_p <- vtrue_sys(frame$female, k)
sy <- est_systematic(frame, k, r, pp, v_true_mean = v_sys_y, v_true_p = v_sys_p)
save_results(sy, "systematic_estimates", "Table 3.2: Systematic sample estimates with 95% confidence intervals")
save_sample(frame[attr(sy, "idx"), ], "systematic_sample")
report_text(
  "A single systematic sample has no unbiased variance estimator, so the SE above uses the usual SRSWOR ",
  "approximation v = (1 - f) s^2 / n with f = n / N = ", signif(n / N, 3), " (fpc = ", round(1 - n / N, 5),
  "). The **exact SE** is computed from all 3,851 possible samples (Part C)."
)

# -----------------------------------------------------------------------------
header("Part C: Effect of the starting point - all 3,851 possible samples")
# -----------------------------------------------------------------------------
my <- sys_matrix(frame$Y, k) # row r = systematic sample with start r
mp <- sys_matrix(frame$female, k)
means_y <- rowMeans(my)
means_p <- rowMeans(mp)
se_y <- sqrt((1 - n / N) * rowSums((my - means_y)^2) / (n - 1) / n)
se_p <- sqrt((1 - n / N) * means_p * (1 - means_p) / (n - 1))
cover_y <- mean(abs(means_y - pp$Ybar) <= Z * se_y)
cover_p <- mean(abs(means_p - pp$P) <= Z * se_p)

starts <- data.frame(
  Summary = c(
    "Smallest sample mean", "25th percentile", "Median", "75th percentile", "Largest sample mean",
    "Average of all k sample means", "True value", "Exact SE = SD of the k sample means",
    "% of starts whose 95% CI contains the true value"
  ),
  `Mean workers` = c(quantile(means_y, c(0, 0.25, 0.5, 0.75, 1)), mean(means_y), pp$Ybar, sqrt(v_sys_y),
    100 * cover_y),
  `Proportion female-owned` = c(quantile(means_p, c(0, 0.25, 0.5, 0.75, 1)), mean(means_p), pp$P,
    sqrt(v_sys_p), 100 * cover_p),
  check.names = FALSE
)
save_table(starts, "all_starts", "Table 3.3: The 3,851 possible systematic samples")
report_text(
  "The average of all possible sample means equals the true value exactly: the estimator is unbiased. ",
  "For the proportion, every start gives a similar answer. For the mean, most starts underestimate slightly ",
  "and a few starts, those that hit a very large establishment, overestimate a lot. ",
  "Only ", round(100 * cover_y), "% of the CIs for the mean contain the truth (95% is the target), ",
  "because the SE formula underestimates when the sample misses the rare giants."
)

fig_open("all_starts_histogram", width = 2000)
par(mfrow = c(1, 2))
hist(pmin(means_y, 8),
  breaks = 60, col = PALETTE["light"], border = "white", main = "Mean workers (k = 3,851 samples)",
  xlab = "Sample mean (values above 8 shown at 8)", ylab = "Number of starting points"
)
abline(v = pp$Ybar, col = PALETTE["red"], lwd = 2)
abline(v = means_y[r], col = PALETTE["blue"], lwd = 2, lty = 2)
hist(means_p,
  breaks = 50, col = PALETTE["light"], border = "white", main = "Proportion female-owned",
  xlab = "Sample proportion", ylab = "Number of starting points"
)
abline(v = pp$P, col = PALETTE["red"], lwd = 2)
abline(v = means_p[r], col = PALETTE["blue"], lwd = 2, lty = 2)
legend("topright", c("true value", "our start r"), col = c(PALETTE["red"], PALETTE["blue"]),
  lty = c(1, 2), lwd = 2, bty = "n", cex = 0.8)
fig_close("Figure 3.1: Estimates from every possible starting point (red = true value, blue = our sample)")

fig_open("mean_by_start", width = 2000)
par(mfrow = c(1, 2))
plot(seq_len(k), means_p,
  pch = 20, cex = 0.4, col = "#4C72B066", xlab = "Starting point r",
  ylab = "Sample proportion", main = "Proportion vs starting point"
)
lines(lowess(seq_len(k), means_p, f = 0.05), col = PALETTE["red"], lwd = 2)
plot(seq_len(k), pmin(means_y, 8),
  pch = 20, cex = 0.4, col = "#4C72B066", xlab = "Starting point r",
  ylab = "Sample mean (capped at 8)", main = "Mean vs starting point"
)
lines(lowess(seq_len(k), means_y, f = 0.05), col = PALETTE["red"], lwd = 2)
fig_close("Figure 3.2: No trend or repeating pattern across starting points (red = smoothed average)")
report_text(
  "**Trend or periodicity?** If the list had a periodic pattern with period close to k, some starts would ",
  "always land on high values and Figure 3.2 would show waves. The smoothed line is flat, so the choice of ",
  "start does not systematically matter; the remaining scatter is random variation between samples."
)

# -----------------------------------------------------------------------------
header("Part D: Comparison with SRS and stratified sampling")
# -----------------------------------------------------------------------------
info <- strat$info
v_srs <- c(vtrue_srswor(pp, n), vtrue_srswor_p(pp, n))
cmp <- data.frame(
  Design = c("SRSWOR", "Stratified (proportional)", "Stratified (Neyman)", "Systematic"),
  `Exact variance, mean` = c(v_srs[1], vtrue_strat(info, strat$nh_prop), vtrue_strat(info, strat$nh_ney), v_sys_y),
  `Exact variance, proportion` = c(v_srs[2], vtrue_strat_p(info, strat$nh_prop), vtrue_strat_p(info, strat$nh_ney),
    v_sys_p),
  check.names = FALSE
)
cmp$`RE mean` <- v_srs[1] / cmp[[2]]
cmp$`RE proportion` <- v_srs[2] / cmp[[3]]
save_table(cmp, "comparison", "Table 3.4: Systematic vs SRS and stratified (exact variances, RE against SRSWOR)")
report_text(
  "For the **proportion**, systematic sampling beats both SRS and stratified sampling by division: walking ",
  "down a geographically ordered list spreads the sample evenly over all 30 districts and their towns, ",
  "a much finer *implicit stratification* than 4 divisions. For the **mean**, all designs are limited by the ",
  "few giant establishments."
)

# -----------------------------------------------------------------------------
header("Part E: One-way ANOVA with the k systematic samples as groups")
# -----------------------------------------------------------------------------
# Unit i belongs to sample r = ((i - 1) mod k) + 1. MSW is the within-sample variance S^2_wsy.
# Theory (Cochran §8.2):  V(ybar_sy) = (N-1)/N S^2 - k (n-1)/N S^2_wsy
#   -> systematic beats SRSWOR exactly when S^2_wsy > S^2.
# Intraclass correlation within samples:  V(ybar_sy) = (S^2 / n) ((N-1)/N) [1 + (n-1) rho_w]
group <- rep(seq_len(k), times = n)
report_text("H0: the k = 3,851 possible samples have equal means (the start does not matter). H1: they differ.")
a_y <- anova_oneway(frame$Y, group)
save_table(a_y, "anova_mean", "Table 3.5: ANOVA, workers per establishment, samples as groups")
a_p <- anova_oneway(frame$female, group)
save_table(a_p, "anova_proportion", "Table 3.6: ANOVA, female ownership (0/1), samples as groups")

within <- function(a, s2, v_sy) {
  s2w <- a[2, "Mean square"]
  c(s2w, s2, s2w / s2, (v_sy / (s2 / n * (N - 1) / N) - 1) / (n - 1), (N - 1) / N * s2 - k * (n - 1) / N * s2w, v_sy)
}
s2p <- var(frame$female)
wtab <- data.frame(
  Quantity = c(
    "Within-sample variance S^2_wsy (= MSW)", "Population variance S^2", "Ratio S^2_wsy / S^2",
    "Intraclass correlation within samples rho_w", "V(ybar_sy) from the ANOVA formula",
    "V(ybar_sy) from the k sample means"
  ),
  `Mean workers` = within(a_y, pp$S2, v_sys_y),
  `Proportion female-owned` = within(a_p, s2p, v_sys_p),
  check.names = FALSE
)
save_table(wtab, "within_vs_population", "Table 3.7: Within-sample variance vs population variance", digits = 5)
decide <- function(a) {
  if (a[1, "p-value"] < ALPHA) {
    "**Reject H0** at the 5% level: the possible samples differ more than chance would explain."
  } else {
    "**Do not reject H0** at the 5% level: the choice of starting point makes no systematic difference."
  }
}
report_text(
  "**Decision, workers:** F = ", round(a_y$F[1], 3), ", p = ", fmt_p(a_y[1, "p-value"]), ". ", decide(a_y), " ",
  "**Decision, female ownership:** F = ", round(a_p$F[1], 3), ", p = ", fmt_p(a_p[1, "p-value"]), ". ", decide(a_p)
)
report_text(
  "**Workers:** F = ", round(a_y$F[1], 3), " (p = ", fmt_p(a_y[1, "p-value"]), ") and S^2_wsy ~ S^2, so ",
  "the systematic samples are about as variable inside as the population: systematic ~ SRS for the mean. ",
  "**Female ownership:** F = ", round(a_p$F[1], 3), " (p = ", fmt_p(a_p[1, "p-value"]), "). S^2_wsy is ",
  "slightly larger than S^2 and rho_w is negative, which means units inside one systematic sample are *less* ",
  "alike than random units, because they come from all over the state. That is exactly why systematic beats SRS ",
  "for the proportion. Normality: Y is extremely skewed, so the F-test for the mean is only approximate; ",
  "the variance comparison (S^2_wsy vs S^2) does not depend on normality."
)

# -----------------------------------------------------------------------------
header("Part F: Effect of k (different sample sizes)")
# -----------------------------------------------------------------------------
ks <- c(15404, 7702, 3851, 748) # all give N = n k exactly
eff <- do.call(rbind, lapply(ks, function(kk) {
  nn <- N / kk
  data.frame(
    k = kk, n = nn,
    `RE mean (vs SRSWOR)` = vtrue_srswor(pp, nn) / vtrue_sys(frame$Y, kk),
    `RE proportion (vs SRSWOR)` = vtrue_srswor_p(pp, nn) / vtrue_sys(frame$female, kk),
    `Exact SE of p` = sqrt(vtrue_sys(frame$female, kk)),
    check.names = FALSE
  )
}))
save_table(eff, "effect_of_k", "Table 3.8: Effect of the sampling interval k")
report_text(
  "A smaller k means a larger sample and a smaller SE. Against SRS of the **same** size, systematic sampling ",
  "is better for the proportion at every k (RE ", sprintf("%.2f", min(eff[[4]])), " to ",
  sprintf("%.2f", max(eff[[4]])), "), but not steadily more so as k changes: how much it gains depends on how ",
  "the interval happens to line up with the geographic pattern of the list. For the mean, RE stays close to 1 ",
  "for every k."
)

fig_open("effect_of_k")
plot(eff$n, eff$`RE proportion (vs SRSWOR)`,
  type = "b", pch = 19, lwd = 2, col = PALETTE["green"], log = "x",
  ylim = range(0.9, eff[, 3:4]), xlab = "Sample size n (log scale)", ylab = "Relative efficiency vs SRSWOR",
  main = "Systematic sampling: relative efficiency for different k", xaxt = "n"
)
axis(1,
  at = eff$n, labels = paste0("n=", eff$n, "\nk=", trimws(format(eff$k, big.mark = ","))),
  padj = 0.5, cex.axis = 0.75
)
lines(eff$n, eff$`RE mean (vs SRSWOR)`, type = "b", pch = 17, lwd = 2, col = PALETTE["blue"])
abline(h = 1, lty = 2, col = PALETTE["grey"])
legend("topleft", c("proportion", "mean", "SRS level"),
  col = c(PALETTE["green"], PALETTE["blue"], PALETTE["grey"]),
  pch = c(19, 17, NA), lty = c(1, 1, 2), bty = "n", cex = 0.85)
fig_close("Figure 3.3: Relative efficiency of systematic sampling against SRS for four values of k")

# -----------------------------------------------------------------------------
header("Part G: Extra - how the order of the list matters")
# -----------------------------------------------------------------------------
set.seed(SEED + 5)
orders <- list(
  `Location code (used above)` = seq_len(N),
  `Random order (shuffled list)` = sample.int(N),
  `Sorted by activity type` = order(frame$activity, frame$unit_id)
)
ord_tab <- do.call(rbind, lapply(names(orders), function(nm) {
  o <- orders[[nm]]
  data.frame(
    `List order` = nm,
    `RE mean` = v_srs[1] / vtrue_sys(frame$Y[o], k),
    `RE proportion` = v_srs[2] / vtrue_sys(frame$female[o], k),
    check.names = FALSE
  )
}))
save_table(ord_tab, "list_order", "Table 3.9: The same design on differently ordered lists (RE against SRSWOR)")
report_text(
  "On a **randomly shuffled** list, systematic sampling is just SRS (RE ~ 1). Ordering the list by location or ",
  "by activity makes it act like a finely stratified sample, and sorting by activity helps the proportion most, ",
  "because female ownership differs most between activities. The order of the frame is a design choice."
)

save_shared(list(results = sy, v_mean = v_sys_y, v_prop = v_sys_p), "systematic")
report_close()
