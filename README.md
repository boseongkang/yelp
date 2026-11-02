# Yelp New Orleans Restaurant Analysis

## Data

Source: [Yelp Open Dataset](https://business.yelp.com/data/resources/open-dataset/) (Download JSON, 4.35 GB TAR, 8.65 GB uncompressed).

The raw JSON files are not committed because they are too large for GitHub (the review file alone is 5.0 GB). To reproduce:

1. Download and extract the dataset into `data/raw/`.
2. Run `R/import.R`.

## Progress

- [x] Import business and review JSON files ([R/import.R](R/import.R))
- [x] Filter to New Orleans restaurants: 2,259 businesses, 476,421 reviews
- [x] Save filtered data as compressed RDS in `data/new_orleans/`
