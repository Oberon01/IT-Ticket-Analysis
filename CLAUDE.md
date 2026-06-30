# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Analysis

The pipeline must run in order within a **single R session** — `anonymize.R` depends on the `data` object already in memory from `analysis.R`:

```r
source("R/analysis.R")   # clean, EDA, statistical tests
source("anonymize.R")    # produce the public-safe anonymized dataset
```

Install dependencies once:

```r
install.packages(c("dplyr", "lubridate", "stringr", "ggplot2",
                   "tidyr", "car", "rstatix", "rcompanion"))
```

## Architecture

Two scripts, strict order dependency:

**`R/analysis.R`** — reads the raw (non-anonymized) CSV, cleans it, runs EDA, and performs all statistical tests. Produces the in-memory `data` object and all figures. The cleaning pipeline runs in this sequence: column rename → date parsing → empty-string-to-NA → status standardization → category consolidation → priority factoring → resolution time computation → data error flagging → derived time columns.

**`anonymize.R`** — consumes the `data` object from `analysis.R`. Replaces real assignee/requester names with role-based labels (`Assignee_N` ranked by volume, `Requester_N` sequential), drops the `subject` field, and writes `data/raw/BMSC_Closed_anonymized.csv`. Saves name-to-label mappings to `data/private/` (gitignored).

## Data

- **Tracked (safe to commit):** `data/raw/BMSC_Closed_anonymized.csv`
- **Never tracked:** `data/raw/BMSC Closed.csv` (original), `data/private/` (mapping files) — both gitignored
- `data/README.md` is a full data dictionary describing every column in the cleaned, anonymized dataset including derived columns (`resolution_days`, `data_error`, `priority_set`, `created_month`, `created_week`, `created_hour`) and known quality issues

## Key Data Quality Facts

- 4 tickets have negative `resolution_days` — flagged via `data_error = TRUE`, excluded from time analyses but kept in volume counts
- `location` is 73% missing — not used in analysis
- `priority` is `NONE` on ~71% of tickets — treated as a process finding, not a data error
- Categories `Hardware`, `Power Platform`, `Security` each have n < 5 — retained in volume counts but folded into `Other` for chi-square tests (`category_grouped` column)

## Statistical Approach

Test selection is assumption-driven. The pattern throughout `analysis.R`:
1. Check normality (Shapiro-Wilk per group)
2. Check variance homogeneity (Levene's Test)
3. Select non-parametric test if assumptions fail → Kruskal-Wallis
4. Compute effect size (epsilon-squared via `kruskal_effsize`)
5. Post-hoc pairwise comparisons with Bonferroni correction (Dunn's test)
6. Chi-square for categorical associations; Cramer's V for effect size
