library(jsonlite)
library(dplyr)
library(lubridate)
library(curl)
library(tidyr)
library(glue)

source("R/functions.R")


custom_link <- Sys.getenv("DATAGOV_LINK")

download_link <- "ftp://atviriduomenys.nvsc.lt/COVID19.json"
if (custom_link != "") {
  download_link <- glue::glue("http://{custom_link}:2020/ftp/download?path=COVID19.json")
}

curl_download(download_link, "raw_data/datagov/COVID19.json")
suff <- gsub("-", "", Sys.Date())

if (custom_link == "") file.copy("raw_data/datagov/COVID19.json", paste0("~/tmp/covid19lt-json/COVID19-", suff, ".json"))

zz <- fromJSON("raw_data/datagov/COVID19.json")

zz1 <- zz %>%
  rename(
    actual_day = `Susirgimo data`,
    day = `Atvejo patvirtinimo data`,
    imported = `Įvežtinis`,
    country = `Šalis`,
    status = `Išeitis`,
    foreigner = `Užsienietis`,
    age = `Atvejo amžius`,
    sex = `Lytis`,
    administrative_level_3 = `Savivaldybė`,
    hospitalized = `Ar hospitalizuotas`,
    intensive = `Gydomas intensyvioje terapijoje`,
    precondition = `Turi lėtinių ligų`
  ) %>%
  arrange(day, actual_day, administrative_level_3, age)

cnv <- function(x) {
  x %>%
    strsplit("T") %>%
    sapply("[[", 1) %>%
    ymd()
}

zz1 <- zz1 %>%
  mutate(actual_day = ifelse(actual_day == "", day, actual_day)) %>%
  mutate(day = cnv(day), actual_day = cnv(actual_day))

oo <- read.csv("data/nvsc/lt-covid19-individual.csv") %>% mutate(day = ymd(day), actual_day = ymd(actual_day))

ss <- identical(oo, zz1)

if (ss) {
  cat("\nNo new data from data.gov.lt\n")
} else {
  zz1 %>% write.csv("data/nvsc/lt-covid19-individual.csv", row.names = FALSE)

  iit <- zz1 %>% summarize(
    confirmed = n(), hospitalized = sum(hospitalized == "Taip" & status == "Gydomas"),
    intensive = sum(intensive == "Taip" & status == "Gydomas"),
    active = sum(status == "Gydomas"),
    deaths = sum(status == "Mirė"),
    deaths_different = sum(status == "Kita"),
    recovered = sum(status == "Pasveiko"),
    imported = sum(imported == "Taip")
  )


  iit <- iit %>% mutate(day = max(zz1$day), incidence = sum(zz1$day == max(zz1$day)))

  iit1 <- iit %>% select(day, confirmed, recovered, deaths, deaths_different, imported, active, hospitalized, intensive, incidence)

  idt <- gsub("-", "", iit1$day[1])

  write.csv(iit1, paste0("raw_data/datagov/lt-covid19-individual-daily-", idt, ".csv"), row.names = FALSE)

  fns <- dir("raw_data/datagov/", pattern = "[0-9]+.csv", full.names = TRUE)

  fns %>%
    lapply(read.csv, stringsAsFactor = FALSE) %>%
    bind_rows() %>%
    write.csv("data/nvsc/lt-covid19-individual-daily.csv", row.names = FALSE)


  # Do death and incidence by age group -------------------------------------


  agr <- read.csv("raw_data/agegroups.csv") %>% bind_rows(data.frame(age = "", age1 = "Nenustatyta"))
  zz2 <- zz1 %>%
    inner_join(agr, by = "age") %>%
    select(-age) %>%
    rename(age = age1)

  #  daily_xtable(zz2, colsums = TRUE) %>% write.csv("data/lt-covid19-age-region-incidence.csv", row.names =  FALSE)

  daily_xtable(zz2 %>% filter(status == "Mirė")) %>% write.csv("data/nvsc/lt-covid19-age-region-deaths.csv", row.names = FALSE)
}
