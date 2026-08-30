# Purpose: Retrieve a small country profile and real flag image for the README.
# Inputs: Public World Bank country API and FlagCDN. Outputs: cached JSON/PNG.
# Assumptions: Country metadata is context, not a source for Georgia residents.
# Run after 04; optional source failures must not invalidate Census analysis.
source("scripts/00_config.R")
source("R/helpers.R")
country_url <- "https://api.worldbank.org/v2/country/UZ?format=json"
country_path <- "data_raw/uzbekistan_world_bank.json"
tryCatch({
  if (!file.exists(country_path) || refresh_downloads) {
    response <- jsonlite::fromJSON(country_url)
    stopifnot(response[[2]]$iso2Code == "UZ", response[[2]]$name == "Uzbekistan")
    jsonlite::write_json(response, country_path, pretty = TRUE, auto_unbox = TRUE)
    writeLines(as.character(Sys.Date()), paste0(country_path, ".retrieved.txt"))
  }
  profile <- jsonlite::fromJSON(country_path)[[2]]
  stopifnot(nrow(profile) == 1, profile$iso2Code == "UZ", profile$name == "Uzbekistan")
  facts <- tibble(country = profile$name, capital = profile$capitalCity,
                  capital_longitude = as.numeric(profile$longitude), capital_latitude = as.numeric(profile$latitude),
                  source = country_url, retrieved = readLines(paste0(country_path, ".retrieved.txt")))
  write_csv(facts, "outputs/country_facts.csv")
}, error = function(e) warning("Optional country profile unavailable: ", conditionMessage(e)))
flag_url <- "https://flagcdn.com/w320/uz.png"
tryCatch({
  if (!file.exists("assets/uzbekistan_flag.png") || refresh_downloads) {
    download.file(flag_url, "assets/uzbekistan_flag.png", mode = "wb", quiet = TRUE)
    writeLines(c(paste("Source:", flag_url), paste("Retrieved:", Sys.Date())), "assets/flag_source.txt")
  }
}, error = function(e) warning("Optional flag download failed."))
