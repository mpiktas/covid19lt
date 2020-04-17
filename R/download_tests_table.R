library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)

raw <- GET("http://sam.lrv.lt/lt/naujienos/koronavirusas")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)


# Get the tests data ------------------------------------------------------


tbs <- html_table(oo, fill = TRUE)

fns <- dir("tests", pattern="[0-9]+.csv", full.names  = TRUE)

days <- fns %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)

new_day <- max(daysd)+days(1)

outd <- gsub("-","",as.character(new_day))

new_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)

tb1 <- tbs[[1]][-1:-4,]

colnames(tb1) <- c("laboratory", "tested_all", "tested_mobile", "negative_all", "negative_mobile", "positive_all","positive_mobile","not_tested", "not_tested_mobile")

tb1[, -1] <- sapply(tb1[, -1], as.integer)

tbr <- tb1 %>% filter(laboratory != "VISO")

tbr <- bind_cols(data.frame(day = rep(new_day, nrow(tbr))), tbr)

tot <- tbr[,-1:-2] %>% sapply(sum, na.rm = TRUE)

if ( sum(abs(tot - tb1 %>% filter(laboratory == "VISO") %>% .[,-1] %>% unlist)) == 0) {
    write.csv(tbr, glue::glue("tests/lt-covid19-laboratory-{outd}.csv"), row.names = FALSE )
}
