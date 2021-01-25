# COVID-19 data for Lithuania

[The link to the site](https://mpiktas.github.io/covid19lt/)

Compiled from various sources, used at your own risk. If you want to contribute create pull request or file an issue.

All the data is contained in the data folder.

The main datasets are the following three:

1.  [lt-covid19-country.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-country.csv) - data for Lithuania
2.  [lt-covid19-level2.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-level2.csv) - data for 10 administrative regions of Lithuania
3.  [lt-covid19-level3.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-level2.csv) - data at Lithuania municipality level.

These data sets contain historical cases, test and deaths data. The country level data additionaly has hospitalization data. The column names should be explanatory. The data is harmonized, level 3 sums up to level 2 and level 2 sums up to country. All the data is fetched from Statistics Lithuania. ([Daily dispatches](https://osp.stat.gov.lt/praejusios-paros-covid-19-statistika), [Open data hub](https://open-data-ls-osp-sdg.hub.arcgis.com/search?collection=Dataset&tags=covid%2Cevrk2)). There some cases which are not attributed to any region. They are attributed to "Unknown" administrative region and municipality.

The additional data sets are available some of which are used as a source for the main files:

1.  [lt-covid19-daily.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-daily.csv) - historical daily data from Ministry of Health [webpage](https://sam.lrv.lt/lt/naujienos/koronavirusas). Now gets the daily updates from [Statics Lithuania](https://osp.stat.gov.lt/praejusios-paros-covid-19-statistika). The daily releases are snapshots of the data and do not provide consistent time series.

2.  [lt-covid19-individual.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-individual.csv) - anonymized data of each confirmed case. Provided by [data.gov.lt](https://data.gov.lt/dataset/covid-19-epidemiologiniai-duomenys)

3.  [lt-covid19-individual-daily.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-individual-daily.csv) - Daily summaries from the `lt-covid19-individual.csv`.

4.  [lt-covid19-age-region-deaths.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-age-region-deaths.csv) - Deaths summary by age and region from `lt-covid19-individual.csv`

5.  [lt-covid19-age-region-incidence.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-age-region-incidence.csv) - Incidence summary by age and region from `lt-covid19-individual.csv`.

6.  [lt-covid19-effective-R.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-effective-R.csv) - Effective R calculated from `lt-covid19-individual.csv` incidence data.

7.  [lt-covid19-tests.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-tests.csv) - Testing data from Statistics Lithuania. A source for the main data file.

8.  [lt-covid19-cases.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-tests.csv) - Cases and deaths data from Statistics Lithuania. A source for the main data file.

9.  [lt-covid19-hospitalized.csv](https://github.com/mpiktas/covid19lt/blob/master/data/lt-covid19-tests.csv) - Patient data.

Archived data sets

1.  [lt-covid19-total.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-total.csv) - historical data of confirmed cases from the start of epidemic
2.  [lt-covid19-laboratory-total.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-laboratory-total.csv) - historical data of laboratory tests from Ministry of Health [webpage](https://sam.lrv.lt/lt/naujienos/koronavirusas)
3.  [lt-covid19-agegroups.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-agegroups.csv) - historical data of confirmed cases by age groups. Provided by [Registrų centras](https://registrucentras.maps.arcgis.com/apps/opsdashboard/index.html#/becd01f2fade4149ba7a9e5baaddcd8d)
4.  [lt-covid19-regions.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-regions.csv) - historical data of confirmed cases by administrative regions of Lithuania. Provided by [Registrų centras](https://registrucentras.maps.arcgis.com/apps/opsdashboard/index.html#/becd01f2fade4149ba7a9e5baaddcd8d)
5.  [lt-covid19-aggregate.csv](https://github.com/mpiktas/covid19lt/blob/master/data/archive/lt-covid19-aggregate.csv) - All the time series collected from all the sources.

The data is updated every day, usually in the evenings. The data in the webpage on Lithuanian Health Ministry is updated irregularly, usually around 10-11 am. It is not updated on Saturdays and Sundays. The data is then gathered from unofficial sources, usually media portal pages. The Registrų centras is also updated irregularly.

Surinkta iš įvairių šaltinių, tai nėra oficiali informacija. Jeigu pamatėte klaidą, kurkite pull request arba užpildykite issue.
