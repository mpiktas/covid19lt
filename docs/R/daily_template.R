library(lubridate)

fns <- dir("total", pattern="[0-9]+.csv", full.names  = TRUE)

days <- fns %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)

new_day <- max(daysd)+days(1)

outd <- gsub("-","",as.character(new_day))


new_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)
new_day_data$day <- new_day

write.csv(new_day_data, glue::glue("total/lt-covid19-total-{outd}.csv"), row.names = FALSE )


