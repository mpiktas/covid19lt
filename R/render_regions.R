library(dplyr)

regs <- read.csv("data/lt-covid19-individual.csv") %>% .$administrative_level_3 %>% unique %>% sort

regs_n <- paste0(gsub("[.]","",gsub(" ", "_",regs)),".html")

out <- mapply(function(r, f) rmarkdown::render("R/region.Rmd", output_dir = 'docs/regions/', output_file = f, params = list(region = r)), regs, regs_n)
