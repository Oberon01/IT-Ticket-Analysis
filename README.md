# IT Helpdesk Ticket Analysis

**Tools:** R · dplyr · ggplot2 · lubridate · car · rstatix · rcompanion

Statistical analysis of 933 closed IT helpdesk tickets spanning December 2025 – June 2026, examining ticket volume, team workload distribution, resolution time, and priority-assignment practices. Real operational data — not a tutorial dataset.

---

## Questions Answered

1. Where does ticket volume concentrate across categories?
2. How is workload distributed across the support team?
3. Does resolution time differ significantly by ticket category or by assignee?
4. How has ticket volume trended over the observation period?
5. Is ticket priority being assigned consistently, and does the gap vary by category?

---

## Key Findings

| Finding | Result |
|---|---|
| Resolution time by category | Not significant (Kruskal-Wallis p = 0.109, η² = 0.006) |
| Resolution time by assignee | Significant (p < 0.0001), small effect size (η² = 0.035) |
| Priority assignment gap | 71.3% of tickets have no priority set |
| Priority gap by category | Consistent across all categories (χ² p = 0.057, V = 0.11) |
| Ticket volume growth | ~27x increase from December 2025 to May 2026 peak |
| Workload concentration | 5 of 10 team members closed 92.6% of all tickets |

---

## Analytical Approach

Test selection was assumption-driven throughout rather than defaulting to a single method:

- **Shapiro-Wilk** confirmed resolution time is non-normally distributed in every category — ruling out ANOVA
- **Levene's Test** confirmed equal variance across groups
- **Kruskal-Wallis** used as the appropriate non-parametric alternative
- **Dunn's post-hoc test** with Bonferroni correction applied to identify which specific assignee pairs differ
- **Chi-square test** used to assess whether priority-assignment behavior varies by ticket category; sparse categories collapsed to satisfy expected-cell-count assumptions before testing
- **Cramer's V** reported alongside chi-square as a scale-independent effect size

---

## Repository Structure

```
it-ticket-analysis/
├── README.md
├── .gitignore
├── anonymize.R                        # De-identification pipeline
├── data/
│   ├── raw/
│   │   └── BMSC_Closed_anonymized.csv # Anonymized source data
│   ├── private/                       # Name mappings — gitignored, not tracked
│   └── README.md                      # Data dictionary & quality notes
├── R/
│   └── analysis.R                     # Full pipeline: cleaning → EDA → statistics
└── outputs/
    ├── figures/                       # All generated plots
    └── BMSC_Ticket_Analysis_Report.docx
```

---

## Data & Anonymization

Source data was a real closed-ticket export from an internal IT helpdesk system. Before publishing, employee and requester names were replaced with volume-ranked labels (`Assignee_1`, `Assignee_2`, etc.) and the free-text subject field was dropped entirely — subject lines contained names and email addresses that a column-level rename wouldn't catch.

The anonymization pipeline is in `anonymize.R` and runs as a second step after `analysis.R` in the same R session. The name-to-label mapping is saved locally to `data/private/` (gitignored). See `data/README.md` for the full data dictionary and quality notes.

---

## How to Run

```r
# Install dependencies
install.packages(c("dplyr", "lubridate", "stringr", "ggplot2",
                    "tidyr", "car", "rstatix", "rcompanion"))

# Step 1 — clean, explore, and test
source("R/analysis.R")

# Step 2 — produce the anonymized public dataset
source("anonymize.R")
```

---

## Report

Full written report with figures, statistical interpretation, and recommendations:
[`outputs/BMSC_Ticket_Analysis_Report.docx`](outputs/BMSC_Ticket_Analysis_Report.docx)

---

## Author

**Kentrell Morrow**
IT Systems Administrator & Support Specialist transitioning into data science
[github.com/Oberon01](https://github.com/Oberon01)
