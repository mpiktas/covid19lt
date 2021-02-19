library(httr)
library(rvest)
library(dplyr)
library(lubridate)
library(stringr)

source("R/functions.R")

osp1 <- read.csv("https://opendata.arcgis.com/datasets/d49a63c934be4f65a93b6273785a8449_0.csv")

osp1 %>% arrange(date, municipality_code) %>% write.csv("raw_data/osp/osp_covid19_stats.csv", row.names = FALSE)


osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(date)))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm)

if(nrow(osp3) == nrow(osp2)) {

    osp4 <- osp3 %>% select(day, municipality_code, administrative_level_3,
                            confirmed_cases=incidence, active_cases=active_sttstcl, active_cases_de_jure = active_de_jure,
                            confirmed_cases_cumulative = cumulative_totals, recovered_cases_cumulative = recovered_sttstcl, dead_cases_cumulative = dead_cases,
                            recovered_cases_de_jure_cumulative = recovered_de_jure,
                            deaths_1_daily = daily_deaths_def1, deaths_2_daily= daily_deaths_def2, deaths_3_daily = daily_deaths_def3,
                    tests_positive = dgn_pos_day, tests_total = dgn_tot_day, tests_mobile = dgn_tot_day_gmp,
                    tests_pcr = pcr_tot_day, tests_ag = ag_tot_day, tests_ab = ab_tot_day,
                    tests_pcr_positive = pcr_pos_day, tests_ag_positive = ag_pos_day, tests_ab_positive = ab_tot_day) %>%
        arrange(day, municipality_code)

    osp5 %>% write.csv("data/osp/lt-covid19-stats.csv", row.names = FALSE)


}

if(FALSE) {

    httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
    posp <- GET("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=test_performed_date+desc&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=pjson")
    posp1 <- fix_esridate(rawToChar(posp$content))
    posp2 <- posp1 %>% mutate(day = ymd(test_performed_date))
    posp22 <- posp2 %>% filter(day == max(day))


        osp4 <- osp2  %>% bind_rows(posp22 %>% select(-test_performed_date)) %>% unique
        osp5 <-  osp4 %>% inner_join(adm %>% select(-population)) %>% select(-municipality_name)


    library(zoo)
    tta <- osp5 %>% select(day, tests_total, tests_positive_new) %>% group_by(day) %>% summarise_all(sum)
    tta1 <- tta %>% mutate(l7 = lag(tests_positive_new, 7), gdod = round(100*(tests_positive_new/l7-1),2))
    tta2 <- tta1 %>% mutate(tr  = rollsum(tests_positive_new, 7, fill = NA, align = "right"), tr7 = rollsum(l7, 7, fill = NA, align = "right"), p = round(100 * (tr/tr7 -1),2))

    aa <- read.csv("data/lt-covid19-aggregate.csv") %>% mutate(day = ymd(day)) %>% tibble


    aa1 <- aa %>% select(day, incidence) %>% bind_rows(data.frame(day = ymd("2020-11-19"), incidence= 2270))
    aa2 <- aa1 %>%  mutate(l7 = lag(incidence, 7), gdod = round(100*(incidence/l7-1),2))
    aa3 <- aa2 %>% mutate(tr  = rollsum(incidence, 7, fill = NA, align = "right"), tr7 = rollsum(l7, 7, fill = NA, align = "right"), p = round(100 * (tr/tr7 -1),2))

}

if(FALSE) {
   a1 <- "https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=municipality_name%3D%27Kazl%C5%B3+R%C5%ABdos+sav.%27&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=json"
   sav <- URLencode("Kazlų Rūdos sav.")
   a2 <- glue::glue("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=json")

   alls <- lapply(unique(posp22$municipality_name), function(x) {
       sav <- URLencode(x)
       try(GET(glue::glue("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=json")))
   })

   osp1 <- lapply(alls, function(l)fix_esridate(rawToChar(l$content))) %>% bind_rows

}