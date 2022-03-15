defaultMapBounds <- function(...) {
  fitBounds(..., 19.33594, 53.21261, 31.77246, 46.52863)
}

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  output$mymap <- renderLeaflet({
    checkpoints <- state$checkpoints
    refugees <- state$refugees

    leaflet(
      options = leafletOptions(preferCanvas = NULL)
    ) %>%
      addProviderTiles(providers$Stamen.TonerLite,
        options = providerTileOptions(noWrap = TRUE)
      ) %>%
      defaultMapBounds() %>%
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
      ) %>% {
        session$sendCustomMessage("toggleLoader", TRUE)
        .
      }
  })

  observeEvent(input$resetZoom, {
    leafletProxy("mymap") %>%
      defaultMapBounds()
  })

  observeEvent(input$mymap_click, {

    print(input$mymap_click)
    if (is.null(input$mymap_click$id)) {
      session$sendCustomMessage("togglePopup", FALSE)
    }
  })

  observeEvent(input$mymap_marker_click, {
    feature_id <- input$mymap_marker_click$id

    if (feature_id %in% state$refugees$geomaster_name) {
      return()
    }

    trackEvent(session, "Border Point", feature_id, "View Border Point")

    country_code <- stringr::str_split(feature_id, "_")[[1]][1]
    station_code <- stringr::str_split(feature_id, "_")[[1]][2]

    info <- state$checkpoints[[country_code]][station_code, ]

    car_state <- info$car_queue_hours %>%
      as.numeric() %>%
      getCarState()

    pedestrian_state <- info$foot_queue_hours %>%
      as.numeric() %>%
      getPedestrianState()

    session$sendCustomMessage("togglePopupClass", list(
      car = car_state,
      pedestrian = pedestrian_state
    ))

    output$checkpointInnerTitle <- renderUI({
      info$inner_border_name
    })

    output$checkpointOuterTitle <- renderUI({
      info$outer_border_name
    })

    output$carHours <- renderUI({
      if (identical(car_state, "none")) {
        return(tagList(span(), span("Not available")))
      }

      tagList(
        span(as.numeric(info$car_queue_hours)),
        span(" Hours")
      )
    })
    output$carKM <- renderUI({
      if (identical(car_state, "none")) {
        return(tagList(span(), span("Not available")))
      }

      tagList(
        span(as.numeric(info$car_queue_km)),
        span(" KM")
      )
    })
    output$pedestrianHours <- renderUI({
      if (identical(pedestrian_state, "none")) {
        return(tagList(span(), span("Not available")))
      }

      tagList(
        span(as.numeric(info$foot_queue_hours)),
        span(" Hours")
      )
    })
    output$pedestrianNumber <- renderUI({
      if (identical(pedestrian_state, "none")) {
        return(tagList(span(), span("Not available")))
      }

      tagList(
        span(as.numeric(info$foot_queue_units)),
        span(" People")
      )
    })
    output$lastUpdate <- renderUI({
      span(format(as.Date(as.numeric(info$last_update), origin = "1899-12-30")))
    })
    output$telegramChats <- renderUI({
      tagList(
        a(target = "_target", href = info$telegram, info$telegram)
      )
    })
  })
}
