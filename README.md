# Yelp New Orleans Restaurant Analysis

**Research question:** Where can someone find the best East Asian (Korean, Japanese, and Chinese) restaurants in New Orleans, and which neighborhood is best for finding them?

**Analysis through Step 6:** [analysis.md](analysis.md) (tables and maps, viewable on GitHub). Source: [analysis.qmd](analysis.qmd).

## Data

Source: [Yelp Open Dataset](https://business.yelp.com/data/resources/open-dataset/) (Download JSON, 4.35 GB TAR, 8.65 GB uncompressed).

The raw JSON files are not committed because they are too large for GitHub (the review file alone is 5.0 GB). To reproduce:

1. Download and extract the dataset into `data/raw/`.
2. Run `R/import.R`.
3. Render `analysis.qmd` with `quarto render analysis.qmd`.

Neighborhood boundaries: City of New Orleans Neighborhood Statistical Areas (data.nola.gov, dataset `exvn-jeh2`), saved in `data/boundaries/`. Census places, tracts, and ZCTAs are downloaded with `tigris`.

## Progress

- [x] Import business and review JSON files ([R/import.R](R/import.R))
- [x] Filter to New Orleans restaurants: 2,259 businesses, 476,421 reviews
- [x] Save filtered data as compressed RDS in `data/new_orleans/`
- [x] Select East Asian categories: 145 restaurants, 18,141 reviews
- [x] Spatial join with the Census place boundary
- [x] Compare Neighborhood Statistical Areas, Census tracts, and ZIP codes; choose Neighborhood Statistical Areas
- [ ] Reviewer adjusted ratings (Step 7)
- [ ] Final report and top 10 restaurants
