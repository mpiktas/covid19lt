Apibendrintas augimo modelis
================

Modelis paremtas šituo
[straipsniu](https://www.sciencedirect.com/science/article/pii/S1755436516000037).
Modeliuojamas užsikrėtusių per dieną skaičius.

Duomenys modeliavimui

    ##           day confirmed incidence times w
    ## 1  2020-03-11         3         2    13 1
    ## 2  2020-03-12         3         0    14 0
    ## 3  2020-03-13         6         3    15 1
    ## 4  2020-03-14         7         1    16 1
    ## 5  2020-03-15        12         5    17 1
    ## 6  2020-03-16        17         5    18 1
    ## 7  2020-03-17        26         9    19 1
    ## 8  2020-03-18        34         8    20 1
    ## 9  2020-03-19        48        14    21 1
    ## 10 2020-03-20        69        21    22 1
    ## 11 2020-03-21       105        36    23 1
    ## 12 2020-03-22       143        38    24 1
    ## 13 2020-03-23       187        44    25 1
    ## 14 2020-03-24       255        68    26 1
    ## 15 2020-03-25       290        35    27 1
    ## 16 2020-03-26       344        54    28 1
    ## 17 2020-03-27       382        38    29 1

Sugeneruoti keturi modeliai, numetant po vieną dieną nuo visos imties.
Kiekvienam modeliui suskaičiuota 10 dienų prognozė.

Juoda spalva SAM skelbti užsikrėtusių per dieną skaičiai.
![](ggm_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Viso atvejų

![](ggm_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

Prognozių lentelė.

    ##           day 2020-03-25 2020-03-26 2020-03-27 historic
    ## 1  2020-03-11          2          2          2        2
    ## 2  2020-03-12          2          2          3        0
    ## 3  2020-03-13          3          3          4        3
    ## 4  2020-03-14          5          5          6        1
    ## 5  2020-03-15          7          7          9        5
    ## 6  2020-03-16          9         10         11        5
    ## 7  2020-03-17         12         12         14        9
    ## 8  2020-03-18         15         16         17        8
    ## 9  2020-03-19         19         19         21       14
    ## 10 2020-03-20         23         24         24       21
    ## 11 2020-03-21         28         28         28       36
    ## 12 2020-03-22         34         33         32       38
    ## 13 2020-03-23         40         39         36       44
    ## 14 2020-03-24         48         45         41       68
    ## 15 2020-03-25         55         52         45       35
    ## 16 2020-03-26         64         59         50       54
    ## 17 2020-03-27         73         67         55       38
    ## 18 2020-03-28         83         75         61       NA
    ## 19 2020-03-29         94         84         66       NA
    ## 20 2020-03-30        106         94         72       NA
    ## 21 2020-03-31        118        104         78       NA
    ## 22 2020-04-01        132        114         84       NA
    ## 23 2020-04-02        147        126         90       NA
    ## 24 2020-04-03        162        138         97       NA
    ## 25 2020-04-04        179        150        103       NA
    ## 26 2020-04-05        196        163        110       NA
    ## 27 2020-04-06        215        177        117       NA

Viso atvejų

    ## # A tibble: 27 x 5
    ##    day        `2020-03-25` `2020-03-26` `2020-03-27` historic
    ##    <date>            <dbl>        <dbl>        <dbl>    <int>
    ##  1 2020-03-11            2            2            2        3
    ##  2 2020-03-12            4            4            5        3
    ##  3 2020-03-13            7            7            9        6
    ##  4 2020-03-14           12           12           15        7
    ##  5 2020-03-15           19           19           24       12
    ##  6 2020-03-16           28           29           35       17
    ##  7 2020-03-17           40           41           49       26
    ##  8 2020-03-18           55           57           66       34
    ##  9 2020-03-19           74           76           87       48
    ## 10 2020-03-20           97          100          111       69
    ## # … with 17 more rows

Modelių koeficentai. Eksponentinis augimas yra p = 1. K yra suminis visų
atvejų skaičius.

    ##       r     p
    ## 1 0.527 0.893
    ## 2 0.920 0.729
    ## 3 1.017 0.702
    ## 4 1.328 0.631

Savaitinis R įvertis. R\<1 reiškia kad epidemija perėjo į kritimą.
Daryta pagal šitą
[straipsnį](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3816335/) su R
paketu
[EpiEstim](https://cran.r-project.org/web/packages/EpiEstim/index.html).
Daryta pagal pavyzdį iš šio
[blogo](https://timchurches.github.io/blog/posts/2020-02-18-analysing-covid-19-2019-ncov-outbreak-data-with-r-part-1/#fitting-an-sir-model-to-the-hubei-province-data).

![](ggm_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

Ta pati informacija lentelėje

    ##    t_start t_end  Mean(R)    Std(R)
    ## 1        2     8 5.111861 3.5940920
    ## 2        3     9 4.786472 3.0274482
    ## 3        4    10 4.479645 2.5899665
    ## 4        5    11 4.775311 2.5681635
    ## 5        6    12 4.402680 2.3266441
    ## 6        7    13 3.991162 2.0739817
    ## 7        8    14 3.818475 1.9125357
    ## 8        9    15 3.070837 1.4761623
    ## 9       10    16 2.642353 1.1436499
    ## 10      11    17 2.156591 0.8089412

[Serijiniai intervalai](https://en.wikipedia.org/wiki/Serial_interval)
(intervalai tarp užsikrėtimų)

![](ggm_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->
