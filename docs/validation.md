# Validation record — August 30, 2026

The full pipeline completed with R 4.5.3, using cached Census observations from
this project's live API download. It regenerated the data, QA, figures,
interactive files, country facts, reporter brief and README.

- Coverage: 51 states/DC, 393 metropolitan areas, 159 Georgia counties,
  675 Georgia places and 2,796 tracts. No duplicate geography IDs or impossible
  birthplace estimates were found. Six metro estimates/MOEs were missing.
- County birthplace estimates sum to Georgia's 1,705 estimate exactly.
  Georgia's 90% MOE is 1,434 and CV is 51.1%. No local Georgia estimates pass
  the CV/MOE screen; no reliable place-ranking chart is produced.
- All tested geometries are valid. Five zero-population coastal water tracts
  have empty cartographic geometry and are accounted for separately.
  Drawable GeoJSON exports were reopened and checked for EPSG:4326 and row counts.
- All six PNG review figures and the flag were visually inspected. Captions
  fit; static maps use white backgrounds and review watermarks.
- README text, including its emoji, date range, estimate and MOE, was inspected
  after fixing Windows C-locale substitution. Country JSON parsing was also
  corrected and the API capital field verified as Tashkent.

Remaining environment warnings are from character transliteration under R's
C locale, Plotly's unsupported custom watermark annotation, and pre-existing
HTML companion directories on reruns. The static graphics retain their
watermarks; do not assume Plotly carries that annotation over. Pandoc is not
available here, so HTML files must stay with their companion asset folders.
Interactive files were generated, but their browser interactions have not
been manually tested. Session details and warning messages are saved locally
under `outputs/`.

At initial validation, the Uzbekistan folder had its own initialized Git
repository on `main`, with no remote, commit or publication. Jennifer later
authorized pushing it to her separate private GitHub repository for review;
it must remain private until she chooses to make it public. All Iran-project access in this task
was read-only. A Git status check on the Iran repository was blocked by Git's
mixed-ownership safety check; no trust settings or Iran files were changed.

Before public release, review the prose and the uncertainty warning. A small
point estimate with a very large MOE is the principal reporting limitation,
not something additional mapping can resolve. The missing Uzbek ancestry
category prevents a like-for-like copy of the Iran project's two measures.
