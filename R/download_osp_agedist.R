library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(bit64)

source("R/functions.R")

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

osp <- tryget("https://opendata.arcgis.com/datasets/064ca1d6b0504082acb1c82840e79ce0_0.geojson")
osp1 <- fromJSON(rawToChar(osp$content))$features$properties



osp1 %>% arrange(confirmation_date, municipality_code, case_code) %>% select(-object_id) %>%
    write.csv("raw_data/osp/osp_covid19_agedist.csv", row.names = FALSE)

osp2 <- osp1 %>% mutate(day = ymd(ymd_hms(confirmation_date)))

adm <- read.csv("raw_data/administrative_levels.csv")

adm <- adm %>% rbind(
    data.frame(administrative_level_2 = c("Unknown","Lithuania"),
                                administrative_level_3 = c("Unknown","Lithuania"),
                                municipality_name = c("nenustatyta","Lietuva"),
                                population = c(0,sum(adm$population)))
    )

osp3 <- osp2 %>% inner_join(adm %>% select(-population))

if(nrow(osp3) == nrow(osp2)) {
    osp4 <- osp3 %>% select(day, administrative_level_2, administrative_level_3, municipality_code,
                    age=age_bracket, sex = gender, case_code) %>%
        arrange(day, municipality_code, case_code)

    osp4 %>%  write.csv("data/lt-covid19-agedist.csv", row.names = FALSE)

    agr <- read.csv("raw_data/agegroups.csv") %>%
        bind_rows(data.frame(age = c("nenustatyta","Virš 80"), age1 = c("Nenustatyta","80+")))
    zz2 <- osp4  %>% inner_join(agr, by = "age") %>% select(-age) %>% rename(age = age1)
    zz2 <- zz2 %>% mutate(administrative_level_3 = ifelse(administrative_level_3 == "Unknown", "", administrative_level_3))
    bb <- daily_xtable(zz2, colsums = TRUE)

    bb %>% write.csv("data/lt-covid19-age-region-incidence.csv", row.names =  FALSE)

}

