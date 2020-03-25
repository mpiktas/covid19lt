Simple forecasts
================

Modelis paremtas šituo
[straipsniu](https://bmcmedicine.biomedcentral.com/articles/10.1186/s12916-019-1406-6).
Modeliuojamas užsikrėtusių per dieną skaičius.

Duomenys modeliavimui

    ##           day confirmed incidence times
    ## 1  2020-03-13         6         3    15
    ## 2  2020-03-14         7         1    16
    ## 3  2020-03-15        12         5    17
    ## 4  2020-03-16        17         5    18
    ## 5  2020-03-17        26         9    19
    ## 6  2020-03-18        34         8    20
    ## 7  2020-03-19        48        14    21
    ## 8  2020-03-20        69        21    22
    ## 9  2020-03-21       105        36    23
    ## 10 2020-03-22       143        38    24
    ## 11 2020-03-23       187        44    25
    ## 12 2020-03-24       255        68    26

Sugeneruoti trys modeliai, numetant po vieną dieną nuo visos imties.
Kiekvienam modeliui suskaičiuota 10 dienų prognozė.

Juoda spalva SAM skelbti užsikrėtusių per dieną skaičiai.
![](forecast_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Prognozių lentelė.

    ##           day 2020-03-22 2020-03-23 2020-03-24 historic
    ## 1  2020-03-13          3          3          3        3
    ## 2  2020-03-14          2          2          2        1
    ## 3  2020-03-15          3          3          3        5
    ## 4  2020-03-16          4          5          5        5
    ## 5  2020-03-17          7          7          8        9
    ## 6  2020-03-18         11         11         11        8
    ## 7  2020-03-19         16         16         16       14
    ## 8  2020-03-20         23         23         21       21
    ## 9  2020-03-21         31         31         29       36
    ## 10 2020-03-22         40         39         38       38
    ## 11 2020-03-23         46         44         50       44
    ## 12 2020-03-24         48         45         65       68
    ## 13 2020-03-25         45         41         83       NA
    ## 14 2020-03-26         38         34        106       NA
    ## 15 2020-03-27         30         26        133       NA
    ## 16 2020-03-28         21         18        165       NA
    ## 17 2020-03-29         15         13        203       NA
    ## 18 2020-03-30         10          8        248       NA
    ## 19 2020-03-31          6          5        301       NA
    ## 20 2020-04-01          4          3        362       NA
    ## 21 2020-04-02          3          2        434       NA
    ## 22 2020-04-03          2          1        516       NA

Modelių koeficentai. Eksponentinis augimas yra p = 1. K yra suminis visų
atvejų skaičius.

    ##       r     p      K
    ## 1 0.472 1.000    410
    ## 2 0.476 1.000    384
    ## 3 0.684 0.846 330000
