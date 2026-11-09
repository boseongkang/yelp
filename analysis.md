# East Asian Restaurants in New Orleans: Steps 3 to 6


- [Summary for Steps 1 to 6](#summary-for-steps-1-to-6)
- [Setup](#setup)
- [Step 3: Select related restaurant
  categories](#step-3-select-related-restaurant-categories)
  - [Split the comma separated
    categories](#split-the-comma-separated-categories)
  - [Starting point: Korean food](#starting-point-korean-food)
  - [Expanding to East Asian food](#expanding-to-east-asian-food)
  - [Co-occurrence among the selected
    categories](#co-occurrence-among-the-selected-categories)
  - [Inclusion rule](#inclusion-rule)
- [Step 4: Join businesses to
  reviews](#step-4-join-businesses-to-reviews)
- [Step 5: Spatial join with the Census place
  boundary](#step-5-spatial-join-with-the-census-place-boundary)
- [Step 6: Compare geographic
  systems](#step-6-compare-geographic-systems)
  - [Load the boundaries](#load-the-boundaries)
  - [Spatial join for each system](#spatial-join-for-each-system)
  - [Area level results](#area-level-results)
  - [Maps](#maps)
  - [Unmatched restaurants](#unmatched-restaurants)
- [Decision: Neighborhood Statistical
  Areas](#decision-neighborhood-statistical-areas)
  - [How much the minimum rule keeps](#how-much-the-minimum-rule-keeps)
  - [Check against ZIP codes](#check-against-zip-codes)

**Research question:** Where can someone find the best East Asian
(Korean, Japanese, and Chinese) restaurants in New Orleans, and which
neighborhood is best for finding them?

## Summary for Steps 1 to 6

**Region chosen: New Orleans Neighborhood Statistical Areas (NSA),
ranking only neighborhoods with at least 5 East Asian restaurants.**

- **Why:** NSAs are official city neighborhoods with names visitors
  recognize, which fits a question about where to go. Census tracts were
  too small (median 1 restaurant per tract), and ZIP codes gave larger
  counts but are postal areas, not neighborhoods, and extend outside the
  city into Jefferson Parish. The minimum of 5 keeps 8 neighborhoods (76
  of 135 restaurants) so averages do not rest on one or two restaurants.
- **Check:** The top neighborhood, St. Claude, is also inside the top
  ranked ZIP code (70117), so the main finding does not depend on the
  boundary choice.
- **Where to look:** the comparison table and three maps are in [Step
  6](#step-6-compare-geographic-systems), and the reasoning is in
  [Decision](#decision-neighborhood-statistical-areas).

Steps 1 and 2 (import, filter to New Orleans, save RDS) are in
[`R/import.R`](R/import.R). This file covers category selection (Step
3), the business to review join (Step 4), the Census place spatial join
(Step 5), and the comparison of geographic systems (Step 6).

## Setup

``` r
library(tidyverse)
library(sf)
library(tigris)
library(knitr)

options(tigris_use_cache = TRUE)
dir.create("figures", showWarnings = FALSE)
dir.create("data/boundaries", recursive = TRUE, showWarnings = FALSE)

nola <- readRDS("data/new_orleans/business_new_orleans.rds")
reviews <- readRDS("data/new_orleans/reviews_new_orleans.rds")

dim(nola)
```

    [1] 2259   12

``` r
dim(reviews)
```

    [1] 476421      9

## Step 3: Select related restaurant categories

### Split the comma separated categories

``` r
restaurant_categories <- nola |>
  select(business_id, categories) |>
  separate_rows(categories, sep = ",") |>
  mutate(category = str_to_lower(str_squish(categories))) |>
  filter(category != "") |>
  distinct(business_id, category)

category_counts <- restaurant_categories |>
  count(category, sort = TRUE)

category_counts |>
  slice_head(n = 20) |>
  kable(caption = "Most common categories among New Orleans restaurants")
```

| category                  |    n |
|:--------------------------|-----:|
| restaurants               | 2259 |
| food                      |  725 |
| nightlife                 |  540 |
| bars                      |  508 |
| cajun/creole              |  401 |
| breakfast & brunch        |  367 |
| sandwiches                |  354 |
| seafood                   |  331 |
| american (new)            |  323 |
| american (traditional)    |  299 |
| coffee & tea              |  208 |
| burgers                   |  202 |
| cafes                     |  173 |
| pizza                     |  172 |
| cocktail bars             |  160 |
| event planning & services |  156 |
| southern                  |  155 |
| fast food                 |  142 |
| mexican                   |  124 |
| salad                     |  124 |

Most common categories among New Orleans restaurants

### Starting point: Korean food

I started with Korean food, but only a handful of New Orleans
restaurants carry the Korean category, which is below the project
minimum of 10 restaurants in 7 areas.

``` r
korean_ids <- restaurant_categories |>
  filter(category == "korean") |>
  distinct(business_id)

nrow(korean_ids)
```

    [1] 6

``` r
restaurant_categories |>
  semi_join(korean_ids, by = "business_id") |>
  filter(!category %in% c("korean", "restaurants")) |>
  count(category, sort = TRUE) |>
  kable(caption = "Categories that appear together with Korean")
```

| category       |   n |
|:---------------|----:|
| food           |   2 |
| asian fusion   |   1 |
| barbeque       |   1 |
| cajun/creole   |   1 |
| ethnic food    |   1 |
| food court     |   1 |
| food trucks    |   1 |
| gluten-free    |   1 |
| imported food  |   1 |
| soup           |   1 |
| specialty food |   1 |
| vegan          |   1 |
| vegetarian     |   1 |
| vietnamese     |   1 |

Categories that appear together with Korean

### Expanding to East Asian food

I expanded the theme to the East Asian food tradition that Korean food
belongs to: Korean, Japanese, and Chinese, plus their sub styles (sushi
bars and ramen for Japanese; dim sum, Szechuan, and Taiwanese for
Chinese). Southeast Asian categories (Vietnamese, Thai) and nationality
neutral labels (Asian Fusion, Noodles, Poke) are excluded so the group
stays conceptually consistent.

``` r
core_categories <- c("korean", "japanese", "chinese")
sub_categories <- c("sushi bars", "ramen", "dim sum", "szechuan", "taiwanese")
selected_categories <- c(core_categories, sub_categories)

considered <- c(selected_categories, "vietnamese", "thai", "asian fusion",
                "noodles", "poke")

category_counts |>
  filter(category %in% considered) |>
  mutate(decision = if_else(category %in% selected_categories,
                            "included", "excluded")) |>
  kable(caption = "Asian categories considered")
```

| category     |   n | decision |
|:-------------|----:|:---------|
| chinese      |  69 | included |
| vietnamese   |  57 | excluded |
| japanese     |  54 | included |
| asian fusion |  53 | excluded |
| sushi bars   |  50 | included |
| thai         |  25 | excluded |
| noodles      |  15 | excluded |
| ramen        |  11 | included |
| poke         |   9 | excluded |
| korean       |   6 | included |
| dim sum      |   4 | included |
| taiwanese    |   3 | included |
| szechuan     |   2 | included |

Asian categories considered

``` r
category_counts |>
  filter(category %in% considered) |>
  mutate(
    decision = if_else(category %in% selected_categories, "Included", "Excluded"),
    category = fct_reorder(str_to_title(category), n)
  ) |>
  ggplot(aes(x = n, y = category, fill = decision)) +
  geom_col() +
  scale_fill_manual(values = c(Included = "#C0392B", Excluded = "grey70")) +
  labs(
    title = "Asian Restaurant Categories in New Orleans",
    x = "Number of restaurants", y = NULL, fill = NULL
  ) +
  theme_minimal()
```

![](analysis_files/figure-commonmark/unnamed-chunk-5-1.png)

``` r
ggsave("figures/category_counts.png", width = 7, height = 4, dpi = 150)
```

### Co-occurrence among the selected categories

``` r
selected_category_rows <- restaurant_categories |>
  filter(category %in% selected_categories)

selected_category_rows |>
  inner_join(selected_category_rows, by = "business_id",
             relationship = "many-to-many") |>
  filter(category.x < category.y) |>
  count(category.x, category.y, sort = TRUE, name = "restaurants") |>
  kable(caption = "Pairs of selected categories on the same restaurant")
```

| category.x | category.y | restaurants |
|:-----------|:-----------|------------:|
| japanese   | sushi bars |          32 |
| japanese   | ramen      |          11 |
| chinese    | dim sum    |           4 |
| ramen      | sushi bars |           3 |
| chinese    | japanese   |           2 |
| chinese    | sushi bars |           2 |
| chinese    | szechuan   |           2 |
| chinese    | taiwanese  |           1 |
| dim sum    | szechuan   |           1 |
| dim sum    | taiwanese  |           1 |
| japanese   | taiwanese  |           1 |
| szechuan   | taiwanese  |           1 |

Pairs of selected categories on the same restaurant

### Inclusion rule

A restaurant is included if it has **at least one** of the selected
categories. Each restaurant also gets one cuisine label for maps (Korean
first, then Japanese, then Chinese).

``` r
selected_ids <- selected_category_rows |>
  distinct(business_id)

selected_restaurants <- nola |>
  semi_join(selected_ids, by = "business_id") |>
  mutate(
    cat_lower = str_to_lower(categories),
    cuisine = case_when(
      str_detect(cat_lower, "korean") ~ "Korean",
      str_detect(cat_lower, "japanese|sushi bars|ramen") ~ "Japanese",
      str_detect(cat_lower, "chinese|dim sum|szechuan|taiwanese") ~ "Chinese"
    )
  ) |>
  select(-cat_lower)

nrow(selected_restaurants)
```

    [1] 145

``` r
selected_restaurants |>
  count(cuisine) |>
  kable(caption = "Selected East Asian restaurants by cuisine label")
```

| cuisine  |   n |
|:---------|----:|
| Chinese  |  67 |
| Japanese |  72 |
| Korean   |   6 |

Selected East Asian restaurants by cuisine label

The group has 145 restaurants. Step 6 shows that the 135 inside the city
fall in 43 different neighborhoods, so the project minimum of 10
restaurants in at least 7 geographic areas is met.

## Step 4: Join businesses to reviews

Reviews are filtered to the selected restaurants before any further
analysis.

``` r
east_asian_reviews <- reviews |>
  semi_join(selected_restaurants, by = "business_id")

review_summary <- east_asian_reviews |>
  group_by(business_id) |>
  summarise(
    n_reviews = n(),
    avg_review_stars = mean(stars, na.rm = TRUE),
    .groups = "drop"
  )

selected_restaurants <- selected_restaurants |>
  left_join(review_summary, by = "business_id")

tibble(
  restaurants = nrow(selected_restaurants),
  reviews = nrow(east_asian_reviews),
  reviewers = n_distinct(east_asian_reviews$user_id),
  restaurants_without_reviews = sum(is.na(selected_restaurants$n_reviews))
) |>
  kable(caption = "Business to review join")
```

| restaurants | reviews | reviewers | restaurants_without_reviews |
|------------:|--------:|----------:|----------------------------:|
|         145 |   18141 |     12521 |                           0 |

Business to review join

## Step 5: Spatial join with the Census place boundary

The Yelp `city` field is a text label. Here every New Orleans restaurant
is placed inside the official Census place polygon that contains its
coordinates.

``` r
la_places <- places(state = "LA", cb = TRUE, year = 2024, class = "sf") |>
  st_transform(4326)

new_orleans_boundary <- la_places |>
  filter(NAME == "New Orleans")

all_points <- nola |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

all_with_place <- all_points |>
  st_join(la_places |> select(place_name = NAME), join = st_within, left = TRUE)

all_with_place |>
  st_drop_geometry() |>
  count(city, place_name, sort = TRUE) |>
  kable(caption = "Yelp city label compared with the Census place")
```

| city        | place_name  |    n |
|:------------|:------------|-----:|
| New Orleans | New Orleans | 2202 |
| New Orleans | Elmwood     |   18 |
| New Orleans | Jefferson   |   13 |
| New Orleans | Harahan     |   10 |
| New Orleans | Terrytown   |    4 |
| New Orleans | Metairie    |    3 |
| New Orleans | River Ridge |    3 |
| New Orleans | Arabi       |    2 |
| New Orleans | Harvey      |    2 |
| New Orleans | Gretna      |    1 |
| New Orleans | Kenner      |    1 |

Yelp city label compared with the Census place

**Mismatches.** 2,202 of the 2,259 restaurants labeled “New Orleans” by
Yelp are inside the official New Orleans boundary. The other 57 have
coordinates in neighboring places (Elmwood, Jefferson, Harahan,
Metairie, and others), mostly in Jefferson Parish. These businesses use
a New Orleans mailing address, but they are outside the city, so they
are not deleted from the data; they are reported as unmatched in Step 6
and left out of the neighborhood comparison.

``` r
all_with_place |>
  st_drop_geometry() |>
  filter(place_name != "New Orleans" | is.na(place_name)) |>
  count(postal_code, sort = TRUE) |>
  kable(caption = "ZIP codes of restaurants outside the New Orleans boundary")
```

| postal_code |   n |
|:------------|----:|
| 70123       |  27 |
| 70121       |  17 |
| 70056       |   4 |
| 70001       |   2 |
| 70032       |   2 |
| 70058       |   2 |
| 70005       |   1 |
| 70053       |   1 |
| 70115       |   1 |

ZIP codes of restaurants outside the New Orleans boundary

Almost all of these ZIP codes (70123, 70121, 70001, 70005 and others)
belong to suburbs next to the city, which confirms that the mismatch
comes from mailing addresses, not from errors in the data. The one
exception is a restaurant with the Uptown New Orleans ZIP code 70115
whose coordinates fall just outside the boundary; this looks like a
coordinate or boundary edge issue and is flagged for checking rather
than treated as a suburban restaurant.

``` r
selected_points <- selected_restaurants |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

ggplot() +
  geom_sf(data = new_orleans_boundary, fill = "grey95", color = "grey40") +
  geom_sf(data = selected_points, aes(color = cuisine), size = 2, alpha = 0.8) +
  scale_color_manual(values = c(Korean = "#C0392B", Japanese = "#2E86C1",
                                Chinese = "#D4AC0D")) +
  labs(
    title = "East Asian Restaurants on Yelp, New Orleans",
    subtitle = "Census place boundary of New Orleans",
    color = "Cuisine"
  ) +
  theme_minimal()
```

![](analysis_files/figure-commonmark/unnamed-chunk-11-1.png)

``` r
ggsave("figures/east_asian_points.png", width = 8, height = 6, dpi = 150)
```

## Step 6: Compare geographic systems

Three systems are compared:

1.  **Neighborhood Statistical Areas (NSA):** City of New Orleans
    planning neighborhoods (data.nola.gov, dataset `exvn-jeh2`).
2.  **Census tracts:** Orleans Parish tracts from TIGER/Line (2024).
3.  **ZIP Code Tabulation Areas (ZCTA):** Census ZIP
    approximations (2020) that overlap New Orleans.

### Load the boundaries

``` r
nsa_file <- "data/boundaries/neighborhood_statistical_areas.geojson"

if (!file.exists(nsa_file)) {
  nsa_urls <- c(
    "https://data.nola.gov/api/geospatial/exvn-jeh2?method=export&format=GeoJSON",
    "https://data.nola.gov/api/v3/views/exvn-jeh2/query.geojson?accessType=DOWNLOAD"
  )
  for (u in nsa_urls) {
    ok <- tryCatch({
      download.file(u, nsa_file, mode = "wb", quiet = TRUE)
      file.size(nsa_file) > 1000
    }, error = function(e) FALSE)
    if (isTRUE(ok)) break
    if (file.exists(nsa_file)) unlink(nsa_file)
  }
}

nsa_raw <- st_read(nsa_file, quiet = TRUE) |>
  st_make_valid() |>
  st_transform(4326)

nsa_name_col <- grep("gnocdc_lab", names(nsa_raw), ignore.case = TRUE, value = TRUE)[1]

nsa <- nsa_raw |>
  transmute(area_name = str_to_title(.data[[nsa_name_col]]))

tracts_orleans <- tracts(state = "LA", county = "Orleans", cb = TRUE,
                         year = 2024, class = "sf") |>
  st_transform(4326) |>
  transmute(area_name = paste("Tract", NAME))

zcta_raw <- zctas(cb = TRUE, year = 2020, starts_with = c("700", "701"),
                  class = "sf") |>
  st_transform(4326)

zcta_col <- grep("^ZCTA5CE", names(zcta_raw), value = TRUE)[1]

zcta_nola <- zcta_raw |>
  st_filter(new_orleans_boundary, .predicate = st_intersects) |>
  transmute(area_name = .data[[zcta_col]])

boundary_systems <- list(
  "Neighborhood Statistical Area" = nsa,
  "Census tract" = tracts_orleans,
  "ZIP/ZCTA" = zcta_nola
)

map_dbl(boundary_systems, nrow)
```

    Neighborhood Statistical Area                  Census tract 
                               72                           184 
                         ZIP/ZCTA 
                               34 

### Spatial join for each system

``` r
assign_areas <- function(points, boundaries) {
  points |>
    st_join(boundaries, join = st_within, left = TRUE) |>
    st_drop_geometry() |>
    distinct(business_id, .keep_all = TRUE)
}

assigned <- map(boundary_systems, \(b) assign_areas(selected_points, b))

summarise_system <- function(assigned_df, boundaries, system_name) {
  per_area <- assigned_df |>
    filter(!is.na(area_name)) |>
    count(area_name)

  tibble(
    `Geographic system` = system_name,
    `Number of areas` = nrow(boundaries),
    `Areas with a restaurant` = nrow(per_area),
    `Restaurants assigned` = sum(!is.na(assigned_df$area_name)),
    `Unmatched restaurants` = sum(is.na(assigned_df$area_name)),
    `Smallest area count` = min(per_area$n),
    `Median area count` = median(per_area$n),
    `Largest area count` = max(per_area$n),
    `Areas with 5 or more` = sum(per_area$n >= 5)
  )
}

comparison_table <- imap(assigned, \(a, name)
  summarise_system(a, boundary_systems[[name]], name)) |>
  list_rbind()

comparison_table |>
  kable(caption = "Comparison of geographic systems (East Asian restaurants)")
```

| Geographic system | Number of areas | Areas with a restaurant | Restaurants assigned | Unmatched restaurants | Smallest area count | Median area count | Largest area count | Areas with 5 or more |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Neighborhood Statistical Area | 72 | 43 | 135 | 10 | 1 | 2.0 | 26 | 8 |
| Census tract | 184 | 61 | 135 | 10 | 1 | 1.0 | 26 | 4 |
| ZIP/ZCTA | 34 | 20 | 139 | 6 | 1 | 4.5 | 29 | 10 |

Comparison of geographic systems (East Asian restaurants)

``` r
write_csv(comparison_table, "figures/geographic_comparison.csv")
```

### Area level results

``` r
area_summary <- function(assigned_df) {
  assigned_df |>
    filter(!is.na(area_name)) |>
    group_by(area_name) |>
    summarise(
      restaurants = n(),
      avg_business_stars = round(mean(stars, na.rm = TRUE), 2),
      median_business_stars = median(stars, na.rm = TRUE),
      total_reviews = sum(n_reviews, na.rm = TRUE),
      avg_review_stars = round(mean(avg_review_stars, na.rm = TRUE), 2),
      .groups = "drop"
    ) |>
    arrange(desc(restaurants))
}

area_results <- map(assigned, area_summary)

for (sys in names(area_results)) {
  cat("\n\n**Top 10 areas by restaurant count:", sys, "**\n\n")
  cat(kable(slice_head(area_results[[sys]], n = 10), format = "pipe"),
      sep = "\n")
  cat("\n")
}
```

**Top 10 areas by restaurant count: Neighborhood Statistical Area**

| area_name | restaurants | avg_business_stars | median_business_stars | total_reviews | avg_review_stars |
|:---|---:|---:|---:|---:|---:|
| Central Business District | 26 | 3.69 | 4.00 | 4034 | 3.70 |
| Leonidas | 10 | 3.50 | 3.25 | 1308 | 3.53 |
| Lower Garden District | 9 | 3.94 | 4.00 | 1519 | 3.94 |
| French Quarter | 7 | 3.71 | 3.50 | 813 | 3.84 |
| Marigny | 7 | 3.93 | 4.00 | 943 | 3.86 |
| Gert Town | 6 | 3.67 | 3.75 | 1724 | 3.74 |
| St. Claude | 6 | 4.25 | 4.00 | 472 | 4.26 |
| West Riverside | 5 | 4.00 | 4.00 | 628 | 3.99 |
| Mid-City | 4 | 2.88 | 3.00 | 423 | 2.91 |
| Central City | 3 | 3.33 | 3.50 | 846 | 3.23 |

**Top 10 areas by restaurant count: Census tract**

| area_name | restaurants | avg_business_stars | median_business_stars | total_reviews | avg_review_stars |
|:---|---:|---:|---:|---:|---:|
| Tract 134 | 26 | 3.69 | 4.00 | 4034 | 3.70 |
| Tract 129 | 9 | 3.56 | 3.50 | 1269 | 3.61 |
| Tract 26 | 6 | 3.92 | 4.00 | 741 | 3.85 |
| Tract 72 | 6 | 3.67 | 3.75 | 1724 | 3.74 |
| Tract 15 | 4 | 4.12 | 4.00 | 391 | 4.10 |
| Tract 135.02 | 3 | 3.50 | 3.50 | 159 | 3.66 |
| Tract 139 | 3 | 3.33 | 3.50 | 846 | 3.23 |
| Tract 144 | 3 | 4.33 | 4.50 | 379 | 4.33 |
| Tract 50 | 3 | 3.17 | 3.00 | 397 | 3.17 |
| Tract 77 | 3 | 3.67 | 3.50 | 634 | 3.74 |

**Top 10 areas by restaurant count: ZIP/ZCTA**

| area_name | restaurants | avg_business_stars | median_business_stars | total_reviews | avg_review_stars |
|:---|---:|---:|---:|---:|---:|
| 70130 | 29 | 3.81 | 4.00 | 4942 | 3.82 |
| 70115 | 15 | 3.80 | 3.50 | 2472 | 3.81 |
| 70118 | 14 | 3.43 | 3.25 | 1665 | 3.45 |
| 70112 | 13 | 3.42 | 3.50 | 1040 | 3.48 |
| 70116 | 10 | 4.00 | 4.00 | 1344 | 3.99 |
| 70117 | 10 | 4.15 | 4.00 | 1132 | 4.14 |
| 70119 | 8 | 3.44 | 3.50 | 569 | 3.48 |
| 70125 | 8 | 3.81 | 4.00 | 1873 | 3.85 |
| 70122 | 6 | 3.75 | 4.00 | 432 | 3.81 |
| 70124 | 5 | 3.90 | 4.00 | 484 | 3.78 |

### Maps

``` r
map_system <- function(boundaries, area_df, system_name, file_name) {
  map_data <- boundaries |>
    left_join(area_df |> select(area_name, restaurants), by = "area_name") |>
    mutate(restaurants = replace_na(restaurants, 0))

  bbox <- st_bbox(new_orleans_boundary)

  p <- ggplot() +
    geom_sf(data = map_data, aes(fill = restaurants), color = "white",
            linewidth = 0.2) +
    geom_sf(data = selected_points, size = 0.9, color = "black", alpha = 0.6) +
    scale_fill_viridis_c(option = "C", direction = -1) +
    coord_sf(xlim = bbox[c("xmin", "xmax")], ylim = bbox[c("ymin", "ymax")]) +
    labs(
      title = paste("East Asian Restaurants by", system_name),
      subtitle = "Fill = number of restaurants in the area; dots = restaurants",
      fill = "Restaurants"
    ) +
    theme_minimal()

  ggsave(file.path("figures", file_name), p, width = 8, height = 6, dpi = 150)
  p
}
```

``` r
map_system(nsa, area_results[["Neighborhood Statistical Area"]],
           "Neighborhood Statistical Area", "map_nsa.png")
```

![](analysis_files/figure-commonmark/unnamed-chunk-16-1.png)

``` r
map_system(tracts_orleans, area_results[["Census tract"]],
           "Census Tract", "map_tract.png")
```

![](analysis_files/figure-commonmark/unnamed-chunk-17-1.png)

``` r
map_system(zcta_nola, area_results[["ZIP/ZCTA"]],
           "ZIP Code Tabulation Area", "map_zcta.png")
```

![](analysis_files/figure-commonmark/unnamed-chunk-18-1.png)

### Unmatched restaurants

``` r
assigned |>
  imap(\(a, sys) a |>
         filter(is.na(area_name)) |>
         transmute(system = .env$sys, business_name, address, postal_code)) |>
  list_rbind() |>
  kable(caption = "Restaurants not assigned to any area")
```

| system | business_name | address | postal_code |
|:---|:---|:---|:---|
| Neighborhood Statistical Area | Sake Cafe of Elmwood | 1130 S Clearview Pkwy | 70123 |
| Neighborhood Statistical Area | Hong Kong Kitchen | 1820 Dickory Ave | 70123 |
| Neighborhood Statistical Area | Jade Buddha Chinese Restaurant | 4433 Jefferson Hwy | 70121 |
| Neighborhood Statistical Area | Grand Buffet | 800 S Clearview Pkwy | 70123 |
| Neighborhood Statistical Area | Oriental Triangle Chinese | 4808 Jefferson Hwy | 70121 |
| Neighborhood Statistical Area | China Kitchen | 700 Terry Pkwy, Ste A | 70056 |
| Neighborhood Statistical Area | Kyoto 2 | 5608 Citrus Blvd | 70123 |
| Neighborhood Statistical Area | Chun Lee Chinese Restaurant | 1100 Elmwood Park Blvd | 70123 |
| Neighborhood Statistical Area | China Palace | 1915 Hickory Ave | 70123 |
| Neighborhood Statistical Area | Chinese American Cafe | 1228 Jefferson Hwy | 70121 |
| Census tract | Sake Cafe of Elmwood | 1130 S Clearview Pkwy | 70123 |
| Census tract | Hong Kong Kitchen | 1820 Dickory Ave | 70123 |
| Census tract | Jade Buddha Chinese Restaurant | 4433 Jefferson Hwy | 70121 |
| Census tract | Grand Buffet | 800 S Clearview Pkwy | 70123 |
| Census tract | Oriental Triangle Chinese | 4808 Jefferson Hwy | 70121 |
| Census tract | China Kitchen | 700 Terry Pkwy, Ste A | 70056 |
| Census tract | Kyoto 2 | 5608 Citrus Blvd | 70123 |
| Census tract | Chun Lee Chinese Restaurant | 1100 Elmwood Park Blvd | 70123 |
| Census tract | China Palace | 1915 Hickory Ave | 70123 |
| Census tract | Chinese American Cafe | 1228 Jefferson Hwy | 70121 |
| ZIP/ZCTA | Sake Cafe of Elmwood | 1130 S Clearview Pkwy | 70123 |
| ZIP/ZCTA | Hong Kong Kitchen | 1820 Dickory Ave | 70123 |
| ZIP/ZCTA | Grand Buffet | 800 S Clearview Pkwy | 70123 |
| ZIP/ZCTA | Kyoto 2 | 5608 Citrus Blvd | 70123 |
| ZIP/ZCTA | Chun Lee Chinese Restaurant | 1100 Elmwood Park Blvd | 70123 |
| ZIP/ZCTA | China Palace | 1915 Hickory Ave | 70123 |

Restaurants not assigned to any area

The unmatched restaurants are labeled “New Orleans” by Yelp, but their
coordinates fall in Jefferson Parish (Elmwood and Jefferson), outside
the city limits. This matches the Step 5 comparison of the Yelp `city`
field with the Census place. They are excluded from the area comparison
because they are not in New Orleans.

## Decision: Neighborhood Statistical Areas

**I chose Neighborhood Statistical Areas (NSA) as the main geographic
system, and I only rank neighborhoods that contain at least 5 East Asian
restaurants.**

Reasons, based on the comparison table and maps:

1.  **The areas match the question.** The question is where a person
    should go in New Orleans to find good East Asian food. NSAs have
    names people actually use (French Quarter, Marigny, Central Business
    District), and they are official City of New Orleans planning
    boundaries. A ZIP code such as 70130 or a label such as “Tract 134”
    means little to a visitor.
2.  **Census tracts are too small.** With 184 tracts, half of the tracts
    that contain a restaurant have only 1, and only 4 tracts have 5 or
    more. Averages based on one or two restaurants are not reliable.
3.  **ZCTAs are the most stable but not neighborhoods.** ZCTAs give the
    largest areas (median 4.5 restaurants, 10 areas with 5 or more), but
    ZIP codes are postal routes, not neighborhoods, and the ZCTAs that
    touch New Orleans also extend into Jefferson Parish. Their lower
    unmatched count comes from including restaurants outside the city,
    not from better matching.
4.  **NSA’s weakness is small counts, which a minimum rule handles.**
    Many neighborhoods have only 1 or 2 East Asian restaurants, so
    neighborhoods with fewer than 5 restaurants are shown on the maps
    but not ranked. This leaves 8 neighborhoods for comparison, which
    still meets the project requirement of at least 7 areas.
5.  **ZCTA is kept as a check.** The check below shows that the top
    neighborhood (St. Claude) is also in the top ZIP code, so the main
    finding does not depend on the boundary choice. The order of the
    next few neighborhoods is less certain.
6.  **The minimum of 5 is a middle ground.** A minimum of 3 would rank
    13 neighborhoods but many averages would rest on one or two
    restaurants; a minimum of 10 would leave only 2 neighborhoods, below
    the 7 area requirement. A minimum of 5 ranks 8 neighborhoods
    covering 76 of the 135 assigned restaurants (56%).

What this choice hides: neighborhoods with one excellent restaurant
cannot win the area ranking, and the 10 restaurants just outside the
city limits are left out.

``` r
area_results[["Neighborhood Statistical Area"]] |>
  filter(restaurants >= 5) |>
  arrange(desc(avg_review_stars)) |>
  kable(caption = "Neighborhoods with at least 5 East Asian restaurants, ranked by average review stars")
```

| area_name | restaurants | avg_business_stars | median_business_stars | total_reviews | avg_review_stars |
|:---|---:|---:|---:|---:|---:|
| St. Claude | 6 | 4.25 | 4.00 | 472 | 4.26 |
| West Riverside | 5 | 4.00 | 4.00 | 628 | 3.99 |
| Lower Garden District | 9 | 3.94 | 4.00 | 1519 | 3.94 |
| Marigny | 7 | 3.93 | 4.00 | 943 | 3.86 |
| French Quarter | 7 | 3.71 | 3.50 | 813 | 3.84 |
| Gert Town | 6 | 3.67 | 3.75 | 1724 | 3.74 |
| Central Business District | 26 | 3.69 | 4.00 | 4034 | 3.70 |
| Leonidas | 10 | 3.50 | 3.25 | 1308 | 3.53 |

Neighborhoods with at least 5 East Asian restaurants, ranked by average
review stars

### How much the minimum rule keeps

``` r
nsa_counts <- area_results[["Neighborhood Statistical Area"]]

map(c(3, 5, 10), \(k) tibble(
  minimum_restaurants = k,
  neighborhoods_ranked = sum(nsa_counts$restaurants >= k),
  restaurants_covered = sum(nsa_counts$restaurants[nsa_counts$restaurants >= k]),
  share_of_assigned = round(restaurants_covered / sum(nsa_counts$restaurants), 2)
)) |>
  list_rbind() |>
  kable(caption = "Effect of the minimum restaurant rule on NSA rankings")
```

| minimum_restaurants | neighborhoods_ranked | restaurants_covered | share_of_assigned |
|---:|---:|---:|---:|
| 3 | 13 | 92 | 0.68 |
| 5 | 8 | 76 | 0.56 |
| 10 | 2 | 36 | 0.27 |

Effect of the minimum restaurant rule on NSA rankings

A minimum of 3 keeps many neighborhoods whose averages depend on one or
two restaurants. A minimum of 10 leaves too few neighborhoods to meet
the 7 area requirement. A minimum of 5 is the middle ground.

### Check against ZIP codes

If the neighborhood result is real and not caused by where the
boundaries were drawn, the highest rated neighborhoods should also sit
in the higher rated ZIP codes.

``` r
zcta_ranked <- area_results[["ZIP/ZCTA"]] |>
  filter(restaurants >= 5) |>
  arrange(desc(avg_review_stars)) |>
  mutate(zcta_rank = row_number())

zcta_ranked |>
  select(zcta_rank, area_name, restaurants, avg_review_stars) |>
  kable(caption = "ZIP codes with at least 5 East Asian restaurants, ranked by average review stars")
```

| zcta_rank | area_name | restaurants | avg_review_stars |
|----------:|:----------|------------:|-----------------:|
|         1 | 70117     |          10 |             4.14 |
|         2 | 70116     |          10 |             3.99 |
|         3 | 70125     |           8 |             3.85 |
|         4 | 70130     |          29 |             3.82 |
|         5 | 70115     |          15 |             3.81 |
|         6 | 70122     |           6 |             3.81 |
|         7 | 70124     |           5 |             3.78 |
|         8 | 70112     |          13 |             3.48 |
|         9 | 70119     |           8 |             3.48 |
|        10 | 70118     |          14 |             3.45 |

ZIP codes with at least 5 East Asian restaurants, ranked by average
review stars

``` r
top_nsa <- area_results[["Neighborhood Statistical Area"]] |>
  filter(restaurants >= 5) |>
  arrange(desc(avg_review_stars)) |>
  slice_head(n = 3) |>
  pull(area_name)

assigned[["Neighborhood Statistical Area"]] |>
  select(business_id, neighborhood = area_name) |>
  filter(neighborhood %in% top_nsa) |>
  left_join(assigned[["ZIP/ZCTA"]] |> select(business_id, zcta = area_name),
            by = "business_id") |>
  count(neighborhood, zcta) |>
  left_join(zcta_ranked |> select(zcta = area_name, zcta_rank), by = "zcta") |>
  kable(caption = "ZIP codes containing the restaurants of the top 3 neighborhoods")
```

| neighborhood          | zcta  |   n | zcta_rank |
|:----------------------|:------|----:|----------:|
| Lower Garden District | 70130 |   9 |         4 |
| St. Claude            | 70117 |   6 |         1 |
| West Riverside        | 70115 |   4 |         5 |
| West Riverside        | 70118 |   1 |        10 |

ZIP codes containing the restaurants of the top 3 neighborhoods

**Result of the check.** The top neighborhood holds up under ZIP codes:
all 6 St. Claude restaurants fall in ZIP 70117, which is also the
highest rated ZIP code. The second and third neighborhoods are less
clear. Lower Garden District falls in 70130 (rank 4 of 10), and West
Riverside is split between 70115 (rank 5) and 70118 (rank 10). Larger
ZIP codes mix these neighborhoods with nearby restaurants that are rated
lower, so their advantage shrinks. The conclusion that St. Claude is the
strongest area does not depend on the boundary choice, but the order of
the next few neighborhoods does.
