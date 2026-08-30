# Purpose: Create review charts, maps and interactive geographic exploration.
# Inputs: script 02 spatial/CSV files after script 03 QA. Outputs: exports/.
# Assumptions: Estimate rankings are not significance tests. Next: script 05.
source("scripts/00_config.R")
source("R/helpers.R")
states <- read_clean(paste0("data_clean/states_acs_", acs_year, ".csv"))
msas <- read_clean(paste0("data_clean/us_msas_acs_", acs_year, ".csv"))
source_note <- paste0("Source: U.S. Census Bureau, ", acs_product_label,
                      ", B05006_066 and B01001_001. Whiskers: 90% margins of error. ")

make_count_chart <- function(data, title, object_name) {
  chart <- ggplot(data, aes(x = reorder(NAME, uzbekistan_born_foreign_born),
                           y = uzbekistan_born_foreign_born)) +
    geom_col(fill = "#286DAD") +
    geom_errorbar(aes(ymin = pmax(0, uzbekistan_born_foreign_born - uzbekistan_born_foreign_born_moe),
                      ymax = uzbekistan_born_foreign_born + uzbekistan_born_foreign_born_moe), width = .2) +
    coord_flip() + scale_y_continuous(labels = scales::comma) +
    labs(title = title, subtitle = "Foreign-born residents born in Uzbekistan; estimates, not exact counts",
         x = NULL, y = "Estimated residents", caption = wrap_plot_caption(source_note, object_name, 100)) +
    peeblestoolbox::theme_peebles_chart(angle_x_labels = 0) +
    peeblestoolbox::add_peebles_watermark(watermark_label)
  chart
}
chart_georgia_birthplace <- make_count_chart(filter(states, GEOID == "13"),
                                            "Georgia residents born in Uzbekistan", "chart_georgia_birthplace")
chart_georgia_birthplace
peeblestoolbox::save_peebles_plot(chart_georgia_birthplace, "georgia_birthplace.png", folder = "exports", width = 11, height = 5)
msa_counts <- msas %>% filter(!is.na(uzbekistan_born_foreign_born)) %>%
  slice_max(uzbekistan_born_foreign_born, n = 15, with_ties = FALSE)
chart_msa_counts <- make_count_chart(msa_counts, "Metro areas with the largest Uzbekistan-born estimates", "chart_msa_counts")
chart_msa_counts
peeblestoolbox::save_peebles_plot(chart_msa_counts, "msa_counts.png", folder = "exports", width = 12, height = 8)
save_interactive(plotly::ggplotly(chart_msa_counts), "msa_counts.html")
msa_concentrations <- msas %>% filter(uzbekistan_born_concentration_eligible %in% TRUE) %>%
  slice_max(uzbekistan_born_foreign_born_pct, n = 15, with_ties = FALSE)
write_csv(msa_concentrations, "outputs/msa_concentration_ranking.csv")
if (nrow(msa_concentrations)) {
  chart_msa_concentration <- ggplot(msa_concentrations,
    aes(reorder(NAME, uzbekistan_born_foreign_born_pct), uzbekistan_born_foreign_born_pct)) +
    geom_col(fill = "#7857A3") + coord_flip() +
    labs(title = "Where Uzbekistan-born residents make up a larger population share",
         subtitle = paste0("Metros with at least ", scales::comma(minimum_msa_population_for_concentration),
                           " residents and birthplace CV below ", cv_review_threshold, "%"),
         x = NULL, y = "Percent of all residents",
         caption = str_wrap(paste0("Source: ", acs_product_label,
                    ", B05006_066 and B01001_001. No percent error bars when denominator MOE is unavailable. ",
                    "Eligibility screens count uncertainty; it does not establish significant rank differences."), 100)) +
    peeblestoolbox::theme_peebles_chart(angle_x_labels = 0) +
    peeblestoolbox::add_peebles_watermark(watermark_label)
  chart_msa_concentration
  peeblestoolbox::save_peebles_plot(chart_msa_concentration, "msa_concentrations.png", folder = "exports", width = 12, height = 8)
  save_interactive(plotly::ggplotly(chart_msa_concentration), "msa_concentrations.html")
}

# Keep all source rows. Separate population floors and reliability flags
# determine which rows can receive a choropleth color or enter a place chart.
exclusions <- list()
for (level in c("counties", "places", "tracts")) {
  spatial <- readRDS(paste0("data_clean/georgia_", level, "_acs_", acs_year, "_sf.rds"))
  floor <- switch(level, places = minimum_place_population, tracts = minimum_tract_population, 0)
  spatial <- spatial %>% mutate(
    eligible = reliable_estimate(.) & !is.na(total_population) & total_population >= floor,
    percent_for_map = if_else(eligible, uzbekistan_born_foreign_born_pct, NA_real_))
  exclusions[[level]] <- tibble(geography = level, received = nrow(spatial),
                                retained = sum(spatial$eligible), excluded = sum(!spatial$eligible),
                                population_floor = floor, empty_geometry = sum(st_is_empty(spatial)))
  write_csv(st_drop_geometry(spatial), paste0("outputs/", level, "_map_eligibility.csv"))
  spatial <- spatial %>% filter(!st_is_empty(.))
  if (level == "places") {
    top_places <- spatial %>% st_drop_geometry() %>% filter(eligible) %>%
      slice_max(uzbekistan_born_foreign_born, n = 15, with_ties = FALSE)
    write_csv(top_places, "outputs/georgia_place_ranking.csv")
    if (nrow(top_places)) {
      chart_places_birthplace <- make_count_chart(top_places, "Georgia places with larger Uzbekistan-born estimates", "chart_places_birthplace")
      chart_places_birthplace
      peeblestoolbox::save_peebles_plot(chart_places_birthplace, "georgia_places.png", folder = "exports", width = 12, height = 8)
      save_interactive(plotly::ggplotly(chart_places_birthplace), "georgia_places_chart.html")
    }
  }
  static <- st_transform(spatial, 5070)
  map_georgia_birthplace <- ggplot(static) +
    geom_sf(aes(fill = percent_for_map), color = "white", linewidth = .1) +
    scale_fill_viridis_c(name = "% born in\nUzbekistan", na.value = "#dddddd") +
    labs(title = paste("Uzbekistan-born residents in Georgia", level),
         subtitle = "Gray: unavailable, below population floor or fails reliability screen; gray does not mean zero",
         caption = str_wrap(paste0("Source: ", acs_product_label, ", B05006_066 / B01001_001. ",
                            "Static map: ", st_crs(static)$Name, " (EPSG:", st_crs(static)$epsg,
                            "). GeoJSON: WGS84 (EPSG:4326). Object: map_georgia_birthplace."), 105)) +
    peeblestoolbox::theme_peebles_map() + peeblestoolbox::add_peebles_watermark(watermark_label)
  map_georgia_birthplace
  peeblestoolbox::save_peebles_plot(map_georgia_birthplace, paste0("georgia_", level, "_map.png"),
                                   folder = "exports", width = 12, height = 8, bg = "white")
  # Set a harmless palette domain for an all-unavailable map without inventing data.
  palette_domain <- spatial$percent_for_map[!is.na(spatial$percent_for_map)]
  if (!length(palette_domain)) palette_domain <- c(0, 1)
  palette <- leaflet::colorNumeric("viridis", domain = palette_domain, na.color = "#dddddd")
  popup <- paste0(htmltools::htmlEscape(spatial$NAME), "<br>Estimate: ",
                  spatial$uzbekistan_born_foreign_born, "<br>90% MOE: ", spatial$uzbekistan_born_foreign_born_moe,
                  "<br>CV (%): ", round(spatial$uzbekistan_born_foreign_born_cv, 1),
                  "<br>Eligible for map color: ", spatial$eligible)
  interactive_georgia_birthplace <- leaflet(spatial) %>% addProviderTiles("CartoDB.Positron") %>%
    addPolygons(fillColor = palette(spatial$percent_for_map), color = "#666666", weight = .5,
                fillOpacity = .75, popup = popup) %>%
    addLegend(pal = palette, values = palette_domain, title = "% born in Uzbekistan")
  save_interactive(interactive_georgia_birthplace, paste0("georgia_", level, "_map.html"))
  peeblestoolbox::export_geojson(spatial, paste0("uzbekistan_population_georgia_", level),
                                folder = "exports/geojson", overwrite = TRUE)
  exported <- st_read(paste0("exports/geojson/uzbekistan_population_georgia_", level, ".geojson"), quiet = TRUE)
  stopifnot(st_crs(exported)$epsg == 4326, nrow(exported) == nrow(spatial))
}
write_csv(bind_rows(exclusions), "outputs/map_exclusions.csv")
