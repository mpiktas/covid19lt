library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)

raw <- GET("https://koronastop.lrv.lt")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)
cd <- html_nodes(oo,".stats_widget")

tls <- html_nodes(cd, ".title") %>% html_text
nums1 <-  html_nodes(cd, ".value") %>% html_text %>% as.integer

ft <- html_nodes(cd, ".stats_footnote") %>% html_text

nums2 <- regmatches(ft, gregexpr("[[:digit:]]+", ft))[[1]][4:5] %>% as.integer

fns <- dir("total", pattern="[0-9]+.csv", full.names  = TRUE)

days <- fns %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)

new_day <- max(daysd)+days(1)

outd <- gsub("-","",as.character(new_day))

old_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)

new_day_data <- old_day_data
new_day_data$day <- new_day

nums <- c(nums1, nums2)
if ((nums[1] - nums[2]) == new_day_data$confirmed[1])  {
    new_day_data$confirmed[1] <- old_day_data$confirmed[1] + nums[2]
} else {
    warning("Confirmed do not match")
    new_day_data$confirmed[1] <- old_day_data$confirmed[1] + nums[2]
}
if (nums[4] >= new_day_data$deaths[1]) {
    new_day_data$deaths[1] <- nums[4]
} else stop("Deaths is lower that previous day")

if (nums[3] >= new_day_data$recovered[1]) {
    new_day_data$recovered[1] <- nums[3]
} else stop("Recovered is lower that previous day")

if ((nums[6] - nums[5]) == new_day_data$tested[1]) {
    new_day_data$tested[1] <- nums[6]
} else {
    warning("Test numbers do not match")
    new_day_data$tested[1] <- nums[6]
}
write.csv(new_day_data, glue::glue("total/lt-covid19-total-{outd}.csv"), row.names = FALSE )

ndd <- new_day_data %>% select(country, day) %>% mutate(incidence = nums[2], daily_tests = nums[5])
write.csv(new_day_data, glue::glue("daily/lt-covid19-daily-{outd}.csv"), row.names = FALSE )


