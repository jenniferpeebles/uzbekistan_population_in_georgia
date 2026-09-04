# Happy Independence Day, Uzbekistan! 🇺🇿

<img src="https://flagcdn.com/w320/uz.png" alt="Flag of Uzbekistan" width="320">

Sept. 1 is **Uzbekistan's Independence Day** — a lovely occasion to learn a little about the country and the people who connect it to Georgia, the U.S. state. Uzbekistan declared independence on Aug. 31, 1991; the national holiday is celebrated Sept. 1. [Holiday source: Government of Uzbekistan](https://gov.uz/en/rishton/news/view/74095).

This R project follows a simple idea: celebrate a country's national day, share what public data can tell us about our neighbors, and make the code available for anyone who wants to follow along. Welcome!

## How many Georgia residents were born in Uzbekistan?

The **2020-2024 ACS five-year estimates** estimate **1,705 foreign-born Georgia residents born in Uzbekistan**, with a **90% margin of error of ±1,434**. The approximate 90 percent confidence interval is **271–3,139** residents. The statewide estimate fails this project's reliability screen. Treat it as an uncertain estimate, not a precise count.

The uncertainty matters! Keep the margin of error beside the estimate whenever you share it. These data describe **2020-2024 ACS five-year estimates**, not a head count on Independence Day.

**Why “born in Uzbekistan” instead of simply “Uzbek”?** Uzbek can refer to ethnicity or language, while this Census measure is about birthplace. People born in Uzbekistan can have different ethnic backgrounds, and people of Uzbek heritage can be born elsewhere. This measure excludes U.S.-born descendants and people born abroad who were U.S. citizens at birth. It is not a citizenship, language or complete diaspora count.

The variable is [B05006_066: Uzbekistan](https://api.census.gov/data/2024/acs/acs5/groups/B05006.html), in the ACS foreign-born place-of-birth table. The "Iranian population in Georgia" coding" project that served as the basis for this Uzbekistan project also measured ancestry; unfortunately, ACS Table [B04006](https://api.census.gov/data/2024/acs/acs5/groups/B04006.html) does **not** offer a separate Uzbek ancestry category in this release. No broader category has been substituted.

## A little country context

A little geography to go with the celebration: Uzbekistan's capital is **Tashkent**. This fact comes from the [World Bank country API](https://api.worldbank.org/v2/country/UZ?format=json), retrieved 2026-08-30. The API supplies country context; it does not supply the Georgia estimate.

[Explore Uzbekistan on OpenStreetMap](https://www.openstreetmap.org/#map=5/41.3/64.5). The flag is downloaded from [FlagCDN](https://flagcdn.com/w320/uz.png); its source and retrieval date are saved beside the image. The project uses a real flag asset, not an AI-generated approximation.

## A suggested social post if you want to share!

> Happy Independence Day, Uzbekistan! Sept. 1 is a chance to celebrate our Georgia neighbors with ties to Uzbekistan. The 2020-2024 ACS five-year estimates put Georgia's foreign-born population born in Uzbekistan at about 1,705 (90% margin of error: ±1,434). That's a very uncertain survey estimate, not a count of everyone with Uzbek heritage.

Add the public repository link after publication. This is a draft for human review, not an automatically posted message.

## Run it yourself

1. Open `uzbekistan_population_in_georgia.Rproj` in RStudio.
2. Install the CRAN packages listed in `scripts/00_config.R`. Install PeeblesToolbox with `pak::pak("jenniferpeebles/peeblestoolbox@v0.3.0")`.
3. You'll need a free [Census API key](https://api.census.gov/data/key_signup.html) from the Census Bureau. Put `CENSUS_API_KEY=your_key_here` in your **user-level** `.Renviron` and restart R. Never put a key in the code repository.
4. Run `source("run_all.R")` from the project root.

Internet access is needed for Census data and boundaries, variable metadata and optional country context, but if you're reading this online, I'm guessing you have that already. Source observations are cached locally; set `refresh_downloads <- TRUE` in `scripts/00_config.R` to replace them. The default release is 2024, pooling 2020–2024 responses. Changing the release requires rechecking variables, geography and documentation; a new variable code is never guessed automatically.

**Editing this README:** edit `docs/readme_template.md`, then rerun script 06 after the pipeline. It generates the numerical text from current outputs and overwrites `README.md`. Do not hand-edit a result into the generating code.

## What's in the project?

| Script | What it does |
|---|---|
| `00_config.R` | Editable settings, folders, package and key checks |
| `01_variable_reconnaissance.R` | Verifies Census variable labels and audits the ancestry-table limitation |
| `02_download_and_prepare.R` | Adapts the Iran project's state, national metro, Georgia county, place and tract downloads |
| `03_quality_assurance.R` | Checks coverage, duplicate IDs, missing values, uncertainty, geographic issues and county/state reconciliation |
| `04_charts_maps_interactives.R` | Builds review charts, static and interactive maps, rankings and WGS84 GeoJSON |
| `05_country_facts.R` | Retrieves a World Bank country profile and flag image |
| `06_reporter_brief_readme.R` | Generates the reporter brief, suggested post and this README |

Start with [the reporter brief](outputs/reporter_brief.md), [Georgia summary](outputs/georgia_summary.csv) and [QA summary](outputs/qa_summary.csv). Detailed generated data, maps and interactives are produced locally and ignored by Git; small review summaries and the flag are retained for public transparency. Static analysis graphics carry **NOT FOR PUBLICATION** watermarks, but you can always tweak the code to remove those

## Please carry the caveats with the numbers

No Georgia county, place or tract estimate passes the project's reliability screen. Do not use these estimates to name a biggest local community. Local maps are gray because the estimates fail the screen, not because nobody lives there.

- Estimates and 90 percent margins of error stay together. The project flags a coefficient of variation (CV) of 30 percent or more and an MOE larger than the estimate. A zero estimate does not prove absence.
- No missing values are imputed. Missing denominator MOEs mean percentage MOEs remain unavailable; source annotations can be inspected in the Census API.
- Metro concentration rankings require at least 100,000 total residents and a passing birthplace reliability screen. Rank differences are descriptive, not significance tests.
- Maps use 2024 Census cartographic boundaries. Static Georgia maps use WGS 84 / Pseudo-Mercator (Web Mercator; EPSG:3857); GIS handoff files use WGS84 (EPSG:4326). Coastal water-only tracts without drawable geometry remain in data tables and are documented separately.
- Georgia places include incorporated places, census-designated places and consolidated governments. A government “balance” is not necessarily the entire county.

Read [the methodology and adaptation notes](docs/methodology.md) for the full accounting of what carried over from the Iranian population project and what could not.

## Special thanks
This project uses a number of R packages, including the [tidyverse family of packages](https://tidyverse.tidyverse.org/index.html) created by [Hadley Wickham](https://hadley.nz/) et al and the [tigris package](https://cran.r-project.org/web/packages/tigris/index.html) created by [Kyle Walker](https://walker-data.com/) that downloads and works with U.S. Census Bureau TIGER/Line geographic files. I am also very grateful for packages including [janitor](https://cran.r-project.org/web/packages/janitor/index.html) and [sf](https://cran.r-project.org/web/packages/sf/index.html), among others. Thank you to the brilliant people behind these packages who wrote all the code and keep it maintained.

## About this project

Built for Jennifer Peebles' national-holiday data posts, adapted from her Iranian population in Georgia R project. This repository is prepared for eventual public sharing; generating it does not publish it or post to social media.

> A note from JP: I built this project with help from ChatGPT/Codex, which drafted this README from the project's code, outputs and my instructions. I want to be transparent about the help I received.

[Jennifer Peebles](https://www.ajc.com/staff/jennifer-peebles/) / [Atlanta Journal-Constitution](https://www.ajc.com/)

Generated from the project outputs on 2026-09-04. Human editorial review is still needed before publication.
