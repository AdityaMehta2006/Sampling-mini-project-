# =============================================================================
# 04_cluster.R — MEMBER 4: single-stage cluster sampling
#
# Part A  Clusters = enumeration blocks; how many to sample
# Part B  The selected clusters and the estimates (ratio and unbiased estimators)
# Part C  One-way ANOVA with clusters as groups -> intraclass correlation (ICC)
# Part D  Design effect and relative efficiency against SRS
# Part E  Extra: bigger clusters, lower efficiency (blocks vs wards vs towns)
# Part F  Comparison with SRS, stratified and systematic sampling
# Output: output/04_cluster/README.md
# =============================================================================
source("analysis/common.R")
source("analysis/designs.R")
report_open("04_cluster", "Unit 4: Cluster sampling (Member 4)")

frame <- load_frame()
pp <- load_shared("population")
N <- pp$N
n <- N_SAMPLE

# ICC from the one-way ANOVA mean squares (clusters of unequal size; Snedecor & Cochran):
#   rho = (MSB - MSW) / (MSB + (m0 - 1) MSW),   m0 = (N - sum M_i^2 / N) / (N_c - 1)
icc <- function(y, g) {
  a <- anova_oneway(y, g)
  M <- tabulate(as.factor(g))
  m0 <- (length(y) - sum(M^2) / length(y)) / (length(M) - 1)
  msb <- a[1, "Mean square"]
  msw <- a[2, "Mean square"]
  list(anova = a, m0 = m0, rho = (msb - msw) / (msb + (m0 - 1) * msw))
}

# -----------------------------------------------------------------------------
header("Part A: The clusters")
# -----------------------------------------------------------------------------
ct <- cluster_table(frame)
Nc <- nrow(ct)
Mbar <- N / Nc
n_c <- round(n / Mbar) # clusters needed for about n = 748 establishments
clus <- data.frame(
  Quantity = c(
    "Cluster", "Number of clusters in the frame N_c", "Average cluster size Mbar = N / N_c",
    "Smallest cluster", "Median cluster", "Largest cluster",
    "Clusters sampled n_c = n / Mbar (rounded)", "Expected establishments n_c x Mbar"
  ),
  Value = c(
    "Enumeration block (about one neighbourhood or village part)", format(Nc, big.mark = ","),
    sprintf("%.2f", Mbar), min(ct$M), median(ct$M), format(max(ct$M), big.mark = ","), n_c, round(n_c * Mbar)
  )
)
save_table(clus, "clusters", "Table 4.1: Enumeration blocks as clusters")
report_text(
  "Enumeration blocks are the natural work areas of census enumerators. In single-stage cluster sampling ",
  "we select ", n_c, " blocks at random (SRSWOR) and record **every** establishment in them, about ",
  round(n_c * Mbar), " in total, close to n = 748, so the designs are compared at the same sample size."
)

fig_open("cluster_sizes")
hist(log10(ct$M),
  breaks = 50, col = PALETTE["light"], border = "white", xaxt = "n",
  xlab = "Establishments in the enumeration block (log scale)", ylab = "Number of blocks",
  main = "Sizes of the 105,624 enumeration blocks"
)
axis(1, at = log10(c(1, 3, 10, 30, 100, 300, 1000)), labels = c(1, 3, 10, 30, 100, 300, "1,000"))
abline(v = log10(Mbar), col = PALETTE["red"], lwd = 2)
legend("topright", sprintf("average = %.1f", Mbar), col = PALETTE["red"], lwd = 2, bty = "n")
fig_close("Figure 4.1: Cluster sizes vary widely, so the ratio estimator is needed")

# -----------------------------------------------------------------------------
header("Part B: The selected clusters and the estimates")
# -----------------------------------------------------------------------------
set.seed(SEED + 6)
pick <- sample.int(Nc, n_c)
cl_ratio <- est_cluster(ct, n_c, pp, idx = pick, estimator = "ratio")
cl_unb <- est_cluster(ct, n_c, pp, idx = pick, estimator = "unbiased")
sel <- ct[pick, ]
selected <- data.frame(
  Cluster = sel$cluster_id,
  District = frame$district[match(sel$cluster_id, frame$cluster_id)],
  `Establishments M_i` = sel$M, `Workers y_i` = sel$y, `Female-owned a_i` = sel$a,
  `Mean workers y_i / M_i` = sel$y / sel$M, check.names = FALSE
)
save_table(selected[order(selected$District), ], "selected_clusters",
  "Table 4.2: The 27 selected enumeration blocks (cluster code = district-tehsil-town/village-ward-block)")
save_sample(frame[frame$cluster_id %in% sel$cluster_id, ], "cluster_sample_all_units")

res <- rbind(cl_ratio, cl_unb)
save_results(res, "cluster_estimates", "Table 4.3: Cluster sample estimates with 95% confidence intervals")
report_text(
  "**Ratio estimator** (used for comparisons): mean = sum y_i / sum M_i. **Unbiased estimator**: ",
  "mean = N_c sum y_i / (n_c N). The unbiased one ignores how many establishments each block has, so ",
  "its variance depends on the variation in block *totals*, which is huge because sizes vary from 1 to over ",
  "1,800. CIs use t with n_c - 1 = ", n_c - 1, " degrees of freedom, since only ", n_c, " clusters carry ",
  "information. fpc = 1 - n_c / N_c = ", round(1 - n_c / Nc, 5), "."
)

# -----------------------------------------------------------------------------
header("Part C: ANOVA with clusters as groups and the intraclass correlation")
# -----------------------------------------------------------------------------
report_text(
  "H0: all 105,624 clusters have the same mean (no clustering). H1: cluster means differ. ",
  "Level of significance: 5%. The mean squares give the intraclass correlation (ICC)."
)
icc_y <- icc(frame$Y, frame$cluster_id)
save_table(icc_y$anova, "anova_workers", "Table 4.4: ANOVA, workers per establishment, clusters as groups")
icc_p <- icc(frame$female, frame$cluster_id)
save_table(icc_p$anova, "anova_female", "Table 4.5: ANOVA, female ownership (0/1), clusters as groups")
report_text(
  "**Reject H0 for both variables** (F = ", round(icc_y$anova$F[1], 2), " for workers and ",
  round(icc_p$anova$F[1], 2), " for female ownership; both p < 0.0001): establishments in the same block are ",
  "more alike than establishments picked at random, much more so for female ownership. ANOVA assumes normal ",
  "data; with 2.9 million units the test is robust to this, but for workers the clustering is driven mostly by ",
  "the few blocks that contain very large employers."
)

# -----------------------------------------------------------------------------
header("Part D: Design effect and relative efficiency")
# -----------------------------------------------------------------------------
# Equal-cluster theory (Gupta & Kapoor; Cochran §9.4) with M replaced by Mbar:
#   V(ybar_cl) ~ V_SRS(n = n_c Mbar) [1 + (Mbar - 1) rho]     deff = 1 + (Mbar - 1) rho,  RE = 1 / deff
n_equiv <- n_c * Mbar
v_srs_y <- vtrue_srswor(pp, n_equiv)
v_srs_p <- vtrue_srswor_p(pp, n_equiv)
eff <- data.frame(
  Quantity = c(
    "MSB (between clusters)", "MSW (within clusters)", "m0 (adjusted average cluster size)",
    "Intraclass correlation rho", "Design effect by formula 1 + (Mbar - 1) rho",
    "Actual design effect V(cluster, ratio) / V(SRS, same n)", "Relative efficiency vs SRS = 1 / actual deff",
    "Actual design effect, unbiased estimator", "Relative efficiency, unbiased estimator"
  ),
  `Mean workers` = c(
    icc_y$anova[1, "Mean square"], icc_y$anova[2, "Mean square"], icc_y$m0, icc_y$rho,
    1 + (Mbar - 1) * icc_y$rho, cl_ratio$var_true[1] / v_srs_y, v_srs_y / cl_ratio$var_true[1],
    cl_unb$var_true[1] / v_srs_y, v_srs_y / cl_unb$var_true[1]
  ),
  `Proportion female-owned` = c(
    icc_p$anova[1, "Mean square"], icc_p$anova[2, "Mean square"], icc_p$m0, icc_p$rho,
    1 + (Mbar - 1) * icc_p$rho, cl_ratio$var_true[3] / v_srs_p, v_srs_p / cl_ratio$var_true[3],
    cl_unb$var_true[3] / v_srs_p, v_srs_p / cl_unb$var_true[3]
  ),
  check.names = FALSE
)
save_table(eff, "icc_design_effect", "Table 4.6: Intraclass correlation, design effect and relative efficiency")
report_text(
  "**Female ownership clusters strongly** (rho = ", sprintf("%.3f", icc_p$rho), "): women-owned businesses ",
  "are concentrated in particular localities and trades, so a block tells us little that its neighbours do not. ",
  "With about ", round(Mbar), " establishments per block, each sampled block is worth only about ",
  sprintf("%.1f", n_c * Mbar / (cl_ratio$var_true[3] / v_srs_p) / n_c), " independent establishments. ",
  "For workers rho is ", sprintf("%.3f", icc_y$rho), ". The formula and the actual design effect agree in direction; ",
  "they differ in size because the formula assumes equal cluster sizes."
)

fig_open("female_share_by_cluster")
big <- ct$M >= 20
share <- ct$a[big] / ct$M[big]
sim <- rbinom(sum(big), ct$M[big], pp$P) / ct$M[big] # what we would see with NO clustering
hist(share,
  breaks = seq(0, 1, 0.025), col = "#4C72B099", border = "white", ylim = c(0, max(table(cut(sim, seq(0, 1, 0.025))))),
  xlab = "Share of establishments in the block that are female-owned", ylab = "Number of blocks (with 20+ units)",
  main = "Female ownership is clustered by block"
)
hist(sim, breaks = seq(0, 1, 0.025), col = "#C44E5266", border = "white", add = TRUE)
legend("topright", c("actual blocks", "if there were no clustering"),
  fill = c("#4C72B099", "#C44E5266"), bty = "n", cex = 0.85)
fig_close("Figure 4.2: Actual blocks are far more spread out than they would be without clustering (high ICC)")

# -----------------------------------------------------------------------------
header("Part E: Extra - bigger clusters, lower efficiency")
# -----------------------------------------------------------------------------
parts <- strsplit(frame$cluster_id, "-", fixed = TRUE)
definitions <- list(
  `Enumeration block (used)` = frame$cluster_id,
  `Ward` = vapply(parts, function(x) paste(x[1:4], collapse = "-"), character(1)),
  `Town / village` = vapply(parts, function(x) paste(x[1:3], collapse = "-"), character(1))
)
size_tab <- do.call(rbind, lapply(names(definitions), function(nm) {
  g <- definitions[[nm]]
  fr2 <- frame
  fr2$cluster_id <- g
  ct2 <- cluster_table(fr2)
  mbar2 <- N / nrow(ct2)
  nc2 <- max(2, round(n / mbar2))
  ne <- nc2 * mbar2
  data.frame(
    Cluster = nm, Clusters = nrow(ct2), `Average size` = mbar2, `Clusters for n ~ 748` = nc2,
    `ICC, female` = icc(frame$female, g)$rho,
    `Design effect, female` = vtrue_cluster(ct2, nc2, "a", pp$P) / vtrue_srswor_p(pp, ne),
    `Design effect, workers` = vtrue_cluster(ct2, nc2, "y", pp$Ybar) / vtrue_srswor(pp, ne),
    check.names = FALSE
  )
}))
save_table(size_tab, "cluster_size_effect", "Table 4.7: Larger clusters, larger design effect (same total sample size)")
report_text(
  "With the total sample fixed at about 748 establishments, larger clusters mean fewer of them. Wards and ",
  "whole towns/villages give enormous design effects, because a handful of them cannot represent the state; ",
  "Bengaluru city alone is one 'town' with over 360,000 establishments. Small clusters like enumeration blocks ",
  "are the only workable choice, and even they are less efficient than SRS."
)

fig_open("design_effect_by_cluster_size")
plot(size_tab$`Average size`, size_tab$`Design effect, female`,
  log = "xy", type = "b", pch = 19, lwd = 2, col = PALETTE["green"],
  ylim = range(size_tab[, 6:7], 1), xlab = "Average cluster size (log scale)",
  ylab = "Design effect (log scale)", main = "Design effect grows with cluster size"
)
lines(size_tab$`Average size`, size_tab$`Design effect, workers`, type = "b", pch = 17, lwd = 2, col = PALETTE["blue"])
text(size_tab$`Average size`, size_tab$`Design effect, female`, size_tab$Cluster, pos = 4, cex = 0.75)
abline(h = 1, lty = 2, col = PALETTE["grey"])
legend("topleft", c("female ownership", "workers", "SRS (deff = 1)"),
  col = c(PALETTE["green"], PALETTE["blue"], PALETTE["grey"]), pch = c(19, 17, NA), lty = c(1, 1, 2), bty = "n")
fig_close("Figure 4.3: The larger the clusters, the larger the loss of precision")

# -----------------------------------------------------------------------------
header("Part F: Comparison with SRS, stratified and systematic sampling")
# -----------------------------------------------------------------------------
strat <- load_shared("stratified")
sys <- load_shared("systematic")
v_srs <- c(vtrue_srswor(pp, n), vtrue_srswor_p(pp, n))
designs_v <- rbind(
  `SRSWOR (n = 748)` = v_srs,
  `Stratified, proportional (n = 748)` = c(
    vtrue_strat(strat$info, strat$nh_prop), vtrue_strat_p(strat$info, strat$nh_prop)
  ),
  `Stratified, Neyman (n = 748)` = c(
    vtrue_strat(strat$info, strat$nh_ney), vtrue_strat_p(strat$info, strat$nh_ney)
  ),
  `Systematic (n = 748)` = c(sys$v_mean, sys$v_prop),
  `Cluster, ratio estimator (27 blocks, about 736 units)` = cl_ratio$var_true[c(1, 3)]
)
comp <- data.frame(
  Design = rownames(designs_v),
  `Exact SE, mean` = sqrt(designs_v[, 1]), `Exact SE, proportion` = sqrt(designs_v[, 2]),
  `RE mean` = sprintf("%.3f", v_srs[1] / designs_v[, 1]),
  `RE proportion` = sprintf("%.3f", v_srs[2] / designs_v[, 2]),
  check.names = FALSE, row.names = NULL
)
save_table(comp, "comparison", "Table 4.8: Cluster sampling compared with the other designs (RE against SRSWOR)")
report_text(
  "Stratified and systematic samples spread the units over the whole state; a cluster sample concentrates ",
  "them in ", n_c, " small areas. Stratification gains when strata differ, and clustering loses when clusters ",
  "differ, which is the same ANOVA idea seen from opposite sides. ",
  "Cluster sampling is chosen for **cost**, not precision: 27 compact blocks need far less travel, ",
  "and only a list of blocks (not of every establishment) is needed."
)

save_shared(list(results = cl_ratio, unbiased = cl_unb, n_c = n_c), "cluster")
report_close()
