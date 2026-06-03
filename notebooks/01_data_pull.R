# ============================================================================
# 01 — Data pull and processing
# Pulls ACS 5-Year data for all Illinois counties (2014–2022)
# Output: illinois_housing_affordability.csv
#
# Setup: install.packages(c("tidycensus", "tidyverse", "tigris", "sf"))
#        Census API key: https://api.census.gov/data/key_signup.html
# ============================================================================

library(tidycensus)
library(tidyverse)
library(tigris)
library(sf)

census_api_key("INSERT API KEY HERE", install = FALSE)
options(tigris_use_cache = TRUE)

# ── ACS variables ───────────────────────────────────────────────────────────

acs_vars <- c(
  # Affordability
  median_income       = "B19013_001",
  median_home_value   = "B25077_001",
  median_gross_rent   = "B25064_001",
  # Rent burden buckets
  rent_30_34          = "B25070_007",
  rent_35_39          = "B25070_008",
  rent_40_49          = "B25070_009",
  rent_50_plus        = "B25070_010",
  total_renters       = "B25070_001",
  # Supply
  total_housing_units = "B25001_001",
  vacant_units        = "B25002_003",
  total_units_vac     = "B25002_001",
  # Equity — homeownership by race
  tenure_total        = "B25003_001",
  owner_occupied      = "B25003_002",
  tenure_white_nh     = "B25003H_001",
  owner_white_nh      = "B25003H_002",
  tenure_black        = "B25003B_001",
  owner_black         = "B25003B_002",
  tenure_hispanic     = "B25003I_001",
  owner_hispanic      = "B25003I_002",
  # Poverty
  poverty_universe    = "B17001_001",
  pop_below_poverty   = "B17001_002",
  # Population
  total_pop           = "B01003_001",
  # Race / ethnicity
  pop_total_race      = "B03002_001",
  pop_white_nh        = "B03002_003",
  pop_black_nh        = "B03002_004",
  pop_aian_nh         = "B03002_005",
  pop_asian_nh        = "B03002_006",
  pop_hispanic        = "B03002_012"
)

# ── Pull function ───────────────────────────────────────────────────────────

pull_year <- function(yr) {
  cat("Pulling", yr, "...\n")
  get_acs(
    geography = "county",
    state     = "IL",
    variables = acs_vars,
    year      = yr,
    survey    = "acs5",
    output    = "wide"
  ) |>
    select(GEOID, NAME, ends_with("E")) |>
    rename_with(~ str_remove(., "E$"), -c(GEOID, NAME)) |>
    mutate(year = yr)
}

years  <- c(2014, 2016, 2018, 2020, 2022)
df_raw <- map(years, pull_year) |> list_rbind()

# ── Derived metrics ─────────────────────────────────────────────────────────

df <- df_raw |>
  mutate(
    county_name = str_remove(NAME, " County, Illinois"),
    fips        = GEOID,

    # Affordability
    price_to_income        = round(median_home_value / median_income, 2),
    rent_burdened          = rent_30_34 + rent_35_39 + rent_40_49 + rent_50_plus,
    rent_burden_pct        = round(rent_burdened / total_renters * 100, 1),
    severe_rent_burden_pct = round(rent_50_plus / total_renters * 100, 1),

    # Supply
    housing_units_per_1k = round(total_housing_units / total_pop * 1000, 1),
    vacancy_rate_pct     = round(vacant_units / total_units_vac * 100, 1),

    # Equity
    homeownership_pct          = round(owner_occupied / tenure_total * 100, 1),
    homeownership_white_nh_pct = round(owner_white_nh / tenure_white_nh * 100, 1),
    homeownership_black_pct    = round(owner_black / tenure_black * 100, 1),
    homeownership_hispanic_pct = round(owner_hispanic / tenure_hispanic * 100, 1),

    # Poverty
    poverty_rate_pct = round(pop_below_poverty / poverty_universe * 100, 1),

    # Demographics
    pct_white_nh = round(pop_white_nh / pop_total_race * 100, 1),
    pct_black_nh = round(pop_black_nh / pop_total_race * 100, 1),
    pct_asian_nh = round(pop_asian_nh / pop_total_race * 100, 1),
    pct_hispanic = round(pop_hispanic / pop_total_race * 100, 1),
    pct_aian_nh  = round(pop_aian_nh / pop_total_race * 100, 1)
  )

# ── County centroids ────────────────────────────────────────────────────────

cat("Fetching county geometry...\n")
il_counties <- counties(state = "IL", year = 2022, cb = TRUE)

centroids <- il_counties |>
  st_centroid() |>
  st_transform(4326) |>
  mutate(
    latitude  = st_coordinates(geometry)[, 2],
    longitude = st_coordinates(geometry)[, 1]
  ) |>
  st_drop_geometry() |>
  select(GEOID, latitude, longitude)

df <- df |> left_join(centroids, by = c("fips" = "GEOID"))

# ── Export ──────────────────────────────────────────────────────────────────

df_out <- df |>
  select(
    county_name, fips, latitude, longitude, year, total_pop,
    median_income, median_home_value, price_to_income,
    median_gross_rent, rent_burden_pct, severe_rent_burden_pct,
    total_housing_units, housing_units_per_1k, vacancy_rate_pct,
    homeownership_pct, homeownership_white_nh_pct,
    homeownership_black_pct, homeownership_hispanic_pct,
    poverty_rate_pct,
    pct_white_nh, pct_black_nh, pct_asian_nh, pct_hispanic, pct_aian_nh
  ) |>
  arrange(county_name, year)

write_csv(df_out, "illinois_housing_affordability.csv")
cat("\n✓ Saved", nrow(df_out), "rows to illinois_housing_affordability.csv\n")
