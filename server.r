library(shinydashboard)
library(leaflet)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)

function(input, output, session) {
    # define available layers
    wms_layers <- data.frame(layer=c("JRC-Global-Water-Bodies-sib", "watermask-sib"),id=c(1,2)) %>% mutate(layer=as.character(layer))


    output$mymap <- renderLeaflet({
        activelayers <- filter(wms_layers,id %in% as.numeric(input$datasets)) %>% pull(layer)

        leaflet() %>%
            addProviderTiles(providers$OpenStreetMap.Mapnik) %>%
            setView(-8,38, zoom=7) %>%
            addWMSTiles(
                "http://141.89.96.184/latestwms",
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
        con <- dbConnect(drv, dbname='watermasks', host = "localhost", port = 5432, user = "sar2water", password = pw)
        rm(pw)
        ts <- dbGetQuery(con, paste0("SELECT jrc_sib.id_jrc, ST_area(ST_Transform(jrc_sib.geom,32629)) as ref_area,sib.area,sib.ingestion_time FROM jrc_sib RIGHT JOIN sib ON jrc_sib.id_jrc=sib.id_jrc WHERE ST_Contains(jrc_sib.geom, ST_SetSRID(ST_Point(",click$lng,",",click$lat,"),4326))"))
        dbDisconnect(conn = con)

        output$plot <- renderPlot({
            ggplot(ts) +
                geom_point(aes(x=ingestion_time,y=area/10000)) +
                scale_y_continuous(limits=c(0,1.1*max(ts$area[1])/10000)) +
                geom_hline(yintercept=ts$ref_area[1]/10000,linetype='dashed',color='orange') +
                xlab("Data de Aquisição") +
                ylab("Área [ha]")
        })



        if(nrow(ts) == 0)
        {
            text <- "Albufeira vazia ou indisponível" #required info
            leafletProxy("mymap") %>%
                clearPopups() %>%
                addPopups(click$lng, click$lat, text)
        }
        else
        {
            return_click = ts %>%
                mutate(area=round(area/10000, digits = 1)) %>%
                filter(area>0) %>%
                filter(ingestion_time == max(ingestion_time))

            if(nrow(return_click)==0)
            {
                text = "Albufeira vazia ou indisponível"
            } else
            {
                text <- paste0("Área do Espelho de Água: ",
                               return_click$area[1],
                               " ha",
                               "<br>",
                               "Data e Hora de Aquisição: ",
                               strptime(return_click$ingestion_time[1],"%Y-%m-%d %H:%M:%S"),
                               "<br>",
                               "ID: ",
                               return_click$id_jrc[1])
             }
            leafletProxy("mymap") %>%
                clearPopups() %>%
                addPopups(click$lng, click$lat, text)
        }

    })


}
