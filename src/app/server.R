server <- function(input, output, session) {
  print("Loading map")

  output$mymap <- renderLeaflet({
    checkpoints <- state$checkpoints %>%
      do.call(dplyr::bind_rows, .)

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
        data = checkpoints,
        layerId = ~ checkpoints$id,
        icon = makeIcon(
          className = getIconClass(checkpoints)
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
      htmlwidgets::onRender("
        function(el,x) {
          $('#overlayLoading').addClass('disabled');
          Shiny.setInputValue('browserComplete', true, {priority: 'event'});

          console.log('disconnecting from server');
          Shiny.shinyapp.$socket.close();
        }
      ") %>%
      suppressWarnings() %>%
      suppressMessages()
  })

  observeEvent(input$browserComplete, {
    session$close()
    print("Page served, disconnecting session")
  })
}
