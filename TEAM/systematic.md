# Aditya Mehta (2440204) — Systematic sampling (and presenting the charts)

**Read your results in:** [output/03_systematic/03_systematic.pdf](../output/03_systematic/03_systematic.pdf)
**Your code:** [analysis/03_systematic.R](../analysis/03_systematic.R) and the Unit 3 section of [analysis/designs.R](../analysis/designs.R)
**Charts duty:** you present the comparison charts in [output/05_comparison](../output/05_comparison/05_comparison.pdf) (Figures 5.1-5.4) as well as your own.

---

## 1. What the assignment asks of you, and where it is answered

| Assignment requirement | Where |
|---|---|
| Units in a listed order so that k = N/n can be applied | Table 3.1 |
| Estimate, variance, SE, 95% CI, fpc for mean, total, proportion | Table 3.2 |
| Effect of different starting points | Table 3.3, Figures 3.1, 3.2 |
| Effect of different values of k | Table 3.8, Figure 3.3 |
| Comparison with SRS and stratified sampling | Table 3.4 |
| ANOVA with the k possible samples as groups; compare within-sample variance with population variance | Tables 3.5-3.7 |
| Charts and visuals (your shared duty) | Figures 3.1-3.3, and Figures 5.1-5.4 |

## 2. What you did, step by step

1. **The list:** all establishments in order of location code (district, tehsil, town/village, ward, enumeration block).
2. **The interval:** k = N / n = 2,880,548 / 748 = **3,851** exactly.
3. **The random start:** r = **975**, a random number between 1 and 3,851.
4. **The sample:** units 975, 4,826, 8,677, ..., one every 3,851 places down the list, 748 in total.
5. **All possible samples:** there are only k = 3,851 possible systematic samples (one for each start). We calculated every one of them, which gives the *exact* variance and shows how much the start matters.
6. **ANOVA, comparison, effect of k, effect of list order.**

## 3. The formulas (each symbol explained)

k = sampling interval, r = random start, ybar_sy = mean of the systematic sample, ybar_r = mean of the sample with start r.

| Quantity | Formula |
|---|---|
| Interval | k = N / n (here exactly 3,851) |
| Units selected | r, r + k, r + 2k, ..., r + (n - 1)k |
| Mean / total | ybar_sy = (sum of the n values) / n; total = N x ybar_sy |
| Exact variance | V(ybar_sy) = (1/k) sum over all r of (ybar_r - Ybar)² |
| Estimated variance (one sample) | v = (1 - f) s² / n (treats the sample as SRS; an approximation) |
| ANOVA link | V(ybar_sy) = ((N - 1)/N) S² - (k(n - 1)/N) S²_wsy |
| Within-sample correlation | V(ybar_sy) = (S²/n) ((N - 1)/N) [1 + (n - 1) rho_w] |

S²_wsy = variance *within* the systematic samples (the ANOVA's MSW).

**The key rule (Cochran):** systematic sampling is more precise than SRS when **S²_wsy > S²**, that is, when units inside one systematic sample are *more* different from each other than random units are. This happens when the list is ordered so that each sample walks through all kinds of units.

**fpc:** f = 748/2,880,548, so (1 - f) = 0.9997.

## 4. Your results

| What | Mean workers | Proportion female-owned |
|---|---|---|
| Our sample (start 975): estimate (SE) | 2.397 (0.248) | 0.1912 (0.0144) |
| True value | 2.481 | 0.1895 |
| Exact SE (from all 3,851 samples) | 0.977 | 0.0135 |
| Range of the 3,851 sample means | 1.87 to 21.04 | 0.144 to 0.239 |
| % of starts whose CI contains the truth | 61% | 96% |
| **RE vs SRSWOR** | **1.009** | **1.121** |
| ANOVA F (p) | 0.991 (0.65) | 0.892 (1.00) |
| rho_w | about 0 | slightly negative |
| RE on a shuffled list / list sorted by activity | 1.001 / 0.958 | 1.009 / 1.283 |

## 5. The key explanations (learn these)

**(a) Why is systematic better than SRS for the proportion (RE 1.12)?**
The list is ordered by location. Taking every 3,851st unit spreads the sample evenly over all 30 districts, their towns and villages. That works like a very fine stratification by location ("implicit stratification"), much finer than Rithesh K R's 4 divisions. Female ownership differs by place, so this helps.

**(b) Why is it no better for the mean (RE 1.01)?**
The big problem for the mean is a few giant establishments. They are scattered all over the list, so walking through the list neither helps nor hurts.

**(c) Does the starting point matter?**
Not systematically. Figure 3.2 shows no trend or wave across the 3,851 starts, and the ANOVA does not reject H0 (p = 0.65 and 1.00). The estimate does vary by start (that is sampling error), but no start is consistently better.

**(d) Why do only 61% of CIs for the mean contain the truth?**
The SE formula uses the sample's own variance. Most samples miss the rare giants, so their SE is too small, and their CI too narrow, to reach the true mean.

**(e) Why does the order of the list matter (Table 3.9)?**
On a randomly shuffled list, systematic sampling is just SRS (RE 1.00). Sorting by activity type helps the proportion most (RE 1.28), because female ownership differs most between activities. So the order of the list is part of the design.

## 6. What to say in the presentation (about 1.5 minutes)

> "With N = 2,880,548 and n = 748, the interval is exactly k = 3,851. Our random start was 975. Because there are only 3,851 possible samples, I calculated all of them. Figure 3.1 shows they average exactly to the true value, so the estimator is unbiased. Figure 3.2 shows no trend or periodic pattern, and the ANOVA confirms the start does not matter (p = 0.65). Systematic sampling is 12% more efficient than SRS for the proportion, because walking down a location-ordered list spreads the sample over every district. On a shuffled list that advantage disappears."

Show **Table 3.4** and **Figure 3.1**. Also present **Figures 5.1 and 5.2** for the group.

## 7. Viva questions and answers

**Q: How did you get k?**
A: k = N/n = 2,880,548 / 748 = 3,851. We chose n = 748 so that this is a whole number, as the syllabus formula N = nk requires.

**Q: How was the start chosen?**
A: A random integer between 1 and k. We used R with seed 2026 and got r = 975.

**Q: Is the systematic sample mean unbiased?**
A: Yes, when N = nk. Every unit belongs to exactly one of the k possible samples and each start has probability 1/k. We checked: the average of all 3,851 sample means equals the true mean exactly (Table 3.3).

**Q: Why can't you estimate the variance properly from one systematic sample?**
A: A systematic sample is really one cluster of units chosen with a single random number, so there is only one "random draw". We used the SRS formula as an approximation and checked it against the exact variance from all 3,851 samples.

**Q: State the hypotheses of your ANOVA.**
A: H0: all k = 3,851 possible samples have the same mean (the start doesn't matter). H1: they differ. At the 5% level, F = 0.99 and p = 0.65, so we do not reject H0.

**Q: What does comparing S²_wsy with S² tell you?**
A: If the variance within systematic samples is larger than the population variance, systematic beats SRS. For the proportion, S²_wsy is slightly larger, so systematic wins. For the mean they are equal, so it is about the same as SRS.

**Q: What is periodicity and why is it dangerous?**
A: If the list repeats a pattern with period equal to k (e.g. every k-th unit is a corner shop), every sample would contain the same type of unit, and the estimate could be badly biased. Figure 3.2 shows no such pattern in our list.

**Q: How does k affect precision?**
A: Smaller k means a bigger sample and a smaller SE. Against SRS of the same size, systematic is better for the proportion at every k we tried (RE 1.12 to 1.24), but not in a steady pattern (Table 3.8).

**Q: Compare systematic with stratified sampling.**
A: For the proportion, systematic (RE 1.12) beats stratified by division (1.03), because it stratifies implicitly by every district and town. For the mean, Neyman stratified (1.17) is better.

**Q: Is the ANOVA's normality assumption met?**
A: Not for the number of workers, which is very skewed, so its F-test is only approximate. The comparison of S²_wsy with S² does not need normality.

## 8. Limitations to mention

- The variance from one systematic sample is only an approximation.
- If the list had been ordered differently, results would change (Table 3.9).
- The advantage depends on the list being ordered by something related to the variable.
