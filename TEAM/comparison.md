# Akash Kumar (2440206) — Comparison of designs, F-tests, simulation, official statistics, report compilation

**Read your results in:** [output/05_comparison/05_comparison.pdf](../output/05_comparison/05_comparison.pdf)
**Your code:** [analysis/05_comparison.R](../analysis/05_comparison.R)
**Report sections you write:** Official statistics link (about 2 pages, draft in Section 8), Conclusion, and compiling the report (Section 9)

---

## 1. What the assignment asks of you, and where it is answered

| Assignment requirement | Where |
|---|---|
| One table: every design's estimate, SE, CI, RE vs SRS, absolute error | Table 5.1 |
| At least one chart | Figures 5.1-5.4 |
| F-test comparing two designs' variances: H0, H1, 5% level, F, p, decision in words | Tables 5.2, 5.4 |
| State and comment on the normality assumption | Table 5.3 and the notes under 5.4 |
| Recommend one design (precision, cost, convenience) | Table 5.5 |
| Optional: repeat 200-500 times, histogram per method | Table 5.3, Figures 5.3-5.4 (500 repeats) |
| Official statistics link (about 2 pages) | Section 8 below |
| Report compilation | Section 9 below |

## 2. What you did, step by step

1. **Collected** the one sample from every design (the other four parts) into one master table.
2. **Compared precision** using the exact variances: RE = V(SRSWOR) / V(design).
3. **F-tests:** compared SRS with stratified (Neyman), systematic and cluster, first using the single samples, then using 500 repeated samples.
4. **Simulation:** repeated every design 500 times to see the bias, the real spread of the estimates, and how often the 95% CIs contain the truth.
5. **Recommended** a design.

## 3. The formulas

| Quantity | Formula |
|---|---|
| Relative efficiency | RE = V(SRSWOR) / V(design). Above 1 = better than SRS |
| Absolute error | abs(estimate - true value) |
| F statistic | F = larger variance / smaller variance |
| Degrees of freedom (single samples) | SRS n - 1 = 747; stratified n - L = 744; systematic 747; cluster n_c - 1 = 26 |
| Degrees of freedom (simulation) | R - 1 = 499 for each design |
| p-value | P(F > observed F), one-sided |
| CI coverage | % of the 500 CIs that contain the true value (should be about 95%) |

**Hypotheses for every F-test:**
- H0: the two designs give estimates with equal variance (equally precise).
- H1: the design with the larger variance really is less precise.
- Level of significance 5%: reject H0 if p < 0.05.
- Assumption: the estimates are roughly normally distributed.

## 4. Your results

**Precision (Table 5.1):**

| Design | RE, mean | RE, proportion |
|---|---|---|
| SRSWOR | 1.000 | 1.000 |
| SRSWR | 1.000 | 1.000 |
| Stratified (proportional) | 1.000 | 1.027 |
| Stratified (Neyman) | **1.167** | 0.799 |
| Systematic | 1.009 | **1.121** |
| Cluster | 0.337 | 0.042 |

**Simulation (Table 5.3):** for the proportion, every design is unbiased, the simulated SE matches the exact SE within 5%, and about 95% of CIs contain the truth (cluster: 80%). For the mean, the simulated SE ranges from 0.4 to 1.3 times the exact SE, and only about 60% of CIs contain the truth.

**F-tests from the simulation (Table 5.4):** every test for the proportion agrees with the exact variances. One test for the mean (SRS vs cluster) points the **wrong way**, because the mean's estimates are far from normal.

## 5. The key explanations (learn these)

**(a) Which design is best?**
For the **proportion: systematic** (RE 1.12). For the **mean: Neyman stratified** (RE 1.17). **Cluster** is worst for both.

**(b) Why do no designs help much for the mean?**
Workers per establishment is extremely skewed: a few businesses with thousands of workers dominate the variance, and they appear in every stratum, every part of the list and every kind of area.

**(c) Why are the single-sample F-tests unreliable for the mean?**
Each single-sample variance is itself very noisy: it depends on whether that one sample caught a giant establishment. For example, the single samples say SRS is 193 times more variable than cluster sampling, yet the exact variances say cluster sampling is 3 times *worse*.

**(d) Why does the simulation's F-test for the mean also go wrong once?**
The F-test assumes normal data. The mean's estimates are strongly right-skewed (skewness 4 to 17), and 500 repeats are too few: each sample includes a given giant establishment with probability only 1 in 3,851. For the proportion the estimates are near-normal, so the F-tests work perfectly. **This is a real result: it shows why the normality assumption matters.**

**(e) Why recommend systematic sampling?**
- Precision: best for the proportion (RE 1.12) and as good as SRS for the mean (1.01).
- Cost: one random number, then every 3,851st establishment on the list.
- Convenience: easy for field staff, and the sample is automatically spread over every district.
- If the mean were the main target, Neyman stratified would be better. Cluster sampling is cheapest in the field but far too imprecise here.

## 6. What to say in the presentation (about 1.5 minutes)

> "Table 5.1 compares all six designs on the same population with about 748 establishments each. For the proportion, systematic sampling is most efficient, 12% better than SRS; for the mean, Neyman stratification is best, 17% better. Cluster sampling is far worse, with an RE of only 0.04 for the proportion, because businesses in the same block are alike. Our 500-repeat simulation confirms the variance formulas for the proportion, and every F-test agrees. For the mean the estimates are so skewed that the F-test's normality assumption fails, and one test even points the wrong way. We recommend systematic sampling from the location-ordered census list: precise, cheap and simple."

Show **Table 5.1** and **Figure 5.2** (Aditya Mehta presents Figures 5.1-5.4 with you).

## 7. Viva questions and answers

**Q: What is relative efficiency?**
A: The variance of SRS divided by the variance of the design. RE = 1.12 means SRS would need 12% more units to be as precise.

**Q: Why use exact variances and not the sample variances for RE?**
A: Because we have the full census, we can calculate each design's true variance. The variance from one sample is noisy, especially for skewed data.

**Q: State H0 and H1 for your F-test.**
A: H0: the two designs are equally precise (equal variances). H1: the one with the larger variance is less precise. We reject H0 at the 5% level if p < 0.05.

**Q: Interpret the test SRSWOR vs Systematic for the proportion.**
A: With 500 repeats, F = 1.21 with (499, 499) df and p = 0.017 < 0.05, so we reject H0: SRS is significantly less precise than systematic sampling.

**Q: What does ANOVA tell you that the F-test does not?**
A: ANOVA splits the total variation into between-group and within-group parts and tests whether group *means* differ. The F-test for two designs compares two *variances* directly.

**Q: Why did you run a simulation?**
A: One sample per design can be lucky or unlucky. Repeating 500 times shows each design's real behaviour: bias, spread, and how often the CI works.

**Q: What did the simulation show about the CIs?**
A: For the proportion, about 95% of CIs contain the truth, as they should. For the mean only about 60% do, because most samples miss the rare very large establishments and underestimate both the mean and its SE.

**Q: Why is cluster coverage for P only 80%?**
A: There are only 27 clusters per sample and the cluster totals are skewed, so the normal and t approximations work poorly.

**Q: Which design would you recommend, and why?**
A: Systematic sampling from the census list ordered by location: most precise for the proportion, as good as SRS for the mean, and the cheapest to run on a list.

**Q: What would you recommend if the mean number of workers mattered most?**
A: Neyman-allocated stratified sampling (RE 1.17). Even better would be strata based on business size, which official surveys use for exactly this reason.

## 8. Draft for the report: Link to India's official statistical system (about 2 pages)

> The facts below come from MoSPI's documentation on the census DVD (overview, data collection and sampling pages, Instruction Manual, All-India Report).

**8.1 The survey and the agency.** Our data is the **Sixth Economic Census (EC6), 2012-13**, conducted by the **Central Statistics Office (CSO), Ministry of Statistics and Programme Implementation (MoSPI)**, through its Economic Statistics Division, together with the Directorates of Economics and Statistics of the State and Union Territory governments. (In 2019 the CSO and the National Sample Survey Office were merged into the National Statistical Office, NSO, under MoSPI.) The Economic Census is a complete count of all establishments, meaning units engaged in producing or distributing goods and services not only for their own consumption, within the country's boundaries.

**8.2 History and purpose.** The CSO began Economic Censuses in 1976 under the scheme "Economic Census and Surveys". Censuses were held in 1977, 1980, 1990, 1998, 2005 and 2013. Their main purpose is to provide a **frame**, a list of establishments, for detailed follow-up sample surveys of the unorganised non-agricultural sector, such as the NSS rounds on enterprises. Before the Economic Census, establishment data came from partial and irregular surveys, which caused under-coverage and unreliable estimates.

**8.3 Design: a census, not a sample.** EC6 enumerated every establishment. Enumerators visited **every house and structure** in each **Enumeration Block (EB) of Population Census 2011**, the same EBs we use as clusters. About **1.17 million enumerators and supervisors** covered about **2.45 million EBs**. The documentation states that no sampling procedure was applied. Fieldwork ran from **January 2013 to April 2014**.

**8.4 Data collection.** Face-to-face interviews with the Schedule 6A questionnaire recorded location, activity (NIC-2008 code), type of ownership, owner's sex and social group, source of finance, and the number of workers (male/female, hired/not hired). Handicraft and handloom establishments were identified for the first time in EC6.

**8.5 Coverage and key results.** EC6 found **58.5 million establishments** in India: 59.5% rural and 40.5% urban. 71.7% were own-account establishments with no hired worker. Among proprietary establishments nationally, **15.4% were female-owned**. In Karnataka (our population): 2,880,548 establishments; **21.3%** of proprietary establishments are female-owned (18.9% of all establishments), higher than the national figure.

**8.6 Reliability.** Strengths: a complete count, with no sampling error in the census itself; a uniform schedule and manual across states; and it reuses the Population Census 2011 EB maps, which reduces gaps and overlaps. Our checks confirm the published microdata is internally consistent (total workers always equals the sum of its parts) and matches MoSPI's published summaries exactly.

**8.7 Limitations.**
- **Excluded activities:** crop production, plantation, public administration, defence and compulsory social security.
- **Under-coverage of informal units:** businesses without a fixed structure, home-based work and seasonal units are easy to miss.
- **Recording errors:** e.g. the single-owner establishments reporting exactly 10,001 workers (see K Suraj Das's report, Table 1.3).
- **Self-reported information** on workers, with no verification against records.
- **Timeliness:** the frame ages quickly, because small businesses open and close often, so it needs regular updating.

**8.8 How it links to our project.** Official surveys use the Economic Census exactly as we did: as a frame for sampling. NSS enterprise surveys, such as the 73rd round (2015-16) on unincorporated non-agricultural enterprises, use stratified multi-stage designs with villages and urban blocks as first-stage units. Our results show why: stratification and ordering the list by location improve precision, while sampling whole areas (clusters) is cheap but loses precision when units in an area are alike.

## 9. Compiling the report (from the assignment)

- **Length:** 15-20 pages. **First page:** title, member names and register numbers, and each member's role (use the table in [TEAM/README.md](README.md)).
- **Sections, in this order:** Introduction, Population and Frame, Method-wise Analysis (Units 1-4), Comparison and Interpretation, Errors, Official Statistics Link, Conclusion, References.
- **Page budget (suggested):** Introduction + frame 2; each unit 2.5 (10 total); comparison 2.5; errors 1; official statistics 2; conclusion + references 1.
- **Tables and figures:** take them from each member's PDF (`output/NN_name/NN_name.pdf`) or the PNG files in `figures/`. Keep the table numbers.
- **References** (at least 3, at least 2 official):
  1. MoSPI, Central Statistics Office. *All India Report of Sixth Economic Census* [check the year on the cover; the file is dated 2016]. Government of India. (On the DVD: `data/REPORTS/EC6_ALL_INDIA_REPORT_PUBLISHED_BY_ESD_CSO.pdf`)
  2. MoSPI. *Instruction Manual, Sixth Economic Census 2012-2013* [check the year on the cover]. (On the DVD: `data/DOCUMENTS/`)
  3. MoSPI. *Sixth Economic Census 2012-13 microdata*, National Data Archive, https://microdata.gov.in/NADA/index.php/catalog/47
  4. Cochran, W. G. (2008). *Sampling Techniques*, 3rd ed. Wiley.
  5. Gupta, S. C. and Kapoor, V. K. (2018). *Fundamentals of Applied Statistics*, 4th ed. Sultan Chand.
- **Annexure:** the dataset (`data/frame_karnataka.rds`, or a description and the link above, since 2.9 million rows cannot be printed), the selected samples (each `output/*/samples/` folder), and the R code (`analysis/`).
