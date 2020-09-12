library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)
library(stringr)

fns <- dir("total", pattern="[0-9]+.csv", full.names  = TRUE)

days <- fns %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)

new_day <- max(daysd)+days(1)

outd <- gsub("-","",as.character(new_day))

new_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)

old_day_data <- new_day_data

new_day_data$day <- new_day

##1. confirmed
##2. active
##3. incidence
##4. deaths
##5. deaths for other reasons
##6. recovered
##7. isolated
##8. tests
##9. total tests
nums <- c(3296, 1127, 53, 86, 13, 2070, 7788, 5105, 692223)
ia1 <- 224


if ((nums[1] - nums[3]) == new_day_data$confirmed[1])  {
    new_day_data$confirmed[1] <- nums[1]
} else {
    warning("Confirmed numbers do not match")
    new_day_data$confirmed[1] <-  new_day_data$confirmed[1] + nums[3]
}

if (nums[4] >= new_day_data$deaths[1]) {
    new_day_data$deaths[1] <- nums[4]
}else warning("Deaths number is lower")

if (nums[6] >= new_day_data$recovered[1]) {
    new_day_data$recovered[1] <- nums[6]
} else warning("Recovered number is lower")

if ((nums[9] - nums[8]) == new_day_data$tested[1])  {
    new_day_data$tested[1] <- nums[9]
} else  {
    warning("Tested numbers do not match")
    new_day_data$tested[1] <- nums[9]
}

new_day_data$quarantined[1] <- nums[7]

write.csv(new_day_data, glue::glue("total/lt-covid19-total-{outd}.csv"), row.names = FALSE )

ndd <- new_day_data %>% select(country, day) %>%
    mutate(confirmed = nums[1],
           active = nums[2],
           incidence = nums[3],
           deaths = nums[4],
           deaths_different =nums[5],
           recovered = nums[6],
           daily_tests = nums[8],
           quarantined = nums[7],
           total_tests = nums[9],
           imported0601 = ia1)
write.csv(ndd, glue::glue("daily/lt-covid19-daily-{outd}.csv"), row.names = FALSE )

