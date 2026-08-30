# =========================================================
# SCRIPT 02: DOWNLOAD AND PREPARE THE ACS DATA
# =========================================================

# Journalistic questions:
# Inputs: verified ACS variables from script 01 and Census geography files.
# Outputs: cached source data, clean CSVs, spatial RDS and WGS84 GeoJSON.
# Assumption: birthplace is not ethnicity. Run QA (03) next.
# Where do foreign-born people born in Uzbekistan live?
# How do Georgia and its communities compare with the nation and U.S. metros?

source("scripts/00_config.R")

source("R/helpers.R")

# =========================================================
# REUSABLE ACS DOWNLOAD FUNCTION
# =========================================================

# Use one transparent wrapper for all tidycensus calls so each geography uses
# the same year, survey, variables, and tidy output format.
fetch_acs <- function(
  geography,
  state = NULL,
  geometry = FALSE
) {
  request_arguments <- list(
    geography = geography,
    variables = acs_variables,
    year = acs_year,
    survey = acs_survey,
    geometry = geometry,
    output = "tidy"
  )

  if (!is.null(state)) {
    request_arguments$state <- state
  }

  cache_path <- file.path("data_raw", paste0(gsub("[^a-z]", "_", geography), "_", acs_year, ".rds"))
  if (file.exists(cache_path) && !refresh_downloads) return(readRDS(cache_path))
  downloaded_data <- do.call(
    tidycensus::get_acs,
    request_arguments
  )

  saveRDS(downloaded_data, cache_path)
  writeLines(as.character(Sys.time()), paste0(cache_path, ".retrieved.txt"))
  downloaded_data
}

# =========================================================
# STATES
# =========================================================

# Question: How does Georgia compare with the 49 other states and D.C.?
log_message("Downloading state-level ACS data.")

state_raw <- fetch_acs(
  geography = "state",
  geometry = TRUE
)

# Puerto Rico is not part of the 50-state-and-D.C. ranking used here.
states <- state_raw %>%
  shape_acs() %>%
  dplyr::filter(
    NAME != "Puerto Rico"
  )

states_sf <- join_geometry(
  attributes = states,
  raw_sf = state_raw
)

# =========================================================
# NATIONAL METROPOLITAN AREAS
# =========================================================

# Questions:
# Which metro has the largest Uzbekistan-born population?
# Which sufficiently large, reliable metro has the highest concentration?
log_message("Downloading national metropolitan-area ACS data.")

msa_raw <- fetch_acs(
  geography = "metropolitan statistical area/micropolitan statistical area"
)

# Keep metropolitan areas and remove micropolitan areas from this ranking.
msas <- msa_raw %>%
  shape_acs() %>%
  dplyr::filter(
    stringr::str_detect(NAME, "Metro Area$")
  ) %>%
  dplyr::mutate(
    uzbekistan_born_count_rank = dplyr::min_rank(
      dplyr::desc(uzbekistan_born_foreign_born)
    ),
    uzbekistan_born_concentration_eligible =
      total_population >= minimum_msa_population_for_concentration &
      uzbekistan_born_foreign_born_high_cv %in% FALSE &
      uzbekistan_born_foreign_born_moe_gt_estimate %in% FALSE,
    uzbekistan_born_pct_rank_reliable = dplyr::min_rank(
      dplyr::desc(
        dplyr::if_else(
          uzbekistan_born_concentration_eligible,
          uzbekistan_born_foreign_born_pct,
          NA_real_
        )
      )
    )
  )

# =========================================================
# GEORGIA COUNTIES
# =========================================================

# Question: Which Georgia counties have the largest Uzbekistan-born communities, and
# how much of the population is concentrated in the Atlanta region?
log_message("Downloading Georgia county ACS data.")

county_raw <- fetch_acs(
  geography = "county",
  state = analysis_state,
  geometry = TRUE
)

counties <- county_raw %>%
  shape_acs() %>%
  dplyr::mutate(
    county_name = stringr::str_remove(
      NAME,
      " County, Georgia$"
    )
  ) %>%
  add_project_metro_flags() %>%
  dplyr::mutate(
    is_five_core_county = county_name %in% atlanta_core_counties
  )

counties_sf <- join_geometry(
  attributes = counties,
  raw_sf = county_raw
)

# =========================================================
# GEORGIA PLACES
# =========================================================

# Question: Which Georgia cities, towns, CDPs, and consolidated governments
# have the largest Uzbekistan-born populations?
log_message("Downloading Georgia place ACS data.")

place_raw <- fetch_acs(
  geography = "place",
  state = analysis_state,
  geometry = TRUE
)

# Keep every place type, but label the categories so we do not casually treat
# consolidated governments and CDPs as ordinary incorporated cities.
places <- place_raw %>%
  shape_acs() %>%
  dplyr::mutate(
    place_name = stringr::str_remove(
      NAME,
      ", Georgia$"
    ),
    place_type = dplyr::case_when(
      substr(GEOID, 3, 7) %in% c("49008", "19000") ~ "consolidated government",
      stringr::str_detect(
        place_name,
        "consolidated government|unified government"
      ) ~ "consolidated government",
      stringr::str_detect(
        place_name,
        " CDP$"
      ) ~ "census-designated place",
      TRUE ~ "incorporated place"
    )
  )

# Preserve place boundaries so a later script can map the birthplace measure.
places_sf <- join_geometry(
  attributes = places,
  raw_sf = place_raw
)

# =========================================================
# GEORGIA CENSUS TRACTS
# =========================================================

# Question: Where are the most concentrated neighborhoods within Georgia?
# Tract estimates are exploratory and require especially careful MOE review.
log_message("Downloading Georgia census-tract ACS data.")

tract_raw <- fetch_acs(
  geography = "tract",
  state = analysis_state,
  geometry = TRUE
)

tracts <- tract_raw %>%
  shape_acs()

tracts_sf <- join_geometry(
  attributes = tracts,
  raw_sf = tract_raw
)

# =========================================================
# STRUCTURAL QA BEFORE EXPORT
# =========================================================

# Every finished table should contain one and only one row per GEOID.
datasets_to_check <- list(
  states = states,
  msas = msas,
  counties = counties,
  places = places,
  tracts = tracts
)

purrr::iwalk(
  datasets_to_check,
  assert_unique_geoid
)

# =========================================================
# EXPORT CLEAN ATTRIBUTE TABLES
# =========================================================

write_csv_clean(
  states,
  paste0("states_acs_", acs_year, ".csv")
)

write_csv_clean(
  msas,
  paste0("us_msas_acs_", acs_year, ".csv")
)

write_csv_clean(
  counties,
  paste0("georgia_counties_acs_", acs_year, ".csv")
)

write_csv_clean(
  places,
  paste0("georgia_places_acs_", acs_year, ".csv")
)

write_csv_clean(
  tracts,
  paste0("georgia_tracts_acs_", acs_year, ".csv")
)

# =========================================================
# SAVE SPATIAL DATA
# =========================================================

# RDS preserves sf geometry and R column types for later scripts.
saveRDS(
  states_sf,
  paste0("data_clean/states_acs_", acs_year, "_sf.rds")
)

saveRDS(
  counties_sf,
  paste0("data_clean/georgia_counties_acs_", acs_year, "_sf.rds")
)

saveRDS(
  places_sf,
  paste0("data_clean/georgia_places_acs_", acs_year, "_sf.rds")
)

saveRDS(
  tracts_sf,
  paste0("data_clean/georgia_tracts_acs_", acs_year, "_sf.rds")
)

# GeoJSON exports are transformed to WGS84 by PeeblesToolbox for DataWrapper.
peeblestoolbox::export_geojson(
  counties_sf,
  "uzbekistan_population_georgia_counties",
  folder = "exports/geojson",
  overwrite = TRUE
)

peeblestoolbox::export_geojson(
  places_sf,
  "uzbekistan_population_georgia_places",
  folder = "exports/geojson",
  overwrite = TRUE
)

peeblestoolbox::export_geojson(
  tracts_sf,
  "uzbekistan_population_georgia_tracts",
  folder = "exports/geojson",
  overwrite = TRUE
)

# =========================================================
# COMPLETION SUMMARY
# =========================================================

log_message(
  "Prepared ",
  nrow(states),
  " states/DC, ",
  nrow(msas),
  " MSAs, ",
  nrow(counties),
  " Georgia counties, ",
  nrow(places),
  " places, and ",
  nrow(tracts),
  " tracts."
)
