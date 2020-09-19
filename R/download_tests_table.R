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

fns <- dir("laboratory", pattern="[0-9]+.csv", full.names  = TRUE)

days <- fns %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)

crtime <- Sys.time()

new_day <- max(daysd)+days(1)

if(new_day != Sys.Date() - days(1)) {
    warning("Possibly the wrong day")
    new_day <- Sys.Date() - days(1)
}

outd <- gsub("-","",as.character(new_day))

new_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)

tb1 <- tbs[[1]][-1:-4,]

colnames(tb1) <- c("laboratory", "tested_all", "tested_mobile", "negative_all", "negative_mobile", "positive_all","positive_mobile","not_tested", "not_tested_mobile")

tb1[, -1] <- sapply(tb1[, -1], function(x)as.integer(gsub("*","",x, fixed = TRUE)))

tbr <- tb1 %>% filter(laboratory != "Iš viso:")

tbr <- bind_cols(data.frame(day = rep(new_day, nrow(tbr))), tbr)

tot <- tbr[,-1:-2] %>% sapply(sum, na.rm = TRUE)
if(sum(abs(tot - tb1 %>% filter(laboratory == "Iš viso:") %>% .[,-1] %>% unlist)) != 0) warning("Totals do not match")

tbr <- tbr %>% mutate(positive_new = NA, positive_retested = NA) %>%
    select(day, laboratory, tested_all, tested_mobile,
           negative_all, negative_mobile,
           positive_all, positive_mobile, positive_new, positive_retested,
           not_tested, not_tested_mobile)


##Compare with the previous days data:
if(identical(dim(tbr),dim(new_day_data))) {
    sm <- sum(abs(new_day_data[,c(-2:-1, -ncol(new_day_data))]-tbr[,-2:-1]), na.rm=TRUE)
}else {
    sm <- 1
}

if (sm > 0) {
    tbr <- tbr %>% mutate(created = crtime)
    write.csv(tbr, glue::glue("raw_data/laboratory/lt-covid19-laboratory-{outd}.csv"), row.names = FALSE )
} else {
    warning("New day data is identical to the previous day")
}

