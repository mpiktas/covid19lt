fns <- dir("tests", pattern = "[0-9]+.csv", full.names = TRUE)

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day))

dtl <- fns %>% lapply(read.csv, stringsAsFactor = FALSE)

zz <- file.info(fns)

days <- rownames(zz) %>% strsplit("-") %>% sapply(function(x)gsub(".csv","",x[length(x)]))

daysd <- ymd(days)


daily_tests <- dtl %>% sapply(function(x)sum(x$tested_all, na.rm = TRUE))

zz1 <- data.frame(fn = rownames(zz), dayt = daily_tests, dayr = daysd, dayc = as.Date(zz$ctime), created = zz$ctime)
zz1 <- zz1 %>%mutate(dayc1 = dayc - days(1))
zz1$day <- zz1$dayr
zz1$day[zz1$dayr>="2020-05-01"] <- zz1$dayc1[zz1$dayr>="2020-05-01"]
zz1$day[zz1$dayr == "2020-05-17"] <- "2020-05-17"

zz2 <- zz1 %>% left_join(dd %>% select(day, daily_tests)) %>% mutate(check = dayt - daily_tests)


for(i in 1:nrow(zz2)) {
    ff <- read.csv(zz2$fn[i])
    dff <- gsub("-","",as.character(zz2$day[i]))
    ff$created <- zz2$created[i]
    if(zz2$day[i]  != unique(ff$day)) {
        ff$day <- zz2$day[i]
    }
    write.csv(ff,paste0("tests1/lt-covid19-laboratory-",dff,".csv"), row.names = FALSE)
}