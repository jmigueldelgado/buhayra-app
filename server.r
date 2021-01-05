library(shinydashboard)
library(leaflet)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)


function(input, output, session) {
    # define available layers
    wms_layers <- data.frame(layer=c("watermask","JRC-Global-Water-Bodies"),id=c(1,2)) %>% mutate(layer=as.character(layer))

    
    output$mymap <- renderLeaflet({
        activelayers <- filter(wms_layers,id %in% as.numeric(input$datasets)) %>% pull(layer)

        source("/srv/shiny-server/buhayra-app/pw.R")

        leaflet() %>%
            addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
            setView(-38.5,-5.3, zoom=12) %>%
            addWMSTiles(
                paste0("http://",mapserver_host,"/latestwms"),
                layers = activelayers,
                options = WMSTileOptions(format = "image/png",
                                         transparent = TRUE,
                                         version='1.3.0',
                                         srs='EPSG:4326')) %>%
            addScaleBar(position = "topleft")
    })
    observeEvent(input$mymap_click,
    {
        click <- input$mymap_click
        source("/srv/shiny-server/buhayra-app/pw.R")
        drv <- dbDriver("PostgreSQL")
        con <- dbConnect(drv, dbname='watermasks', host = db_host, port = 5432, user = "sar2water", password = pw)
        rm(pw)
        ts <- dbGetQuery(con, paste0("SELECT jrc_demo.id_jrc, ST_area(ST_Transform(jrc_demo.geom,32629)) as ref_area,demo.area,demo.ingestion_time,demo.source_id,scene_demo.mission_id,scene_demo.pass FROM jrc_demo RIGHT JOIN demo ON jrc_demo.id_jrc=demo.id_jrc RIGHT JOIN scene_demo ON demo.ingestion_time = scene_demo.ingestion_time WHERE ST_Contains(jrc_demo.geom, ST_SetSRID(ST_Point(",click$lng,",",click$lat,"),4326))"))
        dbDisconnect(conn = con)

        if(nrow(ts) == 0)
        {
            text <- "Albufeira vazia ou indisponível" #required info
            leafletProxy("mymap") %>%
                clearPopups() %>%
                addPopups(click$lng, click$lat, text)
        }
        else
        {
            output$plot <- renderPlot({
                ts %>%
                    filter(area>0) %>%
                    ggplot +
                    geom_point(aes(x=ingestion_time,y=area/10000,color=mission_id,shape=pass)) +
                    scale_y_continuous(limits=c(0,1.1*max(ts$ref_area)/10000)) +
                    geom_hline(yintercept=ts$ref_area[1]/10000,linetype='dashed',color='orange') +
                    xlab("Data de Aquisição") +
                    ylab("Área [ha]") +
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
            #text <- paste0("Área do Espelho de Água: ",ts
                           ## filter(area>0) %>%
                           ## filter(ingestion_time == max(ingestion_time)) %>%
                           ## mutate(area=round(area/10000, digits = 1)) %>%
                           ## pull(area),
                           ## " ha",
                           ## "<br>",
                           ## "Data e Hora de Aquisição: ",
                           ## strptime(max(ts$ingestion_time),"%Y-%m-%d %H:%M:%S"),
                           ## "<br>",
                           ## "ID: ",
                           ## ts$id_jrc[1])
            leafletProxy("mymap") %>%
                clearPopups() %>%
                addPopups(click$lng, click$lat, text)
        }


    })


}
