
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


fns <- dir("raw_data/laboratory1", pattern = "[0-9]+.csv", full.names = TRUE)

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
