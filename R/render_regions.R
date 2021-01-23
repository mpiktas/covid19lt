library(dplyr)
library(rmarkdown)

rmarkdown::render("R/regions_index.Rmd", output_dir = 'docs/', output_file = "savivaldybes.html")


lvl3 <- read.csv("data/lt-covid19-level3.csv") %>% filter(administrative_level_3!= "Unknown")

regs <- c(lvl3$administrative_level_3 %>% unique %>% sort,lvl3$administrative_level_2 %>% unique %>% sort, "Lietuva")

regs_n <- paste0(gsub("[.]","",gsub(" ", "_",regs)),".html")

out <- mapply(function(r, f) try(rmarkdown::render("R/region.Rmd", output_dir = 'docs/regions/', output_file = f, params = list(region = r))),
              regs, regs_n, SIMPLIFY  = FALSE)

