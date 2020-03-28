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
    ## 14 2020-03-26       344        54    28
    ## 15 2020-03-27       382        38    29

Sugeneruoti trys modeliai, numetant po vieną dieną nuo visos imties.
Kiekvienam modeliui suskaičiuota 10 dienų prognozė.

Juoda spalva SAM skelbti užsikrėtusių per dieną skaičiai.
![](forecast_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Viso atvejų

![](forecast_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

Prognozių lentelė.

    ##           day 2020-03-25 2020-03-26 2020-03-27 historic
    ## 1  2020-03-13          3          3          3        3
    ## 2  2020-03-14          2          2          2        1
    ## 3  2020-03-15          3          3          3        5
    ## 4  2020-03-16          5          5          4        5
    ## 5  2020-03-17          7          7          7        9
    ## 6  2020-03-18         11         11         11        8
    ## 7  2020-03-19         17         16         16       14
    ## 8  2020-03-20         24         23         23       21
    ## 9  2020-03-21         33         31         31       36
    ## 10 2020-03-22         42         40         41       38
    ## 11 2020-03-23         48         48         48       44
    ## 12 2020-03-24         50         53         53       68
    ## 13 2020-03-25         46         52         52       35
    ## 14 2020-03-26         39         47         47       54
    ## 15 2020-03-27         30         39         38       38
    ## 16 2020-03-28         21         30         29       NA
    ## 17 2020-03-29         14         22         21       NA
    ## 18 2020-03-30         10         15         15       NA
    ## 19 2020-03-31          6         10         10       NA
    ## 20 2020-04-01          4          7          6       NA
    ## 21 2020-04-02          2          4          4       NA
    ## 22 2020-04-03          2          3          3       NA
    ## 23 2020-04-04          1          2          2       NA
    ## 24 2020-04-05          1          1          1       NA
    ## 25 2020-04-06          0          1          1       NA

Viso atvejų

    ## # A tibble: 25 x 5
    ##    day        `2020-03-25` `2020-03-26` `2020-03-27` historic
    ##    <date>            <dbl>        <dbl>        <dbl>    <int>
    ##  1 2020-03-13            6            6            6        6
    ##  2 2020-03-14            8            8            8        7
    ##  3 2020-03-15           11           11           11       12
    ##  4 2020-03-16           16           16           15       17
    ##  5 2020-03-17           23           23           22       26
    ##  6 2020-03-18           34           34           33       34
    ##  7 2020-03-19           51           50           49       48
    ##  8 2020-03-20           75           73           72       69
    ##  9 2020-03-21          108          104          103      105
    ## 10 2020-03-22          150          144          144      143
    ## # … with 15 more rows

Modelių koeficentai. Eksponentinis augimas yra p = 1. K yra suminis visų
atvejų skaičius.

    ##       r     p   K
    ## 1 0.479 1.000 422
    ## 2 0.487 0.986 475
    ## 3 0.482 0.989 471
