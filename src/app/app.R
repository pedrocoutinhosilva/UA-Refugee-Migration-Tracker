# Single-file entry point for hosts that need one primary file, such as
# Posit Connect Cloud. Shiny does not source global.R for app.R apps.
source("global.R")
source("ui.R")
source("server.R")

shinyApp(ui, server)
