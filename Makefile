## List your targets
.PHONY: osp reff lint test build-docker push run-locally clean
## These settings are needed for running docker locally
## You can push the image to the container registry specific to your project,
## but that is optional.
VERSION=1
APP=covid19lt
## Always change this to your project container registry. This will allow you to
## differentiate between the different project images
GITLAB_REGISTRY=registry.gitlab.com/vzemlys/covid19lt
IMAGE=$(GITLAB_REGISTRY)/$(APP):$(VERSION)

## This is your target to run, you can rename this target or add more
osp:
		Rscript -e "source('R/makefile_osp_live.R')"

reff:
		Rscript -e "source('R/makefile_effective.R')

mobility:
		Rscript -e "source('R/makefile_mobility.R')"


## Run the styler to check that your code conforms to the EMI style
## Run the lintr to check that your code actually runs and there are no problems
## Set the argument dry='fail' for styler to fail, dry='on' to ignore the errors.
## In some weird cases styler wants to change the files which are fine
lint:
		echo "---------Style the files-------------------------"
		echo "If the following test fails, run styler::style_dir('.', filetype = c('R', 'Rmd', 'Rprofile'))"
		Rscript -e "sessionInfo();styler::style_dir('R', filetype = c('R', 'Rmd', 'Rprofile'), dry = 'fail')"
		Rscript -e "styler::style_dir('notebooks', filetype = c('R', 'Rmd', 'Rprofile'), dry = 'fail')"
		Rscript -e "styler::style_dir('website', filetype = c('R', 'Rmd', 'Rprofile'), dry = 'fail')"
		echo "---------Linting starts--------------------------"
		Rscript -e "errors <- lintr::lint_dir('R'); print(errors); quit(save = 'no', status = length(errors))"
		Rscript -e "errors <- lintr::lint_dir('notebooks'); print(errors); quit(save = 'no', status = length(errors))"
		Rscript -e "errors <- lintr::lint_dir('website'); print(errors); quit(save = 'no', status = length(errors))"

## Run the tests.
test:
		Rscript -e "testthat::test_dir('tests')"

## Build the docker image locally
build-docker:
		docker build --rm . --tag $(IMAGE)

## Push the image to the gitlab registry
push:
		docker push $(IMAGE)

## Run the docker image locally. Go to localhost:8787 and login into Rstudio
## with the user rstudio and the password set below. Your code will reside in
## /home/rstudio/app.
run-locally:
		docker run --rm -p 8787:8787 -e PASSWORD=emids $(IMAGE)

## Remove local docker image
clean:
		docker rmi $(IMAGE)
