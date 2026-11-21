# =============================================================================
# designs.R — the estimators of every sampling design, in ONE place
#
# Each member owns one section. The member's own script (01-04) calls these
# functions once to draw "the" sample; script 05 calls them 500 times for the
# Monte Carlo simulation, so every number comes from the same formulas.
#
# Notation (Cochran; Gupta & Kapoor):
#   N, n       population and sample size          f = n / N  (sampling fraction)
#   Y_i, y_i   value of the study variable         Ybar, ybar  population / sample mean
#   S^2        population variance (divisor N-1)   s^2         sample variance (divisor n-1)
#   P, p       population / sample proportion      Q = 1 - P,  q = 1 - p
# Every est_*() function returns rows for Mean, Total and Proportion.
# =============================================================================

# -----------------------------------------------------------------------------
# UNIT 1 — SRSWOR and SRSWR                                         (MEMBER 1)
# -----------------------------------------------------------------------------
# Exact variances (from the population):
#   SRSWOR:  V(ybar) = (1 - f) S^2 / n                   V(p) = (N - n) / (N - 1) * PQ / n
#   SRSWR :  V(ybar) = sigma^2 / n, sigma^2 = (N-1) S^2 / N    V(p) = PQ / n
vtrue_srswor <- function(pp, n) (1 - n / pp$N) * pp$S2 / n
vtrue_srswor_p <- function(pp, n) (pp$N - n) / (pp$N - 1) * pp$P * (1 - pp$P) / n
vtrue_srswr <- function(pp, n) ((pp$N - 1) / pp$N) * pp$S2 / n
vtrue_srswr_p <- function(pp, n) pp$P * (1 - pp$P) / n

# Estimated variances (from the sample):
#   SRSWOR:  v(ybar) = (1 - f) s^2 / n                   v(p) = (1 - f) pq / (n - 1)
#   SRSWR :  v(ybar) = s^2 / n                           v(p) = pq / (n - 1)
est_srswor <- function(fr, n, pp, idx = sample.int(nrow(fr), n)) {
  N <- nrow(fr)
  f <- n / N
  y <- fr$Y[idx]
  p <- mean(fr$female[idx])
  out <- three_rows("SRSWOR", N, mean(y), (1 - f) * var(y) / n,
    p, (1 - f) * p * (1 - p) / (n - 1), pp,
    v_true_mean = vtrue_srswor(pp, n), v_true_p = vtrue_srswor_p(pp, n)
  )
  attr(out, "idx") <- idx
  out
}

est_srswr <- function(fr, n, pp, idx = sample.int(nrow(fr), n, replace = TRUE)) {
  N <- nrow(fr)
  y <- fr$Y[idx]
  p <- mean(fr$female[idx])
  out <- three_rows("SRSWR", N, mean(y), var(y) / n,
    p, p * (1 - p) / (n - 1), pp,
    v_true_mean = vtrue_srswr(pp, n), v_true_p = vtrue_srswr_p(pp, n)
  )
  attr(out, "idx") <- idx
  out
}

# -----------------------------------------------------------------------------
# UNIT 2 — STRATIFIED RANDOM SAMPLING                               (MEMBER 2)
# -----------------------------------------------------------------------------
# Summary of every stratum h: N_h, W_h = N_h / N, Ybar_h, S_h, P_h (+ its units).
strata_info <- function(fr, col) {
  units <- split(seq_len(nrow(fr)), fr[[col]])
  info <- data.frame(
    stratum = names(units),
    N_h = lengths(units),
    W_h = lengths(units) / nrow(fr),
    Ybar_h = vapply(units, function(i) mean(fr$Y[i]), numeric(1)),
    S_h = vapply(units, function(i) sd(fr$Y[i]), numeric(1)),
    P_h = vapply(units, function(i) mean(fr$female[i]), numeric(1)),
    row.names = NULL, stringsAsFactors = FALSE
  )
  attr(info, "units") <- units
  info
}

# Proportional allocation:  n_h = n N_h / N
alloc_proportional <- function(info, n) round_allocation(n * info$N_h / sum(info$N_h), n)

# Neyman (optimum) allocation:  n_h = n N_h S_h / sum(N_h S_h)
# (at least 2 per stratum so that s_h^2 can be computed)
alloc_neyman <- function(info, n) {
  pmax(round_allocation(n * info$N_h * info$S_h / sum(info$N_h * info$S_h), n), 2)
}

# Exact variances for a given allocation n_h:
#   V(ybar_st) = sum W_h^2 (1 - f_h) S_h^2 / n_h
#   V(p_st)    = sum W_h^2 (N_h - n_h) / (N_h - 1) * P_h Q_h / n_h
vtrue_strat <- function(info, nh) sum(info$W_h^2 * (1 - nh / info$N_h) * info$S_h^2 / nh)
vtrue_strat_p <- function(info, nh) {
  sum(info$W_h^2 * (info$N_h - nh) / (info$N_h - 1) * info$P_h * (1 - info$P_h) / nh)
}

# One stratified sample (SRSWOR inside every stratum):
#   ybar_st = sum W_h ybar_h        v(ybar_st) = sum W_h^2 (1 - f_h) s_h^2 / n_h
#   p_st    = sum W_h p_h           v(p_st)    = sum W_h^2 (1 - f_h) p_h q_h / (n_h - 1)
est_stratified <- function(fr, info, nh, pp, label) {
  units <- attr(info, "units")
  picked <- Map(function(u, k) u[sample.int(length(u), k)], units, nh)
  ybar_h <- vapply(picked, function(i) mean(fr$Y[i]), numeric(1))
  s2_h <- vapply(picked, function(i) var(fr$Y[i]), numeric(1))
  p_h <- vapply(picked, function(i) mean(fr$female[i]), numeric(1))
  W <- info$W_h
  fh <- nh / info$N_h
  out <- three_rows(label, nrow(fr),
    sum(W * ybar_h), sum(W^2 * (1 - fh) * s2_h / nh),
    sum(W * p_h), sum(W^2 * (1 - fh) * p_h * (1 - p_h) / (nh - 1)), pp,
    v_true_mean = vtrue_strat(info, nh), v_true_p = vtrue_strat_p(info, nh)
  )
  attr(out, "idx") <- unlist(picked, use.names = FALSE)
  attr(out, "by_stratum") <- data.frame(
    Stratum = info$stratum, n_h = nh, `Sample mean` = ybar_h,
    `Sample variance` = s2_h, `Sample proportion` = p_h,
    row.names = NULL, check.names = FALSE
  )
  out
}

# -----------------------------------------------------------------------------
# UNIT 3 — LINEAR SYSTEMATIC SAMPLING (N = n k)                     (MEMBER 3)
# -----------------------------------------------------------------------------
# With N = n k, unit number i belongs to systematic sample r = ((i - 1) mod k) + 1.
# Putting y into a k x n matrix (filled column by column) puts sample r in row r.
sys_matrix <- function(y, k) matrix(y, nrow = k)

# Exact variance = average squared deviation of the k possible sample means:
#   V(ybar_sy) = (1 / k) sum_r (ybar_r - Ybar)^2
vtrue_sys <- function(y, k) {
  means <- rowMeans(sys_matrix(y, k))
  mean((means - mean(y))^2)
}

# One systematic sample with random start r (1 <= r <= k). A single systematic
# sample has no unbiased variance estimator; the usual approximation treats it as
# SRSWOR (Cochran §8.11):  v(ybar_sy) = (1 - f) s^2 / n.
est_systematic <- function(fr, k, r, pp, v_true_mean = NA, v_true_p = NA) {
  N <- nrow(fr)
  idx <- seq(r, N, by = k)
  n <- length(idx)
  f <- n / N
  y <- fr$Y[idx]
  p <- mean(fr$female[idx])
  out <- three_rows("Systematic", N, mean(y), (1 - f) * var(y) / n,
    p, (1 - f) * p * (1 - p) / (n - 1), pp,
    v_true_mean = v_true_mean, v_true_p = v_true_p
  )
  attr(out, "idx") <- idx
  out
}

# -----------------------------------------------------------------------------
# UNIT 4 — SINGLE-STAGE CLUSTER SAMPLING                            (MEMBER 4)
# -----------------------------------------------------------------------------
# Clusters = enumeration blocks. For each cluster i: size M_i, total y_i of the
# study variable, and a_i = number of female-owned establishments.
cluster_table <- function(fr) {
  g <- factor(fr$cluster_id, levels = unique(fr$cluster_id))
  data.frame(
    cluster_id = levels(g),
    M = tabulate(g, nlevels(g)),
    y = as.numeric(rowsum(fr$Y, g)),
    a = as.numeric(rowsum(fr$female, g)),
    stringsAsFactors = FALSE
  )
}

# Clusters are of unequal size, so the mean per establishment is estimated with the
# ratio estimator (Cochran Ch. 9A, clusters of unequal size):   ybar_cl = sum y_i / sum M_i
#   v(ybar_cl) = (1 - f) / (n_c Mbar^2) * sum (y_i - ybar_cl M_i)^2 / (n_c - 1)
# where f = n_c / N_c and Mbar = N / N_c. Its exact (large-sample) variance is
#   V(ybar_cl) = (1 - f) / (n_c Mbar^2) * sum (y_i - Ybar M_i)^2 / (N_c - 1)
vtrue_cluster <- function(ct, n_c, total_col, Ybar) {
  Nc <- nrow(ct)
  Mbar <- sum(ct$M) / Nc
  (1 - n_c / Nc) / (n_c * Mbar^2) * sum((ct[[total_col]] - Ybar * ct$M)^2) / (Nc - 1)
}

# Unbiased estimator:  ybar_u = N_c / (n_c N) * sum y_i
#   V(ybar_u) = (1 - f) N_c^2 S_t^2 / (n_c N^2),  S_t^2 = variance of the cluster totals
vtrue_cluster_unbiased <- function(ct, n_c, total_col) {
  Nc <- nrow(ct)
  N <- sum(ct$M)
  (1 - n_c / Nc) * Nc^2 * var(ct[[total_col]]) / (n_c * N^2)
}

est_cluster <- function(ct, n_c, pp, idx = sample.int(nrow(ct), n_c), estimator = c("ratio", "unbiased")) {
  estimator <- match.arg(estimator)
  Nc <- nrow(ct)
  N <- sum(ct$M)
  Mbar <- N / Nc
  f <- n_c / Nc
  s <- ct[idx, ]
  if (estimator == "ratio") {
    ybar <- sum(s$y) / sum(s$M)
    p <- sum(s$a) / sum(s$M)
    v_y <- (1 - f) / (n_c * Mbar^2) * sum((s$y - ybar * s$M)^2) / (n_c - 1)
    v_p <- (1 - f) / (n_c * Mbar^2) * sum((s$a - p * s$M)^2) / (n_c - 1)
    vt_y <- vtrue_cluster(ct, n_c, "y", pp$Ybar)
    vt_p <- vtrue_cluster(ct, n_c, "a", pp$P)
    label <- "Cluster"
  } else {
    ybar <- Nc * sum(s$y) / (n_c * N)
    p <- Nc * sum(s$a) / (n_c * N)
    v_y <- (1 - f) * Nc^2 * var(s$y) / (n_c * N^2)
    v_p <- (1 - f) * Nc^2 * var(s$a) / (n_c * N^2)
    vt_y <- vtrue_cluster_unbiased(ct, n_c, "y")
    vt_p <- vtrue_cluster_unbiased(ct, n_c, "a")
    label <- "Cluster (unbiased estimator)"
  }
  # Only n_c clusters carry information, so the CI uses t with n_c - 1 df.
  out <- three_rows(label, N, ybar, v_y, p, v_p, pp, v_true_mean = vt_y, v_true_p = vt_p, df = n_c - 1)
  attr(out, "idx") <- idx
  out
}
