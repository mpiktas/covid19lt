library(testthat)
library(gert)

source("R/functions.R")

cat("\n=======Downloading tests================\n")
try(source("R/download_osp_tests.R"))
cat("\n=======Downloading stats================\n")
try(source("R/download_osp_stats.R"))
cat("\n=======Downloading main OSP site================\n")
try(source("R/download_osp.R"))
cat("\n=======Downloading age distribution data================\n")
try(source("R/download_osp_agedist.R"))
cat("\n=======Downloading vaccine data ================\n")
try(source("R/download_osp_vaccine.R"))
cat("\n=======Downloading deaths data ================\n")
try(source("R/download_osp_deaths.R"))

cat("\n=======Downloading hospital data================\n")
try(source("R/download_osp_hospital.R"))

cat("\n=======Downloading transition data================\n")
try(source("R/download_osp_transitions.R"))

cat("\n=======Downloading EVRK data================\n")
try(source("R/download_osp_evrk.R"))

cat("\n=======Treating OSP data================\n")
try(source("R/treat_osp.R"))
cat("\n=======Creating levels data================\n")
try(source("R/create_levels.R"))

find_root <- function(x) {
  x %>%
    strsplit("/") %>%
    sapply("[[", 1)
}

## Was the data modified?
##
##


## Doing the workaround, as pushing from gert results in error.
## So set up github remote first.
## If nothing needs to be pushed, do not commit.
## CI/CD calls git push and we rely on that not failing.
## Yes this is a hack.

set_github_remote()

modf <- git_status() %>%
  .$file %>%
  find_root() %>%
  unique()
if (!("data" %in% modf)) {
  cat("\nNo new data, not pushing anything\n")
} else {
  push_to_github(c("data", "raw_data"), "Update OSP data", push = FALSE)
}
