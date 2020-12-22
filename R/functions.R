daily_xtable <- function(zz1, colsums = FALSE) {

    agad <- zz1 %>% count(day, administrative_level_3, age)  %>%
        pivot_wider(names_from = "age", values_from ="n", values_fill = 0,names_sort = TRUE) %>%
        arrange(day, administrative_level_3)

    agr <- zz1$age %>% unique
    sagr <- sapply(strsplit(agr, "-"),"[[",1) %>% gsub("[+]","",.)
    agr_sorted <- agr[order(sagr)]

    ad <- zz1 %>% count(day,administrative_level_3) %>% rename(Total = n)

    agad1 <- agad %>% inner_join(ad, by = c("day", "administrative_level_3"))

    if(colsums) {
        ag <- zz1 %>% count(day, age)
        ag1 <- ag %>% group_by(day) %>% summarise(n = sum(n))
        ag2 <- ag %>% bind_rows(ag1 %>% mutate(age = "Total")) %>%
            pivot_wider(names_from = "age", values_from ="n", values_fill = 0,names_sort = TRUE) %>%
            mutate(administrative_level_3 = "ZTotal")

        agad2 <- agad1 %>% bind_rows(ag2) %>%
            arrange(day, administrative_level_3) %>%
            mutate(administrative_level_3 = gsub("ZTotal","Total", administrative_level_3))
    } else {
        agad2 <- agad1 %>% arrange(day, administrative_level_3)
    }

    agad2[, c("day","administrative_level_3", agr_sorted, "Total")]
}

fix_esridate <- function(str) {
    dd <- fromJSON(str)
    fn <- dd$fields %>% filter(type == "esriFieldTypeDate") %>% .$name

    if (length(fn) == 0) return(dd$features$attributes)
    else {
        for (aa in fn) {
            str <- gsub(paste0("(\"",aa,"\": +)([0-9]+)"),"\\1\"\\2\"",str)
        }
        dd <- fromJSON(str)$features$attributes
        for (aa in fn) {
            dd[[aa]] <- as_datetime(as.integer64(dd[[aa]])/1000)
        }
    }
    dd
}

tryget <- function(link, times = 10) {
    res <- NULL
    for (i in 1:times) {
        res <- try(GET(link))
        if(inherits(res, "try-error")) {
            cat("\nFailed to get the data, sleeping for 1 second\n")
            Sys.sleep(1)
        } else break
    }
    if(is.null(res))stop("Failed to get the data after ", times, " times.")
    res
}

