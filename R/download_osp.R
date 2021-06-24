library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)
library(tidyr)

source("R/functions.R")

raw <- tryget("https://atlas.jifo.co/api/connectors/86105d38-f8c5-4578-8477-22ced61ff9bd")



tbs <- rawToChar(raw$content) %>% fromJSON()

dd <- gsub(" ", "_", Sys.time())

# Get covid hospitalisation data ----------------------------------------------------------

hdd4 <- data.frame(tbs$data[[10]])
colnames(hdd4) <- c("actual", "description")

cvh <- data.frame(
  description = "Pacientai, kuriems patvirtinta COVID19 infekcija",
  total = hdd4$actual[4],
  oxygen = hdd4$actual[5],
  ventilated = hdd4$actual[7],
  hospitalized_not_intensive = NA,
  intensive = hdd4$actual[6]
)

write.csv(cvh, glue::glue("raw_data/hospitalization/covid_hospitalization_{dd}.csv"), row.names = FALSE)
