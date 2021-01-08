library(leaflet)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)
library(sf)



function(input, output, session) {


    municipios=st_read('data/municipios_ce_simple.geojson') %>% mutate(pop=as.numeric(as.character(Pop_Est_17)))

    bins <- c(0, 1000, 2000, 5000, 10000, 20000, 50000, 100000, Inf)
    pal <- colorBin("YlOrRd", domain = municipios$pop, bins = bins)


    wms_layers <- list('Watermasks and Static Water Bodies'=c("watermask","JRC-Global-Water-Bodies"),'Only Watermasks'=c('watermask'))

    source("/srv/shiny-server/buhayra-app/pw.R")
    
    output$mymap <- renderLeaflet({
        active_layers  <- wms_layers[[input$datasets]]


        map=leaflet() %>%
            addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
            setView(-38.5,-5.3, zoom=12) %>%
            addWMSTiles(paste0("http://",mapserver_host,"/latestwms"),
                        layers = active_layers,
                        options = WMSTileOptions(format = "image/png",
                                                 transparent = TRUE,
                                                 version='1.3.0',
                                                 srs='EPSG:4326')) %>%
            addScaleBar(position = "topleft")
        


    }) # end of renderLeaflet

    observe({

        proxy = leafletProxy("mymap",data = municipios) %>%
            clearPopups() %>%
            clearShapes()
        
        labels <- sprintf(
            "<strong>%s</strong><br/>%g people",
            municipios$NM_MUNICIP, municipios$pop) %>%
            lapply(htmltools::HTML)

        if(input$municipios) {
            proxy %>% addPolygons(fillColor = ~pal(pop),
                                  weight = 2,
                                  opacity = 1,
                                  color = "white",
                                  dashArray = "3",
                                  fillOpacity = 0.7,
                                  highlight = highlightOptions(
                                      weight = 5,
                                      color = "#666",
                                      dashArray = "",
                                      fillOpacity = 0.7,
                                      bringToFront = TRUE),
                                  label = labels,
                                  labelOptions = labelOptions(
                                      style = list("font-weight" = "normal", padding = "3px 8px"),
                                      textsize = "15px",
                                      direction = "auto"))
        }
    }) # end of observe addPolygons municipios
    
    output$selected_var <- renderText({
        as.character(input$municipios)
    })

   
    
    observeEvent(input$mymap_click,
    {
        if(!input$municipios) {
            click <- input$mymap_click
                source("/srv/shiny-server/buhayra-app/pw.R")
            drv <- dbDriver("PostgreSQL")
            con <- dbConnect(drv, dbname='watermasks', host = db_host, port = 5432, user = "sar2water", password = pw)
            rm(pw)
            ts <- dbGetQuery(con, paste0("SELECT jrc_demo.id_jrc, ST_area(ST_Transform(jrc_demo.geom,32629)) as ref_area,demo.area,demo.ingestion_time,demo.source_id,scene_demo.mission_id,scene_demo.pass FROM jrc_demo RIGHT JOIN demo ON jrc_demo.id_jrc=demo.id_jrc RIGHT JOIN scene_demo ON demo.ingestion_time = scene_demo.ingestion_time WHERE ST_Contains(jrc_demo.geom, ST_SetSRID(ST_Point(",click$lng,",",click$lat,"),4326))"))
            dbDisconnect(conn = con)
            
            if(nrow(ts) == 0)
            {
                text <- "Unable to find a reservoir on this location" #required info
                leafletProxy("mymap") %>%
                    clearPopups() %>%
                        addPopups(click$lng, click$lat, text)
            }
            else
            {
                output$tsVol <- renderPlot({
                    ts %>%
                        filter(area>0) %>%
                        ggplot +
                        geom_point(aes(x=ingestion_time,y=area/10000,color=mission_id,shape=pass)) +
                        scale_y_continuous(limits=c(0,1.1*max(ts$ref_area)/10000)) +
                        geom_hline(yintercept=ts$ref_area[1]/10000,linetype='dashed',color='orange') +
                        xlab("Acquisition Date") +
                        ylab("Area [ha]") +
                        theme(legend.position='bottom')
                })
                
                text= paste0("ID: ",ts$id_jrc[1],"<br>",ts %>%
                                                        mutate(`area [ha]`=area/10000) %>%
                                                        dplyr::select(`area [ha]`,ingestion_time) %>%
                                                        distinct(ingestion_time,.keep_all=TRUE) %>%
                                                        arrange(desc(ingestion_time)) %>%
                                                        slice(1:3) %>%
                                                        knitr::kable(.,"html") %>%
                                                        kableExtra::kable_styling())
                leafletProxy("mymap") %>%
                    clearPopups() %>%
                    addPopups(click$lng, click$lat, text)
            }
        }
    }) # end of observeEvent(input$mymap_click,

     

}
