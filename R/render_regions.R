library(dplyr)
library(rmarkdown)

regs <- read.csv("data/lt-covid19-individual.csv") %>% .$administrative_level_3 %>% unique %>% sort

regs <- regs[regs!=""]
regs_n <- paste0(gsub("[.]","",gsub(" ", "_",regs)),".html")

out <- mapply(function(r, f) try(rmarkdown::render("R/region.Rmd", output_dir = 'docs/regions/', output_file = f, params = list(region = r))),
              regs, regs_n, SIMPLIFY  = FALSE)

rmarkdown::render("R/regions_index.Rmd", output_dir = 'docs/', output_file = "savivaldybes.html")
