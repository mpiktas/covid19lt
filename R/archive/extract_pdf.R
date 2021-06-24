library(pdftools)
library(dplyr)

fns <- dir("tests", pattern = "[0-9]+.csv", full.names = TRUE)
days <- fns %>%
  strsplit("-") %>%
  sapply(function(x) gsub(".csv", "", x[length(x)]))
daysd <- ymd(days)
new_day <- max(daysd) + days(1)
outd <- gsub("-", "", as.character(new_day))
new_day_data <- read.csv(fns[which.max(daysd)], stringsAsFactors = FALSE)

txt <- pdf_text("tests/pdfs/2020-04-11 Issami statistika.pdf") %>% strsplit("\n")

tb <- txt[[1]][16:28]

stb <- strsplit(tb, " +")

lns <- stb %>% lapply(function(x) {
  ints <- na.omit(as.integer(x))
  txt <- x[attributes(ints)$na.action]
  list(numbers = ints, text = txt)
})

lns_l <- lns %>% sapply(function(l) length(l$numbers))

num_cols <- t(sapply(lns[lns_l != 0], "[[", "numbers"))

txt_cols <- sapply(lns[lns_l != 0], function(l) {
  paste(l$text[l$text != ""], collapse = " ")
})

tb <- bind_cols(data.frame(laboratory = txt_cols, stringsAsFactors = FALSE), as.data.frame(num_cols))
colnames(tb)[-1] <- c("tested_all", "tested_mobile", "negative_all", "negative_mobile", "positive_all", "positive_mobile", "not_tested", "not_tested_mobile")

tb[4, 1] <- "Klaipėdos universitetinė ligoninė"

tbr <- tb %>% filter(laboratory != "VISO")

tbr <- bind_cols(data.frame(day = rep(new_day, nrow(tbr))), tbr)

tot <- tbr[, -1:-2] %>% sapply(sum, na.rm = TRUE)

if (sum(abs(tot - tb %>% filter(laboratory == "VISO") %>% .[, -1] %>% unlist())) == 0) {
  write.csv(tbr, glue::glue("tests/lt-covid19-laboratory-{outd}.csv"), row.names = FALSE)
}
