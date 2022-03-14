loader <- gridPanel(
  id = "overlayLoading",

  columns = "1fr auto 1fr",
  rows = "1fr auto 1fr",

  areas = c(
    "... ... ...",
    "... loader ...",
    "... ... ..."
  ),

  loader = div(
    span("Retrieving Live data..."),
    div(class = "flag")
  )
)
