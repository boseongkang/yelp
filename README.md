

# Where to Find the Best East Asian Food in New Orleans

**Research question:** Where can someone find the best East Asian
(Korean, Japanese, and Chinese) restaurants in New Orleans, and which
neighborhood is best for finding them?

**[View the complete report](https://boseongkang.github.io/yelp/)**
(tables, maps, code, and methods)

## Executive summary

Using 2,259 New Orleans restaurants and 476,421 reviews from the Yelp
Open Dataset, I selected the East Asian restaurants inside the city,
placed them in the city’s official neighborhoods, and ranked them with a
reviewer adjusted score that removes how generous or strict each
reviewer usually is. The top ranked restaurant is **The Wandering
Buddha** in St. Roch, and the best neighborhood after adjustment is
**Gert Town**. Both leads are narrow, and the best area changes if ZIP
codes are used instead of neighborhoods; the report explains these
limits.

## Main findings

1.  **Gert Town** has the highest reviewer adjusted score among
    neighborhoods with at least 5 East Asian restaurants. By the
    ordinary Yelp average, Lower Garden District is first by only 0.02
    stars, effectively a tie. Gert Town’s lead on the adjusted score is
    small (0.17 against 0.13 for second place).
2.  **The best restaurants are spread out.** 5 of the top 10 are in one
    of the 5 neighborhoods with at least 5 East Asian restaurants, and
    the other 5 are in neighborhoods with fewer, including the number
    one restaurant. For the most choice, Central Business District has
    the most East Asian restaurants (17).
3.  **Most of the top group holds, the exact order does not.** When the
    way reviewer habits are measured is changed (6 settings), 5 to 10 of
    the main top 10 stay in the top 10 (5 of the 6 settings keep at
    least 7), but the number one restaurant changes: The Wandering
    Buddha is first in 2 of the 6 settings. The list is best read as a
    set of strong East Asian restaurants rather than a strict ranking.

![Top 10 East Asian restaurants in New
Orleans](figures/final_top10_map.png)

| Rank | Restaurant | Cuisine | Neighborhood | Reviews | Raw average | Eligible reviews | Normalized score |
|---:|:---|:---|:---|---:|---:|---:|---:|
| 1 | The Wandering Buddha | Korean | St. Roch | 45 | 4.51 | 7 | 0.82 |
| 2 | Yo Nashi | Japanese | Central Business District | 40 | 4.45 | 6 | 0.77 |
| 3 | Nagomi | Japanese | St. Claude | 24 | 4.96 | 10 | 0.73 |
| 4 | Mister Mao | Chinese | West Riverside | 29 | 4.66 | 8 | 0.67 |
| 5 | Foodies Destination | Korean | Tulane - Gravier | 20 | 4.60 | 5 | 0.65 |
| 6 | Oishii Sushi House | Japanese | Tall Timbers - Brechtel | 82 | 4.48 | 10 | 0.58 |
| 7 | Asuka Sushi & Hibachi | Japanese | Gert Town | 316 | 4.40 | 45 | 0.43 |
| 8 | Gyu-Kaku Japanese BBQ | Japanese | Central Business District | 334 | 4.39 | 46 | 0.39 |
| 9 | Union Ramen | Japanese | Lower Garden District | 156 | 4.37 | 30 | 0.36 |
| 10 | Blue Giant | Chinese | Lower Garden District | 194 | 4.13 | 46 | 0.33 |

![Reviewer adjusted score by
neighborhood](figures/neighborhood_adjusted.png)

## Repository contents and source code

| Path | Contents |
|----|----|
| [`yelp_new_orleans_project.qmd`](yelp_new_orleans_project.qmd) | Source of the full report (Steps 1 to 7, top 10, AI prompts) |
| [`docs/index.html`](docs/index.html) | Rendered report, published with GitHub Pages |
| [`R/import.R`](R/import.R) | Imports the raw JSON files, filters to New Orleans restaurants, saves RDS |
| [`README.qmd`](README.qmd) | Source of this README (reads the result tables in `output/`) |
| [`renv.lock`](renv.lock) | Package versions used |
| [`analysis.qmd`](analysis.qmd), [`analysis.md`](analysis.md) | Homework 6 version of Steps 3 to 6 (geographic system comparison), made before the inclusion rule was tightened |
| [`data/new_orleans/`](data/new_orleans) | Filtered business and review data (compressed RDS) |
| [`data/boundaries/`](data/boundaries) | New Orleans Neighborhood Statistical Areas (data.nola.gov) |
| [`figures/`](figures) | Saved figures used in this README |
| [`output/`](output) | Result tables (top 10, neighborhood comparison, restaurant summary, reviewer thresholds, sensitivity) |

## Data and reproduction

Data source: [Yelp Open
Dataset](https://business.yelp.com/data/resources/open-dataset/)
(Download JSON: 4.35 GB TAR, 8.65 GB uncompressed). Neighborhood
boundaries: City of New Orleans Neighborhood Statistical Areas
(data.nola.gov, dataset `exvn-jeh2`). Census places, tracts, and ZIP
code areas are downloaded with the `tigris` package.

The raw JSON files are **not committed** because they are too large for
GitHub (the review file alone is 5.0 GB). To reproduce:

1.  Download the Yelp JSON dataset and extract it into `data/raw/` (git
    ignored). Only `yelp_academic_dataset_business.json` and
    `yelp_academic_dataset_review.json` are used.
2.  Run `R/import.R` once. It reads the review file in chunks and saves
    the filtered data to `data/new_orleans/`.
3.  Render the report:
    `quarto render yelp_new_orleans_project.qmd --output-dir docs`
4.  Render this README: `quarto render README.qmd`

Package versions used for the report are recorded in `renv.lock` (and
printed at the end of the report with `sessionInfo()`);
`renv::restore()` installs the same versions.

The report is published from the `docs/` folder with GitHub Pages
(Settings, Pages, Deploy from a branch, `main`, `/docs`).
