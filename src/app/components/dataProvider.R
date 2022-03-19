import("utils")
import("dplyr")
import("rvest")
import("stringr")
import("jsonlite")
import("xml2")

export(
  load_data,
  load_refugee_data,
  load_country_shapes
)

stations <- use("data/stations.R")$stations

load_country_shapes <- function() {
  path <- "data/country_shapes.rds"
  if (file.exists(path)) {
    geojson <- readRDS(path)
  } else {
    # From http://data.okfn.org/data/datasets/geo-boundaries-world-110m
    geojson <- readLines("data/country_shapes.geojson", warn = FALSE) %>%
      paste(collapse = "\n") %>%
      fromJSON(simplifyVector = FALSE)

      # Default styles for all features
    geojson$style <- list(
      weight = 1,
      color = "#222",
      opacity = 1,
      fillOpacity = 0.6
    )

    options <- list(
      countries = c("PL", "SK", "RO", "HU", "MD", "UA")
    )

    geojson$features <- geojson$features[sapply(geojson$features, function(feat) {
        if (feat$properties$iso2 %in% options$countries) {
            return(TRUE)
        }

        return(FALSE)
    })]

    # Add a properties$style list to each feature
    geojson$features <- lapply(geojson$features, function(feat) {
      if (feat$properties$iso2 == "UA") {
        feat$properties$style <- list(
          fillColor = "#0058B5",
          color = "white",
          className = "ukraine country-shape"
        )
      } else {
        feat$properties$style <- list(
          fillColor = "#F7CE00",
          className = "bordering country-shape"
        )
      }

      feat
    })

    saveRDS(geojson, path)
  }

  geojson
}

load_refugee_data <- function() {
  url <- "https://data2.unhcr.org/population/get/sublocation?widget_id=284471&sv_id=54&population_group=5459,5460&forcesublocation=0&fromDate=1900-01-01"
  path <- paste0(getwd(), "/data/data-refugee.json")

  try({
    data <- jsonlite::fromJSON(url)
    saveRDS(data, path)
  })
  data <- readRDS(path)

  data.frame(
    geomaster_name = data$data$geomaster_name,
    lat = data$data$centroid_lat %>% as.numeric(),
    lng = data$data$centroid_lon %>% as.numeric(),
    date = data$data$date,
    value = data$data$individuals
  )
}

values_as_numeric <- function(entries) {
  lapply(entries, function(entry) {
    as.numeric(gsub(",", ".", entry))
  }) %>% unlist()
}

country_data <- function(raw, country) {
  ids <- sapply(seq_len(nrow(raw) / 2), function(index) {
    paste0(country, "_", index)
  })

  lats <- lapply(stations[[country]], function(station) {
    station$lat
  }) %>% unlist()

  lngs <- lapply(stations[[country]], function(station) {
    station$lng
  }) %>% unlist()

  last_update_day <- lapply(raw[[11]][c(TRUE, FALSE)], function(last_update) {
    stringr::str_split(last_update, " ")[[1]][1]
  }) %>% unlist()

  last_update_hour <- lapply(raw[[11]][c(TRUE, FALSE)], function(last_update) {
    stringr::str_split(last_update, " ")[[1]][2] %>%
      paste("EET")
  }) %>% unlist()

  data.frame(
    id                = ids,
    inner_border_name = raw[[5]][c(TRUE, FALSE)],
    outer_border_name = raw[[5]][c(FALSE, TRUE)],
    car_queue_km      = raw[[7]][c(TRUE, FALSE)] %>% values_as_numeric(),
    car_queue_hours   = raw[[8]][c(TRUE, FALSE)] %>% values_as_numeric(),
    foot_queue_units  = raw[[9]][c(TRUE, FALSE)] %>% values_as_numeric(),
    foot_queue_hours  = raw[[10]][c(TRUE, FALSE)] %>% values_as_numeric(),
    last_update       = raw[[11]][c(TRUE, FALSE)],
    last_update_day   = last_update_day,
    last_update_hour  = last_update_hour,
    telegram          = raw[[12]][c(TRUE, FALSE)],
    lat               = lats,
    lng               = lngs
  )
}

load_data = function() {
  print("Updating online data")

  url <- "https://docs.google.com/spreadsheets/u/1/d/e/2PACX-1vTmKNAxZn2cPpBqPHnRx9Hc_GPzfi7U92h05hkNuES6pA8l7IcbfdRELMkTBWGcBFoRkUdwlnfX889X/pubhtml?gid=0&single=true"

  path <- paste0(getwd(), "/data/data.rds")
  try({
    table <- xml2::read_html(url) %>%
      html_elements("table") %>%
      html_table() %>%
      as.data.frame()

    saveRDS(table, path)
  })

  data <- readRDS(path) %>%
    suppressWarnings() %>%
    suppressMessages()

  rows <- lapply(stations, function(country) {
    mapping <- lapply(country, function(station) {
      data %>%
        add_rownames() %>%
        filter(str_detect(Var.5, station$name)) %>%
        .$rowname
    })

    do.call(
      bind_rows,
      lapply(mapping, function(key) {
        data[c((as.integer(key) - 1), key), ]
      })
    )
  }) %>%
  suppressWarnings() %>%
  suppressMessages()

  list(
    PL = country_data(rows$PL, "PL"),
    SK = country_data(rows$SK, "SK"),
    RO = country_data(rows$RO, "RO"),
    HU = country_data(rows$HU, "HU"),
    MD = country_data(rows$MD, "MD")
  )
}
