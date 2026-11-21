# =============================================================================
# run_all.R — runs the whole analysis in order (about 2 minutes)
#
#   Rscript analysis/run_all.R
#
# Scripts 01-05 need only data/frame_karnataka.rds, which is in the repository.
# Script 00 also needs the DVD files and the nesstarR package; it is skipped
# automatically when the raw export is not available.
# =============================================================================
scripts <- c(
  "00_data_verification.R", # Member 1: export + check against official MoSPI figures
  "01_srs.R", # Member 1: frame, sample size, SRSWOR / SRSWR
  "02_stratified.R", # Member 2: stratified sampling
  "03_systematic.R", # Member 3: systematic sampling
  "04_cluster.R", # Member 4: cluster sampling
  "05_comparison.R", # Member 5: comparison, F-tests, simulation
  "06_slides.R" # presentation built from the verified results
)

for (s in scripts) {
  if (s == "00_data_verification.R" && !file.exists("data/karnataka_ec6_raw.csv")) {
    message("Skipping ", s, " (raw export not present; data/frame_karnataka.rds is used instead)")
    next
  }
  message("\n>>> Running analysis/", s)
  status <- system2("Rscript", file.path("analysis", s), stdout = FALSE)
  if (status != 0) stop("analysis/", s, " failed - run it on its own to see the error.")
}
# One combined PDF of all reports (needs qpdf), and PDFs of the team notes.
pdfs <- Sys.glob("output/0*/0*.pdf")
if (length(pdfs) > 0 && nzchar(Sys.which("qpdf"))) {
  system2("qpdf", c("--empty", "--pages", shQuote(pdfs), "--", "output/all_results.pdf"))
  message("Combined PDF: output/all_results.pdf")
}
source("analysis/common.R")
dir.create("TEAM/pdf", showWarnings = FALSE)
for (md in Sys.glob("TEAM/*.md")) {
  markdown_to_pdf(md, file.path("TEAM/pdf", sub("\\.md$", ".pdf", basename(md))))
}
message("\nDone. Open output/README.md to browse the results.")
