# =========================================================
# REUSABLE PROJECT HELPER FUNCTIONS
# =========================================================

# These helpers keep repeated calculations consistent across every geography.
# Each function favors readable intermediate objects over clever shortcuts.

# =========================================================
# LOGGING
# =========================================================

# Write the same progress message to the console and the pipeline log.
shape_acs <- function(raw_data) {
  raw_attributes <- sf::st_drop_geometry(raw_data)
  if (anyDuplicated(raw_attributes[c("GEOID", "variable")])) stop("Duplicate raw geography-variable keys.")
  wide <- raw_attributes %>%
    select(GEOID, NAME, variable, estimate, moe) %>%
    pivot_wider(names_from = variable, values_from = c(estimate, moe)) %>%
    rename(total_population = estimate_total_population,
           total_population_moe = moe_total_population,
           uzbekistan_born_foreign_born = estimate_uzbekistan_born_foreign_born,
           uzbekistan_born_foreign_born_moe = moe_uzbekistan_born_foreign_born) %>%
    mutate(uzbekistan_born_foreign_born_pct = safe_divide(uzbekistan_born_foreign_born, total_population, 100),
           uzbekistan_born_foreign_born_pct_moe = ratio_moe_90(
             uzbekistan_born_foreign_born, total_population,
             uzbekistan_born_foreign_born_moe, total_population_moe, 100))
  add_reliability_fields(wide, "uzbekistan_born_foreign_born",
                        "uzbekistan_born_foreign_born_moe", "uzbekistan_born_foreign_born")
}

read_clean <- function(path) {
  if (!file.exists(path)) stop("Missing input: ", path, ". Run script 02 first.")
  readr::read_csv(path, show_col_types = FALSE,
                  col_types = readr::cols(GEOID = readr::col_character()))
}

reliable_estimate <- function(data) {
  !is.na(data$uzbekistan_born_foreign_born) &
    data$uzbekistan_born_foreign_born_high_cv %in% FALSE &
    data$uzbekistan_born_foreign_born_moe_gt_estimate %in% FALSE
}

log_message <- function(...) {
  message_text <- paste0(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    " | ",
    paste0(..., collapse = "")
  )

  message(message_text)

  cat(
    message_text,
    "\n",
    file = file.path(project_root, "logs", "pipeline.log"),
    append = TRUE
  )
}

# =========================================================
# ACS MATH AND RELIABILITY
# =========================================================

# Divide only when both values exist and the denominator is positive.
# Missing values stay missing; this function never manufactures a zero.
safe_divide <- function(
  numerator,
  denominator,
  multiplier = 1
) {
  dplyr::if_else(
    is.na(numerator) |
      is.na(denominator) |
      denominator <= 0,
    NA_real_,
    numerator / denominator * multiplier
  )
}

# Calculate a 90 percent MOE for a ratio or percentage using the Census
# approximation. If the subtraction formula produces a negative radicand,
# use the Census alternative addition formula.
ratio_moe_90 <- function(
  numerator,
  denominator,
  numerator_moe,
  denominator_moe,
  multiplier = 1
) {
  ratio <- numerator / denominator

  # Missing denominator uncertainty remains unavailable; never impute zero.
  denominator_moe_for_ratio <- denominator_moe

  radicand <- numerator_moe^2 -
    ratio^2 * denominator_moe_for_ratio^2

  fallback_radicand <- numerator_moe^2 +
    ratio^2 * denominator_moe_for_ratio^2

  ratio_moe <- sqrt(
    ifelse(
      radicand >= 0,
      radicand,
      fallback_radicand
    )
  ) / denominator * multiplier

  ratio_moe[
    is.na(numerator) |
      is.na(denominator) |
      denominator <= 0
  ] <- NA_real_

  ratio_moe
}

# Add the uncertainty fields Charles and Jennifer need to review before
# treating an ACS estimate as story-ready.
add_reliability_fields <- function(
  data,
  estimate_col,
  moe_col,
  prefix
) {
  estimate <- data[[estimate_col]]

  moe <- data[[moe_col]]

  data[[paste0(prefix, "_ci90_lower")]] <- ifelse(
    is.na(estimate) | is.na(moe),
    NA_real_,
    pmax(0, estimate - moe)
  )

  data[[paste0(prefix, "_ci90_upper")]] <- ifelse(
    is.na(estimate) | is.na(moe),
    NA_real_,
    estimate + moe
  )

  data[[paste0(prefix, "_cv")]] <- ifelse(
    is.na(estimate) | estimate <= 0 | is.na(moe),
    NA_real_,
    (moe / 1.645) / estimate * 100
  )

  data[[paste0(prefix, "_moe_gt_estimate")]] <- ifelse(
    is.na(estimate) | is.na(moe),
    NA,
    moe > estimate
  )

  data[[paste0(prefix, "_ci_crosses_zero")]] <- ifelse(
    is.na(estimate) | is.na(moe),
    NA,
    estimate - moe <= 0
  )

  cv_column <- paste0(prefix, "_cv")

  data[[paste0(prefix, "_high_cv")]] <- ifelse(
    is.na(data[[cv_column]]),
    NA,
    data[[cv_column]] >= cv_review_threshold
  )

  data
}

# =========================================================
# ACS DATA SHAPING
# =========================================================

# Turn tidycensus's long output into one row per geography. Then calculate
# population shares and attach reliability fields for the birthplace measure.
# Keep one geometry per GEOID and join it back to the shaped attributes.
# Final GIS objects are always returned in WGS84 for sharing and export.
join_geometry <- function(
  attributes,
  raw_sf
) {
  geometry_data <- raw_sf %>%
    dplyr::filter(
      variable == names(acs_variables)[1]
    ) %>%
    dplyr::select(
      GEOID,
      geometry
    ) %>%
    dplyr::distinct(
      GEOID,
      .keep_all = TRUE
    )

  joined_data <- attributes %>%
    dplyr::left_join(
      geometry_data,
      by = "GEOID"
    ) %>%
    sf::st_as_sf() %>%
    sf::st_transform(4326)

  joined_data
}

# =========================================================
# QA AND EXPORT HELPERS
# =========================================================

# Wrap long chart and map source lines at word boundaries so captions stay
# inside the exported image. stringr::str_wrap() is the existing tidyverse
# tool built for this purpose; the helper keeps one width across the project.
wrap_plot_caption <- function(
  source_text,
  object_name,
  width = 95
) {
  full_caption <- paste0(
    source_text,
    object_name
  )

  wrapped_caption <- stringr::str_wrap(
    full_caption,
    width = width,
    whitespace_only = TRUE
  )

  wrapped_caption
}

# GEOID should uniquely identify every geography in a finished table.
assert_unique_geoid <- function(
  data,
  label
) {
  duplicate_count <- sum(
    duplicated(data$GEOID)
  )

  if (duplicate_count > 0) {
    stop(
      label,
      " contains ",
      duplicate_count,
      " duplicate GEOIDs."
    )
  }

  invisible(TRUE)
}

# Export a flat CSV after removing any sf geometry column.
write_csv_clean <- function(
  data,
  filename
) {
  output_path <- file.path(
    project_root,
    "data_clean",
    filename
  )

  data %>%
    sf::st_drop_geometry() %>%
    readr::write_csv(
      output_path,
      na = ""
    )
}

# Save a self-contained widget when Pandoc is available. Otherwise keep the
# HTML and its companion assets together in the exports folder.
save_interactive <- function(
  widget,
  filename
) {
  can_self_contain <- requireNamespace(
    "rmarkdown",
    quietly = TRUE
  ) && rmarkdown::pandoc_available()

  if (!can_self_contain) {
    log_message(
      "Pandoc is unavailable; saving ",
      filename,
      " with a companion asset folder."
    )
  }

  htmlwidgets::saveWidget(
    widget,
    file.path(project_root, "exports", filename),
    selfcontained = can_self_contain
  )
}

# =========================================================
# METRO-AREA FLAGS
# =========================================================

# Read PeeblesToolbox's official July 2023 OMB county-to-MSA lookup with a
# BOM-safe reader. This local wrapper can be retired after the toolbox fix.
add_project_metro_flags <- function(data) {
  lookup_path <- system.file(
    "extdata",
    "msa_counties_2023.csv",
    package = "peeblestoolbox"
  )

  if (!nzchar(lookup_path)) {
    stop("PeeblesToolbox MSA lookup is unavailable.")
  }

  metro_lookup <- readr::read_csv(
    lookup_path,
    show_col_types = FALSE,
    col_types = readr::cols(
      .default = readr::col_character()
    )
  ) %>%
    janitor::clean_names() %>%
    dplyr::transmute(
      GEOID = geoid,
      ga_msa_code = cbsa_code,
      ga_msa_name = cbsa_title,
      ga_msa_county_type = central_outlying,
      in_ga_msa = !is.na(cbsa_code),
      in_atlanta_msa = cbsa_code == "12060",
      msa_definition_date = delineation_date
    ) %>%
    dplyr::filter(
      substr(GEOID, 1, 2) == "13"
    )

  flagged_data <- data %>%
    dplyr::left_join(
      metro_lookup,
      by = "GEOID"
    )

  flagged_data
}
