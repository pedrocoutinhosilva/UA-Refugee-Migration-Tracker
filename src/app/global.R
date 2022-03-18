library(shiny)
library(modules)
library(leaflet)
library(echarts4r)
library(echarts4r.assets)
library(echarts4r.maps)
library(imola)
library(curl)
library(rvest)
library(sass)
library(shiny.pwa)
library(rvest)
library(xml2)
library(readxl)

source("components/utils.R")
source("components/loader.R")
source("components/tracker.R")

dataProvider <- use("components/dataProvider.R")

state <- list(
  shapes = dataProvider$load_country_shapes(),
  checkpoints = dataProvider$load_data(),
  refugees = dataProvider$load_refugee_data(),
  map_bounds = list(c(46.52863, 31.77246), c(53.21261, 19.33594))
)

browser_data <- jsonlite::toJSON(state)

sass(
  sass::sass_file("styles/main.scss"),
  cache = NULL,
  options = sass_options(output_style = "compressed"),
  output = "www/css/sass.min.css"
)
