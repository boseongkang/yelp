# Import the Yelp JSON files, filter to New Orleans restaurants, and save as RDS.
# Raw files go in data/raw/ (not committed to GitHub).

library(tidyverse)
library(jsonlite)

business_file <- "data/raw/yelp_academic_dataset_business.json"
review_file   <- "data/raw/yelp_academic_dataset_review.json"

dir.create("data/new_orleans", recursive = TRUE, showWarnings = FALSE)

# Step 1: business file (small enough to read at once)

business_raw <- stream_in(file(business_file), verbose = FALSE)

business <- business_raw |>
  select(
    business_id, name, address, city, state, postal_code,
    latitude, longitude, stars, review_count, categories
  )

rm(business_raw)   # free memory

dim(business)
glimpse(business)

# Check how New Orleans is spelled in the city column before filtering
business |>
  filter(state == "LA") |>
  count(city, sort = TRUE) |>
  head(20)

# Step 2: filter to New Orleans restaurants

new_orleans_restaurants <- business |>
  filter(
    state == "LA",
    city == "New Orleans",
    !is.na(categories),
    str_detect(categories, regex("Restaurants", ignore_case = TRUE))
  ) |>
  mutate(
    postal_code = na_if(postal_code, ""),
    categories = str_squish(categories),
    business_name = str_squish(name)
  ) |>
  distinct(business_id, .keep_all = TRUE)

new_orleans_restaurants |>
  summarise(
    number_of_restaurants = n(),
    missing_latitude = sum(is.na(latitude)),
    missing_longitude = sum(is.na(longitude)),
    missing_categories = sum(is.na(categories))
  )

saveRDS(
  new_orleans_restaurants,
  "data/new_orleans/business_new_orleans.rds",
  compress = "xz"
)

# Step 3: review file, read in chunks
# The review file is too large to load at once on many laptops.
# stream_in() with a handler reads 50,000 lines at a time and keeps only
# reviews for New Orleans restaurants, so memory use stays small.

nola_ids <- new_orleans_restaurants$business_id
review_chunks <- list()

stream_in(
  file(review_file),
  handler = function(chunk) {
    kept <- chunk[chunk$business_id %in% nola_ids,
                  c("review_id", "business_id", "user_id", "stars", "date",
                    "text", "useful", "funny", "cool")]
    if (nrow(kept) > 0) {
      review_chunks[[length(review_chunks) + 1]] <<- kept
    }
  },
  pagesize = 50000,
  verbose = TRUE   # prints progress so you can see it is still running
)

new_orleans_reviews <- bind_rows(review_chunks)
rm(review_chunks)

dim(new_orleans_reviews)
glimpse(new_orleans_reviews)

# Every review should belong to a saved restaurant (should be 0)
sum(!new_orleans_reviews$business_id %in% nola_ids)

saveRDS(
  new_orleans_reviews,
  "data/new_orleans/reviews_new_orleans.rds",
  compress = "xz"
)

# Step 4: check file sizes (GitHub blocks files over 100 MB)

file.size(list.files("data/new_orleans", full.names = TRUE)) / 1e6   # MB
