library(shiny)
library(modules)
library(leaflet)
library(imola)
library(curl)
library(sass)
library(shiny.pwa)

source("components/utils.R")

dataProvider <- use("components/dataProvider.R")

state <- list(
  shapes = dataProvider$load_country_shapes(),
  checkpoints = dataProvider$load_data(),
  refugees = dataProvider$load_refugee_data(),
  cities = dataProvider$load_city_data(),
  regions = dataProvider$load_interest_regions(),
  map_bounds = list(c(45.1, 31.77246), c(53.21261, 19.33594)),
  map_bounds_focus = list(c(51.943305, 22.854364), c(46.026401, 39.685416))
)

browser_data <- jsonlite::toJSON(state)

# The compiled stylesheet is committed, so a read-only deploy can skip this.
tryCatch(
  sass(
    sass::sass_file("styles/main.scss"),
    cache = NULL,
    options = sass_options(output_style = "compressed"),
    output = "www/css/sass.min.css"
  ),
  error = function(e) message("Skipping sass build: ", conditionMessage(e))
)
