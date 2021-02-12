library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

source("R/functions.R")
geojson <- FALSE

if(geojson) {
} else {

    httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

    posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/OV_COVID_grafikai_serga_mirtys/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=")

    posp1 <- fix_esridate(rawToChar(posp$content))
    posp2 <- posp1 %>% mutate(day = ymd(date))

    alls <- lapply(unique(posp2$municipality_name), function(x) {
        sav <- URLencode(x)
            try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/OV_COVID_grafikai_serga_mirtys/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=")))
        })

    osp1 <- lapply(alls, function(l)fix_esridate(rawToChar(l$content))) %>% bind_rows

}

osp1 %>% arrange(date, municipality_code) %>% select(-municipality_order,-object_id) %>% write.csv("raw_data/osp/osp_covid19_deaths.csv", row.names = FALSE)

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
    osp4 <- osp3 %>% select(day, municipality_code, administrative_level_3,
                    tests_daily = dgn_tot_day, tests_positive_daily = dgn_pos_day,
                    deaths_1_daily = daily_deaths_def1, deaths_2_daily= daily_deaths_def2, deaths_3_daily = daily_deaths_def3 ) %>%
        arrange(day, municipality_code)
    osp4 %>% write.csv("data/lt-covid19-deaths.csv", row.names = FALSE)
}
