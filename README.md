# Targeting Community Revitalization Investment in Illinois

An analysis of housing affordability, vacancy, poverty, and population trends across 102 Illinois counties using ACS 5-Year Estimates (2014–2022).

## Research Question

**Which Illinois counties would benefit most from targeted community revitalization investment?**

This project develops a composite need score to identify and rank Illinois counties based on five indicators of housing and economic vulnerability, with the goal of informing where community revitalization programs — such as home repair grants, land bank initiatives, and vacant property interventions — could have the greatest impact.

## Methodology

Each of Illinois' 102 counties is scored across five variables using 2022 ACS 5-Year Estimates:

| Variable | Direction | Rationale |
|----------|-----------|-----------|
| Rent burden % | Higher = more need | Share of renters paying 30%+ of income on rent |
| Price-to-income ratio | Higher = more need | Median home value relative to median household income |
| Poverty rate % | Higher = more need | Share of population below the poverty line |
| Homeownership rate % | Lower = more need | Lower ownership signals less housing stability |
| Vacancy rate % | Higher = more need | Indicates deteriorating or abandoned housing stock |

Each variable is percentile-ranked across all 102 counties, summed, and divided by 5 to produce a composite score on a 0–100 scale.

## Key Findings

*Results and top 5 counties are detailed in the presentation linked below.*

- Counties with the highest composite scores show overlapping challenges: high rent burden, elevated poverty, low homeownership, and significant vacancy
- Many of these same counties are experiencing population decline, suggesting a cycle of disinvestment
- Poverty concentrates geographically in the same regions flagged by the composite score, reinforcing the case for targeted intervention

## Presentation

[View the full presentation](link-to-google-slides-here)

## Repository Structure

```
illinois-housing-revitalization/
├── README.md
├── data/
│   ├── illinois_housing_affordability.csv   # Processed dataset (510 rows)
│   ├── composite_scores.csv                 # All 102 counties ranked
│   └── top5_counties.csv                    # Top 5 counties detail
├── notebooks/
│   ├── 01_data_pull.R                       # Census API data pull and processing
│   ├── 02_analysis.R                        # Composite score calculation and ranking
│   └── 03_visualizations.R                  # Chart and map generation
├── presentation/
│   └── IL_Community_Revitalization_Analysis.pptx
└── visualizations/
    ├── slide2_map.png
    ├── slide2_table.png
    ├── slide3_rent_burden.png
    ├── slide4_pop_change.png
    ├── appendix_composite_full.png
    ├── appendix_vacancy.png
    └── appendix_poverty.png
```

## How to Reproduce

### Prerequisites

- R (4.4+)
- Census API key ([get one here](https://api.census.gov/data/key_signup.html))
- R packages: `tidycensus`, `tidyverse`, `tigris`, `sf`, `scales`, `gt`, `ggrepel`, `showtext`

### Steps

```r
# Install packages
install.packages(c("tidycensus", "tidyverse", "tigris", "sf", "scales", "gt", "ggrepel", "showtext"))

# Set your Census API key in notebooks/01_data_pull.R, then run in order:
source("notebooks/01_data_pull.R")    # Pulls data, outputs CSV (~2 min)
source("notebooks/02_analysis.R")     # Scores counties, outputs rankings
source("notebooks/03_visualizations.R") # Generates all charts and maps
```

## Data Source

U.S. Census Bureau, American Community Survey 5-Year Estimates (2014, 2016, 2018, 2020, 2022). County-level data for all 102 Illinois counties. Retrieved via the Census API using the `tidycensus` R package.

## Considerations & Constraints

- **ACS 5-year estimates are rolling averages** — "2022" data actually reflects 2018–2022, not a single point in time
- **County-level analysis masks local variation** — conditions within a county like Cook can vary dramatically by neighborhood
- **Equal weighting is a methodological choice** — assigning different weights to the five composite variables could produce different rankings
- **Missing dimensions** — housing stock condition, age of housing, and homelessness are relevant to revitalization but not captured in ACS data
- **Relative ranking, not absolute need** — percentile scoring identifies which counties are worst compared to each other, not whether a county meets an objective threshold of need
- **Not population-weighted** — a high-need county of 5,000 residents and one of 500,000 are ranked equivalently. This is intentional, as community revitalization programs often target smaller communities that lack the scale to attract private investment. However, population context should be considered when evaluating the scale of potential impact.

## Author

Chris Kucewicz

---

*This is an independent research project and is not affiliated with or endorsed by the Illinois Housing Development Authority.*
