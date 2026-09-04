# Purpose: Generate current findings and reporter-facing analytical outputs.
# Inputs: QA-approved ACS tables.
# Outputs: Reporter brief, social draft, session info and summary CSV.
# Assumption: Generated text is unreviewed; no claim of publication approval.
# Run last after scripts 01–05. Numbers always come from this run's objects.
source("scripts/00_config.R")
source("R/helpers.R")
states <- read_clean(paste0("data_clean/states_acs_", acs_year, ".csv"))
qa <- read_csv("outputs/qa_summary.csv", show_col_types = FALSE)
ga <- filter(states, GEOID == "13")
stopifnot(nrow(ga) == 1, !is.na(ga$uzbekistan_born_foreign_born),
          !is.na(ga$uzbekistan_born_foreign_born_moe), all(qa$impossible == 0))
fmt <- function(x) scales::comma(x, accuracy = 1)
estimate <- fmt(ga$uzbekistan_born_foreign_born)
moe <- fmt(ga$uzbekistan_born_foreign_born_moe)
interval <- paste0(fmt(ga$uzbekistan_born_foreign_born_ci90_lower), "–", fmt(ga$uzbekistan_born_foreign_born_ci90_upper))
reliability_text <- if (reliable_estimate(ga)) {
  "The statewide estimate passes this project's CV/MOE screen, but remains a survey estimate."
} else {
  "The statewide estimate fails this project's reliability screen. Treat it as an uncertain estimate, not a precise count."
}
headline <- paste0("The **", acs_product_label, "** estimate **", estimate,
                   " foreign-born Georgia residents born in Uzbekistan**, with a **90% margin of error of ±", moe,
                   "**. The approximate 90 percent confidence interval is **", interval, "** residents. ", reliability_text)
local_qa <- filter(qa, dataset %in% c("counties", "places", "tracts"))
local_note <- if (all(local_qa$reliability_eligible == 0)) {
  "No Georgia county, place or tract estimate passes the project's reliability screen. Do not use these estimates to name a biggest local community. Local maps are gray because the estimates fail the screen, not because nobody lives there."
} else {
  paste0("Local estimates passing the reliability screen: ",
         paste(paste(local_qa$dataset, local_qa$reliability_eligible, sep = ": "), collapse = "; "),
         ". Population floors may exclude additional places and tracts. Rankings do not establish statistically significant differences.")
}
social_caution <- if (reliable_estimate(ga)) "That's a survey estimate, not a count of everyone with Uzbek heritage." else "That's a very uncertain survey estimate, not a count of everyone with Uzbek heritage."
social <- paste0("Happy Independence Day, Uzbekistan! Sept. 1 is a chance to celebrate our Georgia neighbors with ties to Uzbekistan. ",
                 "The ", acs_product_label, " put Georgia's foreign-born population born in Uzbekistan at about ", estimate,
                 " (90% margin of error: ±", moe, "). ", social_caution)
writeLines(social, "outputs/social_post_draft.txt", useBytes = TRUE)
brief <- c("# Reporter brief", "", headline, "", "## Geographic caution", "", local_note, "",
           paste0("Statewide coefficient of variation: ", round(ga$uzbekistan_born_foreign_born_cv, 1),
                  "%. The review threshold is ", cv_review_threshold, "%."), "",
           "## Suggested social post (review before posting)", "", social, "",
           "## Questions for reporting", "",
           "Ask community organizations how birthplace differs from the community they serve. Can they describe Georgia ties without treating this survey estimate as a census of Uzbek ethnicity?", "",
           "## Do not overstate", "",
           "Foreign-born birthplace excludes U.S.-born descendants and people born abroad who were U.S. citizens at birth. It can include people of many ethnicities. These are pooled five-year estimates, not the number living here today.")
writeLines(brief, "outputs/reporter_brief.md", useBytes = TRUE)
summary <- ga %>% select(GEOID, NAME, starts_with("uzbekistan")) %>%
  mutate(acs_year = acs_year, collection_period = acs_product_label, variable = "B05006_066", generated = as.character(Sys.Date()))
write_csv(summary, "outputs/georgia_summary.csv")
writeLines(capture.output(sessionInfo()), "outputs/session_info.txt")
log_message("Reporter brief and machine-readable summary generated from current data.")
