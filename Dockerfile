FROM rocker/verse:4.0.5
LABEL maintainer="Vaidotas Zemlys-Balevičius"

## Install google cloud SDK so that you can use all google tools
RUN apt-get update -y

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN apt-get install -y apt-transport-https ca-certificates gnupg
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update -y
RUN apt-get install -y google-cloud-sdk

## Copy your code to rstudio home directory, so that you can check your code in Rstudio locally
RUN mkdir /home/rstudio/app
COPY ./ /home/rstudio/app
WORKDIR /home/rstudio/app

##Install additional packages which are necessary to run the code
RUN install2.r gert COVID19 dygraphs xts gridExtra distill EpiEstim flexdashboard config styler lintr
