# IT Helpdesk Ticket Analysis

Statistical analysis of 933 closed IT helpdesk tickets to identify patterns in ticket volume, team workload distribution, resolution time, and priority-assignment practices.

## Project Overview

This project analyzes real closed-ticket data from an internal IT helpdesk system covering December 2025 through June 2026. The goal was to answer five practical questions for the IT team:

1. Where does ticket volume concentrate by category?
2. How is workload distributed across the team?
3. Does resolution time differ meaningfully by ticket category or by assignee?
4. How has ticket volume trended over time?
5. Is ticket priority being assigned consistently?

> **Note:** This repository contains anonymized data. The original export included real employee and requester names; those have been replaced with role-based labels (`Assignee_1`, `Requester_1`, etc.) before publishing. See **Anonymization** below for how this was done.

## Key Findings

- **Resolution time does not differ significantly by ticket category** (Kruskal-Wallis, p = 0.109) - ticket type alone doesn't predict how long a ticket takes to close.
- **Resolution time does differ significantly by assignee** (p < 0.0001, small effect size), with three pairwise differences surviving correction for multiple comparisons.
- **71.3% of tickets have no priority level assigned**, and this gap is consistent across every category (p = 0.057) - pointing to a single process fix rather than several category-specific ones.
- **Ticket volume grew roughly 27x** from December 2025 (10 tickets) to a May 2026 peak (270 tickets).
- **Workload is concentrated**: 5 of 10 team members closed over 92% of all tickets.

## Tools & Methods

- **Language:** R (dplyr, ggplot2, lubridate, stringr, car, rstatix, rcompanion)
- **Data cleaning:** encoding fixes, malformed timestamp parsing, category consolidation, missing value handling
- **Statistical methods:** Shapiro-Wilk (normality), Levene's Test (variance homogeneity), Kruskal-Wallis (non-parametric group comparison), Dunn's post-hoc test with Bonferroni correction, Chi-square test of independence, Cramer's V (effect size)

Test selection was assumption-driven throughout: normality and variance checks determined whether parametric or non-parametric tests were appropriate at each step, rather than defaulting to one method.

## Pipeline

This project runs in three stages, in order:

```
1. R/analysis.R      reads the raw CSV, cleans it, runs EDA and statistical tests
2. anonymize.R       de-identifies assignees/requesters, drops free-text subject field
3. (manual)          anonymized output is committed; original raw data never is
```

`anonymize.R` depends on the cleaned `data` object already existing in memory, so it's run as a second step in the same R session - not standalone.

```r
source("R/analysis.R")   # clean, explore, test
source("anonymize.R")    # produce the public-safe dataset
```

The anonymization step:
- Replaces assignee names with `Assignee_1`, `Assignee_2`, etc., ranked by ticket volume (so `Assignee_1` is always the highest-volume person - the report stays interpretable without revealing identities)
- Replaces requester names with sequential generic labels
- Drops the `subject` field entirely, since free-text ticket subjects can contain names, emails, or other identifying details that a column-level rename wouldn't catch
- Saves the name-to-label mapping to `data/private/` for internal reference only - this folder is gitignored and never published

The raw, non-anonymized CSV is excluded from version control via `.gitignore`. Only `data/raw/BMSC_Closed_anonymized.csv` is tracked.

## Repository Structure

```
it-ticket-analysis/
CDD README.md                          # This file
CDD .gitignore                         # Excludes raw data & anonymization mappings
CDD anonymize.R                        # De-identification script
CDD data/
3   CDD raw/
3   3   @DD BMSC_Closed_anonymized.csv # Public-safe source data (tracked)
3   CDD private/                       # Name mappings (gitignored, not tracked)
3   @DD README.md                      # Data dictionary
CDD R/
3   @DD analysis.R                     # Full analysis script (cleaning  EDA  stats)
@DD outputs/
    CDD figures/                       # All generated plots
    @DD BMSC_Ticket_Analysis_Report.docx  # Full written report
```

## How to Run

```r
# Install dependencies
install.packages(c("dplyr", "lubridate", "stringr", "ggplot2",
                    "tidyr", "car", "rstatix", "rcompanion"))

# Run the full pipeline
source("R/analysis.R")
source("anonymize.R")
```

## Report

The full written report - including all tables, figures, statistical interpretation, and recommendations - is available at [`outputs/BMSC_Ticket_Analysis_Report.docx`](outputs/BMSC_Ticket_Analysis_Report.docx).

## Author

Kentrell Morrow - IT Systems Administrator & Support Specialist
[GitHub](https://github.com/Oberon01)
