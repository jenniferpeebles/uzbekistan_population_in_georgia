# Purpose: Verify source variable identities before downloading observations.
# Inputs: 00 settings, Census metadata. Outputs: variable audit and dictionary.
# Assumption: No Uzbek ancestry substitute is permitted. Next: script 02.
source("scripts/00_config.R")
source("R/helpers.R")
available_variables <- tidycensus::load_variables(acs_year, acs_survey, cache = TRUE)
verified_variables <- available_variables %>%
  filter(name %in% unname(acs_variables)) %>%
  left_join(acs_variable_dictionary, by = c("name" = "variable"))
stopifnot(nrow(verified_variables) == length(acs_variables))
birthplace_label <- verified_variables$label[verified_variables$name == "B05006_066"]
stopifnot(length(birthplace_label) == 1, grepl("!!Uzbekistan$", birthplace_label),
          grepl("Foreign-Born", verified_variables$concept[verified_variables$name == "B05006_066"]))
ancestry_matches <- available_variables %>% filter(grepl("^B04006_", name), grepl("Uzbek", label, ignore.case = TRUE))
write_csv(ancestry_matches, "outputs/ancestry_variable_search.csv")
write_csv(verified_variables, "outputs/variable_reconnaissance.csv")
write_csv(acs_variable_dictionary, "outputs/data_dictionary.csv")
print(verified_variables)
log_message("Verified birthplace variable; separate B04006 Uzbek ancestry matches: ", nrow(ancestry_matches))
