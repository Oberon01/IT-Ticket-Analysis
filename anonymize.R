# Anonymize ----
# Run this once, after analysis.R, to produce a public-safe version of the
# dataset for the GitHub repo. The original data is never modified or
# committed — only the anonymized output goes in data/raw/.
#
# Mapping is saved locally (gitignored) so re-running produces consistent
# labels, and so you can still interpret your own report internally if needed.

library(dplyr)

set.seed(42)  # reproducible mapping if re-run

# Build assignee mapping ----
# Ranked by ticket volume (descending) so labels are stable and meaningful
# even without real names - Assignee_1 is always the highest-volume person.
assignee_lookup <- data %>%
  filter(!is.na(assignee)) %>%
  count(assignee, sort = TRUE) %>%
  mutate(assignee_anon = paste0("Assignee_", row_number())) %>%
  select(assignee, assignee_anon)

# Build requester mapping ----
# Requesters aren't analyzed individually anywhere in this project, so they
# get generic sequential labels rather than volume-ranked ones.
requester_lookup <- data %>%
  filter(!is.na(requester)) %>%
  distinct(requester) %>%
  mutate(requester_anon = paste0("Requester_", row_number()))

# - Save mappings locally (NEVER commit this file) ----
dir.create("data/private", showWarnings = FALSE)
write.csv(assignee_lookup, "data/private/assignee_mapping.csv", row.names = FALSE)
write.csv(requester_lookup, "data/private/requester_mapping.csv", row.names = FALSE)

cat("Mappings saved to data/private/ (gitignored, kept for your own reference only)\n")

# Apply anonymization ----
data_anon <- data %>%
  left_join(assignee_lookup, by = "assignee") %>%
  left_join(requester_lookup, by = "requester") %>%
  mutate(
    assignee  = if_else(is.na(assignee), NA_character_, assignee_anon),
    requester = if_else(is.na(requester), NA_character_, requester_anon)
  ) %>%
  select(-assignee_anon, -requester_anon) %>%
  # Subject lines can contain names, account details, or other identifying
  # text (e.g. "Email search for RM documentation in POCONFIRMATION@...").
  # Safest default: drop it from the public version entirely.
  select(-subject)

# Validation ----
cat("\n=== ANONYMIZATION CHECK ===\n")
cat("Original assignee names present in anon data:",
    any(data_anon$assignee %in% assignee_lookup$assignee), "\n")
cat("Original requester names present in anon data:",
    any(data_anon$requester %in% requester_lookup$requester), "\n")
cat("Subject column removed:", !("subject" %in% names(data_anon)), "\n")
cat("Rows preserved:", nrow(data_anon) == nrow(data), "\n")

# Write public-safe CSV ----
dir.create("data/raw", showWarnings = FALSE)
write.csv(data_anon, "data/raw/BMSC_Closed_anonymized.csv", row.names = FALSE)

cat("\nAnonymized file written to data/raw/BMSC_Closed_anonymized.csv\n")
cat("This file is safe to commit. The mapping files in data/private/ are not.\n")