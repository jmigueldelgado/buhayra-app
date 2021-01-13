library(leaflet)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)
library(sf)



function(input, output, session) {

    load('data/municipios_ce_simple.RData')
    municipios=municipios_ce_simple %>% mutate(pop=as.numeric(as.character(Pop_Est_17))) %>% rename(ID=CD_GEOCMU)
    load('data/catchment_geometry_simple.RData')
    catchments=catchment_geometry_simple %>% rename(ID=HYBAS_ID) %>% st_set_crs(st_crs(municipios))
    bins <- c(0, 1000, 2000, 5000, 10000, 20000, 50000, 100000, Inf)
    pal <- colorBin("YlOrRd", domain = municipios$pop, bins = bins)

    

    wms_layers <- list('Watermasks and Static Water Bodies'=c("watermask","JRC-Global-Water-Bodies"))
    overlay_layers <- list('Municipalities'=municipios,'Catchments'=catchments,'None'=NA)
    
    source("/srv/shiny-server/buhayra-app/pw.R")
    
    output$mymap <- renderLeaflet({
        active_layers  <- wms_layers[['Watermasks and Static Water Bodies']]

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
 #       if(input$datasets!='None') {
        proxy = leafletProxy("mymap",data = overlay_layers[[input$datasets]]) %>%
                                       clearPopups() %>%
                                       clearShapes()
                                        #        }
        if(input$datasets=='None'){
            proxy
        }

        if(input$datasets=='Municipalities'){
            labels <- sprintf(
                "<strong>%s</strong><br/>%g people",
                overlay_layers[[input$datasets]]$NM_MUNICIP, overlay_layers[[input$datasets]]$pop) %>%
                lapply(htmltools::HTML)        
            
            proxy %>% addPolygons(fillColor = ~pal(pop),
                                  layerId=~ID,
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

        if(input$datasets=='Catchments'){
            labels <- sprintf(
                "<strong>%s</strong><br/>%g km2",
                overlay_layers[[input$datasets]]$ID, overlay_layers[[input$datasets]]$SUB_AREA) %>%
                lapply(htmltools::HTML)        
            
            proxy %>% addPolygons(layerId=~ID,
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
    })
                 

    
    
    observeEvent(input$mymap_click,
    {
        if(input$datasets=='None') {
            click <- input$mymap_click
            ts = query_watermask(click)
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
                    plot_watermask_ts(ts,10000*input$thresh)
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

    observeEvent(input$mymap_shape_click,
    {
        ts = query_on_sf( overlay_layers[[input$datasets]] %>% filter(ID==input$mymap_shape_click$id))        
        if(nrow(ts) == 0)
        {
            text <- "Unable to find a reservoir on this location" #required info
            leafletProxy("mymap") %>%
                clearPopups() %>%
                addPopups(input$mymap_shape_click$lng, input$mymap_shape_click$lat, text)
        }
            else
        {
            output$tsVol <- renderPlot({
                plot_aggregated_ts(ts,10000*input$thresh)
            })
        }
            
    }) # end of observer event shape click
    
    output$selected_var <- renderText({  
        paste(input$mymap_shape_click$id,input$mymap_click$lng,input$mymap_click$lat,sep=' | ')
    })
     

}
