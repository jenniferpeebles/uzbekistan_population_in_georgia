# Purpose: Shared settings and dependencies for the Uzbekistan ACS project.
# Inputs: Launch from the project root; user-level Census key. Outputs: folders.
# Assumptions: ACS 5-year birthplace, not ethnicity. Run before scripts 01–06.
acs_year <- 2024L
acs_survey <- "acs5"
acs_product_label <- paste0(acs_year - 4L, "–", acs_year, " ACS five-year estimates")
analysis_state <- "GA"
cv_review_threshold <- 30
minimum_place_population <- 1000
minimum_tract_population <- 500
minimum_msa_population_for_concentration <- 100000
atlanta_core_counties <- c("Clayton", "Cobb", "DeKalb", "Fulton", "Gwinnett")
watermark_label <- "NOT FOR PUBLICATION"
refresh_downloads <- FALSE # TRUE explicitly replaces cached source snapshots.
project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists("uzbekistan_population_in_georgia.Rproj")) {
  stop("Open the Uzbekistan R project and run from its root directory.")
}
project_dirs <- c("data_raw", "data_clean", "outputs", "exports/geojson", "docs", "logs", "assets")
invisible(lapply(file.path(project_root, project_dirs), dir.create,
                 recursive = TRUE, showWarnings = FALSE))
options(tigris_use_cache = TRUE, timeout = 300, scipen = 999)
required_packages <- c("tidyverse", "janitor", "tidycensus", "tigris", "sf",
                       "peeblestoolbox", "jsonlite", "leaflet", "plotly", "htmlwidgets")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace,
                                             logical(1), quietly = TRUE)]
if (length(missing_packages)) stop("Install required packages: ", paste(missing_packages, collapse = ", "))
suppressPackageStartupMessages(invisible(lapply(required_packages, library, character.only = TRUE)))
if (!nzchar(Sys.getenv("CENSUS_API_KEY")) && nzchar(Sys.getenv("CENSUS_KEY"))) {
  Sys.setenv(CENSUS_API_KEY = Sys.getenv("CENSUS_KEY"))
}
# This pipeline requires a key to support its repeated multi-geography requests.
if (!nzchar(Sys.getenv("CENSUS_API_KEY"))) stop("Set CENSUS_API_KEY in your user-level .Renviron and restart R. Never commit a key.")
acs_variables <- c(total_population = "B01001_001", uzbekistan_born_foreign_born = "B05006_066")
acs_variable_dictionary <- tibble::tribble(
  ~machine_name, ~variable, ~table, ~human_label, ~universe,
  "total_population", "B01001_001", "B01001", "Total population", "Total population",
  "uzbekistan_born_foreign_born", "B05006_066", "B05006", "Foreign-born residents born in Uzbekistan", "Foreign-born population in the United States"
)
run_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
message("ACS product: ", acs_product_label)
