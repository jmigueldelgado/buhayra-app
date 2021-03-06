library(leaflet)
library(dplyr)
library(RPostgreSQL)
library(ggplot2)
library(sf)

#click = data.frame(lng=-38.540039,lat=-5.566782)

query_watermask  <- function(click){
    source("/srv/shiny-server/buhayra-app/pw.R")
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname='watermasks', host = db_host, port = 5432, user = "readonly", password = pw)
    rm(pw)
    ts <- dbGetQuery(con, paste0("SELECT jrc_demo.id_jrc, ST_area(ST_Transform(jrc_demo.geom,32629)) as ref_area, ST_Perimeter(ST_Transform(jrc_demo.geom,32629)) as ref_perimeter, demo.area,demo.ingestion_time,demo.source_id FROM jrc_demo RIGHT JOIN demo ON jrc_demo.id_jrc=demo.id_jrc WHERE ST_Contains(jrc_demo.geom, ST_SetSRID(ST_Point(",click$lng,",",click$lat,"),4326))"))
    dbDisconnect(conn = con)
    return(ts)
}



#pol=catchments %>% filter(ID==6121095870)
#pol=municipios %>% filter(ID==2308708)
#pol=municipios %>% filter(ID==2304269)


query_on_sf  <- function(pol){
    source("/srv/shiny-server/buhayra-app/pw.R")
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname='watermasks', host = db_host, port = 5432, user = "readonly", password = pw)
    rm(pw)

    q_string=paste0("SELECT jrc_demo.id_jrc, ST_area(ST_Transform(jrc_demo.geom,32629)) as ref_area, ST_Perimeter(ST_Transform(jrc_demo.geom,32629)) as ref_perimeter, demo.area,demo.ingestion_time,demo.source_id FROM jrc_demo RIGHT JOIN demo ON jrc_demo.id_jrc=demo.id_jrc WHERE ST_Intersects(jrc_demo.geom, '",st_as_text(pol$geometry,EWKT=TRUE),"');")

    ts <- dbGetQuery(con,q_string)
    dbDisconnect(conn = con)
    return(ts)
}

#pol1=municipios %>% filter(ID==2306702)
#pol2=municipios %>% filter(ID==2311306)

## ts1=query_on_sf(pol1)
## ts2=query_on_sf(pol2)
## ts_comb=bind_rows(ts1,ts2)
## ref=ts_comb %>% group_by(id_jrc) %>% summarise(P=first(ref_perimeter),A=first(ref_area)) %>% arrange(A,.keep_all=TRUE) %>%
##     mutate(alpha_mod=modified_alpha(P,A),K_mod=modified_K(P,A), ref_volume=modified_molle(A,alpha_mod,K_mod))


plot_watermask_ts  <- function(ts,threshold) {
        ts_crunched=ts %>%
            filter(area>0,ref_area<threshold) %>%
            mutate(alpha_mod=modified_alpha(ref_perimeter,ref_area),K_mod=modified_K(ref_perimeter,ref_area), volume=ifelse(area>5000,modified_molle(area,alpha_mod,K_mod),molle(area)),ref_volume=modified_molle(ref_area,alpha_mod,K_mod)) %>%
            filter(!is.na(ref_volume))

        volmax=ts_crunched$ref_volume[1]/1000000
        plt=ts_crunched %>%
            ggplot +
            geom_point(aes(x=ingestion_time,y=volume/1000000)) +#,color=mission_id,shape=pass)) +
            scale_y_continuous(limits=c(0,1.1*volmax)) +
            geom_hline(yintercept=volmax,linetype='dashed',color='orange') +
            xlab("Acquisition Date") +
            ylab(expression(~Measured~Volume~'['*hm^3*']')) +
            theme(legend.position='bottom')
    return(plt)
}

plot_aggregated_ts  <- function(ts,threshold) {
    ts_clean = ts %>% distinct(id_jrc,ingestion_time,.keep_all=TRUE)
    all = ts_clean %>% tidyr::expand(id_jrc,ingestion_time)
    ts_crunched=left_join(all,ts_clean) %>%
        group_by(id_jrc) %>%
        arrange(ingestion_time) %>%
        tidyr::fill(area,source_id,ref_area,ref_perimeter) %>%
        ungroup %>%
        filter(area>0,ref_area<threshold) %>%
        mutate(alpha_mod=modified_alpha(ref_perimeter,ref_area),K_mod=modified_K(ref_perimeter,ref_area), volume=ifelse(area>5000,modified_molle(area,alpha_mod,K_mod),molle(area)),ref_volume=modified_molle(ref_area,alpha_mod,K_mod)) %>%
        filter(!is.na(ref_volume)) %>%
        group_by(ingestion_time) %>%
        summarise(`Acquisition Date`=first(ingestion_time),`Measured Volume [hm^3]`=sum(volume,na.rm=TRUE)/1000000,`Maximum Volume`=sum(ref_volume,na.rm=TRUE)/1000000,Mission=first(source_id))

    plt = ts_crunched %>%
        ggplot +
        geom_point(aes(x=`Acquisition Date`,y=`Measured Volume [hm^3]`,color=Mission)) +
        scale_y_continuous(limits=c(0,1.1*ts_crunched$`Maximum Volume`[1])) +
        geom_hline(yintercept=ts_crunched$`Maximum Volume`[1],linetype='dashed',color='orange') +
        ylab(expression(~Measured~Volume~'['*hm^3*']')) +
        theme(legend.position='bottom')
    return(plt)
}
