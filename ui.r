library(shinydashboard)
library(leaflet)
library(dplyr)

#shiny::includeCSS('/srv/shiny-server/buhayra-app/www/cursor.css')

csscode <- HTML("
#mymap {
  cursor: auto !important;
}"
)

navbarPage("Reservoirs in real time", id="nav",

  tabPanel("Interactive map",
    div(class="outer",

      # tags$head(
      #   # Include our custom CSS
      #   includeCSS("styles.css"),
      #   includeScript("gomap.js")
      # ),

      # If not using custom CSS, set height of leafletOutput to a number instead of percent
      leafletOutput("mymap", width="100%", height="100%"),

      # Shiny versions prior to 0.11 should use class = "modal" instead.
      absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
        draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
        width = 330, height = "auto",

        h2("Municipalities"),

        # selectInput("color", "Color", vars),
        # selectInput("size", "Size", vars, selected = "adultpop"),
        # conditionalPanel("input.color == 'superzip' || input.size == 'superzip'",
        #   # Only prompt for threshold when coloring or sizing by superzip
        #   numericInput("threshold", "SuperZIP threshold (top n percentile)", 5)
        # ),

        # plotOutput("histCentile", height = 200),
        plotOutput("plot", height = 250)
      ),

      # tags$div(id="cite",
      #   'Data compiled for ', tags$em('Coming Apart: The State of White America, 1960–2010'), ' by Charles Murray (Crown Forum, 2012).'
      # )
    )
  ),


  conditionalPanel("false", icon("crosshair"))
)
#
#   fluidRow(
#     column(width = 9,
#       box(width = NULL, solidHeader = TRUE,
#         leafletOutput("mymap", height = 500)
#       )),
#     column(width = 3,
#       box(width = NULL, status = "warning",
#         checkboxGroupInput("datasets", "Mostrar",
#           choices = c(
#             `Referência (JRC, dados estáticos)` = 1,
#             `buhayra/Sentinel-1` = 2
#           ),
#           selected = c(1,2)
#           ),
#         p(
#             class = "text-muted",
#             paste("Clique sobre uma albufeira para consultar a série temporal")
#         ),
#         plotOutput("plot"))
# )
# )
# )
#
# dashboardPage(
#   header,
#   dashboardSidebar(disable = TRUE),
#   body
# )
