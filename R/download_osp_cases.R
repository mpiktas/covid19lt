library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

Sys.setlocale(locale = "lt_LT.UTF-8")
osp <- GET("https://opendata.arcgis.com/datasets/3df1e86f5235498ab7cf9cec615a7fd7_0.geojson")
osp1 <- fromJSON(rawToChar(osp$content))$features$properties

fix_esridate <- function(str) {
    dd <- fromJSON(str)
    fn <- dd$fields %>% filter(type == "esriFieldTypeDate") %>% .$name

    if (length(fn) == 0) return(dd$features$attributes)
    else {
        for (aa in fn) {
            str <- gsub(paste0("(\"",aa,"\": +)([0-9]+)"),"\\1\"\\2\"",str)
        }
        dd <- fromJSON(str)$features$attributes
        for (aa in fn) {
            dd[[aa]] <- as_datetime(as.integer64(dd[[aa]])/1000)
        }
    }
    dd
}

osp1 %>% arrange(date, municipality_code) %>% write.csv("raw_data/osp/osp_covid19_cases.csv", row.names = FALSE)


osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(date)))


adm <- read.csv("raw_data/administrative_levels.csv")

adm <- adm %>% rbind(data.frame(administrative_level_3 = "Unknown", population = NA, municipality_name="nenustatyta"))

osp3 <- osp2 %>% inner_join(adm %>% select(-population))

if(nrow(osp3) == nrow(osp2)) {
    osp3 %>% select(day, municipality_code, administrative_level_3,
                    confirmed_cases, recovered_cases, active_cases, deaths, other_deaths,
                    confirmed_cases_cumulative, recovered_cases_cumulative, deaths_cumulative,
                    other_deaths_cumulative) %>%
        arrange(day, municipality_code) %>%
        write.csv("data/lt-covid19-cases.csv", row.names = FALSE)
}

if(FALSE) {
    posp <- GET("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=test_performed_date+desc&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=pjson")
    posp1 <- fix_esridate(rawToChar(posp$content))
    posp2 <- posp1 %>% mutate(day = ymd(test_performed_date))
    posp22 <- posp2 %>% filter(day == max(day))

    osp4 <- osp2  %>% bind_rows(posp22 %>% select(-test_performed_date)) %>% unique
    osp5 <-  osp4 %>% inner_join(adm %>% select(-population)) %>% select(-municipality_name)

    osp5 %>% select(day, municipality_code, administrative_level_3,
                    tests_negative, tests_positive, tests_positive_repeated,
                    tests_positive_new, tests_total) %>%
        arrange(day, municipality_code) %>%
        write.csv("data/lt-covid19-tests.csv", row.names = FALSE)

    library(zoo)
    tta <- osp5 %>% select(day, tests_total, tests_positive_new) %>% group_by(day) %>% summarise_all(sum)
    tta1 <- tta %>% mutate(l7 = lag(tests_positive_new, 7), gdod = round(100*(tests_positive_new/l7-1),2))
    tta2 <- tta1 %>% mutate(tr  = rollsum(tests_positive_new, 7, fill = NA, align = "right"), tr7 = rollsum(l7, 7, fill = NA, align = "right"), p = round(100 * (tr/tr7 -1),2))

    aa <- read.csv("data/lt-covid19-aggregate.csv") %>% mutate(day = ymd(day)) %>% tibble


    aa1 <- aa %>% select(day, incidence) %>% bind_rows(data.frame(day = ymd("2020-11-19"), incidence= 2270))
    aa2 <- aa1 %>%  mutate(l7 = lag(incidence, 7), gdod = round(100*(incidence/l7-1),2))
    aa3 <- aa2 %>% mutate(tr  = rollsum(incidence, 7, fill = NA, align = "right"), tr7 = rollsum(l7, 7, fill = NA, align = "right"), p = round(100 * (tr/tr7 -1),2))

}
