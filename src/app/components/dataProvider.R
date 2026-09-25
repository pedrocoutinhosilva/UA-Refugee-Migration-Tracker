import("utils")
import("stats")
import("dplyr")
import("stringr")
import("jsonlite")
import("shiny")

export(
  load_data,
  load_refugee_data,
  load_country_shapes,
  load_city_data,
  load_interest_regions
)

stations <- use("data/stations.R")$stations

load_interest_regions <- function() {
  list(
    transnistria = readLines("data/transnistria.geojson", warn = FALSE) %>%
      paste(collapse = "\n") %>%
      fromJSON(simplifyVector = FALSE),
    crimea = readLines("data/Crimea.json", warn = FALSE) %>%
      paste(collapse = "\n") %>%
      fromJSON(simplifyVector = FALSE),
    donetsk = readLines("data/Donetsk.json", warn = FALSE) %>%
      paste(collapse = "\n") %>%
      fromJSON(simplifyVector = FALSE),
    luhansk = readLines("data/Luhansk.json", warn = FALSE) %>%
      paste(collapse = "\n") %>%
      fromJSON(simplifyVector = FALSE)
  )
}

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

# Fetches fresh data and caches it on disk. Falls back to the last good cache
# when the source is down or returns something unusable, so a broken upstream
# never takes the app down or overwrites good data with bad.
cached <- function(path, fetch, validate, max_age_mins = 0) {
  age <- if (file.exists(path)) {
    difftime(Sys.time(), file.mtime(path), units = "mins")
  } else {
    Inf
  }

  if (age >= max_age_mins) {
    result <- tryCatch(fetch(), error = function(e) {
      message("Fetch for ", basename(path), " failed: ", conditionMessage(e))
      NULL
    })

    if (!is.null(result) && isTRUE(validate(result))) {
      tryCatch(saveRDS(result, path), error = function(e) {
        message("Could not cache ", basename(path), ": ", conditionMessage(e))
      })
      return(result)
    }
  }

  if (file.exists(path)) {
    message("Using cached ", basename(path))
    return(readRDS(path))
  }

  NULL
}

fetch_json <- function(url, headers = list(), ...) {
  handle <- curl::new_handle(timeout = 30)
  curl::handle_setheaders(handle, .list = c(
    list("User-Agent" = "UA-Refugee-Migration-Tracker (R/Shiny)"),
    headers
  ))
  response <- curl::curl_fetch_memory(url, handle = handle)

  if (response$status_code != 200) {
    stop("HTTP ", response$status_code, " from ", url)
  }

  fromJSON(rawToChar(response$content), ...)
}

# Even-odd ray casting test of many points against one polygon ring.
in_ring <- function(x, y, ring) {
  xi <- ring[, 1]
  yi <- ring[, 2]
  prev <- c(length(xi), seq_len(length(xi) - 1))
  xj <- xi[prev]
  yj <- yi[prev]

  vapply(seq_along(x), function(k) {
    crosses <- ((yi > y[k]) != (yj > y[k])) &
      (x[k] < (xj - xi) * (y[k] - yi) / (yj - yi) + xi)
    sum(crosses, na.rm = TRUE) %% 2 == 1
  }, logical(1))
}

# Rings after the first are holes, so XOR-ing ring membership handles them.
in_polygon <- function(x, y, rings) {
  Reduce(xor, lapply(rings, function(ring) in_ring(x, y, ring)))
}

feature_control <- function(name) {
  case_when(
    str_detect(name, "Liberated") ~ "Ukraine",
    str_detect(name, "Unknown status") ~ "Contested",
    str_detect(name, "Occupied|CADR and CALR") ~ "Russia",
    TRUE ~ NA_character_
  )
}

classify_cities <- function(lng, lat, features) {
  control <- rep("Ukraine", length(lng))
  # Lowest precedence first: later matches overwrite earlier ones.
  precedence <- c("Russia", "Contested", "Ukraine")

  polygons <- Filter(function(feat) feat$geometry$type == "Polygon", features)
  kinds <- vapply(polygons, function(feat) {
    feature_control(feat$properties$name)
  }, character(1))

  for (kind in precedence) {
    for (feat in polygons[kinds %in% kind]) {
      rings <- lapply(feat$geometry$coordinates, function(ring) {
        do.call(rbind, lapply(ring, function(point) unlist(point)[1:2]))
      })

      outer <- rings[[1]]
      candidates <- which(
        lng >= min(outer[, 1]) & lng <= max(outer[, 1]) &
        lat >= min(outer[, 2]) & lat <= max(outer[, 2])
      )
      if (length(candidates) == 0) next

      inside <- in_polygon(lng[candidates], lat[candidates], rings)
      control[candidates[inside]] <- kind
    }
  }

  control
}

load_city_data <- function() {
  cities <- jsonlite::fromJSON("data/ua.json") %>%
    mutate(
      lat = as.numeric(lat),
      lng = as.numeric(lng),
      population = as.numeric(population)
    ) %>%
    filter(capital != "" | population >= 10000) %>%
    arrange(desc(population)) %>%
    distinct(city, .keep_all = TRUE)

  cached(
    path = "data/city_control.rds",
    fetch = function() {
      features <- fetch_json(
        "https://deepstatemap.live/api/history/last",
        simplifyVector = FALSE
      )$map$features

      cities %>%
        mutate(control = classify_cities(lng, lat, features)) %>%
        transmute(
          id = city,
          lat = lat,
          lng = lng,
          color = case_when(
            control == "Contested" ~ "orange",
            control == "Russia" ~ "red",
            TRUE ~ "blue"
          ),
          size = case_when(
            capital == "admin" ~ 10,
            capital == "primary" ~ 7,
            capital == "minor" ~ 5,
            TRUE ~ 3
          ),
          population = population,
          control = control
        )
    },
    validate = function(data) nrow(data) > 0 && any(data$control != "Ukraine")
  )
}

refugee_countries <- data.frame(
  geomaster_name = c(
    "Poland", "Republic of Moldova", "Hungary", "Romania",
    "Slovakia", "Russian Federation", "Belarus"
  ),
  eurostat = c("PL", NA, "HU", "RO", "SK", NA, NA),
  unhcr = c(NA, "MDA", NA, NA, NA, "RUS", "BLR"),
  lat = c(52.1224, 47.1976, 47.1672, 45.8667, 48.7062, 51.4889, 53.5384),
  lng = c(19.4013, 28.4646, 19.4131, 25.3, 19.4864, 38.1556, 28.0463)
)

# Beneficiaries of temporary protection from Ukraine, monthly (EU members).
fetch_eurostat_refugees <- function(geos) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
    "migr_asytpsm?citizen=UA&sex=T&age=TOTAL&lastTimePeriod=3&",
    paste0("geo=", geos, collapse = "&")
  )
  stat <- fetch_json(url, simplifyVector = FALSE)

  # JSON-stat stores values in a flat array indexed row-major over all dims.
  strides <- c(rev(cumprod(rev(unlist(stat$size)[-1]))), 1)
  names(strides) <- unlist(stat$id)
  position <- function(dim, code) stat$dimension[[dim]]$category$index[[code]]
  periods <- names(stat$dimension$time$category$index)

  do.call(rbind, lapply(geos, function(geo) {
    for (period in rev(sort(periods))) {
      index <- position("geo", geo) * strides[["geo"]] +
        position("time", period) * strides[["time"]]
      value <- stat$value[[as.character(index)]]
      if (!is.null(value)) {
        return(data.frame(code = geo, date = period, value = value))
      }
    }
    NULL
  }))
}

# UNHCR annual refugee figures, for neighbours outside the EU.
fetch_unhcr_refugees <- function(codes) {
  url <- paste0(
    "https://api.unhcr.org/population/v1/population/",
    "?limit=500&yearFrom=2022&coo=UKR&coa=", paste(codes, collapse = ",")
  )

  fetch_json(url)$items %>%
    mutate(refugees = as.numeric(refugees)) %>%
    filter(coa %in% codes, refugees > 0) %>%
    group_by(coa) %>%
    slice_max(year, n = 1) %>%
    ungroup() %>%
    transmute(code = coa, date = as.character(year), value = refugees)
}

load_refugee_data <- function() {
  cached(
    path = "data/refugees.rds",
    fetch = function() {
      figures <- rbind(
        fetch_eurostat_refugees(na.omit(refugee_countries$eurostat)),
        fetch_unhcr_refugees(na.omit(refugee_countries$unhcr))
      )

      refugee_countries %>%
        mutate(code = coalesce(eurostat, unhcr)) %>%
        inner_join(figures, by = "code") %>%
        arrange(desc(value)) %>%
        select(geomaster_name, lat, lng, date, value)
    },
    validate = function(data) nrow(data) > 0 && all(!is.na(data$value))
  )
}

nakordoni_countries <- c(PL = 2, SK = 3, HU = 4, RO = 5, MD = 6)
nakordoni_types <- c(car = 4, foot = 7)

# Live queues leaving Ukraine, one call per destination country and vehicle
# type. Border calls are "heavy" quota (200/day on the free Explorer key),
# hence the long cache below.
fetch_nakordoni_queues <- function(key) {
  if (!nzchar(key)) stop("NAKORDONI_API_KEY is not set")

  do.call(rbind, lapply(names(nakordoni_countries), function(country) {
    do.call(rbind, lapply(names(nakordoni_types), function(type) {
      url <- sprintf(
        "https://nakordoni.eu/api/v1/data/border/1/%s/%s?lang=uk",
        nakordoni_countries[[country]], nakordoni_types[[type]]
      )
      rows <- fetch_json(
        url,
        headers = list(Authorization = paste("Bearer", key))
      )$data$checkpoints

      if (length(rows) == 0) return(NULL)

      field <- function(name) {
        if (name %in% names(rows)) rows[[name]] else rep(NA, nrow(rows))
      }

      data.frame(
        country = country,
        type = type,
        name = field("name"),
        queue = as.numeric(field("queue")),
        wait_min = as.numeric(field("wait_min")),
        updated_at = as.character(field("updated_at")),
        source_url = as.character(field("source_url"))
      )
    }))
  }))
}

normalise_name <- function(name) {
  gsub("[^[:alpha:]]", "", tolower(name))
}

# Pick the queue reading whose name contains the Ukrainian side of the
# crossing, e.g. "Рава-Руська" for "Рава-Руська - Хребенне".
match_queue <- function(queues, country, type, ua_name) {
  if (is.null(queues)) return(NULL)

  ua_side <- normalise_name(str_split(ua_name, " - ")[[1]][1])
  hits <- queues[
    queues$country == country &
    queues$type == type &
    str_detect(normalise_name(queues$name), fixed(ua_side)),
  ]

  if (nrow(hits) == 0) NULL else hits[1, ]
}

country_data <- function(queues, country) {
  do.call(rbind, lapply(seq_along(stations[[country]]), function(index) {
    station <- stations[[country]][[index]]
    car <- match_queue(queues, country, "car", station$ua_name)
    foot <- match_queue(queues, country, "foot", station$ua_name)

    value <- function(reading, name) {
      if (is.null(reading)) NA else reading[[name]]
    }
    last_update <- coalesce(
      value(car, "updated_at"),
      value(foot, "updated_at"),
      ""
    )

    data.frame(
      id                = paste0(country, "_", index),
      inner_border_name = station$ua_name,
      outer_border_name = station$name,
      car_queue_units   = value(car, "queue"),
      car_queue_hours   = round(value(car, "wait_min") / 60, 1),
      foot_queue_units  = value(foot, "queue"),
      foot_queue_hours  = round(value(foot, "wait_min") / 60, 1),
      last_update       = last_update,
      last_update_day   = substr(last_update, 1, 10),
      last_update_hour  = substr(last_update, 12, 16),
      source_url        = coalesce(
        value(car, "source_url"),
        value(foot, "source_url"),
        "https://nakordoni.eu"
      ),
      lat               = station$lat,
      lng               = station$lng
    )
  }))
}

load_data <- function() {
  print("Updating online data")

  queues <- cached(
    path = "data/checkpoint_queues.rds",
    fetch = function() fetch_nakordoni_queues(Sys.getenv("NAKORDONI_API_KEY")),
    validate = function(data) !is.null(data) && nrow(data) > 0,
    max_age_mins = 120
  )

  lapply(names(nakordoni_countries), function(country) {
    country_data(queues, country)
  }) %>%
    setNames(names(nakordoni_countries))
}
