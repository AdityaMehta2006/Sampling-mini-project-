# Results

Every folder below is produced by the R script with the same name in [`analysis/`](../analysis). Each folder contains:

- **`NN_name.pdf`**: the report to read and print (tables, figures, explanations)
- `README.md`: the same report (GitHub shows it when you open the folder)
- `figures/`: the charts as PNG, to paste into the final report
- `tables/`: every table as CSV with full precision, for Excel or the Annexure
- `samples/`: the establishments selected by each method, for the Annexure

**[all_results.pdf](all_results.pdf)** combines all six reports in one file.

| Folder | Owner | What it contains |
|---|---|---|
| [00_data_verification](00_data_verification/README.md) | K Suraj Das | The data export, checked against MoSPI's official figures (67/67 match) |
| [01_srs](01_srs/README.md) | K Suraj Das | Data quality, survey design, true values, sample size, SRSWOR and SRSWR |
| [02_stratified](02_stratified/README.md) | Rithesh K R | Strata, proportional vs Neyman allocation, gain over SRS, ANOVA |
| [03_systematic](03_systematic/README.md) | Aditya Mehta | Systematic sample, all 3,851 starting points, effect of k, ANOVA, list order |
| [04_cluster](04_cluster/README.md) | Abhinaba Das | Enumeration blocks as clusters, ICC, design effect, cluster size |
| [05_comparison](05_comparison/README.md) | Akash Kumar | Master comparison table, F-tests, 500-repeat simulation, recommendation |

`_shared/` holds intermediate results passed between scripts. It is not in git; `run_all.R` rebuilds it.

**Do not edit anything here by hand.** Run `Rscript analysis/run_all.R` to rebuild it all.
