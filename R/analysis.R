# Setup ----
library(dplyr)
library(lubridate)
library(stringr)
library(ggplot2)
library(tidyr)
library(rcompanion)
library(rstatix)
library(car)

# Data Ingestion ----
data <- read.csv("data/raw/BMSC Closed.csv", 
                 fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)

glimpse(data)

# Data Cleaning ----

## Column Names ----
data <- data %>%
  rename(
    created_at = Created,
    ticket_id = Id,
    location = Location,
    requester = Requester,
    priority = Priority,
    subject = Subject,
    assignee = Primary.Assignee,
    status = Status,
    category = Category,
    closed_on = Closed.On
  ) %>% select(-Tags) # always empty, no analytical value

## Parse dates ----
data <- data %>%
  mutate(
    created_at = mdy_hm(created_at),
    closed_on = mdy(closed_on)
  )

## Empty strings > NA ----
data <- data %>%
  mutate(
    location = na_if(location, ""),
    requester = na_if(requester, ""),
    assignee = na_if(assignee, "")
  )

## Standardize Status ----
data <- data %>%
  mutate(status = "Closed") # Completed/Closed/Resolved all mean the same thing

## Consolidate Category Duplicates ----
data <- data %>%
  mutate(category = case_when(
    category == "Software" ~ "Software & Applications",
    category == "Networking" ~ "Network & Connectivity",
    category == "Access and Accounts" ~ "User Accounts & Access",
    category == "Printer Issue" ~ "Printers & Labeling", 
    category == "Security Spam or phishing attempts)" ~ "Security",
    category == "Not Listed (Other)" ~ "Other",
    is.na(category) ~ "Other",
    TRUE ~ category
  ))

## Standardize Priority ----
data <- data %>%
  mutate(priority = factor(priority,
                           levels = c("High", "Medium", "Low", "NONE"),
                           ordered = TRUE))

## Compute Resolution Time ----
data <- data %>%
  mutate(resolution_days = as.numeric(closed_on - as.Date(created_at)))

## Flag bad records ----
data <- data %>%
  mutate(data_error = resolution_days < 0)

## Derived time columns ----
data <- data %>%
  mutate(
    created_month = floor_date(created_at, "month"),
    created_week = floor_date(created_at, "week"),
    created_hour = hour(created_at)
    )

# Cleaning Validation ----
# Notes on data quality (as of initial clean):
#   - 4 records have negative resolution time (closed before created) — excluded
#     from resolution time analysis, not removed from dataset
#   - Location is 73% missing (673/916) — not usable for location-based analysis
#   - Priority is unset (NONE) on 72% of tickets — flagged as a process gap,
#     not a data error; will be reported as a finding
#   - Hardware, Power Platform, Security categories have n < 5 — too small
#     for category-level conclusions, kept in dataset but noted as low-volume

cat("******* POST-CLEAN SUMMARY *******\n")
cat("Rows:", nrow(data), "\n")
cat("Data errors (negative resolution):", sum(data$data_error, na.rm = TRUE), "\n")
cat("Missing assignee:", sum(is.na(data$assignee)), "\n")
cat("Missing location:", sum(is.na(data$location)), "\n")
cat("Missing closed_on:", sum(is.na(data$closed_on)), "\n")
cat("\nCategory counts:\n")
print(table(data$category))
cat("\nPriority counts:\n")
print(table(data$priority))

# Exploratory Data Analysis ----

## 1. Ticket Volume by Category ----
category_summary <- data %>%
  count(category, sort=TRUE) %>%
  mutate(pct = round(n/sum(n) * 100, 1))

print(category_summary)

p1 <- ggplot(category_summary, aes(x=reorder(category, n), y = n)) +
  geom_col(fill = "#2E75B6") +
  geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
  coord_flip() +
  labs(
    title = "Ticket Volume by Category",
    x = NULL, y = "Number of Tickets"
  ) +
  theme_minimal(base_size = 12) +
  expand_limits(y = max(category_summary$n) * 1.1)

p1

## 2. Workload Distribution by Assignee ----
assignee_summary <- data %>%
  filter(!is.na(assignee)) %>%
  count(assignee, sort = TRUE) %>%
  mutate(pct = round(n / sum(n) * 100, 1))

print(assignee_summary)

p2 <- ggplot(assignee_summary, aes(x = reorder(assignee, n), y = n)) +
  geom_col(fill = "#90BE6D") +
  geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
  coord_flip() +
  labs(
    title = "Ticket Workload by Assignee",
    x = NULL, y = "Number of Tickets Closed"
  ) +
  theme_minimal(base_size = 12) +
  expand_limits(y = max(assignee_summary$n) * 1.1)

p2


## 3. Resolution Time by Category and Assignee ----
resolution_by_category <- data %>%
  filter(!data_error, !is.na(resolution_days)) %>%
  group_by(category) %>%
  summarise(
    n = n(),
    mean_days   = round(mean(resolution_days), 2),
    median_days = median(resolution_days),
    max_days    = max(resolution_days),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_days))

print(resolution_by_category)

resolution_by_assignee <- data %>%
  filter(!data_error, !is.na(resolution_days), !is.na(assignee)) %>%
  group_by(assignee) %>%
  summarise(
    n = n(),
    mean_days   = round(mean(resolution_days), 2),
    median_days = median(resolution_days),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_days))

print(resolution_by_assignee)

p3 <- data %>%
  filter(!data_error, !is.na(resolution_days)) %>%
  ggplot(aes(x = reorder(category, resolution_days, FUN = median), y = resolution_days)) +
  geom_boxplot(fill = "#F9844A", alpha = 0.7, outlier.alpha = 0.4) +
  coord_flip() +
  labs(
    title = "Resolution Time by Category",
    x = NULL, y = "Resolution Time (days)"
  ) +
  theme_minimal(base_size = 12)

p3

## 4. Monthly Volume Trend ----
monthly_trend <- data %>%
  count(created_month) %>%
  arrange(created_month)

print(monthly_trend)

p4 <- ggplot(monthly_trend, aes(x = created_month, y = n)) +
  geom_line(color = "#2E75B6", linewidth = 1) +
  geom_point(color = "#2E75B6", size = 2.5) +
  labs(
    title = "Monthly Ticket Volume Trend",
    x = NULL, y = "Tickets Created"
  ) +
  theme_minimal(base_size = 12) +
  scale_x_datetime(date_labels = "%b %Y")

p4

## 5. Priority Gap Analysis ----
priority_summary <- data %>%
  count(priority) %>%
  mutate(pct = round(n / sum(n) * 100, 1))

print(priority_summary)

p5 <- ggplot(priority_summary, aes(x = priority, y = n, fill = priority)) +
  geom_col() +
  geom_text(aes(label = paste0(n, " (", pct, "%)")), vjust = -0.3, size = 3.5) +
  scale_fill_manual(values = c("High" = "#E63946", "Medium" = "#F9844A",
                               "Low" = "#90BE6D", "NONE" = "#CCCCCC")) +
  labs(
    title = "Ticket Priority Distribution",
    subtitle = "71% of tickets have no priority assigned",
    x = NULL, y = "Number of Tickets"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

p5

# Statistical Analysis ----

## Assumption Checks ----

### Normality (Shapiro-Wilk per Category) ----
normality_by_category <- data %>% 
  filter(!data_error, !is.na(resolution_days)) %>%
  group_by(category) %>%
  filter(n() >= 3) %>%
  summarise(
    n = n(),
    shapiro_p = tryCatch(shapiro.test(resolution_days)$p.value, error = function(e) NA),
    .groups = "drop"
  ) %>%
  mutate(normal = shapiro_p > 0.05)

print(normality_by_category)

### Homogeneity of Variance (Levene's Test) ----

clean_resolution <- data %>%
  filter(!data_error, !is.na(resolution_days))

levene_category <- leveneTest(resolution_days ~ factor(category), data = clean_resolution)
print(levene_category)

## Primary Test: Kruskal-Wallis (Category) ----
kruskal_category <- kruskal.test(resolution_days ~ category, data = clean_resolution)
print(kruskal_category)

## Effect Size (Epsilon-squared) ----

kw_effect_category <- clean_resolution %>%
  kruskal_effsize(resolution_days ~ category)
print(kw_effect_category)

## Post-Hoc: Dunn's Test (if Kruskal-Wallis is significant) ----
dunn_category <- clean_resolution %>%
  dunn_test(resolution_days ~ category, p.adjust.method = "bonferroni")
print(dunn_category, n = 50)

## Same test, by Assignee ----
clean_resolution_assignee <- data %>%
  filter(!data_error, !is.na(resolution_days), !is.na(assignee))

kruskal_assignee <- kruskal.test(resolution_days ~ assignee, data = clean_resolution_assignee)
print(kruskal_assignee)

kw_effect_assignee <- clean_resolution_assignee %>%
  kruskal_effsize(resolution_days ~ assignee)
print(kw_effect_assignee)

## Post-Hoc: Dunn's Test (Assignee) ----
dunn_assignee <- clean_resolution_assignee %>%
  dunn_test(resolution_days ~ assignee, p.adjust.method = "bonferroni")
print(dunn_assignee, n = 50)

## Chi-Square: Priority Assignment by Category ----

# Collapse to binary: was a priority set, or not?
data <- data %>%
  mutate(priority_set = if_else(priority == "NONE", "Not Set", "Set"))

# Collapse sparse categories (n < 5) into "Other" so expected cell counts
# meet chi-square's validity assumption (expected >= 5 per cell)
data <- data %>%
  mutate(category_grouped = case_when(
    category %in% c("Hardware", "Power Platform", "Security") ~ "Other",
    str_trim(category) == "" ~ "Other",
    TRUE ~ category
  ))

priority_category_table <- table(data$category_grouped, data$priority_set)
print(priority_category_table)

chi_test_priority <- chisq.test(priority_category_table)
print(chi_test_priority$expected)  # confirm all cells >= 5 before trusting result
print(chi_test_priority)

# Effect size: Cramer's V
cramerV(priority_category_table)