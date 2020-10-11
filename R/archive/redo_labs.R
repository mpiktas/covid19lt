
fns <- dir("raw_data/laboratory/", pattern = "lt-c")

lapply(fns, function(fn) {
    lb <- read.csv(paste0("raw_data/laboratory/",fn))
    cr <- lb$created %>% unique
    crd <- ymd_hms(cr)
    dd <- ymd(lb$day %>% unique)

    if (date(crd) > ymd(dd)+days(1)) {
        cr1 <- paste0(gsub("-","",as.character(ymd(dd)+days(1))),"_00:00:01")
    } else {
        cr1 <- gsub(" ","_",gsub("-","", cr))
    }

    lb1 <- lb %>% select(-created)

    fn1 <- paste0("raw_data/laboratory1/lt-covid19-laboratory_",cr1,".csv")
    write.csv(lb1, fn1,row.names = FALSE)
})


fns <- dir("raw_data/laboratory", pattern = "[0-9]+.csv", full.names = TRUE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[3:4],collapse="_")))

lbd <- lapply(fns, read.csv, stringsAsFactor = FALSE)

dtl0 <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm), lbd, pt, SIMPLIFY = FALSE) %>% bind_rows %>%
     select(-day) %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

dtl <-  dtl0 %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, laboratory,
           tested_all, tested_mobile,
           negative_all, negative_mobile,
           positive_all, positive_mobile, positive_retested, positive_new, not_tested, not_tested_mobile) %>%
    arrange(day, laboratory)


ln <- read.csv("raw_data/laboratory/laboratory_names.csv", stringsAsFactors = FALSE)

lrn <- unique(dtl$laboratory)

lr <- setdiff(lrn,intersect(lrn,ln$lab_reported))
if (length(lr) > 0) {
    warning("New laboratories: ", paste(lr, collapse = ", "))
    ln <- bind_rows(ln, data.frame(lab_reported = lr, lab_actual = lr, stringsAsFactors = FALSE))
    write.csv(ln, "raw_data/laboratory/laboratory_names.csv", row.names = FALSE)
}

ln <- ln %>% rename(laboratory=lab_reported)

dtl <- dtl %>% inner_join(ln, by = "laboratory")

oo <- dtl %>% select(-laboratory) %>% rename(laboratory = lab_actual) %>%
    group_by(day, laboratory) %>% summarise_all(sum) %>% ungroup

zz <- read.csv("data/lt-covid19-laboratory-total.csv") %>% select(-created)

#write.csv(oo,"data/lt-covid19-laboratory-total.csv", row.names = FALSE)
#


# Redo SAM ----------------------------------------------------------------

ddf <- function(x)c(x[1],diff(x))

tt <- read.csv("data/lt-covid19-total.csv") %>% mutate(day = ymd(day)) %>% mutate(incidence = ddf(confirmed), daily_tests = ddf(tested))

dd <- read.csv("data/lt-covid19-daily.csv") %>% mutate(day = ymd(day))

tt %>% inner_join(dd %>% select(day, di = incidence)) %>% mutate(d = di-incidence) %>% .$d
tt %>% inner_join(dd %>% select(day, dt = daily_tests)) %>% mutate(d = dt-tests_daily) %>% View

tt1 <- tt %>% filter(day<="2020-04-26") %>%
    select(day, confirmed, deaths, recovered, total_tests=tested, under_observation, incidence, daily_tests) %>%
    mutate(active = confirmed - deaths - recovered)

tt1 %>% split(tt1$day) %>% lapply(function(d) {
    outd <- paste0(gsub("-","",as.character(d$day+days(1))),"_12:00:01")
    write.csv(d, glue::glue("raw_data/sam1/lt-covid19-daily_{outd}.csv"), row.names = FALSE)
})

fns <- dir("raw_data/sam", pattern = "daily") %>% sort

fns1 <- fns[-9:-1]

fns1 %>% lapply(function(fn) {

    dd <- read.csv(paste0("raw_data/sam/",fn)) %>% mutate(day = ymd(day)) %>% select(-country)
    outd <-  paste0(gsub("-","",as.character(dd$day+days(1))),"_12:00:01")
    write.csv(dd, glue::glue("raw_data/sam1/lt-covid19-daily_{outd}.csv"), row.names = FALSE)
})


fns <- dir("raw_data/sam1", pattern = "daily", full.names = TRUE)

samd <- lapply(fns, read.csv, stringsAsFactors = FALSE)

pt <- strsplit(fns, "_") %>% lapply(function(x)ymd_hms(paste(x[3:4],collapse="_")))

sam <- mapply(function(dt, tm) dt %>% mutate(downloaded = tm) %>% select(-day), samd, pt, SIMPLIFY = FALSE) %>% bind_rows  %>% mutate(day = ymd(floor_date(downloaded, unit = "day")) - days(1))

dl <-  sam %>% group_by(day) %>%
    filter(downloaded == max(downloaded)) %>% ungroup %>%
    select(day, incidence, daily_tests, confirmed, active, deaths, recovered, quarantined, total_tests, deaths_different, imported0601, under_observation)

tl <- dl %>% select(-confirmed) %>% mutate(confirmed = cumsum(incidence)) %>%
    select(day, confirmed, deaths, recovered, tested = total_tests, under_observation, quarantined)


tt <- read.csv("data/lt-covid19-total.csv")

zz <- tt %>% select(-country,-intensive_therapy, -hospitalized,-day) - tl %>% select(-day)

zz <- dl %>% filter(day>="2020-04-18") %>% select(-day,-under_observation) - dd %>% select(-day, -country)

##test with existing files
##

raw <- GET("https://nvsc.lrv.lt/lt/visuomenei/covid-19-ugdymo-istaigose?fbclid=IwAR1RhabJa1O3e1PCaBzRxjifhfCPdrl2qihCvkHEHNJNHRKKyIMvlPZT2Jg")
#writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)
tbs <- html_table(oo, fill = TRUE)

tb1 <- tbs[[1]][-2:-1,-1]
colnames(tb1) <- c("educational_institution","confirmed_students","confirmed_teachers","confirmed_other","quarantined","first_case","last_case")

tb1 %>% write.csv("raw_data/nvsc/education_20201010_23:13:00.csv", row.names=FALSE)
# Get the tests data ------------------------------------------------------



