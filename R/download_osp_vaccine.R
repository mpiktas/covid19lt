library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)
library(tidyr)

source("R/functions.R")

httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
posp <- tryget("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/COVID_vakcinacijos_chart/FeatureServer/0/query?where=1%3D1&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=date+desc&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=")
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(date))

alls <- lapply(unique(posp2$municipality_name), function(x) {
    sav <- URLencode(x)
    try(tryget(glue::glue("https://services3.arcgis.com/MF53hRPmwfLccHCj/ArcGIS/rest/services/COVID_vakcinacijos_chart/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&resultType=none&outFields=*&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&sqlFormat=none&f=pjson&token=")))
    })

osp1 <- lapply(alls, function(l)fix_esridate(rawToChar(l$content))) %>% bind_rows

osp1 %>% arrange(date, municipality_code) %>% write.csv("raw_data/osp/osp_covid19_vaccine.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(date))

adm <- read.csv("raw_data/administrative_levels.csv")


osp3 <- osp2 %>% inner_join(adm)

if(nrow(osp3) == nrow(osp2)) {
    osp4 <- osp3 %>%select(day, municipality_code, administrative_level_2,administrative_level_3,
                    dose_number,  vaccinated = vaccinated_cumulative, vaccinated_daily = vaccinated
                    )
    dosed <- data.frame(dose_number=c("Pirma dozė", "Antra dozė"), dose = c(1,2))
    osp5 <- osp4 %>% inner_join(dosed) %>% select(-dose_number)
    osp6 <- osp5 %>% pivot_wider(id_cols = day:administrative_level_3, names_from = "dose",
                                  values_from  = vaccinated:vaccinated_daily) %>% arrange(day, municipality_code)

    osp6 %>%  write.csv("data/lt-covid19-vaccinated.csv", row.names = FALSE)


}

