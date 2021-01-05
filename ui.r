library(shinydashboard)
library(leaflet)
library(dplyr)

#shiny::includeCSS('/srv/shiny-server/buhayra-app/www/cursor.css')

csscode <- HTML("
#mymap {
  cursor: auto !important;
}"
)

header <- dashboardHeader(
    title = 'Albufeiras em Tempo Real - Demonstração',
    titleWidth = 800
)

##### test branch

body <- dashboardBody(tags$style(csscode),
  fluidRow(
    column(width = 9,
      box(width = NULL, solidHeader = TRUE,
        leafletOutput("mymap", height = 500)
      )),
    column(width = 3,
      box(width = NULL, status = "warning",
        checkboxGroupInput("datasets", "Mostrar",
          choices = c(
            `Referência (JRC, dados estáticos)` = 1,
            `buhayra/Sentinel-1` = 2
          ),
          selected = c(1,2)
          ),
        p(
            class = "text-muted",
            paste("Clique sobre uma albufeira para consultar a série temporal")
        ),
        plotOutput("plot"))
)
)
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)
