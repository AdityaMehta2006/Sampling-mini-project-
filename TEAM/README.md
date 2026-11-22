# Team guide — start here

Each person has one note in this folder. Read this page first, then your own note.

| Name | Register No. | Method (syllabus unit) | Also responsible for | Your note | Your results |
|---|---|---|---|---|---|
| K Suraj Das | 2440224 | SRSWOR and SRSWR (Unit 1) | Data export and checks, sampling frame, sample size | [srs.md](srs.md) | [output/00_data_verification](../output/00_data_verification/README.md), [output/01_srs](../output/01_srs/README.md) |
| Rithesh K R | 2440233 | Stratified sampling (Unit 2) | Allocation comparison, stratified ANOVA | [stratified.md](stratified.md) | [output/02_stratified](../output/02_stratified/README.md) |
| Aditya Mehta | 2440204 | Systematic sampling (Unit 3) | Systematic ANOVA, effect of k, presenting the charts | [systematic.md](systematic.md) | [output/03_systematic](../output/03_systematic/README.md) |
| Abhinaba Das | 2440203 | Cluster sampling (Unit 4) | ICC and efficiency, sampling and non-sampling errors | [cluster.md](cluster.md) | [output/04_cluster](../output/04_cluster/README.md) |
| Akash Kumar | 2440206 | Comparison of designs | F-tests, simulation, official statistics link, report compilation | [comparison.md](comparison.md) | [output/05_comparison](../output/05_comparison/README.md) |

## The group report

**[group_report.pdf](../group_report.pdf)** (project root) is the one report the assignment asks for. It has every member's name, register number and role on page 1, the required sections in order, and each section names who prepared it. `analysis/08_group_report.R` builds it from the verified results and checks it against the rubric; the result is in [reports/rubric_check.md](../reports/rubric_check.md).

## Your individual report

Download your PDF from [reports/](../reports):

| Name | Report |
|---|---|
| K Suraj Das | [K_Suraj_Das_2440224.pdf](../reports/K_Suraj_Das_2440224.pdf) |
| Rithesh K R | [Rithesh_K_R_2440233.pdf](../reports/Rithesh_K_R_2440233.pdf) |
| Aditya Mehta | [Aditya_Mehta_2440204.pdf](../reports/Aditya_Mehta_2440204.pdf) |
| Abhinaba Das | [Abhinaba_Das_2440203.pdf](../reports/Abhinaba_Das_2440203.pdf) |
| Akash Kumar | [Akash_Kumar_2440206.pdf](../reports/Akash_Kumar_2440206.pdf) |

Your name and register number are already printed on page 1 (all five names) and page 2 (your own details and the roles table). Nothing needs to be filled in: download your PDF and submit it.

## The project in five lines

- **Population:** all **2,880,548 establishments in Karnataka**, from the Sixth Economic Census 2012-13 (MoSPI). This is real government data, and we checked it against MoSPI's own published figures: 67 of 67 checks match.
- **Variables:** Y = number of persons employed in an establishment (we estimate the mean and the total); P = proportion of establishments owned by a woman.
- **Sample size:** n = 748 for every method. It comes from a margin of error of 3 percentage points for P, rounded up so that N = n x k exactly (k = 3,851).
- **Strata:** Karnataka's 4 revenue divisions. **Clusters:** enumeration blocks (105,624 of them; we sample 27).
- **Main finding:** the number of workers is extremely skewed (median 1, maximum 14,160), so no design estimates the mean much better than SRS. For the proportion, systematic sampling on the location-ordered list is best. Cluster sampling is cheapest in the field but least precise.

## Words everyone must be able to explain

| Term | Plain meaning |
|---|---|
| Estimate | The value calculated from the sample (e.g. sample mean 2.42). |
| True value | The census value. We know it here only because we have the full census, which lets us check every estimate. |
| SE (standard error) | How much the estimate would change from sample to sample. Small SE = precise. |
| Estimated SE vs exact SE | The **estimated** SE is calculated from one sample. The **exact** SE is calculated from the whole population with the design's variance formula. With skewed data, one sample's SE can be badly off; the exact SE is the reliable one. |
| 95% CI | estimate +/- 1.96 x SE. In 95% of samples, an interval built this way contains the true value. |
| fpc | Finite population correction (1 - n/N). Here n/N = 0.00026, so fpc = 0.9997, practically 1. |
| RE (relative efficiency) | V(SRSWOR) / V(design). Above 1 = the design is more precise than SRS. RE = 1.17 means SRS would need about 17% more units for the same precision. |
| Design effect (deff) | The opposite of RE: V(design) / V(SRS). Used mainly for cluster sampling. |
| ANOVA | Splits the total variation into *between groups* and *within groups*. F = MSB / MSW. |
| F-test for two variances | F = larger variance / smaller variance; tests whether one design is really less precise. |

## How the files are organised

```
analysis/        R code. One script per part, run in numbered order
  common.R       shared settings and helpers (n, seed, tables, figures)
  designs.R      the estimators of every design - one section per design
  run_all.R      runs everything (about 2 minutes)
data/            frame_karnataka.rds - the cleaned sampling frame (all 2.88 million units)
output/          one folder per script; open README.md inside each folder
  NN_name/tables/    every table as CSV (full precision, for Excel or the Annexure)
  NN_name/figures/   charts (PNG) - paste these into the report
  NN_name/samples/   the units each method selected (Annexure)
TEAM/            these notes
```

**To re-run everything:** install R, open a terminal in the project folder, and run `Rscript analysis/run_all.R`. No packages are needed. (Only script 00, K Suraj Das's data export, needs the DVD and the `nesstarR` package; it is skipped automatically if they are missing.)

**Do not edit files in `output/` by hand.** They are rebuilt every time the scripts run. The seed (2026) is fixed, so everyone gets identical numbers.

## Fair split of work

Every part has the same structure: a method, a full estimation (mean, total, proportion with SE, CI and fpc), an ANOVA or test, figures, and one "extra" analysis.

| Name | Tables | Figures | Their "extra" |
|---|---|---|---|
| K Suraj Das | 9 (incl. verification) | 3 | Proving the data is genuine (67 checks against MoSPI) |
| Rithesh K R | 11 | 3 | Which stratification basis is better (division vs activity) |
| Aditya Mehta | 9 | 3 | How the order of the list changes precision |
| Abhinaba Das | 8 | 3 | How cluster size changes efficiency (blocks vs wards vs towns) |
| Akash Kumar | 7 | 4 | 500-repeat simulation and CI coverage |

Abhinaba and Akash also write report sections (errors and the official statistics link); see their notes.

## Report and presentation (marks)

| Component | Marks | Who |
|---|---|---|
| Survey design: population, frame, strata, clusters, sample size | 5 | K Suraj Das (Tables 1.5, 1.7) |
| Own-method estimation: formulas, variance, SE, CI | 10 | Each person, own unit |
| Own-method interpretation: precision, efficiency, ICC or gain | 5 | Each person, own unit |
| Comparison table, ANOVA, F-test, charts, recommended design | 8 | Akash Kumar (tables), ANOVAs from Rithesh K R, Aditya Mehta and Abhinaba Das, charts presented by Aditya Mehta |
| Conclusion, limitations, sampling and non-sampling errors | 4 | Abhinaba Das (errors), Akash Kumar (conclusion) |
| Official statistics link (about 2 pages) | 4 | Akash Kumar |
| Report and presentation | 3 + 7 | Everyone; Akash Kumar compiles |
| Viva | 4 | Everyone, on their own method |

**Presentation (7-10 minutes):** use [presentation/slides.html](../presentation/slides.html) (open it in a browser: arrow keys to move, **N** for speaker notes, **F** for full screen). A PDF copy is in [presentation/slides.pdf](../presentation/slides.pdf). There are 18 slides: 2 opening slides (K Suraj Das), **3 slides per person** in the order of the table above, and a closing slide (Akash Kumar), about 1.5 minutes each. Every number on the slides is filled in automatically from the verified results by `analysis/06_slides.R`, so the slides always match the reports.
