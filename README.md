# COVID-19 data for Lithuania

[The link to the site](https://mpiktas.github.io/covid19lt/)

Compiled from the [Lithuanian COVID19 open data](https://experience.arcgis.com/experience/cab84dcfe0464c2a8050a78f817924ca/page/page_5/). Use at your own risk. If you want to contribute create pull request or file an issue.

All the data is contained in the data folder. All the data files are renewed daily (with exception of archived data sets and effective R data). The Gitlab CI/CD pipeline configuration can be found in [.gitlab-ci.yml file](https://github.com/mpiktas/covid19lt/blob/master/.gitlab-ci.yml).

## Main datasets

The main datasets are the following three:

1.  [lt-covid19-country.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-country.csv) - data for Lithuania
2.  [lt-covid19-level2.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-level2.csv) - data for 10 administrative regions of Lithuania
3.  [lt-covid19-level3.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-level2.csv) - data at Lithuania municipality level.

These data sets contain historical cases, test, deaths and vaccination data. The country level data additionaly has hospitalization data. The column names should be explanatory. The data is harmonized, level 3 sums up to level 2 and level 2 sums up to country. All the data is fetched from Statistics Lithuania. ([Daily dispatches](https://osp.stat.gov.lt/praejusios-paros-covid-19-statistika), [Open data hub](https://open-data-ls-osp-sdg.hub.arcgis.com/search?collection=Dataset&tags=covid%2Cevrk2)). 

There some cases which are not attributed to any region. They are attributed to "Unknown" administrative region and municipality.

## Additional dasets

The additional data sets are available some of which are used as a source for the main files:

1. [lt-covid19-agedist.csv9](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-agedist.csv) - COVID19 confirmed cases and deaths by age, sex and region.

2. [lt-covid19-age-region-deaths.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-age-region-deaths.csv) - Deaths summary by age and region from, age information pivoted to columns from `lt-covid19-agedist.csv`

3. [lt-covid19-age-region-incidence.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-age-region-incidence.csv) - Incidence summary by age and region, age information pivoted to columns from `lt-covid19-agedist.csv`.

4. [lt-covid19-effective-R.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-effective-R.csv) - Effective R calculated from `lt-covid19-country.csv` incidence data.

5. [lt-covid19-evrk.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-evrk.csv) - COVID19 confirmed cases by economic activity. Based on national salary registry.

6. [lt-covid19-hospitals-country.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-hospitals-country.csv) - Country level data on COVID19 hospitalized patients.

7. [lt-covid19-hospitals-region.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-hospitals-region.csv) - Region level data on COVID19 hospitalized patients

8. [lt-covid19-vaccinated.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-vaccinated.csv) - Vaccination data on number of doses and protection states by day and region.

9. [lt-covid19-vaccinated-agedist10-level3.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-vaccinated-agedist10-level3.csv ) - Vaccination data on number of doses and protection states by day, sex, age group and region.

10. [lt-covid19-vaccine-deliveries.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-vaccine-deliveries.csv) - Vaccine delivery numbers by day and by vaccine type.

## OSP datasets

Files in OSP folder are downloads from Lithuanian statistics and are base for all the other files

1. [lt-covid19-cases.csv](https://github.com/mpiktas/covid19lt/blob/master/data/osp/lt-covid19-cases.csv) - COVID19 case data 

2. [lt-covid19-deaths.csv](https://github.com/mpiktas/covid19lt/blob/master/data/osp/lt-covid19-deaths.csv) - COVID19 death data 

3. [lt-covid19-stats.csv](https://github.com/mpiktas/covid19lt/blob/master/data/osp/lt-covid19-stats.csv) - Various COVID19 stats data

4. [lt-covid19-stats.csv](https://github.com/mpiktas/covid19lt/blob/master/data/osp/lt-covid19-tests.csv) - Data on COVID19 performed tests.

5. [lt-covid19-transitions.csv](https://github.com/mpiktas/covid19lt/blob/master/data/osp/lt-covid19-transition.csv) - Transitions from various vaccinated states.

6. [lt-covid19-transitions-init.csv](https://github.com/mpiktas/covid19lt/blob/master/data/osp/lt-covid19-transition.csv) - Initialisation data for transitions.

## Age distribution data

[Age distribution data](https://github.com/mpiktas/covid19lt/tree/master/data/age_distribution) for Lithuania by age, sex and region. Prepared from the officials statistics by the following [script](https://github.com/mpiktas/covid19lt/blob/master/R/prepare_age_distribution.R)

## Archived datasets

1.  [lt-covid19-total.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-total.csv) - historical data of confirmed cases from the start of epidemic
2.  [lt-covid19-laboratory-total.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-laboratory-total.csv) - historical data of laboratory tests from Ministry of Health [webpage](https://sam.lrv.lt/lt/naujienos/koronavirusas)
3.  [lt-covid19-agegroups.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-agegroups.csv) - historical data of confirmed cases by age groups. Provided by [Registrų centras](https://registrucentras.maps.arcgis.com/apps/opsdashboard/index.html#/becd01f2fade4149ba7a9e5baaddcd8d)
4.  [lt-covid19-regions.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-regions.csv) - historical data of confirmed cases by administrative regions of Lithuania. Provided by [Registrų centras](https://registrucentras.maps.arcgis.com/apps/opsdashboard/index.html#/becd01f2fade4149ba7a9e5baaddcd8d)
5.  [lt-covid19-aggregate.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-aggregate.csv) - All the time series collected from all the sources.

6. [lt-covid19-laboratory.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-aggregate.csv) - Laboratory data with test types.


If data is not documented then it means that it is not really relevant.

## Code 

All the code is in [R](https://github.com/mpiktas/covid19lt/tree/master/R) folder. Mainly this is data transformation code. 

## Website

The website is updated daily with various graphs and data summaries. The code resides in [website](https://github.com/mpiktas/covid19lt/tree/master/website) folder.

## Notebooks

Various analyses can be found in [notebooks](https://github.com/mpiktas/covid19lt/tree/master/notebooks) folder. These are usually some ideas which either end up in the website. 
