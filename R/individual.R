library(jsonlite)
library(dplyr)
library(lubridate)
library(curl)

curl_download("ftp://atviriduomenys.nvsc.lt/COVID19.json", "individual/COVID19.json")
suff <- gsub("-","",Sys.Date())

file.copy("individual/COVID19.json",paste0("~/tmp/covid19lt-json/COVID19-",suff,".json"))



zz <- fromJSON("individual/COVID19.json")

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


zz1 %>% write.csv("individual/lt-covid19-individual.csv", row.names = FALSE)


zz2 <- lapply(sort(unique(zz1$day)), function(d) zz1 %>% filter(day <= d))

zz3 <- lapply(zz2, function(d) d %>% mutate(dday = day) %>% summarize(day = max(day), confirmed = n(), incidence = sum(dday == max(day)),
                                               imported = sum(imported == "Taip"),
                                               recovered = sum(status == "Pasveiko"),
                                               deaths = sum(status == "Mirė"),
                                               deaths_different = sum(status == "Kita"),
                                               hospitalized = sum(hospitalized == "Taip"),
                                               intensive = sum(intensive == "Taip"))) %>% bind_rows


tt <- read.csv("data/lt-covid19-total.csv") %>% mutate(day = ymd(day)) %>% arrange(day) %>% mutate(incidence = c(1,diff(confirmed)))

cmp <- zz1 %>% count(day) %>% inner_join(tt %>% select(day, incidence)) %>% mutate(I = cumsum(n), S = cumsum(incidence))


zz4 <- zz1 %>% mutate(aday = ifelse(actual_day> day, day, actual_day)) %>% mutate(d = day -actual_day)


