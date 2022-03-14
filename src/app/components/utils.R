getCarState <- function(value) {
  entry <- as.numeric(value)

  if (is.na(entry)) {
    return("none")
  }

  if (entry > 0 && entry <= 2) {
    return("yellow")
  }
  if (entry > 2) {
    return("red")
  }

  return("green")
}
getPedestrianState <- function(value) {
  entry <- as.numeric(value)

  if (is.na(entry)) {
    return("none")
  }

  if (entry > 0 && entry <= 1) {
    return("yellow")
  }
  if (entry > 1) {
    return("red")
  }

  return("green")
}


getIconClass <- function(df) {
  cars <- lapply(df$car_queue_hours, getCarState)

  pedestrian <- lapply(df$foot_queue_hours, getPedestrianState)

  lapply(seq_len(nrow(df)), function(index) {
    glue::glue("car-{cars[index]} pedestrian-{pedestrian[index]} custom-asset-marker")
  })
}

checkpointPopup <- function(inner,
                            outer,
                            car_hours,
                            car_km,
                            pedestrian_hours,
                            pedestrian_number,
                            lastUpdate,
                            telegramChats) {
  div(class = "control-wrapper",
    div(
      class = "popup-title",
      div(
        div(class = "title-tag", "Ukraine Border Point"),
        inner,
      ),
      div(
        div(class = "title-tag", "Neighbor Border Point"),
        outer
      )
    ),

    gridPanel(
      class = "popup-content",
      style = "height: auto",

      areas = c(
        "left right",
        "telegram update"
      ),
      gap = "10px",

      rows = "150px auto",

      div(
        class = "icons-wrapper",
        div(
          class = "icon-left",
          tags$i(class = "fas fa-car")
        ),
        div(
          class = "icon-separator"
        ),
        div(
          class = "icon-right",
          tags$i(class = "fas fa-hiking")
        )
      ),

      left = gridPanel(
        class = "car-metrics",
        rows = "1fr 1fr",

        div(
          div(class = "popup-content-title", "Queue lenght"),
          car_km,
        ),

        div(
          div(class = "popup-content-title", "Expected Wait"),
          car_hours
        )
      ),

      right = gridPanel(
        class = "pedestrian-metrics",
        rows = "1fr 1fr",

        div(
          div(class = "popup-content-title", "Waiting Pedestrians"),
          pedestrian_number,
        ),

        div(
          div(class = "popup-content-title", "Expected Wait"),
          pedestrian_hours
        )
      ),

      update = div(
        class = "last-update-metrics",

        div(
          div(class = "popup-content-title", "Last update"),
          lastUpdate
        )
      ),

      telegram = div(
        class = "telegram-metrics",

        div(
          div(class = "popup-content-title", "Telegram chats"),
          telegramChats
        )
      )
    )
  )
}

checkpointPopups <- function(df) {
  lapply(seq_len(nrow(df)), function(index) {
    checkpointPopup(df[index, ]$id)
  })
}

refugeeIcons <- function(data) {

  mil_icon <- tags$i(class = "million fas fa-male")
  hundreds_icon <- tags$i(class = "hundred fas fa-male")

  data %>%
    nrow() %>%
    seq_len() %>%
    lapply(function(index) {
        row <- data[index, ]

        minified_units <- ceiling(as.numeric(row$value) / 100000)
        mil_number <- trunc(minified_units / 10)
        hundreds_number <- ((minified_units / 10) - mil_number) * 10

        icons <- c(
          rep(as.character(mil_icon), as.numeric(mil_number)),
          rep(as.character(hundreds_icon), as.numeric(hundreds_number))
        ) %>% HTML()

        div(
          class = "country-refugee-label",
          div(class = "country-refugee-name", row$geomaster_name),
          div(class = "country-refugee-icons", icons),
          div(class = "country-refugee-value", format(as.numeric(row$value), big.mark = " "))
        ) %>% as.character() %>% HTML()
    })
}
