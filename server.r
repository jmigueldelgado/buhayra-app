library(shinydashboard)
library(leaflet)
library(dplyr)

# library(RPostgreSQL)


function(input, output, session) {


  output$routeSelect <- renderUI({
    routeNums <- c('a','b','c')
    # Add names, so that we can add all=0
    names(routeNums) <- routeNums
    routeNums <- c(All = 0, routeNums)
    selectInput("routeNum", "Route", choices = routeNums, selected = routeNums[2])
})


#
#
# server <- function(input, output, session) {
#
#
     output$mymap <- renderLeaflet({
       leaflet() %>%
         addProviderTiles(providers$CartoDB.Positron) %>%
         setView(-8,38, zoom=7) %>%
         addWMSTiles(
           "http://141.89.96.184/latestwms",
            layers = "JRC-Global-Water-Bodies-sib",
            options = WMSTileOptions(format = "image/png",
                                     transparent = TRUE,
                                     version='1.3.0',
                                     srs='EPSG:4326'))
#           addWMSTiles(
#            "http://141.89.96.184/latestwms",
#             layers = "watermask-sib",
#             options = WMSTileOptions(format = "image/png",
#                                      transparent = TRUE,
#                                      version='1.3.0',
#                                      srs='EPSG:4326')) %>%
#
#           # addScaleBar(position = "topleft")
#       })

#        # # show reservoir information ####
#        observeEvent(input$mymap_click, {
#          click <- input$mymap_click
#
#        source("/srv/shiny-server/buhayra-app/pw.R")
#        drv <- dbDriver("PostgreSQL")
#        con <- dbConnect(drv, dbname='watermasks', host = "localhost", port = 5432, user = "sar2water", password = pw)
#        rm(pw)
#        area <- dbGetQuery(con, paste0("SELECT area FROM sib WHERE ST_Contains(geom, ST_SetSRID(ST_Point(",click$lng,",",click$lat,"),4326))
# #                                      AND EXTRACT(month FROM ingestion_time) =", input$M3, "AND EXTRACT(year FROM ingestion_time) =", input$Y3, "ORDER BY ingestion_time DESC Limit 1"))
#
#        dbDisconnect(conn = con)
#
#        if(length(area) == 0) {
#          text <- "here is no reservoir" #required info
#          proxy <- leafletProxy("mymap")
#          proxy %>% clearPopups() %>%
#          addPopups(click$lng, click$lat, text)
#        }
#
#        else {
#          text <- paste0("reservoir extent ", input$M3,"-", input$Y3, ": ", round(area/10000, digits = 1), " ha") #required info
#          proxy <- leafletProxy("mymap")
#          proxy %>% clearPopups() %>%
#          addPopups(click$lng, click$lat, text)
#        }
#
#        })


}

shinyApp(ui, server)
