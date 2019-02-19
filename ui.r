library(shinydashboard)
library(leaflet)
library(dplyr)

header <- dashboardHeader(
    title = 'Albufeiras em Tempo Real - Demonstração',
    titleWidth = 800
)


body <- dashboardBody(
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
          selected = c(1, 2)
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
