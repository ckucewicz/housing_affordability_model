# ============================================================================
# 03 - Visualizations
# Community Revitalization Analysis for Illinois Counties
# Input:  illinois_housing_affordability.csv, composite_scores.csv, top5_counties.csv
# Output: slide PNGs + appendix PNGs
# ============================================================================

library(tidyverse)
library(tigris)
library(sf)
library(scales)
library(gt)
library(ggrepel)
library(showtext)

# Load IHDA brand font
font_add_google("Montserrat", "montserrat")
showtext_auto()
showtext_opts(dpi = 300)

options(tigris_use_cache = TRUE)

df     <- read_csv("illinois_housing_affordability.csv")
scores <- read_csv("composite_scores.csv")
top5   <- read_csv("top5_counties.csv")

df     <- df |> mutate(fips = str_pad(fips, 5, pad = "0"))
scores <- scores |> mutate(fips = str_pad(fips, 5, pad = "0"))
top5   <- top5 |> mutate(fips = str_pad(fips, 5, pad = "0"))

# ── County geometry ─────────────────────────────────────────────────────────

il_counties <- counties(state = "IL", year = 2022, cb = TRUE)

# IHDA brand colors
ihda_primary <- "#0069aa"
ihda_dark    <- "#0c3553"
ihda_light   <- "#62b0e7"
ihda_deep    <- "#0b2442"
ihda_orange  <- "#EF882B"

need_palette <- c("#D4E8F0", "#62b0e7", "#0069aa", "#0c3553", "#0b2442")
score_range  <- c(min(scores$composite_score), max(scores$composite_score))

# Set global font and sizes
theme_update(
  text               = element_text(family = "montserrat", size = 16),
  legend.text        = element_text(size = 14),
  legend.title       = element_text(size = 15, face = "bold"),
  axis.text          = element_text(size = 14),
  axis.title         = element_text(size = 15),
  strip.text         = element_text(size = 15, face = "bold")
)

# ============================================================================
# SLIDE 2: Top 5 map + table
# ============================================================================

map_data <- il_counties |>
  left_join(scores |> select(fips, composite_score, county_name),
            by = c("GEOID" = "fips")) |>
  mutate(
    is_top5    = county_name %in% top5$county_name,
    fill_score = if_else(is_top5, composite_score, NA_real_)
  )

top5_labels <- map_data |>
  filter(is_top5) |>
  st_centroid()

slide2_map <- ggplot(map_data) +
  geom_sf(aes(fill = fill_score), color = "white", linewidth = 0.2) +
  geom_sf(
    data = map_data |> filter(is_top5),
    aes(fill = fill_score), color = "grey30", linewidth = 0.5
  ) +
  geom_text_repel(
    data = top5_labels,
    aes(label = county_name, geometry = geometry),
    stat = "sf_coordinates",
    size = 6, fontface = "bold", color = "grey20",
    nudge_y = 0.4, nudge_x = -0.4,
    min.segment.length = 0,
    segment.color = "grey30",
    segment.size = 0.6,
    segment.linetype = "dotted"
  ) +
  scale_fill_gradientn(
    colors   = need_palette,
    na.value = "grey90",
    name     = "Need score",
    limits   = score_range
  ) +
  labs(
    title    = "Which Illinois counties would benefit most from\ntargeted community revitalization investment?",
    subtitle = "Top 5 counties by composite need score (2022)",
    caption  = "Source: ACS 5-Year Estimates, 2022 | U.S. Census Bureau"
  ) +
  theme_void() +
  theme(
    text          = element_text(family = "montserrat"),
    plot.title    = element_text(size = 20, face = "bold", margin = margin(b = 4)),
    plot.subtitle = element_text(size = 14, color = "grey40", margin = margin(b = 12)),
    plot.caption  = element_text(size = 11, color = "grey60", margin = margin(t = 12)),
    legend.text   = element_text(size = 13),
    legend.title  = element_text(size = 14, face = "bold"),
    legend.position = c(0.2, 0.2)
  )

ggsave("slide2_map.png", slide2_map,
       width = 8, height = 10, dpi = 300, bg = "white")
cat("slide2_map.png\n")

# Table
slide2_table <- top5 |>
  select(county_name, composite_score,
         rent_burden_pct, price_to_income,
         poverty_rate_pct, homeownership_pct, vacancy_rate_pct) |>
  arrange(desc(composite_score)) |>
  gt() |>
  tab_header(
    title    = "Top 5 counties by revitalization need",
    subtitle = "Composite score and component metrics (2022)"
  ) |>
  cols_label(
    county_name       = "County",
    composite_score   = "Score",
    rent_burden_pct   = "Rent burden %",
    price_to_income   = "Price:income",
    poverty_rate_pct  = "Poverty %",
    homeownership_pct = "Homeown. %",
    vacancy_rate_pct  = "Vacancy %"
  ) |>
  fmt_number(columns = composite_score, decimals = 1) |>
  fmt_number(columns = c(rent_burden_pct, poverty_rate_pct,
                         homeownership_pct, vacancy_rate_pct), decimals = 1) |>
  fmt_number(columns = price_to_income, decimals = 2) |>
  tab_source_note("Source: ACS 5-Year Estimates, 2022") |>
  tab_options(
    table.font.size   = 16,
    heading.title.font.size = 20,
    heading.subtitle.font.size = 14,
    column_labels.font.weight = "bold",
    column_labels.font.size = 15
  )

gtsave(slide2_table, "slide2_table.png", vwidth = 750)
cat("slide2_table.png\n")

# ============================================================================
# SLIDE 3: Rent burden bar chart
# ============================================================================

slide3 <- top5 |>
  mutate(county_name = fct_reorder(county_name, rent_burden_pct)) |>
  ggplot(aes(x = county_name, y = rent_burden_pct)) +
  geom_col(fill = ihda_primary, width = 0.7) +
  geom_hline(yintercept = 50, linetype = "dashed", color = ihda_orange) +
  annotate("text", x = 0.6, y = 51.5, label = "50% of renters",
           size = 4.25, color = ihda_orange, hjust = 0.155, vjust = 0.1) +
  geom_text(aes(label = paste0(rent_burden_pct, "%")),
            hjust = 1.5, vjust = 1.05, size = 5.5, fontface = "bold", color = "white") +
  scale_y_continuous(
    labels = label_percent(scale = 1),
    expand = expansion(mult = c(0, 0.12))
  ) +
  coord_flip() +
  labs(
    title    = "Residents in these communities are cost-burdened",
    subtitle = "% of renters spending 30%+ of income on rent (2022)",
    x = NULL, y = NULL,
    caption = "Source: ACS 5-Year Estimates, 2022 | U.S. Census Bureau"
  ) +
  theme_minimal() +
  theme(
    text               = element_text(family = "montserrat"),
    plot.title         = element_text(size = 20, face = "bold", margin = margin(b = 4)),
    plot.subtitle      = element_text(size = 14, color = "grey40", margin = margin(b = 12)),
    plot.caption       = element_text(size = 11, color = "grey60"),
    axis.text          = element_text(size = 14),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank()
  )

ggsave("slide3_rent_burden.png", slide3,
       width = 10, height = 5, dpi = 300, bg = "white")
cat("slide3_rent_burden.png\n")

# ============================================================================
# SLIDE 4: Population change
# ============================================================================

pop_change <- df |>
  filter(fips %in% top5$fips, year %in% c(2014, 2022)) |>
  select(county_name, fips, year, total_pop) |>
  pivot_wider(names_from = year, values_from = total_pop, names_prefix = "pop_") |>
  mutate(
    pop_change_pct = round((pop_2022 - pop_2014) / pop_2014 * 100, 1),
    pop_change_abs = pop_2022 - pop_2014,
    county_name = fct_reorder(county_name, pop_change_pct)
  )

slide4 <- ggplot(pop_change, aes(x = county_name, y = pop_change_pct)) +
  geom_col(aes(fill = pop_change_pct < 0), width = 0.70, show.legend = FALSE) +
  geom_hline(yintercept = 0, color = "grey30", linewidth = 0.5) +
  geom_text(
    aes(label = paste0(ifelse(pop_change_pct > 0, "+", ""), pop_change_pct, "%"),
        hjust = ifelse(pop_change_pct < 0, -0.2, 1.05)),
    size = 3.75, fontface = "bold", color = "white"
  ) +
  scale_fill_manual(values = c("TRUE" = ihda_orange, "FALSE" = ihda_primary)) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  coord_flip() +
  labs(
    title    = "These communities are losing residents",
    subtitle = "Population change from 2014 to 2022 in top revitalization-need counties",
    x = NULL, y = NULL,
    caption = "Source: ACS 5-Year Estimates, 2014 & 2022 | U.S. Census Bureau"
  ) +
  theme_minimal() +
  theme(
    text               = element_text(family = "montserrat"),
    plot.title         = element_text(size = 20, face = "bold", margin = margin(b = 4)),
    plot.subtitle      = element_text(size = 14, color = "grey40", margin = margin(b = 12)),
    plot.caption       = element_text(size = 11, color = "grey60"),
    axis.text          = element_text(size = 14),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank()
  )

ggsave("slide4_pop_change.png", slide4,
       width = 10, height = 5, dpi = 300, bg = "white")
cat("slide4_pop_change.png\n")

# ============================================================================
# APPENDIX MAPS
# ============================================================================

make_map <- function(var, title, legend_label, palette = "Reds", filename) {
  plot_data <- il_counties |>
    left_join(scores |> select(fips, county_name, all_of(var)),
              by = c("GEOID" = "fips"))

  top5_pts <- plot_data |>
    filter(county_name %in% top5$county_name) |>
    st_centroid()

  p <- ggplot(plot_data) +
    geom_sf(aes(fill = .data[[var]]), color = "white", linewidth = 0.2) +
    geom_text_repel(
      data = top5_pts,
      aes(label = county_name, geometry = geometry),
      stat = "sf_coordinates",
      size = 6, fontface = "bold", color = "grey20",
      nudge_y = 0.4, nudge_x = -0.4,
      min.segment.length = 0,
      segment.color = "grey30",
      segment.size = 0.6,
      segment.linetype = "dotted"
    ) +
    scale_fill_distiller(palette = palette, direction = 1, name = legend_label) +
    labs(title = title, subtitle = "By county, 2022",
         caption = "Source: ACS 5-Year Estimates, 2022 | U.S. Census Bureau") +
    theme_void() +
    theme(
      text          = element_text(family = "montserrat"),
      plot.title    = element_text(size = 20, face = "bold", margin = margin(b = 4)),
      plot.subtitle = element_text(size = 14, color = "grey40", margin = margin(b = 12)),
      plot.caption  = element_text(size = 11, color = "grey60", margin = margin(t = 12)),
      legend.text   = element_text(size = 13),
      legend.title  = element_text(size = 14, face = "bold"),
      legend.position = c(0.2, 0.2)
    )
  ggsave(filename, p, width = 8, height = 10, dpi = 300, bg = "white")
  cat(filename, "\n")
}

make_map("vacancy_rate_pct", "Vacancy rate", "% vacant", "Greys", "appendix_vacancy.png")
make_map("poverty_rate_pct", "Poverty rate", "% poverty", "OrRd", "appendix_poverty.png")

# Composite score - all counties
full_map_data <- il_counties |>
  left_join(scores |> select(fips, composite_score, county_name),
            by = c("GEOID" = "fips"))

top5_full_labels <- full_map_data |>
  filter(county_name %in% top5$county_name) |>
  st_centroid()

appendix_full <- ggplot(full_map_data) +
  geom_sf(aes(fill = composite_score), color = "white", linewidth = 0.2) +
  geom_text_repel(
    data = top5_full_labels,
    aes(label = county_name, geometry = geometry),
    stat = "sf_coordinates",
    size = 6, fontface = "bold", color = "white",
    nudge_y = 0.4, nudge_x = -0.4,
    min.segment.length = 0,
    segment.color = "white",
    segment.size = 0.6,
    segment.linetype = "dotted"
  ) +
  scale_fill_gradientn(colors = need_palette, name = "Need score") +
  labs(title = "Composite revitalization need score - all counties",
       subtitle = "Rent burden + price-to-income + poverty + low homeownership + vacancy (2022)",
       caption = "Source: ACS 5-Year Estimates, 2022 | U.S. Census Bureau") +
  theme_void() +
  theme(
    text          = element_text(family = "montserrat"),
    plot.title    = element_text(size = 20, face = "bold", margin = margin(b = 4)),
    plot.subtitle = element_text(size = 14, color = "grey40", margin = margin(b = 12)),
    plot.caption  = element_text(size = 11, color = "grey60", margin = margin(t = 12)),
    legend.text   = element_text(size = 13),
    legend.title  = element_text(size = 14, face = "bold"),
    legend.position = c(0.2, 0.2)
  )

ggsave("appendix_composite_full.png", appendix_full,
       width = 8, height = 10, dpi = 300, bg = "white")
cat("appendix_composite_full.png\n")

cat("\nDone!\n")
cat("Slides: slide2_map, slide2_table, slide3_rent_burden, slide4_pop_change\n")
cat("Appendix: appendix_vacancy, appendix_poverty, appendix_composite_full\n")
