library(leaflet)
library(dplyr)

# define primary elements of dashboard

map=leafletOutput("mymap", height="100%", width="100%")

#vars=c('Watermasks and Static Water Bodies','Only Watermasks')
vars=c('None','Municipalities','Catchments')

panel1 = absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
        draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
        width = 330, height = "auto",
        h2("Water storage dynamics"),
        p("Click on a reservoir or overlay to obtain a time-series"),
        selectInput("datasets", "Overlays", vars),
        plotOutput('tsVol'),
#        checkboxInput("municipios", "Overlay Municipalities", FALSE),
        textOutput("selected_var")
        )


division1 = div(class="outer",tags$head(includeCSS('styles.css')),map,panel1)

tab1=tabPanel("Interactive map", division1)
tab2=tabPanel("Component 2")
tab3=tabPanel("Component 3")


navbarPage(
  "Reservoirs in real time",id="nav",
  tab1
#  tab2,
#  tab3
)


