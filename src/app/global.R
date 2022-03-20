library(shiny)
library(modules)
library(leaflet)
library(imola)
library(curl)
library(rvest)
library(sass)
library(shiny.pwa)
library(xml2)

source("components/utils.R")

dataProvider <- use("components/dataProvider.R")

state <- list(
  shapes = dataProvider$load_country_shapes(),
  checkpoints = dataProvider$load_data(),
  refugees = dataProvider$load_refugee_data(),
  cities = dataProvider$load_city_data(),
  regions = dataProvider$load_interest_regions(),
  map_bounds = list(c(46.52863, 31.77246), c(53.21261, 19.33594)),
  map_bounds_focus = list(c(51.943305, 22.854364), c(46.026401, 39.685416))
)

browser_data <- jsonlite::toJSON(state)

sass(
  sass::sass_file("styles/main.scss"),
  cache = NULL,
  options = sass_options(output_style = "compressed"),
  output = "www/css/sass.min.css"
)
