library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)


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
tryget <- function(link, times = 10) {
    res <- NULL
    for (i in 1:times) {
        res <- try(GET(link))
        if(inherits(res, "try-error")) {
            cat("\nFailed to get the data, sleeping for 1 second\n")
            Sys.sleep(1)
        } else break
    }
    if(is.null(res))stop("Failed to get the data after ", times, " times.")
    res
}

httr::set_config(config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))
posp <- tryget("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=test_performed_date+desc&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=pjson")
posp1 <- fix_esridate(rawToChar(posp$content))
posp2 <- posp1 %>% mutate(day = ymd(test_performed_date))
posp22 <- posp2 %>% filter(day == max(day))

alls <- lapply(unique(posp22$municipality_name), function(x) {
    sav <- URLencode(x)
    try(tryget(glue::glue("https://osp-sdg.stat.gov.lt/arcgis/rest/services/SDG/COVID_TESTS_OPEN/FeatureServer/0/query?where=municipality_name%3D%27{sav}%27&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&gdbVersion=&historicMoment=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=xyFootprint&resultOffset=&resultRecordCount=&returnTrueCurves=false&returnExceededLimitFeatures=false&quantizationParameters=&returnCentroid=false&sqlFormat=none&resultType=&featureEncoding=esriDefault&datumTransformation=&f=json")))
})

osp1 <- lapply(alls, function(l)fix_esridate(rawToChar(l$content))) %>% bind_rows

#osp <- GET("https://opendata.arcgis.com/datasets/538b7bd574594daa86fefd16509cbc36_0.geojson")
#osp1 <- fromJSON(rawToChar(osp$content))$features$properties


osp1 %>% arrange(test_performed_date, municipality_code) %>% write.csv("raw_data/osp/osp_covid19_tests.csv", row.names = FALSE)


#osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(test_performed_date)))
osp2 <- osp1 %>% mutate(day = ymd(test_performed_date))

adm <- read.csv("raw_data/administrative_levels.csv")

osp3 <- osp2 %>% inner_join(adm %>% select(-population))

if(nrow(osp3) == nrow(osp2)) {
    osp3 %>% select(day, municipality_code, administrative_level_3,
                    tests_negative, tests_positive, tests_positive_repeated,
                    tests_positive_new, tests_total) %>%
        arrange(day, municipality_code) %>%
        write.csv("data/lt-covid19-tests.csv", row.names = FALSE)


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