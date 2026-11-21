# =============================================================================
# 01_srs.R — frame preparation, sample size, SRSWOR and SRSWR
#
# Part A  Clean the data and build the sampling frame (used by everyone)
# Part B  True population values (the "ground truth")
# Part C  Sample size n for a specified precision
# Part D  SRSWOR and SRSWR: estimate, variance, SE, 95% CI, fpc
# Part E  Comparison of SRSWOR with SRSWR
# Output: output/01_srs/README.md
# =============================================================================
source("analysis/common.R")
source("analysis/designs.R")
report_open("01_srs", paste0("Unit 1: Frame, sample size, SRSWOR and SRSWR (", TEAM$name[1], ")"))

DISTRICT_NAMES <- c(
  "01" = "Belgaum", "02" = "Bagalkot", "03" = "Bijapur", "04" = "Bidar", "05" = "Raichur",
  "06" = "Koppal", "07" = "Gadag", "08" = "Dharwad", "09" = "Uttara Kannada", "10" = "Haveri",
  "11" = "Bellary", "12" = "Chitradurga", "13" = "Davanagere", "14" = "Shimoga", "15" = "Udupi",
  "16" = "Chikmagalur", "17" = "Tumkur", "18" = "Bangalore", "19" = "Mandya", "20" = "Hassan",
  "21" = "Dakshina Kannada", "22" = "Kodagu", "23" = "Mysore", "24" = "Chamarajanagar",
  "25" = "Gulbarga", "26" = "Yadgir", "27" = "Kolar", "28" = "Chikkaballapura",
  "29" = "Bangalore Rural", "30" = "Ramanagara"
)

# -----------------------------------------------------------------------------
header("Part A: Data cleaning and the sampling frame")
# -----------------------------------------------------------------------------
# The frame is built from the raw export when it is available. Teammates without
# the 300 MB export use the frame and the cleaning results already in the repository.
build_frame <- function() {
  raw <- read.csv(RAW_CSV, colClasses = "character")
  num <- function(x) as.numeric(x)

  checks <- data.frame(
    Check = c(
      "Missing number of workers", "Number of workers below 1",
      "Total workers differs from the sum of its four parts (M_H + F_H + M_NH + F_NH)",
      "Missing owner's sex code", "Missing location code (district to enumeration block)"
    ),
    `Problem records` = c(
      sum(is.na(num(raw$TOTAL_WORKER))),
      sum(num(raw$TOTAL_WORKER) < 1, na.rm = TRUE),
      sum(num(raw$TOTAL_WORKER) != num(raw$M_H) + num(raw$F_H) + num(raw$M_NH) + num(raw$F_NH)),
      sum(raw$SEX == ""),
      sum(raw$DT == "" | raw$TEH == "" | raw$T_V == "" | raw$WC == "" | raw$EB == "")
    ),
    check.names = FALSE
  )

  # Systematic sampling needs a listed order. Establishments are listed by their
  # official location codes: District > Tehsil > Town/Village > Ward > Enumeration
  # Block > Sub-block, keeping the census order inside each block.
  raw <- raw[order(raw$DT, raw$TEH, raw$T_V, raw$WC, raw$EB, raw$EBX, seq_len(nrow(raw))), ]

  dt <- as.integer(raw$DT)
  division <- rep(NA_character_, nrow(raw))
  for (dv in names(DIVISIONS)) division[dt %in% DIVISIONS[[dv]]] <- dv

  frame <- data.frame(
    unit_id = seq_len(nrow(raw)), # position in the listed frame, 1..N
    DT = raw$DT,
    district = unname(DISTRICT_NAMES[raw$DT]),
    division = division, # strata (Unit 2)
    activity = as.character(cut(as.integer(raw$BACT), c(0, 5, 8, 9, 12, 23),
      labels = c("Primary", "Manufacturing", "Construction", "Trade", "Services")
    )),
    sector = ifelse(raw$SECTOR == "1", "Rural", "Urban"),
    ownership = raw$OWN_SHIP_C,
    cluster_id = paste(raw$DT, raw$TEH, raw$T_V, raw$WC, raw$EB, sep = "-"), # clusters (Unit 4)
    Y = num(raw$TOTAL_WORKER), # the numerical variable
    female = as.integer(raw$SEX == "2"), # 1 = female-owned (for the proportion)
    stringsAsFactors = FALSE
  )
  stopifnot(!anyNA(frame$division), !anyNA(frame$activity))
  saveRDS(frame, FRAME_RDS, compress = "xz")
  list(frame = frame, checks = checks)
}

if (file.exists(RAW_CSV)) {
  built <- build_frame()
  frame <- built$frame
  checks <- built$checks
} else {
  message("Raw export not found: using ", FRAME_RDS, " and the saved cleaning checks.")
  frame <- load_frame()
  checks <- read.csv(file.path("output/01_srs/tables/cleaning_checks.csv"), check.names = FALSE)
}
save_table(checks, "cleaning_checks", "Table 1.1: Data quality checks")
report_text(
  "No record had to be removed, so the population is the complete census list of ",
  format(nrow(frame), big.mark = ","), " establishments."
)

# Possible recording errors: very large establishments, especially single-owner ones.
OWNERSHIP <- c(
  "1" = "Government / PSU", "2" = "Private: proprietary (single owner)", "3" = "Private: partnership",
  "4" = "Private: company", "5" = "Private: self-help group", "6" = "Private: co-operative",
  "7" = "Private: non-profit institution", "9" = "Private: others"
)
big <- frame[frame$Y >= 1000, ]
big_tab <- aggregate(Y ~ ownership, data = big, FUN = length)
big_tab <- data.frame(
  `Type of ownership` = unname(OWNERSHIP[big_tab$ownership]),
  `Establishments with 1,000+ workers` = big_tab$Y,
  `Largest reported` = tapply(big$Y, big$ownership, max)[big_tab$ownership],
  check.names = FALSE, row.names = NULL
)
save_table(big_tab, "large_establishments", "Table 1.2: Establishments reporting 1,000 or more workers")
suspect <- frame$Y >= 10000 & frame$ownership == "2"
top <- frame[order(-frame$Y), ][1:8, ]
top_tab <- data.frame(
  District = top$district, Activity = top$activity, Area = top$sector,
  Ownership = unname(OWNERSHIP[top$ownership]), Workers = top$Y,
  `Looks like a recording error?` = ifelse(top$Y >= 10000 & top$ownership == "2", "likely", "possible but plausible"),
  check.names = FALSE
)
save_table(top_tab, "largest_establishments", "Table 1.3: The eight largest establishments in the data")
keep <- !suspect
sens <- data.frame(
  Data = c("All establishments (official data, used in this project)",
           paste0("Without the ", sum(suspect), " single-owner establishments reporting 10,000+ workers")),
  N = c(nrow(frame), sum(keep)),
  `Mean workers` = c(mean(frame$Y), mean(frame$Y[keep])),
  `SD of workers` = c(sd(frame$Y), sd(frame$Y[keep])),
  `Total workers` = c(sum(frame$Y), sum(frame$Y[keep])),
  check.names = FALSE
)
save_table(sens, "sensitivity_large_values", "Table 1.4: How much do the suspicious values matter?")
report_text(
  "**Possible recording errors.** ", sum(suspect), " proprietary (single-owner) establishments, most in rural ",
  "areas, report 10,000 or more workers, and ", sum(frame$Y[suspect] %in% c(10001, 10002)),
  " of them report exactly 10,001 or 10,002. Repeated values just ",
  "above 10,000 for private rural businesses look like a placeholder or data-entry code, not real head-counts. ",
  "We **keep** them because the project must use the official data as published, but they are a clear ",
  "non-sampling (recording) error. Removing them would change the ",
  "mean only slightly (", sprintf("%.3f", sens[1, 3]), " to ", sprintf("%.3f", sens[2, 3]), ") but the SD noticeably (",
  sprintf("%.1f", sens[1, 4]), " to ", sprintf("%.1f", sens[2, 4]), "), because the SD is driven by extreme values."
)

design <- data.frame(
  Element = c(
    "Population", "Sampling unit", "Frame", "Order of the frame (systematic sampling)",
    "Numerical variable Y", "Proportion P", "Strata", "Clusters", "Sample size"
  ),
  Definition = c(
    "All establishments in Karnataka, Sixth Economic Census 2012-13",
    "One establishment",
    paste0("Census list of ", format(nrow(frame), big.mark = ","), " establishments"),
    "District > Tehsil > Town/Village > Ward > Enumeration block",
    "Total persons employed in the establishment (TOTAL_WORKER)",
    "Share of establishments owned by a woman (SEX = 2)",
    "The 4 revenue divisions: Bengaluru, Mysuru, Belagavi, Kalaburagi",
    paste0(format(length(unique(frame$cluster_id)), big.mark = ","), " enumeration blocks"),
    "n = 748 for every method (Part C)"
  )
)
save_table(design, "survey_design", "Table 1.5: Survey design")

# -----------------------------------------------------------------------------
header("Part B: True population values")
# -----------------------------------------------------------------------------
pp <- pop_params(frame)
truth <- data.frame(
  Quantity = c(
    "Number of establishments N", "Mean workers per establishment (Ybar)",
    "Total workers (Y)", "Population variance S^2", "Population SD S",
    "Coefficient of variation S / Ybar", "Median workers", "Largest establishment (workers)",
    "Proportion female-owned P", "Number of female-owned establishments"
  ),
  Value = c(
    pp$N, pp$Ybar, pp$Ytot, pp$S2, sqrt(pp$S2), sqrt(pp$S2) / pp$Ybar,
    median(frame$Y), max(frame$Y), pp$P, pp$A
  )
)
save_table(truth, "population_truth", "Table 1.6: True population values (known from the census)", digits = 5)
save_shared(pp, "population")

classes <- table(cut(frame$Y, c(0, 1, 2, 3, 5, 10, 50, 100, Inf),
  labels = c("1", "2", "3", "4-5", "6-10", "11-50", "51-100", "over 100")
))
share <- as.numeric(classes) / pp$N * 100
fig_open("distribution_of_workers")
bars <- barplot(share,
  names.arg = names(classes), col = PALETTE["blue"], border = NA, ylim = c(0, 75),
  xlab = "Persons employed in the establishment", ylab = "% of establishments",
  main = "How many people do Karnataka's establishments employ?"
)
text(bars, share, paste0(round(share, 1), "%"), pos = 3, cex = 0.8)
mtext(sprintf(
  "Mean %.2f  |  median %d  |  largest %s  |  CV %.1f",
  pp$Ybar, median(frame$Y), format(max(frame$Y), big.mark = ","), sqrt(pp$S2) / pp$Ybar
), cex = 0.85)
fig_close("Figure 1.1: Most establishments have one worker; a handful employ thousands (extreme right skew)")
report_text(
  "**What this means:** over half of all establishments have a single worker, but a few employ thousands. ",
  "This skew drives every result in the project: it makes the mean much harder to estimate than the proportion."
)

# -----------------------------------------------------------------------------
header("Part C: Sample size for a specified precision")
# -----------------------------------------------------------------------------
# Proportion with margin of error d at 95% confidence (Cochran §4.4):
#   n0 = z^2 P Q / d^2,     n = n0 / (1 + (n0 - 1) / N)
# P is taken from the census (in a real survey it would come from the previous census or a pilot).
N <- pp$N
n0 <- Z^2 * pp$P * (1 - pp$P) / D_PROP^2
n_req <- ceiling(n0 / (1 + (n0 - 1) / N))

# Systematic sampling (N = n k) needs n to divide N exactly: take the smallest such n >= n_req.
divisors <- function(x) {
  s <- seq_len(floor(sqrt(x)))
  d <- s[x %% s == 0]
  sort(unique(c(d, x / d)))
}
n_used <- min(divisors(N)[divisors(N) >= n_req])
stopifnot(n_used == N_SAMPLE, N / n_used == K_SYS)
d_achieved <- Z * sqrt((1 - n_used / N) * pp$P * (1 - pp$P) / n_used)

# For comparison, the mean within +/- r x Ybar:  n0 = (z S / (r Ybar))^2,  n = n0 / (1 + n0 / N)
n_for_mean <- function(r) {
  m0 <- (Z * sqrt(pp$S2) / (r * pp$Ybar))^2
  ceiling(m0 / (1 + m0 / N))
}

size <- data.frame(
  Step = c(
    "Required margin of error d for P (95% confidence)", "n0 = z^2 PQ / d^2",
    "n = n0 / (1 + (n0 - 1) / N)", "Chosen n: smallest divisor of N that is at least n",
    "Sampling interval k = N / n", "Margin of error actually achieved for P",
    "For comparison: n to estimate the MEAN within 10%", "For comparison: n to estimate the MEAN within 20%"
  ),
  Value = c(D_PROP, n0, n_req, n_used, N / n_used, d_achieved, n_for_mean(0.10), n_for_mean(0.20))
)
save_table(size, "sample_size", "Table 1.7: Sample size determination", digits = 5)
report_text(
  "**n = ", n_used, " is used for every method.** It is fixed by the proportion: a margin of +/-3 ",
  "percentage points needs ", n_req, " establishments. We round up to ", n_used, " because ",
  "748 x 3,851 = 2,880,548 exactly, which systematic sampling (N = nk) requires. ",
  "The mean would need ", format(n_for_mean(0.10), big.mark = ","), " establishments for 10% precision, ",
  "which is why the other designs try to do better than SRS."
)

d_grid <- seq(0.01, 0.06, by = 0.0025)
n_grid <- vapply(d_grid, function(d) {
  m0 <- Z^2 * pp$P * (1 - pp$P) / d^2
  m0 / (1 + (m0 - 1) / N)
}, numeric(1))
fig_open("sample_size_curve")
plot(d_grid * 100, n_grid,
  type = "l", lwd = 2.5, col = PALETTE["blue"], log = "y",
  xlab = "Margin of error d for P (percentage points)", ylab = "Required sample size n (log scale)",
  main = "Sample size needed to estimate P at 95% confidence"
)
points(D_PROP * 100, n_req, pch = 19, cex = 1.3, col = PALETTE["red"])
text(D_PROP * 100, n_req, paste0("   d = 3 points: n = ", n_req), pos = 4, cex = 0.85)
abline(h = n_used, lty = 2, col = PALETTE["grey"])
text(5.6, n_used, "chosen n = 748", pos = 3, cex = 0.8, col = PALETTE["grey"])
fig_close("Figure 1.2: Required sample size falls quickly as the margin of error is relaxed")

n <- N_SAMPLE

# -----------------------------------------------------------------------------
header("Part D: SRSWOR and SRSWR estimates")
# -----------------------------------------------------------------------------
set.seed(SEED)
wor <- est_srswor(frame, n, pp)
set.seed(SEED + 1)
wr <- est_srswr(frame, n, pp)
res <- rbind(wor, wr)
save_results(res, "srs_estimates", "Table 1.8: SRSWOR and SRSWR estimates with 95% confidence intervals")
report_text(
  "*Estimate, SE and CI come from the sample. True value and exact SE come from the census, ",
  "so we can see how close each sample got.*"
)

fpc <- data.frame(
  Quantity = c(
    "Sample size n", "Population size N", "Sampling fraction f = n / N",
    "Finite population correction (1 - f)"
  ),
  Value = c(n, N, n / N, 1 - n / N)
)
save_table(fpc, "fpc", "Table 1.9: Finite population correction", digits = 6)
save_sample(frame[attr(wor, "idx"), ], "srswor_sample")
save_sample(frame[attr(wr, "idx"), ], "srswr_sample")
report_text(
  "**Why are the two SEs for the mean so different?** The SRSWOR sample happened to include a large ",
  "establishment, which inflates s^2; the SRSWR sample did not. The exact SEs (last column) are almost ",
  "identical. With such skewed data, one sample's SE can be badly misleading."
)

fig_open("srs_confidence_intervals", width = 2000)
par(mfrow = c(1, 2))
for (param in c("Mean", "Proportion")) {
  r <- res[res$parameter == param, ]
  plot(1:2, r$estimate,
    xlim = c(0.5, 2.5), ylim = range(r$ci_low, r$ci_high, r$truth), pch = 19, cex = 1.4,
    col = PALETTE["blue"], xaxt = "n", xlab = "", ylab = param, main = paste("95% CI for the", tolower(param))
  )
  arrows(1:2, r$ci_low, 1:2, r$ci_high, angle = 90, code = 3, length = 0.08, lwd = 2, col = PALETTE["blue"])
  abline(h = r$truth[1], lty = 2, col = PALETTE["red"], lwd = 1.5)
  axis(1, at = 1:2, labels = r$design)
  legend("topright", "true value", lty = 2, col = PALETTE["red"], bty = "n", cex = 0.8)
}
fig_close("Figure 1.3: Both 95% CIs contain the true value; the CIs for the mean differ hugely in width")

# -----------------------------------------------------------------------------
header("Part E: SRSWOR compared with SRSWR")
# -----------------------------------------------------------------------------
# V_WR(ybar) / V_WOR(ybar) = (N - 1) / (N - n): WOR is never worse, but the gain is tiny when f is tiny.
cmp <- data.frame(
  Parameter = c("Mean", "Proportion"),
  `Exact variance, SRSWOR` = c(vtrue_srswor(pp, n), vtrue_srswor_p(pp, n)),
  `Exact variance, SRSWR` = c(vtrue_srswr(pp, n), vtrue_srswr_p(pp, n)),
  check.names = FALSE
)
cmp$`Ratio WR / WOR` <- cmp[[3]] / cmp[[2]]
cmp$`Theory (N - 1) / (N - n)` <- (N - 1) / (N - n)
save_table(cmp, "wor_vs_wr", "Table 1.10: Exact variances of SRSWOR and SRSWR", digits = 7)

# Probability that a specified establishment is in the sample (syllabus, Unit 1):
#   SRSWOR: n / N        SRSWR: 1 - (1 - 1/N)^n   (selected at least once)
# Expected number of distinct units in an SRSWR sample: N [1 - (1 - 1/N)^n]
prob <- data.frame(
  Quantity = c(
    "P(a specified establishment is selected), SRSWOR = n / N",
    "P(a specified establishment is selected at least once), SRSWR = 1 - (1 - 1/N)^n",
    "P(a specified establishment is selected at a given draw) = 1 / N (both schemes)",
    "Expected distinct establishments in SRSWR = N [1 - (1 - 1/N)^n]",
    "Distinct establishments in our SRSWR sample"
  ),
  Value = c(n / N, 1 - (1 - 1 / N)^n, 1 / N, N * (1 - (1 - 1 / N)^n), length(unique(attr(wr, "idx"))))
)
save_table(prob, "selection_probabilities", "Table 1.11: Probability of selecting a specified establishment",
  digits = 6
)
report_text(
  "SRSWR's variance is larger by the factor (N - 1)/(N - n) = ", round((N - 1) / (N - n), 6),
  ", only ", round(100 * ((N - 1) / (N - n) - 1), 3), "% more. Because n is a tiny fraction of N, ",
  "selecting the same establishment twice is very unlikely, so the two schemes are practically equivalent. ",
  "SRSWOR is still preferred, since it is never less precise."
)

save_shared(res, "srs")
report_close()
