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
    ## 13 2020-03-25       290        35    27

Sugeneruoti trys modeliai, numetant po vieną dieną nuo visos imties.
Kiekvienam modeliui suskaičiuota 10 dienų prognozė.

Juoda spalva SAM skelbti užsikrėtusių per dieną skaičiai.
![](forecast_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Viso atvejų

![](forecast_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

Prognozių lentelė.

    ##           day 2020-03-23 2020-03-24 2020-03-25 historic
    ## 1  2020-03-13          3          3          3        3
    ## 2  2020-03-14          2          2          2        1
    ## 3  2020-03-15          3          3          3        5
    ## 4  2020-03-16          5          5          5        5
    ## 5  2020-03-17          7          8          7        9
    ## 6  2020-03-18         11         11         11        8
    ## 7  2020-03-19         16         16         17       14
    ## 8  2020-03-20         23         21         24       21
    ## 9  2020-03-21         31         29         33       36
    ## 10 2020-03-22         39         38         42       38
    ## 11 2020-03-23         44         50         48       44
    ## 12 2020-03-24         45         65         50       68
    ## 13 2020-03-25         41         83         46       35
    ## 14 2020-03-26         34        106         39       NA
    ## 15 2020-03-27         26        133         30       NA
    ## 16 2020-03-28         18        165         21       NA
    ## 17 2020-03-29         13        203         14       NA
    ## 18 2020-03-30          8        248         10       NA
    ## 19 2020-03-31          5        301          6       NA
    ## 20 2020-04-01          3        362          4       NA
    ## 21 2020-04-02          2        434          2       NA
    ## 22 2020-04-03          1        516          2       NA
    ## 23 2020-04-04          1        610          1       NA

Viso atvejų

    ## # A tibble: 23 x 5
    ##    day        `2020-03-23` `2020-03-24` `2020-03-25` historic
    ##    <date>            <dbl>        <dbl>        <dbl>    <int>
    ##  1 2020-03-13            6            6            6        6
    ##  2 2020-03-14            8            8            8        7
    ##  3 2020-03-15           11           11           11       12
    ##  4 2020-03-16           16           16           16       17
    ##  5 2020-03-17           23           24           23       26
    ##  6 2020-03-18           34           35           34       34
    ##  7 2020-03-19           50           51           51       48
    ##  8 2020-03-20           73           72           75       69
    ##  9 2020-03-21          104          101          108      105
    ## 10 2020-03-22          143          139          150      143
    ## # … with 13 more rows

Modelių koeficentai. Eksponentinis augimas yra p = 1. K yra suminis visų
atvejų skaičius.

    ##       r     p      K
    ## 1 0.476 1.000    384
    ## 2 0.684 0.846 330000
    ## 3 0.479 1.000    422
