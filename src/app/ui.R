source("components/loader.R")
source("components/tracker.R")

dependencies <- tagList(
  tags$head(tags$link(rel = "shortcut icon", href = "icon.png")),
  tags$head(HTML("<title>Slava Ukraini - Refugee Live Information</title>")),
  tags$head(includeHTML(("www/google-analytics.html"))),
  tags$link(rel = "stylesheet", type = "text/css", href = "css/fa.all.min.css"),
  tags$link(rel = "stylesheet", type = "text/css", href = "css/sass.min.css"),
  tags$script(src = "js/scripts.js"),
  tags$script(paste0("let station_data = ", browser_data, ";")),
  uiOutput("filterInit") %>% tagAppendAttributes(style = "display: none;")
)

app_title <- h1(
  class = "app-title",
  "Ukraine Migrants - Live Information"
)

helpMenu <- function(...) {
  flexPanel(
    class = "map-controls-help",
    ...
  )
}

map_controls <- gridPanel(
  id = "overlayControlGrid",

  columns = "auto auto 1fr",
  rows = "50px 1fr auto auto auto auto 10px",
  gap = "15px",

  areas = c(
    "...         ...",
    "...         ...",
    "map-help    ...",
    "map-type    ...",
    "map-control ...",
    "map-info    ...",
    "...         ..."
  ),

  `map-help` = flexPanel(
    class = "control-wrapper map-help-wrapper",
    direction = "column",
    style = "text-align: center;",

    tags$i(
      class = "fas fa-question-circle legend-control",
      title = "Map information",
      onclick = "toggleHelp(null);"
    )
  ),

  `map-info` = flexPanel(
    class = "control-wrapper",
    direction = "column",
    style = "text-align: center;",

    helpMenu(
      div("About this project...")
    ),

    tags$i(
      class = "fas fa-info-circle legend-control active",
      title = "Map information",
      onclick = "$('#overlayLegendGrid').addClass('active')"
    )
  ),

  `map-control` = flexPanel(
    class = "control-wrapper",
    direction = "column",
    gap = "10px",
    style = "text-align: center;",

    helpMenu(
      div("Border Control Points"),
      div("Refugee Numbers"),
      div("Ukraine Cities Control"),
      div("Country Colors"),
      div("View Map Tiles"),
      div(class = "separator"),
      div("Zoom In"),
      div("Zoom Out"),
      div(class = "separator"),
      div("Reset Map position")
    ),

    tags$i(
      class = "fas fa-hiking legend-control active border-points",
      title = "Toggle Border Control Points",
      onclick = "toggleBorders(this)"
    ),
    tags$i(
      class = "fas fa-male legend-control active refugee-numbers",
      title = "Toggle Refugee Numbers",
      onclick = "toggleCountries(this)"
    ),
    tags$i(
      class = "fas fa-city legend-control contested-cities active",
      title = "Toggle Cities",
      onclick = "toggleCities(this)"
    ),
    tags$i(
      class = "fas fa-flag legend-control active country-focus",
      title = "Toggle Country Focus",
      onclick = "toggleCountryShapes(this)"
    ),
    tags$i(
      class = "fas fa-map legend-control map-tiles",
      title = "Toggle Map Tiles",
      onclick = "toggleTiles(this)"
    ),
    div(class = "separator"),
    tags$i(
      class = "fas fa-plus legend-control active",
      onclick = "document.querySelector('.leaflet-control-zoom-in').click()"
    ),
    tags$i(
      class = "fas fa-minus legend-control active",
      onclick = "document.querySelector('.leaflet-control-zoom-out').click()"
    ),
    div(class = "separator"),
    tags$i(
      class = "fas fa-crosshairs legend-control active",
      onclick = "resetZoom()"
    )
  ),

  `map-type` = flexPanel(
    class = "control-wrapper",
    direction = "column",
    gap = "10px",
    style = "text-align: center;",

    helpMenu(
      div("Border Points Information"),
      div(span("NEW"), "City Control View")
    ),

    tags$i(
      class = "fas fa-expand-arrows-alt legend-control external-view",
      style = "filter: invert(1);",
      title = "Toggle External View",
      onclick = "toggleExternal(this)"
    ),
    div(class = "separator"),
    tags$i(
      class = "fas fa-compress-arrows-alt legend-control internal-view",
      style = "filter: invert(1);",
      title = "Toggle Internal View",
      onclick = "toggleInternal(this)"
    )
  )
)

map_legend <- gridPanel(
  id = "overlayLegendGrid",

  columns = "1fr auto 1fr",
  rows = "1fr auto auto auto auto auto auto 1fr",
  areas = c(
    "... ...         ...",
    "... title       ...",
    "... description ...",
    "... stand       ...",
    "... about       ...",
    "... sources     ...",
    "... legend      ...",
    "... ...         ..."
  ),
  gap = "15px",

  title = div(
    class = "modal-title",
    "Refugees fleeing Ukraine - Live Information"
  ),

  description = div(
    p("
      General overview of movement information regarding refugees fleeing
      Ukraine.
    "),
    p("
      Data is compiled from diferent sources, updated multiple times a day.
    "),
    p("
      Includes migrant information in neighboring countries, city level control,
      as well as live information regarding border control points with
      neighboring countries.
    ")
  ),

  stand = flexPanel(
    class = "control-wrapper",
    direction = "column",
    style = "color: white;",

    p("#StandWithUkraine"),
    a(
      target = "_blank",
      href = "https://stand-with-ukraine.pp.ua/",
      "How you can help"
    ),
    a(
      target = "_blank",
      href = "https://war.ukraine.ua/",
      "More information on the ongoing war"
    )
  ),

  about = flexPanel(
    class = "control-wrapper",
    direction = "column",
    style = "color: white;",

    p("About this project"),

    flexPanel(
      gridPanel(class = "legend-item",
        columns = "30px 1fr",
        tags$i(class = "fab fa-github"),
        tags$span("Repository")
      ) %>% a(
        href = "https://github.com/pedrocoutinhosilva/UA-Refugee-Migration-Tracker",
        target = "_blank"
      ),
      gridPanel(class = "legend-item",
        columns = "30px 1fr",
        tags$i(class = "fab fa-linkedin"),
        tags$span("Pedro Silva")
      ) %>% a(
        href = "https://www.linkedin.com/in/pedrocoutinhosilva/",
        target = "_blank"
      ),
      gridPanel(class = "legend-item",
        columns = "30px 1fr",
        tags$i(class = "fab fa-twitter"),
        tags$span("@sparktuga")
      ) %>% a(href = "https://twitter.com/sparktuga", target = "_blank")
    )
  ),

  sources = flexPanel(
    class = "control-wrapper",
    direction = "column",
    style = "color: white;",

    p("Data Sources"),
    a(
      target = "_blank",
      href = "https://data2.unhcr.org/en/situations/ukraine",
      "UNHCR Operational data Portal"
    ),
    a(
      target = "_blank",
      href = "https://docs.google.com/spreadsheets/u/1/d/e/2PACX-1vTmKNAxZn2cPpBqPHnRx9Hc_GPzfi7U92h05hkNuES6pA8l7IcbfdRELMkTBWGcBFoRkUdwlnfX889X/pubhtml?gid=0&single=true",
      "Border information - Моніторинг черг на кордоні"
    ),
    a(
      target = "_blank",
      href = "https://en.wikipedia.org/wiki/Control_of_cities_during_the_Russo-Ukrainian_War",
      "Control of cities during the Russo-Ukrainian War"
    )
  ),

  legend = gridPanel(
    class = "control-wrapper map-legend",
    columns = list(
      default = "auto 1px auto",
      xs = "auto"
    ),
    rows = "auto auto auto",
    gap = "0 15px",

    areas = list(
      default = c(
        "title title title",
        "left sep right",
        "bottom bottom bottom"
      ),
      xs = c(
        "title",
        "left",
        "right",
        "bottom"
      )
    ),

    title = p("Map Legend"),

    left = gridPanel(
      columns = "auto auto",
      rows = "auto 18px",
      gap = "5px",

      areas = c(
        "title-type  title-type",
        "type-car    type-foot"
      ),

      `title-type` = div("Queue type"),

      `type-car` = gridPanel(class = "legend-item",
        columns = "auto 1fr",
        gap = "5px",
        tags$i(class = "fas fa-car"),
        tags$span("car")
      ),
      `type-foot` = gridPanel(class = "legend-item",
        columns = "auto 1fr",
        gap = "5px",
        tags$i(class = "fas fa-hiking"),
        tags$span("foot")
      )
    ),

    sep = div(class = "separator"),

    right = gridPanel(
      columns = "auto auto auto",
      rows = "auto 18px",
      gap = "10px",

      areas = c(
        "title-queue title-queue  title-queue",
        "queue-short queue-medium queue-long"
      ),

      `title-queue` = div("Waiting time"),

      `queue-short` = gridPanel(class = "legend-item",
        columns = "auto 1fr",
        gap = "10px",
        tags$i(class = "fas fa-circle wait-short"),
        tags$span("short")
      ),
      `queue-medium` = gridPanel(class = "legend-item",
        columns = "auto 1fr",
        gap = "10px",
        tags$i(class = "fas fa-circle wait-medium"),
        tags$span("medium")
      ),
      `queue-long` = gridPanel(class = "legend-item",
        columns = "auto 1fr",
        gap = "10px",
        tags$i(class = "fas fa-circle wait-long"),
        tags$span("long ")
      )
    ),

    bottom = gridPanel(
      columns = "auto auto",
      rows = "auto 18px",
      gap = "10px",
      style = "padding-top: 15px;",

      areas = c(
        "title-type title-type",
        "type-large type-small"
      ),

      `title-type` = div("Displaced Refugees"),

      `type-large` = gridPanel(class = "legend-item",
        columns = "30px 1fr",

        tags$i(class = "fas fa-male"),
        tags$span("1.000.000s")
      ),
      `type-small` = gridPanel(class = "legend-item",
        columns = "30px 1fr",

        tags$i(class = "fas fa-male"),
        tags$span("100.000s")
      )
    )
  )
)

details_overlay <- gridPanel(
  id = "overlayGrid",
  columns = list(
    default = "1fr 500px 1fr",
    xs = "auto"
  ),
  rows = list(
    default = "auto 1fr",
    xs = "auto 1fr"
  ),

  areas = list(
    default = c(
      "... popup ...",
      "... ...   ..."
    ),
    xs = c(
      "popup",
      "..."
    )
  ),
  popup = checkpointPopup(
    div(id = "checkpointInnerTitle"),
    div(id = "checkpointOuterTitle"),
    div(id = "carHours"),
    div(id = "carKM"),
    div(id = "pedestrianHours"),
    div(id = "pedestrianNumber"),
    div(id = "lastUpdate"),
    div(id = "telegramChats"),
    div(id = "googleLink")
  )
)

ui <- gridPage(
  pwa(
    "https://sparktuga.shinyapps.io/shinyukraini/",
    title = "Slava Ukraini - Refugee Live Information",
    icon = "www/icon.png",
    output = "www",
    color = "#222222"
  ) %>%
  suppressWarnings() %>%
  suppressMessages(),

  dependencies,
  loader,

  app_title,
  map_controls,
  map_legend,
  details_overlay,

  leafletOutput("mymap")
)
