library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)

raw <- GET("https://nvsc.lrv.lt/lt/visuomenei/nacionalines-visuomenes-sveikatos-prieziuros-laboratorijos-duomenys")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)


# Get the tests data ------------------------------------------------------

tbs <- html_table(oo, fill = TRUE)

trs <- html_nodes(oo, "tr")

tbrs1 <- lapply(trs, function(x)html_nodes(x, "td") %>% html_text %>% str_trim)

crtime <- Sys.time()

tb1 <- data.frame(do.call("rbind",tbrs1[-4:-1]))

colnames(tb1) <- c("laboratory", "tested_all", "tested_mobile", "negative_all", "negative_mobile", "positive_all","positive_mobile","not_tested", "not_tested_mobile")

tb1[, -1] <- sapply(tb1[, -1], function(x)as.integer(gsub("*","",x, fixed = TRUE)))

tbr <- tb1 %>% filter(laboratory != "Iš viso:")

tbr <- bind_cols(data.frame(day = rep(floor_date(crtime, unit = "days")-days(1), nrow(tbr))), tbr)

tot <- tbr[,-1:-2] %>% sapply(sum, na.rm = TRUE)
if(sum(abs(tot - tb1 %>% filter(laboratory == "Iš viso:") %>% .[,-1] %>% unlist)) != 0) warning("Totals do not match")

tbr <- tbr %>% mutate(positive_new = NA, positive_retested = NA) %>%
    select(day, laboratory, tested_all, tested_mobile,
           negative_all, negative_mobile,
           positive_all, positive_mobile, positive_new, positive_retested,
           not_tested, not_tested_mobile)


outd <- gsub(" ","_",gsub("-","",as.character(crtime)))

write.csv(tbr, glue::glue("raw_data/laboratory/lt-covid19-laboratory-{outd}.csv"), row.names = FALSE )
