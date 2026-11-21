# Rithesh K R (2440233) — Stratified random sampling

**Read your results in:** [output/02_stratified/02_stratified.pdf](../output/02_stratified/02_stratified.pdf)
**Your code:** [analysis/02_stratified.R](../analysis/02_stratified.R) and the Unit 2 section of [analysis/designs.R](../analysis/designs.R)

---

## 1. What the assignment asks of you, and where it is answered

| Assignment requirement | Where |
|---|---|
| At least 3 strata whose averages differ | Table 2.1, Figures 2.1 and 2.3 |
| Proportional and Neyman allocation | Table 2.2, Figure 2.2 |
| Estimate, variance, SE, 95% CI, fpc for mean, total, proportion | Tables 2.3-2.5 |
| Variance of each allocation and gain in precision over SRS | Tables 2.6, 2.7 |
| ANOVA with strata as groups: between and within SS, F, p, H0/H1, decision | Tables 2.8, 2.9 |
| State and comment on the normality assumption | Table 2.10 |
| Allocation comparison (your shared duty) | Tables 2.2, 2.6, 2.11 |

## 2. What you did, step by step

1. **Strata:** Karnataka's 4 revenue divisions (Bengaluru, Mysuru, Belagavi, Kalaburagi). Every district belongs to exactly one division, so each establishment's stratum is known *before* sampling. That is a requirement for stratification.
2. **Allocation:** we shared n = 748 among the strata in two ways, proportional and Neyman.
3. **Sampling:** inside each stratum we took an SRSWOR of n_h units, independently.
4. **Estimation:** we combined the stratum results with the weights W_h.
5. **Evaluation:** we compared the exact variances with SRS and explained the gain using Cochran's formula.
6. **ANOVA:** we tested whether the stratum means differ.
7. **Extra:** we checked whether a different basis (activity type) would stratify better.

## 3. The formulas (each symbol explained)

h = stratum number; N_h = units in stratum h; W_h = N_h / N = stratum weight; n_h = sample size in stratum h; ybar_h, s²_h, p_h = sample mean, variance and proportion inside stratum h; S_h = population SD of stratum h.

| Quantity | Formula |
|---|---|
| Proportional allocation | n_h = n x N_h / N |
| Neyman (optimum) allocation | n_h = n x N_h S_h / sum(N_h S_h) |
| Stratified mean | ybar_st = sum W_h ybar_h |
| Estimated variance | v(ybar_st) = sum W_h² (1 - f_h) s²_h / n_h, with f_h = n_h / N_h |
| Stratified total | N x ybar_st, variance N² x v(ybar_st) |
| Stratified proportion | p_st = sum W_h p_h, v(p_st) = sum W_h² (1 - f_h) p_h q_h / (n_h - 1) |
| Gain in precision | (V_SRS - V_st) / V_st x 100% |

**Worked example (proportional allocation, Belagavi):** n_h = 748 x 522,129 / 2,880,548 = 135.6, rounded to 136.
**Worked example (Neyman, Bengaluru):** N_h S_h = 1,105,955 x 34.70 = 38.4 million out of a total of 71.6 million, so n_h = 748 x 38.4/71.6 = 401.

**fpc:** every f_h is below 0.0004, so (1 - f_h) is practically 1.

## 4. Your results

| What | Proportional | Neyman |
|---|---|---|
| Allocation (Belagavi, Bengaluru, Kalaburagi, Mysuru) | 136, 287, 84, 241 | 61, 401, 120, 166 |
| Mean estimate (SE) | 2.159 (0.115) | 2.421 (0.399) |
| P estimate (SE) | 0.1979 (0.0144) | 0.1878 (0.0162) |
| **RE for the mean** | 1.000 | **1.167** (about 17% gain) |
| **RE for P** | 1.027 | 0.799 (worse than SRS) |

True values: mean 2.481, P 0.1895.

**ANOVA (Table 2.9, on the sample):** F = 0.38, p = 0.77, so do not reject H0. **Kruskal-Wallis:** p = 0.0004, so the strata do differ.

## 5. The three key explanations (learn these)

**(a) Why does proportional allocation gain almost nothing for the mean?**
Stratification helps only if the stratum means differ a lot *compared with* the spread inside each stratum. Here the means are 2.1 to 3.0, but inside every stratum some businesses have 1 worker and some have thousands. The strata explain only **0.02%** of the total variation (Table 2.7). So proportional allocation behaves like SRS.

**(b) Why is Neyman better (RE 1.17)?**
Neyman allocation uses the stratum SDs. The SDs differ a lot: Belagavi 11, Bengaluru 35, Kalaburagi 35. So Neyman puts more units where the data is most variable (Bengaluru gets 401 instead of 287). Cochran's formula V_prop - V_Neyman = (1/n) sum W_h (S_h - Sbar)² says exactly this: the gain comes from differences between the stratum SDs.

**(c) Why is Neyman *worse* for the proportion (RE 0.80)?**
Neyman was optimised for the *mean*. It took units away from Mysuru, where female ownership (28%) varies the most. An allocation optimised for P would give RE 1.04. One allocation cannot be best for every variable.

## 6. What to say in the presentation (about 1.5 minutes)

> "I stratified by Karnataka's four revenue divisions. Figure 2.1 shows why the gain is limited: inside every division, most businesses have one or two workers but a few have thousands. Proportional allocation gave almost no gain for the mean. Neyman allocation, which gives more units to the most variable divisions, was 17% more efficient than SRS. Neyman made the proportion worse, because it was optimised for the mean. ANOVA on the sample did not find different means (p = 0.77), because a few huge values hide the differences; the Kruskal-Wallis test, which doesn't need normality, did find a difference (p = 0.0004)."

Show **Table 2.6** and **Figure 2.2**.

## 7. Viva questions and answers

**Q: Why did you choose revenue divisions as strata?**
A: They are official, every establishment's division is known before sampling, they give 4 large strata, and their means, SDs and proportions differ.

**Q: What is the difference between proportional and Neyman allocation?**
A: Proportional shares n by stratum size only. Neyman shares it by size times SD, so large *and* variable strata get more units. Neyman gives the smallest variance for a fixed n.

**Q: Why is RE for proportional allocation 0.9997, below 1? Isn't stratification always at least as good?**
A: With exact proportional allocation the gain is tiny but positive (RE 1.0002, Table 2.7). We had to round n_h to whole numbers, and that small rounding effect is bigger than the tiny gain.

**Q: What does an RE of 1.167 mean?**
A: SRS would need about 16.7% more units, about 873 instead of 748, to be as precise as Neyman stratified sampling.

**Q: State the hypotheses of your ANOVA.**
A: H0: all four stratum means are equal. H1: at least one differs. Level of significance 5%.

**Q: The population ANOVA has p < 0.0001 but the sample ANOVA has p = 0.77. Why?**
A: With 2.9 million units, even a tiny difference is statistically significant. With 748 units the differences are too small compared with the huge within-stratum spread to be detected.

**Q: Is the ANOVA assumption of normality satisfied?**
A: No. The skewness is 267 (normal data has 0), and the stratum variances are very unequal. That is why we also ran the Kruskal-Wallis test, which uses ranks and does not need normality; it found a significant difference (p = 0.0004).

**Q: Why does the Neyman sample have a larger SE than the proportional sample, if Neyman is better?**
A: The SE in Table 2.3 comes from one sample. The Neyman sample's Bengaluru stratum caught a very large establishment (variance 421). The exact SE, which describes the design, is smaller for Neyman: 0.908 vs 0.981.

**Q: What information does Neyman allocation need that proportional does not?**
A: The stratum SDs S_h. In practice they come from a previous census or a pilot survey; we used the census values.

**Q: Would another stratification basis be better?**
A: For the proportion, yes: activity type gives RE 1.13, because female ownership ranges from 5% in construction to 42% in manufacturing. For the mean, divisions are slightly better (Table 2.11).

**Q: When does stratification give the largest gain?**
A: When units inside a stratum are similar and the strata are very different from each other: small within-stratum variance and large between-stratum variance.

## 8. Limitations to mention

- The extreme skewness limits every design; no natural stratification separates the few giant establishments.
- The S_h used for Neyman came from the census; a real survey would have to estimate them in advance.
- Each stratum gets one allocation for both variables, so we cannot be optimal for both the mean and P at once.
