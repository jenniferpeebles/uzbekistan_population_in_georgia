# Purpose: Audit structure, coverage, uncertainty and ranking exclusions.
# Inputs: script 02 CSVs/spatial files. Outputs: QA tables and place audit.
# Assumptions: 50 states + DC; all 159 Georgia counties. Next: script 04.
source("scripts/00_config.R")
source("R/helpers.R")
datasets <- list(states = read_clean(paste0("data_clean/states_acs_", acs_year, ".csv")),
                 msas = read_clean(paste0("data_clean/us_msas_acs_", acs_year, ".csv")),
                 counties = read_clean(paste0("data_clean/georgia_counties_acs_", acs_year, ".csv")),
                 places = read_clean(paste0("data_clean/georgia_places_acs_", acs_year, ".csv")),
                 tracts = read_clean(paste0("data_clean/georgia_tracts_acs_", acs_year, ".csv")))
qa_summary <- imap_dfr(datasets, function(data, level) {
  tibble(dataset = level, rows = nrow(data), duplicate_geoids = sum(duplicated(data$GEOID)),
         missing_estimates = sum(is.na(data$uzbekistan_born_foreign_born)),
         missing_moes = sum(is.na(data$uzbekistan_born_foreign_born_moe)),
         missing_total_population = sum(is.na(data$total_population)),
         missing_denominator_moes = sum(is.na(data$total_population_moe)),
         impossible = sum(data$uzbekistan_born_foreign_born < 0 |
                            data$uzbekistan_born_foreign_born > data$total_population |
                            data$uzbekistan_born_foreign_born_moe < 0, na.rm = TRUE),
         moe_gt_estimate = sum(data$uzbekistan_born_foreign_born_moe_gt_estimate %in% TRUE),
         high_cv = sum(data$uzbekistan_born_foreign_born_high_cv %in% TRUE),
         reliability_eligible = sum(reliable_estimate(data)),
         reliability_excluded = sum(!reliable_estimate(data)))
})
write_csv(qa_summary, "outputs/qa_summary.csv")
write_csv(imap_dfr(datasets, ~mutate(.x, dataset = .y) %>% filter(!reliable_estimate(.x))),
          "outputs/qa_flagged_geographies.csv")
print(qa_summary)
stopifnot(all(qa_summary$duplicate_geoids == 0), all(qa_summary$impossible == 0),
          nrow(datasets$states) == 51, nrow(datasets$counties) == 159)
# County estimates should sum to the state birthplace estimate. Do not omit missing rows.
ga <- datasets$states %>% filter(GEOID == "13")
reconciliation <- tibble(measure = "Uzbekistan-born foreign-born population",
                         state_estimate = ga$uzbekistan_born_foreign_born,
                         county_sum = sum(datasets$counties$uzbekistan_born_foreign_born),
                         difference = county_sum - state_estimate)
write_csv(reconciliation, "outputs/county_state_reconciliation.csv")
stopifnot(!is.na(reconciliation$difference), reconciliation$difference == 0)
place_audit <- datasets$places %>% filter(grepl("Augusta|Athens|Macon|Columbus", NAME))
write_csv(place_audit, "outputs/consolidated_place_audit.csv")
stopifnot(all(vapply(c("Augusta", "Athens", "Macon", "Columbus"),
                    function(x) any(grepl(x, place_audit$NAME)), logical(1))))
spatial_qa <- map_dfr(c("states", "counties", "places", "tracts"), function(level) {
  prefix <- if (level == "states") "states" else paste0("georgia_", level)
  spatial <- readRDS(paste0("data_clean/", prefix, "_acs_", acs_year, "_sf.rds"))
  empty_rows <- spatial %>% filter(st_is_empty(.)) %>% st_drop_geometry()
  write_csv(empty_rows, paste0("outputs/", level, "_missing_geometry.csv"))
  # Cartographic boundaries omit these water-only coastal tracts. Preserve
  # their attributes, but require zero source population before allowing QA.
  if (nrow(empty_rows)) stopifnot(level == "tracts", all(empty_rows$total_population == 0),
                                 all(substr(empty_rows$GEOID, 6, 11) == "990000"))
  tibble(dataset = level, epsg = st_crs(spatial)$epsg,
         invalid = sum(!st_is_valid(spatial)), empty = sum(st_is_empty(spatial)))
})
write_csv(spatial_qa, "outputs/spatial_qa.csv")
stopifnot(all(spatial_qa$epsg == 4326), all(spatial_qa$invalid == 0))
log_message("Structural and reconciliation QA passed. Reliability exclusions remain visible.")
