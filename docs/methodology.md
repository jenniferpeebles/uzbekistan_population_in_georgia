# Methodology and adaptation notes

## What this measures

The default is the 2024 ACS five-year release (2020–2024 collection period).
B05006_066 estimates foreign-born residents born in Uzbekistan; B01001_001 is
the denominator for percent of total population. Script 01 verifies official
labels and saves an audit. B04006 has no separate Uzbek ancestry category in
this release. No ancestry number is inferred from birthplace or another group.
Birthplace does not identify ethnicity, language, current citizenship or all
people with Uzbek heritage. Foreign-born excludes people who were U.S. citizens
at birth. The release is a 60-month estimate, not an annual observation.

## Preserving the Iran project

The original sibling repository was used read-only. This separate Uzbekistan
project copies and adapts its download workflow and project helpers. It keeps
states/DC, national metropolitan areas, Georgia counties, places and tracts;
CV/MOE checks; national metro count and concentration comparisons; county,
place and tract geographic exploration; CSVs, interactive outputs, and WGS84
GeoJSON; and a deterministic reporter brief. The original remains unchanged.

The ancestry measure, two-measure comparison and ancestry-specific charts
cannot be reproduced for Uzbekistan from B04006. They are deliberately absent.
Birthplace maps replace the ancestry maps. The place analysis now runs inside
script 04 rather than a separate 04b script. No reliable places means an empty
place-ranking CSV and no place-ranking chart. Reusable theme, watermark,
plot-saving and GIS export functions continue to come from PeeblesToolbox.
The Iran project's caption-wrapping helper is retained.

## Source snapshots and coverage

`tidycensus::get_acs()` calls the Census ACS API. Product, variables and
geography are visible in scripts 00–02. Raw RDS responses and retrieval
timestamps are saved locally before shaping. The 2024 API root is
https://api.census.gov/data/2024/acs/acs5 . Variable metadata are cached by
tidycensus; rerunning for a different release verifies labels again.
Raw estimates/MOEs are retained in those responses; Census sentinel values are
handled by tidycensus as missing, never converted to population zero. These
snapshots do not retain every original API annotation; consult the source
E/EA/M/MA fields to investigate a missing value's cause.

State comparisons exclude Puerto Rico (51 rows retained). National metro
comparisons retain names ending in `Metro Area`, excluding micropolitan areas;
this universe can include Puerto Rico metros. Missing estimates remain visible
in clean tables and QA but cannot enter rankings. County estimates are checked
against the state estimate without dropping missing observations.

## Uncertainty

Count intervals are estimate ± 90% MOE, with the lower limit bounded at zero.
CV is `(MOE / 1.645) / estimate * 100`; it is undefined for zero estimates or
missing inputs. The review screen requires nonmissing estimates/MOEs, CV below
30%, and MOE no larger than estimate. These are editorial review rules, not
Census publication cutoffs. An interval reaching zero and a high CV are
separate flags. The source table preserves both.

Percentages are on a 0–100 scale. Percent MOEs use the Census subset-proportion
approximation, with the alternative addition formula when subtraction gives
a negative radicand. Missing denominator MOEs are **not** substituted with zero.
This intentionally corrects the inherited Iran helper's zero substitution;
the Iran project itself is not edited. Percent MOEs remain missing when an input
MOE is unavailable. A count-reliability screen is not a full assessment of
percentage precision, and descriptive ranks do not establish significant
differences. Metro count rankings retain nonmissing estimates with MOEs;
concentration rankings also require 100,000 total residents and count reliability.

## Geography and maps

The pipeline requests 2024 geography through tidycensus/tigris. Static Georgia
maps use NAD83 / Conus Albers, EPSG:5070. GeoJSON exports use WGS84, EPSG:4326;
script 04 reopens them and checks CRS and row counts. Five coastal 990000 tracts
have empty cartographic geometry in the initial run. QA permits empty geometry
only for zero-population tracts with that tract code, saves the affected rows,
and retains them in the tabular data. Drawable GeoJSON and maps exclude them.
Unexpected empty geometries stop QA.

All source rows are retained in clean tables. Map colors require passing count
reliability and population floors (places: 1,000; tracts: 500; counties: no
additional floor). Gray means unavailable or excluded, never a claim of zero.
Map exclusions are counted in `outputs/map_exclusions.csv`. An all-gray map
is a diagnostic of insufficient precision, not evidence of concentration.
Interactive maps retain estimate/MOE/CV details in popups.

County metro flags reuse PeeblesToolbox's bundled July 2023 OMB delineation
lookup, not a new hand-built county list. Its vintage is preserved on matched
records; it is not represented as an updated 2026 definition. Five-core-county
flags identify Clayton, Cobb, DeKalb, Fulton and Gwinnett. Verify a different
vintage against [OMB delineations](https://www.census.gov/programs-surveys/metro-micro/about/delineation-files.html).

Places retain CDPs, incorporated places and consolidated governments.
Macon-Bibb and Columbus are explicitly classified as consolidated governments
even though Census labels do not contain that phrase. Athens-Clarke and
Augusta-Richmond are government balances, not interchangeable with whole
counties. The four source records are exported for inspection.

## Country context and publication

The World Bank country API supplies a dated capital/country profile separately
from ACS data. FlagCDN supplies the flag, with source metadata saved beside it.
The government holiday source is linked in the README. Optional context
downloads cannot manufacture facts if unavailable. There is no live API call
inside GitHub Markdown: R retrieves facts and writes static Markdown.

All graphics are review drafts. No automated social posting, GitHub publishing,
or claim of human review occurs. README text lives in `docs/readme_template.md`;
script 06 inserts current computed findings. Small summary/audit files are
intentionally tracked, while large generated data and exports stay local.
