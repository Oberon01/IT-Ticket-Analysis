# Data Dictionary

This describes the cleaned, anonymized dataset at `data/raw/BMSC_Closed_anonymized.csv`. It reflects the data **after** the cleaning steps in `R/analysis.R` and the de-identification steps in `anonymize.R` - not the raw export.

## Source

Exported from the BMSC IT helpdesk ticketing system as a closed-tickets report. Original export covered 933 tickets, December 11, 2025 - June 30, 2026.

## Columns

| Column | Type | Description | Notes |
|---|---|---|---|
| `created_at` | datetime | Timestamp the ticket was created | Parsed from a malformed source format (non-standard Unicode space before AM/PM) |
| `ticket_id` | integer | Unique ticket identifier | From source system, unmodified |
| `location` | string | Office/site location (e.g. `B1`, `B2`, `NFP`) | 73% missing - not used in analysis |
| `requester` | string | Anonymized requester label (`Requester_1`, `Requester_2`, ...) | Originally contained real names; relabeled, no volume ranking applied |
| `priority` | ordered factor | Ticket priority: `High` > `Medium` > `Low` > `NONE` | `NONE` means no priority was set at creation - this is the largest category (71.3%) |
| `assignee` | string | Anonymized assignee label (`Assignee_1`, `Assignee_2`, ...) | Ranked by ticket volume - `Assignee_1` closed the most tickets, `Assignee_10` the fewest |
| `status` | string | Ticket status | Standardized to `"Closed"` - source data had `Closed`/`Resolved`/`Completed` used interchangeably |
| `category` | string | Ticket category (e.g. `Software & Applications`, `Network & Connectivity`) | Consolidated from inconsistent source naming (e.g. `Software` and `Software & Applications` merged) |
| `category_grouped` | string | Category with low-volume categories (`Hardware`, `Power Platform`, `Security`, n < 5 each) folded into `Other` | Used only for the chi-square test, where small expected cell counts would otherwise violate test assumptions |
| `closed_on` | date | Date the ticket was closed | |
| `resolution_days` | numeric | `closed_on` - `created_at`, in days | Right-skewed in every category; median is 0 (same-day) in most categories |
| `data_error` | boolean | `TRUE` if `resolution_days` is negative (closed before created) | 4 tickets flagged; excluded from resolution-time analysis but retained in volume counts |
| `priority_set` | string | Binary recoding of `priority`: `"Set"` if not `NONE`, else `"Not Set"` | Used for the chi-square test in Section 6 of the report |
| `created_month` | date | `created_at` floored to the first of the month | Used for the monthly trend analysis |
| `created_week` | date | `created_at` floored to the start of the week | Available for finer-grained trend analysis; not used in the current report |
| `created_hour` | integer | Hour of day (0-23) the ticket was created | Available for time-of-day analysis; not used in the current report |

## Columns Removed During Anonymization

| Original Column | Why Removed |
|---|---|
| `subject` | Free-text field; original values included identifying details (e.g. specific employee names, email addresses) that a column-level rename would not catch |
| `Tags` | Always empty in the source data - no analytical value |

## Known Data Quality Notes

- 4 tickets have negative resolution time (a data entry error, not a real outcome) - flagged via `data_error`, excluded from time-based analysis only
- `location` is missing on 681 of 933 rows (73%) and is not used anywhere in the analysis
- 29 tickets are missing `assignee`; 7 are missing `closed_on` - both excluded only from analyses that require those specific fields
- Several `category` values had a count of fewer than 5 in the raw data (`Hardware`, `Power Platform`, `Security`) - retained in volume counts but folded into `Other` wherever a statistical test required adequate expected cell counts

## Anonymization Method

See `anonymize.R` in the repository root for the full de-identification logic. In summary: assignee and requester names were replaced with sequential role-based labels, and the free-text `subject` field was dropped entirely. The name-to-label mapping is saved locally to `data/private/` (gitignored) and is not included in this repository.
