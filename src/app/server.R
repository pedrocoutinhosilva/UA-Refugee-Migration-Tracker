# defaultMapBounds <- function(...) {
#   fitBounds(..., 19.33594, 53.21261, 31.77246, 46.52863)
# }

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  print("Loading map")

  output$mymap <- renderLeaflet({
    checkpoints <- state$checkpoints
    refugees <- state$refugees

    leaflet(
      options = leafletOptions(preferCanvas = TRUE)
    ) %>%
      addProviderTiles(providers$Stamen.TonerLite,
        options = providerTileOptions(noWrap = TRUE)
      ) %>%
      fitBounds(19.33594, 53.21261, 31.77246, 46.52863) %>%
      addGeoJSON(state$shapes) %>%
      addAwesomeMarkers(
        data = checkpoints$PL,
        layerId = ~ checkpoints$PL$id,
        icon = makeIcon(
          className = getIconClass(checkpoints$PL)
        )
      ) %>%
      addAwesomeMarkers(
        data = checkpoints$SK,
        layerId = ~ checkpoints$SK$id,
        icon = makeIcon(
          iconUrl = "/placeholder.png",
          iconWidth = 30,
          iconHeight = 30,
          className = getIconClass(checkpoints$SK)
        )
      ) %>%
      addAwesomeMarkers(
        data = checkpoints$RO,
        layerId = ~ checkpoints$RO$id,
        icon = makeIcon(
          className = getIconClass(checkpoints$RO)
        )
      ) %>%
      addAwesomeMarkers(
        data = checkpoints$HU,
        layerId = ~ checkpoints$HU$id,
        icon = makeIcon(
          className = getIconClass(checkpoints$HU)
        )
      ) %>%
      addAwesomeMarkers(
        data = checkpoints$MD,
        layerId = ~ checkpoints$MD$id,
        icon = makeIcon(
          className = getIconClass(checkpoints$MD)
        )
      ) %>%
      addAwesomeMarkers(
        data = checkpoints$MD,
        layerId = ~ checkpoints$MD$id,
        icon = makeIcon(
          className = getIconClass(checkpoints$MD)
        )
      ) %>%
      addLabelOnlyMarkers(
        data = refugees,
        label = refugeeIcons(refugees),
        layerId = ~ refugees$geomaster_name,
        labelOptions = leaflet::labelOptions(
          noHide = TRUE,
          direction = "bottom",
          textOnly = TRUE,
          offset = c(0, -14),
          opacity = 1,
          textsize = "14px",
          className = "country-refugees"
        )
      ) %>%
      suppressWarnings() %>%
      suppressMessages() %>%
      htmlwidgets::onRender("
        function(el,x) {
          $('#overlayLoading').addClass('disabled');
          Shiny.setInputValue('browserComplete', true, {priority: 'event'});

          console.log('disconnecting from server');
          Shiny.shinyapp.$socket.close();
        }
      ")
  })

  observeEvent(input$browserComplete, {
    session$close()
    print("Page served, disconnecting session")
  })
}
