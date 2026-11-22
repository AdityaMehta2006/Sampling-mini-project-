# Sampling Techniques Mini-Project (STA405-6)

**Design, estimation and efficiency comparison of SRS, stratified, systematic and cluster sampling on all 2,880,548 establishments in Karnataka (Sixth Economic Census 2012-13, MoSPI).**

Data source: https://microdata.gov.in/NADA/index.php/catalog/47/get-microdata

## Team

| Name | Register No. | Part |
|---|---|---|
| K Suraj Das | 2440224 | SRSWOR and SRSWR, sample size, data and frame |
| Rithesh K R | 2440233 | Stratified sampling |
| Aditya Mehta | 2440204 | Systematic sampling, charts |
| Abhinaba Das | 2440203 | Cluster sampling, errors |
| Akash Kumar | 2440206 | Comparison of designs, official statistics, report compilation |

## Start here

| If you want to... | Open |
|---|---|
| Know your role and what to prepare for the viva | [TEAM/README.md](TEAM/README.md), then your own note in [TEAM/](TEAM) (PDFs in [TEAM/pdf/](TEAM/pdf)) |
| **Submit the group report** | [group_report.pdf](group_report.pdf): the full report (18 pages + annexure), checked against the rubric in [reports/rubric_check.md](reports/rubric_check.md) |
| Get your individual report | [reports/](reports): one PDF per person, names already filled in |
| Present | [presentation/slides.html](presentation/slides.html) (PDF: [presentation/slides.pdf](presentation/slides.pdf)) |
| Read all results in one file | [output/all_results.pdf](output/all_results.pdf) |
| Read one method's results | [output/README.md](output/README.md), then a folder like [output/02_stratified/](output/02_stratified) |
| Check what the assignment asks | [Group Mini-Project Sampling Techniques (50 Marks) (1).docx.pdf](<Group Mini-Project Sampling Techniques (50 Marks) (1).docx.pdf>) |
| See or change the code | [analysis/](analysis) |

## Folders

```
analysis/      R code, numbered in run order (00 to 08) + run_all.R
data/          frame_karnataka.rds: the cleaned list of all 2.88 million establishments
output/        one folder per script: a PDF report, figures, tables (CSV) and selected samples
presentation/  slides.html (built from template.html by analysis/06_slides.R) and slides.pdf
reports/       one report per person (analysis/07_reports.R), the rubric check, cover templates
group_report.pdf   the group report (analysis/08_group_report.R)
TEAM/          one note per person: what to say, formulas, results, viva questions and answers
```

## Re-running everything

1. Install R (https://cran.r-project.org). No extra packages are needed for the analysis.
2. Open a terminal in this folder and run:

   ```
   Rscript analysis/run_all.R
   ```

   It takes about 2 minutes and rebuilds every table, figure and PDF. The random seed is fixed (2026), so everyone gets identical numbers.

PDFs need Google Chrome (or Chromium) and the R package `commonmark`; the individual reports also need LaTeX (`pdflatex`) and `qpdf`. Without them everything else still works. Re-exporting the raw data (script 00) also needs the census DVD in `dataset_archives/` and the R package `nesstarR`; without them script 00 is skipped and the frame in `data/` is used.

## Design in brief

| | |
|---|---|
| Population | All 2,880,548 establishments in Karnataka (Sixth Economic Census 2012-13) |
| Variable | Number of persons employed (mean and total) |
| Proportion | Share of establishments owned by a woman (18.9%) |
| Sample size | n = 748 for every method (P within 3 points; 748 x 3,851 = N exactly) |
| Strata | 4 revenue divisions: Bengaluru, Mysuru, Belagavi, Kalaburagi |
| Systematic frame | List ordered by district, tehsil, town/village, ward, enumeration block; k = 3,851 |
| Clusters | 105,624 enumeration blocks; 27 sampled |
| Recommendation | Systematic sampling on the location-ordered list |
