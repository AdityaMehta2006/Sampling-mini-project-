# Member 4: Cluster sampling (and the errors section)

**Read your results in:** [output/04_cluster/04_cluster.pdf](../output/04_cluster/04_cluster.pdf)
**Your code:** [analysis/04_cluster.R](../analysis/04_cluster.R) and the Unit 4 section of [analysis/designs.R](../analysis/designs.R)
**Report section you write:** Sampling and non-sampling errors (draft in Section 8 below)

---

## 1. What the assignment asks of you, and where it is answered

| Assignment requirement | Where |
|---|---|
| Natural clusters, at least 20 in the frame | Table 4.1 (105,624 enumeration blocks), Figure 4.1 |
| Estimate, variance, SE, 95% CI, fpc for mean, total, proportion | Tables 4.2, 4.3 |
| ANOVA with clusters as groups; mean squares give the ICC | Tables 4.4-4.6 |
| Intraclass correlation and relative efficiency against SRS | Table 4.6, Figure 4.2 |
| Comparison with SRS and stratified (syllabus Unit 4) | Table 4.8 |
| Extra: effect of cluster size | Table 4.7, Figure 4.3 |
| Sampling and non-sampling errors (report section) | Section 8 below |

## 2. What you did, step by step

1. **Clusters:** enumeration blocks (EBs), the small areas each census enumerator covers. Karnataka has 105,624 of them, with 27.3 establishments on average.
2. **How many clusters:** to get about 748 establishments, n_c = 748 / 27.27 = 27 blocks.
3. **Selection:** 27 blocks chosen by SRSWOR, then **every** establishment in them is included (736 expected; that is single-stage cluster sampling).
4. **Estimation:** with the ratio estimator (main) and the unbiased estimator (for comparison).
5. **ANOVA:** across all 105,624 blocks, to get the intraclass correlation (ICC).
6. **Design effect and RE**, the **effect of cluster size**, and a **comparison** with the other designs.

## 3. The formulas (each symbol explained)

N_c = number of clusters (105,624); n_c = clusters sampled (27); M_i = establishments in cluster i; y_i = total workers in cluster i; Mbar = N / N_c = 27.27; f = n_c / N_c.

| Quantity | Formula |
|---|---|
| Ratio estimator of the mean (used) | ybar_cl = sum y_i / sum M_i (over the 27 sampled blocks) |
| Its estimated variance | (1 - f) / (n_c Mbar²) x sum (y_i - ybar_cl M_i)² / (n_c - 1) |
| Unbiased estimator of the mean | ybar_u = N_c x sum y_i / (n_c N) |
| Its estimated variance | (1 - f) N_c² s_t² / (n_c N²), s_t² = variance of cluster totals |
| Proportion | same formulas with a_i = female-owned count in cluster i |
| 95% CI | estimate +/- t(26) x SE (only 27 clusters, so t not z) |
| ICC from ANOVA | rho = (MSB - MSW) / (MSB + (m0 - 1) MSW) |
| Design effect (equal clusters) | deff = 1 + (Mbar - 1) rho |
| Relative efficiency | RE = 1 / deff = V(SRS) / V(cluster) |

MSB = mean square between clusters; MSW = mean square within; m0 = adjusted average cluster size (here 27.27).

**fpc:** 1 - 27 / 105,624 = 0.9997.

**Worked example (ICC for female ownership):** MSB = 1.335, MSW = 0.1086, m0 = 27.27.
rho = (1.335 - 0.1086) / (1.335 + 26.27 x 0.1086) = 1.226 / 4.188 = **0.293**.
deff by formula = 1 + 26.27 x 0.293 = 8.7.

## 4. Your results

| What | Mean workers | Proportion female-owned |
|---|---|---|
| Ratio estimate (SE) | 1.779 (0.135) | 0.2006 (0.0384) |
| True value | 2.481 | 0.1895 |
| Exact SE | 1.691 | 0.0703 |
| ANOVA F (p) | 2.11 (< 0.0001) | 12.29 (< 0.0001) |
| **ICC rho** | **0.039** | **0.293** |
| deff by formula / actual | 2.0 / 2.9 | 8.7 / 23.7 |
| **RE vs SRS** | **0.34** | **0.04** |

Larger clusters (Table 4.7): design effect for P is 24 for blocks, 119 for wards and 2,892 for whole towns or villages.

## 5. The key explanations (learn these)

**(a) What does ICC = 0.29 mean?**
Establishments in the same block are similar: if one is female-owned, its neighbours are more likely to be too. Women-run businesses are concentrated in particular localities, probably because certain trades and markets are run mostly by women (the data shows the clustering, not the reason). So a whole block of 27 establishments tells us about as much as roughly **one** independently chosen establishment (27.3 / 23.7 = 1.15).

**(b) Why is cluster sampling so inefficient here?**
Because it takes many similar units from few places. Only 27 independent "draws" are made, against 748 for SRS. RE = 0.04 for P means SRS would need only 4% as many establishments for the same precision.

**(c) Why did the formula deff (8.7) differ from the actual (23.7)?**
The formula 1 + (M - 1) rho assumes all clusters are the same size. Our blocks range from 1 to 1,854 establishments, and big blocks count more, which increases the variance further.

**(d) Why use the ratio estimator, not the unbiased one?**
The unbiased estimator uses cluster *totals*, which vary hugely because block sizes vary. The ratio estimator divides by the actual number of establishments sampled, removing most of that size variation (deff 2.9 vs 3.4 for the mean, 23.7 vs 32.8 for P).

**(e) Then why would anyone use cluster sampling?**
Cost. Visiting 27 compact blocks is far cheaper than travelling to 748 scattered addresses, and you only need a list of blocks, not a list of every establishment. The Economic Census itself is organised by enumeration blocks for exactly this reason.

## 6. What to say in the presentation (about 1.5 minutes)

> "My clusters are census enumeration blocks: 105,624 of them, about 27 establishments each. I sampled 27 blocks and took every establishment in them. The ANOVA across all blocks gives an intraclass correlation of 0.29 for female ownership: businesses in the same block are alike, as Figure 4.2 shows. As a result the design effect is about 24, so cluster sampling is only 4% as efficient as SRS for the proportion, and 34% for the mean. Figure 4.3 shows that bigger clusters, like wards or whole towns, are far worse. Cluster sampling is chosen for low cost, not for precision."

Show **Table 4.6** and **Figure 4.2**.

## 7. Viva questions and answers

**Q: What is single-stage cluster sampling?**
A: We select clusters at random and include *every* unit in the selected clusters. (Two-stage would sample units again inside the chosen clusters.)

**Q: Why enumeration blocks and not districts or wards?**
A: Districts and wards are too big: even one ward would exceed our sample size, and a handful of them cannot represent the state. Blocks are small, numerous (105,624), and they are the natural work areas of the census.

**Q: How did you decide on 27 clusters?**
A: n_c = n / Mbar = 748 / 27.27 = 27.4, rounded to 27, giving about 736 establishments, close to the common n = 748.

**Q: State the ANOVA hypotheses.**
A: H0: all clusters have the same mean (no clustering). H1: the cluster means differ. At the 5% level, F = 12.3 for female ownership and 2.1 for workers, both with p < 0.0001, so we reject H0.

**Q: What is the intraclass correlation?**
A: The correlation between two units in the same cluster. 0 means units in a cluster are no more alike than random units; 1 means they are identical. We got 0.29 for female ownership and 0.04 for workers.

**Q: How does ICC affect efficiency?**
A: deff = 1 + (M - 1) rho. Even a small rho is multiplied by the cluster size: with 27 units per block, rho = 0.04 already doubles the variance.

**Q: What is the design effect?**
A: The variance of the design divided by the SRS variance for the same sample size. Above 1 means less precise than SRS.

**Q: Why use t with 26 degrees of freedom?**
A: The information comes from only 27 clusters, not 736 establishments, so df = n_c - 1 = 26.

**Q: Your mean CI [1.50, 2.06] missed the truth (2.48). Why?**
A: The 27 blocks happened to contain no very large employer, so the estimate is low and its SE (0.135) underestimates the exact SE (1.69). That happens often with skewed data and few clusters.

**Q: Compare cluster with stratified sampling.**
A: They are opposites. Stratified sampling gains when groups differ (it samples *every* group); cluster sampling loses when groups differ (it samples only *some* groups). Both use the same between-group and within-group ANOVA split.

**Q: Is the ANOVA's normality assumption met?**
A: No for workers (very skewed), but with 2.9 million units the F-test is robust. The ICC itself is a descriptive measure from the mean squares and does not need normality.

## 8. Draft for the report: Sampling and non-sampling errors

**Sampling errors.** These arise because we observe a sample, not the whole population. We measured them with standard errors and confidence intervals for every design. In this project they are unusually large for the mean number of workers, because the distribution is extremely skewed (median 1, maximum 14,160, coefficient of variation 10.8). A sample's result depends heavily on whether it happens to include one of the rare very large establishments. Member 5's simulation shows only about 60% of the 95% CIs for the mean contain the true value, while about 95% do for the proportion. Sampling error falls as n grows, and better designs (Neyman stratification, systematic sampling on an ordered list) reduce it.

**Non-sampling errors.** These would remain even with a complete census.

1. **Frame and coverage errors.** The Economic Census excludes crop production, plantation, public administration, defence and compulsory social security (MoSPI, EC6 documentation), so those establishments are not in our population. Establishments without a fixed structure (street vendors, mobile and seasonal units) are easily missed during listing. The frame dates from 2013; businesses opened or closed since then make it out of date for a survey today.
2. **Recording (measurement) errors.** Seven single-owner establishments report 10,000 or more workers, six of them exactly 10,001 or 10,002, a pattern typical of a data-entry code (Member 1, Tables 1.3-1.4). They change the SD from 21.5 to 26.8. We kept the official values but flag them as probable errors.
3. **Definition and classification issues.** "Owner's sex" exists only for proprietary establishments: 315,170 government, company, partnership and other establishments (10.9%) have no owner's sex and count as "not female-owned". 13,559 have "others". Activity codes (NIC) depend on the enumerator's judgement and can be misclassified.
4. **Non-response.** The census was collected face to face. Closed premises or refusals would be missing or recorded by proxy. The public dataset does not report non-response rates, so we cannot measure this. In our own project there is no non-response, because we sample from the completed census records.
5. **Processing errors.** We converted MoSPI's Nesstar file ourselves. We ruled out errors here by checking all 67 official summary figures; every one matched (Member 1, Table 0.1).

**Conclusion.** For this project the biggest error sources are the skewness (a sampling issue that inflates variance) and a few probable recording errors (a non-sampling issue that no sampling design can correct).
