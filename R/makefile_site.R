library(gert)
library(dplyr)
library(lubridate)

rmarkdown::render_site()
source("R/render_regions.R")

cat("\nSending the site downstream\n")
ghpt <- Sys.getenv("GITHUB_PA_TOKEN")
if(ghpt!="") {
    cat("\nTrying to set signature\n")
    git_config_set("user.name", "Gitlab CI bot")
    git_config_set("user.email", "test@email.com")
    cat("\nCurrent git status\n")
    print(git_status())
    print(git_info())
    git_branch_checkout("master")
    git_add("docs")
    cat("\nTrying to commit\n")
    git_commit("Update the site")
    git_remote_add(glue::glue("https://covid19-ci:{ghpt}@github.com/mpiktas/covid19lt.git"), "github")
    git_push(remote = "github")
} else {
    cat("\nGithub token not found, relying on local git configuration\n")
    git_add("docs")
    git_commit("Update the site")
    git_push()
}
