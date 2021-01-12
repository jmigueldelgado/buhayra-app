library(leaflet)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)
library(sf)

query_watermask  <- function(click){
    source("/srv/shiny-server/buhayra-app/pw.R")
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname='watermasks', host = db_host, port = 5432, user = "sar2water", password = pw)
    rm(pw)
    ts <- dbGetQuery(con, paste0("SELECT jrc_demo.id_jrc, ST_area(ST_Transform(jrc_demo.geom,32629)) as ref_area, ST_Perimeter(ST_Transform(jrc_demo.geom,32629)) as ref_perimeter, demo.area,demo.ingestion_time,demo.source_id,scene_demo.mission_id,scene_demo.pass FROM jrc_demo RIGHT JOIN demo ON jrc_demo.id_jrc=demo.id_jrc RIGHT JOIN scene_demo ON demo.ingestion_time = scene_demo.ingestion_time WHERE ST_Contains(jrc_demo.geom, ST_SetSRID(ST_Point(",click$lng,",",click$lat,"),4326))"))
    dbDisconnect(conn = con)
    return(ts)
}


#pol=catchments %>% filter(ID==6121095870)
#pol=municipios %>% filter(ID==2308708)
#pol=municipios %>% filter(ID==2304269)


query_on_sf  <- function(pol){
    source("/srv/shiny-server/buhayra-app/pw.R")
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname='watermasks', host = db_host, port = 5432, user = "sar2water", password = pw)
    rm(pw)

    q_string=paste0("SELECT jrc_demo.id_jrc, ST_area(ST_Transform(jrc_demo.geom,32629)) as ref_area,, ST_Perimeter(ST_Transform(jrc_demo.geom,32629)) as ref_perimeter, demo.area,demo.ingestion_time,demo.source_id FROM jrc_demo RIGHT JOIN demo ON jrc_demo.id_jrc=demo.id_jrc WHERE ST_Intersects(jrc_demo.geom, '",st_as_text(pol$geometry,EWKT=TRUE),"');")

    ts <- dbGetQuery(con,q_string)
    dbDisconnect(conn = con)
    return(ts)
}


plot_watermask_ts  <- function(ts) {
    plt = ts %>%
        filter(area>0) %>%
        ggplot +
        geom_point(aes(x=ingestion_time,y=area/10000,color=mission_id,shape=pass)) +
        scale_y_continuous(limits=c(0,1.1*max(ts$ref_area)/10000)) +
        geom_hline(yintercept=ts$ref_area[1]/10000,linetype='dashed',color='orange') +
        xlab("Acquisition Date") +
        ylab("Area [ha]") +
        theme(legend.position='bottom')
    return(plt)
}

plot_aggregated_ts  <- function(ts) {
    ts_clean = ts %>% distinct(id_jrc,ingestion_time,.keep_all=TRUE)
    all = ts_clean %>% tidyr::expand(id_jrc,ingestion_time)
    ts_crunched=left_join(all,ts_clean) %>%
        group_by(id_jrc) %>%
        arrange(ingestion_time) %>%
        tidyr::fill(area,source_id,ref_area) %>%
        ungroup %>%
        group_by(ingestion_time) %>%
        summarise(`Acquisition Date`=first(ingestion_time),`Total Area [ha]`=sum(area),`Reference Area`=sum(ref_area),Mission=first(source_id))

    plt = ts_crunched %>%
        ggplot +
        geom_point(aes(x=`Acquisition Date`,y=`Total Area [ha]`/10000,color=Mission)) +
        scale_y_continuous(limits=c(0,1.1*ts_crunched$`Reference Area`[1]/10000)) +
        geom_hline(yintercept=ts_crunched$`Reference Area`[1]/10000,linetype='dashed',color='orange') +
        ylab("Total Area [ha]") +
        theme(legend.position='bottom')
    return(plt)
}
