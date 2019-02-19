library(shinydashboard)
library(leaflet)
library(dplyr)

header <- dashboardHeader(
  title = "Twin Cities Buses"
)


body <- dashboardBody(
  fluidRow(
    column(width = 9,
      box(width = NULL, solidHeader = TRUE,
        leafletOutput("mymap", height = 500)
      ),
      box(width = NULL,
        uiOutput("numVehiclesTable")
      )
),
    column(width = 3,
      box(width = NULL, status = "warning",
        uiOutput("routeSelect"),
        checkboxGroupInput("directions", "Show",
          choices = c(
            Northbound = 4,
            Southbound = 1,
            Eastbound = 2,
            Westbound = 3
          ),
          selected = c(1, 2, 3, 4)
)
)
)
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)


# ui <- pageWithSidebar(
#   headerPanel('Buhayra app for Alentejo'),
#   sidebarPanel(
#     selectInput('xcol', 'X Variable', c(1,2,3)),
#   mainPanel(
#     leafletOutput("mymap")
#   )
# ))

# ui <- fluidPage(leafletOutput("mymap"),p())
