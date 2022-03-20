getHTMLPopup <- function(data) {
  lapply(seq_len(nrow(data)), function(index) {
    row <- data[index, ]

    div(
      div(
        span(class = "popup-title", row$id)
      ),
      div(
        span(class = "popup-metric-title", "Population: "),
        span(class = "popup-metric-value", row$population)
      ),
      div(
        span(class = "popup-metric-title", "Held by: "),
        span(class = "popup-metric-value", row$control)
      )
    ) %>% htmltools::doRenderTags()
  })
}

getCityPopupClass <- function(data) {
  lapply(seq_len(nrow(data)), function(index) {
    row <- data[index, ]

    glue::glue("city-control-marker control-{row$control}")
  }) %>% unlist()
}

server <- function(input, output, session) {
  # Observe changes in the url search parameters
  observeEvent(session$clientData$url_search, {
    query <- parseQueryString(session$clientData$url_search)

    targetView <- ""
    if (!is.null(query$v)) {
      targetView <- switch(
        query$v,
        city = ".legend-control.internal-view",
        border = ".legend-control.external-view",
        ""
      )
    }

    output$filterInit <- renderUI({
      tags$script(glue::glue("
        let initView = function() {{
          $('{targetView}').click();
        }}
      "))
    })
    outputOptions(output, "filterInit", suspendWhenHidden = FALSE)
  })

  output$mymap <- renderLeaflet({
    print("Loading map")
    checkpoints <- state$checkpoints %>%
      do.call(dplyr::bind_rows, .)

    refugees <- state$refugees

    leaflet(
      options = leafletOptions()
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
      addCircleMarkers(
        data = state$cities,
        # popup = ~ getHTMLPopup(state$cities),
        label = ~ getHTMLPopup(state$cities),
        layerId = ~ state$cities$id,
        color = ~ state$cities$color,
        radius = ~ state$cities$size,
        fillOpacity = 1,
        options = pathOptions(
          className = getCityPopupClass(state$cities)
        ),
        labelOptions = labelOptions(
          className = "hover-city-label",
          textsize = "12px"
        )
      ) %>%
      addLabelOnlyMarkers(
        data = refugees,
        label = refugeeIcons(refugees),
        layerId = ~ refugees$geomaster_name,
        labelOptions = labelOptions(
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

          initView();
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
