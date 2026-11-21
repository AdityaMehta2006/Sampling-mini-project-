# Member 1: SRSWOR, SRSWR, sample size, data cleaning and frame

**Read your results in:** [output/01_srs/01_srs.pdf](../output/01_srs/01_srs.pdf) and [output/00_data_verification/00_data_verification.pdf](../output/00_data_verification/00_data_verification.pdf)
**Your code:** [analysis/00_data_verification.R](../analysis/00_data_verification.R), [analysis/01_srs.R](../analysis/01_srs.R), and the Unit 1 section of [analysis/designs.R](../analysis/designs.R)

---

## 1. What the assignment asks of you, and where it is answered

| Assignment requirement | Where |
|---|---|
| Data cleaning and frame preparation | Tables 0.1, 1.1-1.4 |
| Survey design: population, frame, variable, proportion, strata, clusters | Table 1.5 |
| Sample size for a specified precision, fixed for all methods | Table 1.7, Figure 1.2 |
| SRSWOR and SRSWR: estimate, variance, SE, 95% CI, fpc for mean, total, proportion | Tables 1.8, 1.9, Figure 1.3 |
| Variance under both schemes and comparison of the two | Table 1.10 |
| Probability of selecting a specified unit (syllabus) | Table 1.11 |

## 2. What you did, step by step (say it like this)

1. **"We took the official data."** The Sixth Economic Census (2012-13) by MoSPI lists every establishment in India. We used Karnataka: 2,880,548 establishments.
2. **"We proved the data is genuine."** MoSPI's DVD has an official summary page for each variable. We compared our copy with all of them: counts, categories, minimum, maximum, mean and SD. All 67 checks matched (Table 0.1), so nothing was lost or changed.
3. **"We cleaned it."** No missing values, no zero workers, and total workers always equals male plus female, hired plus not hired (Table 1.1). Nothing had to be removed.
4. **"We found possible recording errors."** Seven single-owner businesses report 10,000 or more workers, six of them exactly 10,001 or 10,002 (Table 1.3). That looks like a data-entry code. We kept them because we must use the official data, and we showed their effect: the mean hardly changes (2.481 to 2.456) but the SD drops from 26.8 to 21.5 (Table 1.4).
5. **"We built the frame."** We listed all establishments in order of location: district, tehsil, town or village, ward, enumeration block. Everyone samples from this one list.
6. **"We fixed n = 748."** (Section 3 below.)
7. **"We drew one SRSWOR and one SRSWR sample of 748"** and estimated the mean, total and proportion.

## 3. Sample size, worked out

We want P (the share of female-owned establishments) within **+/-3 percentage points** with 95% confidence.

    n0 = z² P Q / d²  = (1.96)² x 0.1895 x 0.8105 / (0.03)²  = 655.5
    n  = n0 / (1 + (n0 - 1) / N) = 655.5 / (1 + 654.5 / 2,880,548) = 656

- **Why 748 and not 656?** Systematic sampling (Unit 3) needs N = n x k exactly. 748 is the smallest number above 656 that divides 2,880,548 exactly (748 x 3,851). With 748 we get a margin of error of 2.8 points, slightly better than required.
- **Why fix n by the proportion and not the mean?** For the mean within 10% we would need 44,277 establishments (Table 1.7), because the data is so skewed. That is not practical, so we fix n by P and report how precise the mean is at that n.
- **Where did P come from?** From the census itself. In a real survey it would come from the previous census (2005) or a small pilot survey.

## 4. The formulas (each symbol explained)

N = population size (2,880,548), n = sample size (748), f = n/N = sampling fraction, y_i = workers in establishment i.

| | SRSWOR (without replacement) | SRSWR (with replacement) |
|---|---|---|
| Estimate of the mean | ybar = (sum of y_i) / n | same |
| Estimate of the total | N x ybar | same |
| Estimated variance of ybar | (1 - f) s² / n | s² / n |
| Estimated variance of p | (1 - f) p q / (n - 1) | p q / (n - 1) |
| True variance of ybar | (1 - f) S² / n | (N - 1) S² / (N n) |
| 95% CI | estimate +/- 1.96 x SE | same |
| P(a given unit is selected) | n / N | 1 - (1 - 1/N)^n |

- s² = sample variance, S² = population variance, q = 1 - p.
- **fpc** = (1 - f) = 1 - 748/2,880,548 = **0.9997**. It is almost 1 because we sample a tiny fraction of the population, so it hardly matters here.
- **SE** = square root of the variance. Variance of the total = N² x variance of the mean.

**Worked example (SRSWR, mean):** s² = 30.28, so SE = sqrt(30.28 / 748) = 0.201. CI = 2.259 +/- 1.96 x 0.201 = [1.865, 2.654]. It contains the true value 2.481.

## 5. Your results

| What | Result | Table |
|---|---|---|
| True mean / true P | 2.481 workers / 0.1895 (18.9%) | 1.6 |
| Median / largest | 1 worker / 14,160 workers | 1.6 |
| SRSWOR mean, SE, CI | 4.445, 1.877, [0.767, 8.124] | 1.8 |
| SRSWR mean, SE, CI | 2.259, 0.201, [1.865, 2.654] | 1.8 |
| SRSWOR P, SE, CI | 0.2059, 0.0148, [0.177, 0.235] | 1.8 |
| SRSWR P, SE, CI | 0.1805, 0.0141, [0.153, 0.208] | 1.8 |
| Exact SE of the mean (both designs) | 0.981 | 1.8 |
| V(SRSWR) / V(SRSWOR) | 1.00026, exactly (N-1)/(N-n) | 1.10 |

## 6. What to say in the presentation (about 1.5 minutes)

> "Our population is all 2.88 million establishments in Karnataka from the Sixth Economic Census. We checked our data against 67 official MoSPI figures, and all matched. The study variable is the number of workers, and the proportion is the share of female-owned establishments, 18.9%. Figure 1.1 shows the key problem: 57% of establishments have one worker, but a few have thousands. To estimate P within 3 percentage points we need 656 units; we use 748 so that systematic sampling works exactly. With SRS, both samples' confidence intervals contained the true values. SRSWR is only 0.03% less precise than SRSWOR, because we sample such a tiny fraction of the population."

Show **Table 1.8** and **Figure 1.1**.

## 7. Viva questions and answers

**Q: What is the difference between SRSWOR and SRSWR?**
A: In SRSWOR a unit can be selected only once. In SRSWR it is put back and can be selected again. SRSWOR gives every possible sample of n distinct units the same chance.

**Q: Which is better and by how much here?**
A: SRSWOR, because its variance is smaller by the factor (N - n)/(N - 1). Here that is 0.99974, so SRSWR's variance is only 0.026% larger. When n is tiny compared with N, the two are practically the same.

**Q: Why is the SRSWOR estimate 4.4 when the true mean is 2.5? Did something go wrong?**
A: No. Our sample happened to include a very large establishment. The CI is wide, [0.77, 8.12], and still contains the true value, so the method worked; this particular sample was just unlucky.

**Q: Why are the two SEs so different (1.88 and 0.20)?**
A: The SE is calculated from the sample's own variance. One huge value in the SRSWOR sample made s² large. The true (exact) SE is 0.98 for both designs. With such skewed data, one sample's SE can be misleading.

**Q: What is the finite population correction?**
A: (1 - n/N). It reduces the variance because we sample without replacement from a finite population. Here it is 0.9997, almost 1, because n is a tiny part of N.

**Q: What is the probability that a particular establishment is in the sample?**
A: n/N = 748 / 2,880,548 = 0.00026 under SRSWOR. Under SRSWR, the chance it is picked at least once is 1 - (1 - 1/N)^n, practically the same.

**Q: How did you decide the sample size?**
A: From the formula n0 = z²PQ/d² with d = 0.03, giving 656. Then we rounded up to 748 so that N/n is a whole number for systematic sampling.

**Q: Why not use the mean to decide n?**
A: The mean would need about 44,000 units for 10% precision, because the coefficient of variation is 10.8. That is too many, so we fixed n by the proportion.

**Q: Why is the CI for the total so wide?**
A: Total = N x mean, so its SE is N times the SE of the mean. Any uncertainty in the mean is multiplied by 2.88 million.

**Q: How do you know the data is genuine?**
A: It is MoSPI's official release, and our copy matched all 67 official summary figures published on the same DVD.

**Q: What about the establishments with 10,001 workers?**
A: They look like recording errors, because six private rural businesses all report almost exactly 10,000. We kept them because the data must be used as published, and we showed that they change the SD from 21.5 to 26.8 but hardly change the mean.

**Q: What would happen to the SE if n were doubled?**
A: The SE would fall by a factor of sqrt(2), about 29% smaller, because SE is proportional to 1/sqrt(n).

## 8. Limitations to mention

- P in the sample-size formula came from the census itself; normally it comes from a past survey or pilot.
- For such skewed data, the normal-based CI for the mean is often wrong: Member 5's simulation shows only about 60% of them contain the true value.
- The suspicious large values (Table 1.3) are a non-sampling error that sampling cannot fix.
