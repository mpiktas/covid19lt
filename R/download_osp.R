library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

osp <- GET("https://opendata.arcgis.com/datasets/538b7bd574594daa86fefd16509cbc36_0.geojson")
osp1 <- fromJSON(rawToChar(osp$content))$features$properties
#osp <- GET("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=pjson")

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
#osp1 <- fix_esridate(rawToChar(osp$content))
osp1 %>% arrange(test_performed_date,municipality_name) %>% write.csv("raw_data/osp/osp_covid19_tests.csv", row.names = FALSE)


osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(test_performed_date)))
#osp2 <- osp1 %>% mutate(day = ymd(test_performed_date))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm %>% select(-population))

if(nrow(osp3) == nrow(osp2)) {
    osp3 %>% select(day, administrative_level_3,
                    tests_negative, tests_positive, tests_positive_repeated,
                    tests_positive_new, tests_total) %>%
        arrange(day, administrative_level_3) %>%
        write.csv("data/lt-covid19-tests.csv", row.names = FALSE)
}

