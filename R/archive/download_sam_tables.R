library(httr)
library(rvest)
library(jsonlite)
library(dplyr)
library(lubridate)

tryget <- function(link, times = 10) {
  res <- NULL
  for (i in 1:times) {
    res <- try(GET(link))
    if (inherits(res, "try-error")) {
      cat("\nFailed to get the data, sleeping for 1 second\n")
      Sys.sleep(1)
    } else {
      break
    }
  }
  if (is.null(res)) stop("Failed to get the data after ", times, " times.")
  res
}

raw <- tryget("http://sam.lrv.lt/lt/naujienos/koronavirusas")

# writeLines(unlist(strsplit(gsub("\n+","\n",gsub("(\n )+","\n",gsub(" +"," ",gsub("\r|\t", "", html_text(read_html(raw)))))),"\n")), paste0("/home/vaidotas/R/corona/data/korona_LT_",gsub( ":| ","_",raw$date),".csv"))

oo <- read_html(raw)

tbs <- html_table(oo, fill = TRUE)

# Get the total capacity data ------------------------------------------------------


capacity_total <- tbs[[1]][-2:-1, ]
colnames(capacity_total) <- c("description", "total", "intensive", "ventilated", "oxygen_mask")
capacity_total[, -1] <- sapply(capacity_total[, -1], as.integer)
rownames(capacity_total) <- NULL


# Get covid hospitalisation data ----------------------------------------------------------

cvh <- tbs[[2]][-2:-1, ]

colnames(cvh) <- c("description", "total", "oxygen", "ventilated", "hospitalized_not_intensive", "intensive")
cvh[, -1] <- sapply(cvh[, -1], as.integer)


# Get regional hospitalization data ---------------------------------------

tlk <- tbs[[3]][-2:-1, ]
colnames(tlk) <- c("description", "tlk", "total", "intensive", "ventilated", "oxygen_mask")
tlk[, -2:-1] <- sapply(tlk[, -2:-1], function(x) as.integer(gsub("[,.]", "", x)))

tt <- tlk %>% filter(tlk == "Iš viso:")

tlk <- tlk %>% filter(tlk != "Iš viso:")

tt1 <- tlk %>%
  select(-tlk) %>%
  group_by(description) %>%
  summarise_all(sum)

test_total <- sum(tt[order(tt$description), -1:-2] - tt1[order(tt1$description), -1])
if (test_total != 0) warning("Totals do not match with TLK breakdown")


# Write everything --------------------------------------------------------

res <- list(total_capacity = capacity_total, covid_hospitalization = cvh, tlk_capacity = tlk)

dd <- gsub(" ", "_", Sys.time())
fnl <- paste0("raw_data/hospitalization//", names(res), "_", dd, ".csv")

mapply(function(dt, nm) write.csv(dt, nm, row.names = FALSE), res, fnl, SIMPLIFY = FALSE)
