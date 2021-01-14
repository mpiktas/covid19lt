library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

source("R/functions.R")
geojson <- TRUE

if(geojson) {
    osp <- GET("https://opendata.arcgis.com/datasets/45b76303953d40e2996a3da255bf8fe8_0.geojson")
    osp1 <- fromJSON(rawToChar(osp$content))$features$properties
    osp1 <- osp1 %>% mutate(date = ymd(ymd_hms(date)))
} else {

    httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
    posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/COVID_atvejai_chart/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=true&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pjson&token=")
    posp1 <- fix_esridate(rawToChar(posp$content))
    posp2 <- posp1 %>% mutate(day = ymd(date))

    alls <- lapply(unique(posp2$municipality_name), function(x) {
        sav <- URLencode(x)
        try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/COVID_atvejai_chart/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&returnGeodetic=false&outFields=*&returnGeometry=true&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=pjson&token=")))
        })

    osp1 <- lapply(alls, function(l)fix_esridate(rawToChar(l$content))) %>% bind_rows

}

osp1 %>% arrange(date, municipality_code) %>% write.csv("raw_data/osp/osp_covid19_cases.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")

adm <- adm %>% rbind(
    data.frame(administrative_level_2 = c("Unknown","Lithuania"),
                                administrative_level_3 = c("Unknown","Lithuania"),
                                municipality_name = c("nenustatyta","Lietuva"),
                                population = c(0,sum(adm$population)))
    )

osp3 <- osp2 %>% inner_join(adm %>% select(-population))

if(nrow(osp3) == nrow(osp2)) {
    osp3 %>% select(day, municipality_code, administrative_level_3,
                    confirmed_cases, recovered_cases, active_cases, deaths, other_deaths,
                    confirmed_cases_cumulative, recovered_cases_cumulative, deaths_cumulative,
                    other_deaths_cumulative) %>%
        arrange(day, municipality_code) %>%
        write.csv("data/lt-covid19-cases.csv", row.names = FALSE)
}
