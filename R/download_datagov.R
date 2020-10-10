library(jsonlite)
library(dplyr)
library(lubridate)
library(curl)
library(tidyr)

curl_download("ftp://atviriduomenys.nvsc.lt/COVID19.json", "raw_data/datagov/COVID19.json")
suff <- gsub("-","",Sys.Date())

file.copy("raw_data/datagov/COVID19.json",paste0("~/tmp/covid19lt-json/COVID19-",suff,".json"))



zz <- fromJSON("raw_data/datagov/COVID19.json")

zz1 <- zz %>% rename(actual_day = `Susirgimo data`,
                     day = `Atvejo patvirtinimo data`,
                     imported = `Įvežtinis`,
                     country = `Šalis`,
                     status = `Išeitis`,
                     foreigner  = `Užsienietis`,
                     age  =  `Atvejo amžius`,
                     sex = `Lytis`,
                     administrative_level_3 = `Savivaldybė`,
                     hospitalized = `Ar hospitalizuotas`,
                     intensive = `Gydomas intensyvioje terapijoje`,
                     precondition = `Turi lėtinių ligų`) %>%
    arrange(day, actual_day, administrative_level_3, age)

cnv <- function(x) {
    x %>% strsplit("T") %>% sapply("[[",1) %>% ymd
}

zz1<- zz1 %>% mutate(actual_day = ifelse(actual_day == "", day, actual_day)) %>%
    mutate(day = cnv(day), actual_day = cnv(actual_day))


zz1 %>% write.csv("data/lt-covid19-individual.csv", row.names = FALSE)

iit <- zz1 %>% summarize(confirmed = n(), hospitalized = sum(hospitalized == "Taip" & status == "Gydomas"),
                        intensive = sum(intensive == "Taip" & status == "Gydomas"),
                        active = sum(status == "Gydomas"),
                        deaths = sum(status == "Mirė"),
                        deaths_different = sum(status == "Kita"),
                        recovered = sum(status == "Pasveiko"),
                        imported = sum(imported == "Taip"))


iit <- iit %>% mutate(day = max(zz1$day), incidence = sum(zz1$day == max(zz1$day)))

iit1 <- iit %>% select(day, confirmed, recovered, deaths, deaths_different, imported, active, hospitalized, intensive, incidence)

idt <- gsub("-","", iit1$day[1])

write.csv(iit1, paste0("raw_data/datagov/lt-covid19-individual-daily-",idt,".csv"), row.names = FALSE)


zz2 <- lapply(sort(unique(zz1$day)), function(d) zz1 %>% filter(day <= d))

zz3 <- lapply(zz2, function(d) d %>% mutate(dday = day) %>% summarize(day = max(day), confirmed = n(), incidence = sum(dday == max(day)),
                                               imported = sum(imported == "Taip"),
                                               recovered = sum(status == "Pasveiko"),
                                               deaths = sum(status == "Mirė"),
                                               deaths_different = sum(status == "Kita"),
                                               hospitalized = sum(hospitalized == "Taip"),
                                               intensive = sum(intensive == "Taip"))) %>% bind_rows


tt <- read.csv("data/lt-covid19-total.csv") %>% mutate(day = ymd(day)) %>% arrange(day) %>% mutate(incidence = c(1,diff(confirmed)))
dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day)) %>% arrange(day)

cmp <- zz1 %>% count(day) %>% inner_join(tt %>% select(day, incidence)) %>%
    mutate(I = cumsum(n), S = cumsum(incidence)) %>%
    left_join(dd %>% select(day, ID= incidence, SD = confirmed))


zz4 <- zz1 %>% mutate(aday = ifelse(actual_day> day, day, actual_day)) %>% mutate(d = day -actual_day)


zz2 <- zz1 %>% filter(age!="")

daily_xtable <- function(zz1, colsums = FALSE) {

    agad <- zz1 %>% count(day, administrative_level_3, age)  %>%
        pivot_wider(names_from = "age", values_from ="n", values_fill = 0,names_sort = TRUE) %>%
        arrange(day, administrative_level_3)

    agr <- zz1$age %>% unique
    sagr <- sapply(strsplit(agr, "-"),"[[",1) %>% as.integer
    agr_sorted <- agr[order(sagr)]

    ad <- zz1 %>% count(day,administrative_level_3) %>% rename(Total = n)

    agad1 <- agad %>% inner_join(ad)

    if(colsums) {
        ag <- zz1 %>% count(day, age)
        ag1 <- ag %>% group_by(day) %>% summarise(n = sum(n))
        ag2 <- ag %>% bind_rows(ag1 %>% mutate(age = "Total")) %>%
            pivot_wider(names_from = "age", values_from ="n", values_fill = 0,names_sort = TRUE) %>%
            mutate(administrative_level_3 = "ZTotal")

        agad2 <- agad1 %>% bind_rows(ag2) %>%
            arrange(day, administrative_level_3) %>%
            mutate(administrative_level_3 = gsub("ZTotal","Total", administrative_level_3))
    } else {
        agad2 <- agad1 %>% arrange(day, administrative_level_3)
    }

    agad2[, c("day","administrative_level_3", agr_sorted, "Total")]
}


daily_xtable(zz2, colsums = TRUE) %>% write.csv("data/lt-covid19-age-region-incidence.csv", row.names =  FALSE)

daily_xtable(zz2 %>% filter(status == "Mirė")) %>% write.csv("data/lt-covid19-age-region-deaths.csv", row.names =  FALSE)

