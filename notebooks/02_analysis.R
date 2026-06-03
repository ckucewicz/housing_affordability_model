# ============================================================================
# 02 - Analysis
# Builds composite revitalization need score and identifies top 5 counties
# Input:  illinois_housing_affordability.csv
# Output: composite_scores.csv, top5_counties.csv
# ============================================================================

library(tidyverse)

df <- read_csv("illinois_housing_affordability.csv") |>
  mutate(fips = str_pad(fips, 5, pad = "0"))

# ── Composite score (2022 snapshot) ─────────────────────────────────────────
# Methodology:
#   - 5 variables percentile-ranked across all 102 IL counties
#   - Higher percentile = greater revitalization need
#   - Homeownership rate is flipped (lower ownership = more need)
#   - Scores summed and divided by 5 for a 0-100 scale

latest <- df |>
  filter(year == 2022) |>
  mutate(
    ptile_rent_burden   = percent_rank(rent_burden_pct) * 100,
    ptile_price_income  = percent_rank(price_to_income) * 100,
    ptile_poverty       = percent_rank(poverty_rate_pct) * 100,
    ptile_homeownership = (1 - percent_rank(homeownership_pct)) * 100,
    ptile_vacancy       = percent_rank(vacancy_rate_pct) * 100,
    composite_score     = round(
      (ptile_rent_burden + ptile_price_income +
       ptile_poverty + ptile_homeownership + ptile_vacancy) / 5, 1
    )
  ) |>
  arrange(desc(composite_score))

# ── Top 5 ───────────────────────────────────────────────────────────────────

top5 <- latest |> slice_head(n = 5)

cat("Top 5 counties by community revitalization need:\n\n")
top5 |>
  select(county_name, composite_score,
         rent_burden_pct, price_to_income,
         poverty_rate_pct, homeownership_pct, vacancy_rate_pct) |>
  print(n = 5)

# ── Export ──────────────────────────────────────────────────────────────────

write_csv(latest, "composite_scores.csv")
cat("\nSaved composite_scores.csv (102 counties ranked)\n")

write_csv(top5, "top5_counties.csv")
cat("Saved top5_counties.csv\n")
