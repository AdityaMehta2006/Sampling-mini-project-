# =============================================================================
# 02_stratified.R — MEMBER 2: stratified random sampling
#
# Part A  Strata = Karnataka's 4 revenue divisions; population values per stratum
# Part B  Proportional vs Neyman allocation of n = 748
# Part C  Estimates (mean, total, proportion): variance, SE, 95% CI, fpc
# Part D  Gain in precision over SRS, and why (Cochran's variance decomposition)
# Part E  One-way ANOVA with strata as groups (+ normality check)
# Part F  Extra: which basis of stratification is better?
# Output: output/02_stratified/README.md
# =============================================================================
source("analysis/common.R")
source("analysis/designs.R")
report_open("02_stratified", "Unit 2: Stratified random sampling (Member 2)")

frame <- load_frame()
pp <- load_shared("population")
N <- pp$N
n <- N_SAMPLE

# -----------------------------------------------------------------------------
header("Part A: The strata")
# -----------------------------------------------------------------------------
info <- strata_info(frame, "division")
strata_tab <- data.frame(
  Stratum = info$stratum, `N_h` = info$N_h, `W_h = N_h / N` = info$W_h,
  `Mean Ybar_h` = info$Ybar_h, `SD S_h` = info$S_h, `Proportion P_h` = info$P_h,
  check.names = FALSE
)
save_table(strata_tab, "strata_population", "Table 2.1: The four strata (revenue divisions) in the population")
report_text(
  "The divisions are Karnataka's official grouping of its 30 districts, so every establishment's stratum ",
  "is known before sampling. Their means differ a little (2.08 to 2.99), but their **standard deviations ",
  "differ a lot (11 to 35)**, and so do the proportions of female-owned establishments (14% to 28%)."
)

fig_open("boxplot_by_stratum")
boxplot(Y ~ division,
  data = frame, log = "y", col = "#DDE7F2", border = PALETTE["blue"], outcol = "#4C72B055",
  outpch = 20, outcex = 0.4, xlab = "Stratum (revenue division)", ylab = "Persons employed (log scale)",
  main = "Workers per establishment within each stratum"
)
points(seq_len(nrow(info)), info$Ybar_h, pch = 18, cex = 1.8, col = PALETTE["red"])
legend("topright", "stratum mean", pch = 18, col = PALETTE["red"], bty = "n", cex = 0.85)
fig_close("Figure 2.1: In every stratum most establishments have 1-2 workers and a few have thousands")

# -----------------------------------------------------------------------------
header("Part B: Allocating n = 748 to the strata")
# -----------------------------------------------------------------------------
# Proportional: n_h = n N_h / N          Neyman (optimum): n_h = n N_h S_h / sum(N_h S_h)
nh_prop <- alloc_proportional(info, n)
nh_ney <- alloc_neyman(info, n)
alloc <- data.frame(
  Stratum = info$stratum, N_h = info$N_h, S_h = info$S_h, `N_h x S_h` = info$N_h * info$S_h,
  `n_h proportional` = nh_prop, `n_h Neyman` = nh_ney, check.names = FALSE
)
save_table(rbind(alloc, data.frame(
  Stratum = "Total", N_h = N, S_h = NA, `N_h x S_h` = sum(alloc[[4]]),
  `n_h proportional` = sum(nh_prop), `n_h Neyman` = sum(nh_ney), check.names = FALSE
)), "allocation", "Table 2.2: Proportional vs Neyman allocation")
report_text(
  "Neyman allocation gives **more** units to strata that are large *and* variable (Bengaluru, Kalaburagi) ",
  "and **fewer** to the more homogeneous ones (Belagavi, Mysuru)."
)

fig_open("allocation")
barplot(rbind(nh_prop, nh_ney),
  beside = TRUE, names.arg = info$stratum, col = c(PALETTE["light"], PALETTE["blue"]),
  border = NA, ylim = c(0, 450), ylab = "Units allocated (n_h)", main = "Allocation of n = 748"
)
legend("topright", c("Proportional", "Neyman"), fill = c(PALETTE["light"], PALETTE["blue"]), bty = "n")
fig_close("Figure 2.2: Neyman moves units from homogeneous strata to the most variable ones")

# -----------------------------------------------------------------------------
header("Part C: Estimates from one stratified sample")
# -----------------------------------------------------------------------------
set.seed(SEED + 2)
st_prop <- est_stratified(frame, info, nh_prop, pp, "Stratified (Proportional)")
set.seed(SEED + 3)
st_ney <- est_stratified(frame, info, nh_ney, pp, "Stratified (Neyman)")
res <- rbind(st_prop, st_ney)
save_results(res, "stratified_estimates", "Table 2.3: Stratified estimates with 95% confidence intervals")
save_table(attr(st_prop, "by_stratum"), "by_stratum_proportional",
  "Table 2.4: Results inside each stratum (proportional allocation)")
save_table(attr(st_ney, "by_stratum"), "by_stratum_neyman",
  "Table 2.5: Results inside each stratum (Neyman allocation)")
save_sample(frame[attr(st_prop, "idx"), ], "stratified_proportional_sample")
save_sample(frame[attr(st_ney, "idx"), ], "stratified_neyman_sample")
report_text(
  "**Reading Tables 2.4-2.5:** the Neyman sample's Bengaluru stratum caught a very large establishment ",
  "(sample variance 421), so its SE is larger even though Neyman is the more precise *design*. ",
  "Single samples of skewed data are noisy; the exact SEs (Table 2.3, last column) show the true precision. ",
  "fpc: every stratum's sampling fraction f_h = n_h / N_h is below 0.0004, so (1 - f_h) is practically 1."
)

# -----------------------------------------------------------------------------
header("Part D: Gain in precision over SRS")
# -----------------------------------------------------------------------------
v_srs <- c(vtrue_srswor(pp, n), vtrue_srswor_p(pp, n))
v_pro <- c(vtrue_strat(info, nh_prop), vtrue_strat_p(info, nh_prop))
v_ney <- c(vtrue_strat(info, nh_ney), vtrue_strat_p(info, nh_ney))
gain <- data.frame(
  Parameter = c("Mean", "Proportion"),
  `V(SRSWOR)` = v_srs, `V(proportional)` = v_pro, `V(Neyman)` = v_ney,
  `RE proportional` = v_srs / v_pro, `RE Neyman` = v_srs / v_ney,
  `Gain % proportional` = 100 * (v_srs - v_pro) / v_pro, `Gain % Neyman` = 100 * (v_srs - v_ney) / v_ney,
  check.names = FALSE
)
save_table(gain, "gain_in_precision",
  "Table 2.6: Exact variances, relative efficiency RE = V(SRS) / V(design), and gain in precision")

# The Neyman allocation is optimum for the MEAN. The optimum allocation for the
# PROPORTION uses sqrt(P_h Q_h) in place of S_h (Cochran §5.10-5.11).
spq <- sqrt(info$P_h * (1 - info$P_h))
nh_neyP <- pmax(round_allocation(n * info$N_h * spq / sum(info$N_h * spq), n), 2)
report_text(
  "**Why does Neyman make the proportion worse (RE ", round(gain[2, "RE Neyman"], 3), ")?** ",
  "The allocation was optimised for the *mean*, so it took units away from Mysuru, the stratum where ",
  "female ownership (28%) varies most. An allocation optimised for P (",
  paste(info$stratum, nh_neyP, collapse = ", "), ") would give RE = ",
  round(v_srs[2] / vtrue_strat_p(info, nh_neyP), 3), ". The best allocation for one variable can be poor for another."
)

# Two exact results explain the gains (Cochran §5.6):
#  (1) V_SRS - V_prop = (1-f) / (n (N-1)) * [ sum N_h (Ybar_h - Ybar)^2 - (1/N) sum (N - N_h) S_h^2 ]
#      -> proportional allocation gains only if the stratum MEANS differ
#  (2) V_prop - V_ney = (1/n) sum W_h (S_h - Sbar)^2,  Sbar = sum W_h S_h
#      -> Neyman gains over proportional only if the stratum SDs differ
# Both are exact for unrounded allocations; real n_h must be whole numbers.
W <- info$W_h
Sbar <- sum(W * info$S_h)
f <- n / N
v_pro_exact <- (1 - f) / n * sum(W * info$S_h^2)
v_ney_exact <- sum(W * info$S_h)^2 / n - sum(W * info$S_h^2) / N
term1 <- (1 - f) / (n * (N - 1)) * (sum(info$N_h * (info$Ybar_h - pp$Ybar)^2) - sum((N - info$N_h) * info$S_h^2) / N)
term2 <- sum(W * (info$S_h - Sbar)^2) / n
decomp <- data.frame(
  Quantity = c(
    "Variation of stratum means: sum W_h (Ybar_h - Ybar)^2",
    "Population variance S^2",
    "Share of S^2 explained by the strata",
    "(1) V(SRS) - V(prop), by Cochran's formula",
    "     the same, computed directly",
    "     effect of rounding n_h to whole numbers",
    "Variation of stratum SDs: sum W_h (S_h - Sbar)^2",
    "(2) V(prop) - V(Neyman), by Cochran's formula",
    "     the same, computed directly",
    "RE proportional, unrounded allocation",
    "RE Neyman, unrounded allocation"
  ),
  Value = c(
    sum(W * (info$Ybar_h - pp$Ybar)^2), pp$S2, sum(W * (info$Ybar_h - pp$Ybar)^2) / pp$S2,
    term1, v_srs[1] - v_pro_exact, v_pro[1] - v_pro_exact,
    sum(W * (info$S_h - Sbar)^2), term2, v_pro_exact - v_ney_exact,
    v_srs[1] / v_pro_exact, v_srs[1] / v_ney_exact
  )
)
save_table(decomp, "variance_decomposition", "Table 2.7: Why the gain is what it is (mean)", digits = 5)
report_text(
  "**Reading Table 2.7.** (1) The stratum means explain only 0.02% of S^2, so proportional allocation gains ",
  "almost nothing. The gain is even smaller than the effect of rounding n_h to whole numbers, which is why ",
  "its RE in Table 2.6 is just below 1. (2) The stratum SDs differ a lot, and that is exactly what Neyman ",
  "allocation uses, giving about a 17% gain over SRS."
)

# -----------------------------------------------------------------------------
header("Part E: One-way ANOVA with strata as groups")
# -----------------------------------------------------------------------------
report_text("H0: all four stratum means are equal. H1: at least one differs. Level of significance: 5%.")
a_pop <- anova_oneway(frame$Y, frame$division)
save_table(a_pop, "anova_population", "Table 2.8: ANOVA on the whole population")
report_text(
  "With 2.9 million establishments even a tiny difference is 'significant' (p < 0.0001), but the ",
  "between-strata sum of squares is only ", signif(100 * a_pop[1, 3] / a_pop[3, 3], 2), "% of the total. ",
  "Almost all variation is **within** strata."
)

smp <- frame[attr(st_prop, "idx"), ]
a_smp <- anova_oneway(smp$Y, smp$division)
stopifnot(abs(summary(aov(Y ~ division, data = smp))[[1]][1, "F value"] - a_smp$F[1]) < 1e-8) # cross-check
save_table(a_smp, "anova_sample", "Table 2.9: ANOVA on the proportional-allocation sample (n = 748)")
decision <- if (a_smp[1, "p-value"] < ALPHA) {
  "**Reject H0:** the stratum means differ."
} else {
  "**Do not reject H0:** the sample gives no evidence that the stratum means differ."
}
report_text("F = ", round(a_smp$F[1], 3), ", p = ", fmt_p(a_smp[1, "p-value"]), ". ", decision)

skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
kw <- kruskal.test(Y ~ division, data = smp)
normality <- data.frame(
  Check = c(
    "Skewness of Y in the population (normal data: 0)",
    "Kruskal-Wallis chi-squared on the sample (needs no normality)",
    "Kruskal-Wallis p-value"
  ),
  Value = c(skew(frame$Y), unname(kw$statistic), kw$p.value)
)
save_table(normality, "normality_check", "Table 2.10: Checking ANOVA's normality assumption")
report_text(
  "ANOVA assumes roughly normal data with equal variances. Y has skewness ", round(skew(frame$Y)),
  " and very unequal stratum variances, so the assumption fails badly: a few huge values inflate the ",
  "within-group mean square and hide real differences. The rank-based Kruskal-Wallis test does not need ",
  "normality, and it ", if (kw$p.value < ALPHA) "**does** find a difference between strata (p = " else
    "also finds no difference (p = ", fmt_p(kw$p.value), ")."
)

# -----------------------------------------------------------------------------
header("Part F: Extra - which basis of stratification is better?")
# -----------------------------------------------------------------------------
basis_eval <- function(col, label) {
  inf <- strata_info(frame, col)
  data.frame(
    Basis = label, Strata = nrow(inf),
    `RE mean, proportional` = v_srs[1] / vtrue_strat(inf, alloc_proportional(inf, n)),
    `RE mean, Neyman` = v_srs[1] / vtrue_strat(inf, alloc_neyman(inf, n)),
    `RE proportion, proportional` = v_srs[2] / vtrue_strat_p(inf, alloc_proportional(inf, n)),
    `Range of P_h` = paste(sprintf("%.1f%%", 100 * range(inf$P_h)), collapse = " to "),
    check.names = FALSE
  )
}
save_table(rbind(basis_eval("division", "Revenue division"), basis_eval("activity", "Activity type")),
  "basis_comparison", "Table 2.11: Revenue division vs activity type as the basis of stratification")
report_text(
  "Divisions are better for the **mean** (their SDs differ more). Activity type is better for the ",
  "**proportion**: female ownership ranges from 5% in construction to 42% in manufacturing. ",
  "The best basis depends on which parameter matters most."
)

fig_open("stratum_means_and_proportions", width = 2000)
par(mfrow = c(1, 2))
barplot(info$Ybar_h,
  names.arg = info$stratum, col = PALETTE["blue"], border = NA, ylim = c(0, 3.5),
  main = "Mean workers per establishment", cex.names = 0.8
)
abline(h = pp$Ybar, lty = 2)
barplot(info$P_h * 100,
  names.arg = info$stratum, col = PALETTE["green"], border = NA, ylim = c(0, 32),
  main = "% of establishments female-owned", cex.names = 0.8
)
abline(h = pp$P * 100, lty = 2)
fig_close("Figure 2.3: Stratum means differ little; female ownership differs a lot (dashed line = whole state)")

save_shared(list(results = res, info = info, nh_prop = nh_prop, nh_ney = nh_ney), "stratified")
report_close()
