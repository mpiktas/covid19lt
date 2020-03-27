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

Sugeneruoti keturi modeliai, numetant po vieną dieną nuo visos imties.
Kiekvienam modeliui suskaičiuota 10 dienų prognozė.

Juoda spalva SAM skelbti užsikrėtusių per dieną skaičiai.
![](ggm_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Viso atvejų

![](ggm_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

Prognozių lentelė.

    ##           day 2020-03-24 2020-03-25 2020-03-26 historic
    ## 1  2020-03-11          2          2          2        2
    ## 2  2020-03-12          1          2          2        0
    ## 3  2020-03-13          2          3          3        3
    ## 4  2020-03-14          3          5          5        1
    ## 5  2020-03-15          4          7          7        5
    ## 6  2020-03-16          6          9         10        5
    ## 7  2020-03-17          8         12         12        9
    ## 8  2020-03-18         11         15         16        8
    ## 9  2020-03-19         16         19         19       14
    ## 10 2020-03-20         21         23         24       21
    ## 11 2020-03-21         29         28         28       36
    ## 12 2020-03-22         38         34         33       38
    ## 13 2020-03-23         50         40         39       44
    ## 14 2020-03-24         66         48         45       68
    ## 15 2020-03-25         85         55         52       35
    ## 16 2020-03-26        109         64         59       54
    ## 17 2020-03-27        140         73         67       NA
    ## 18 2020-03-28        177         83         75       NA
    ## 19 2020-03-29        223         94         84       NA
    ## 20 2020-03-30        279        106         94       NA
    ## 21 2020-03-31        348        118        104       NA
    ## 22 2020-04-01        430        132        114       NA
    ## 23 2020-04-02        530        147        126       NA
    ## 24 2020-04-03        649        162        138       NA
    ## 25 2020-04-04        791        179        150       NA
    ## 26 2020-04-05        959        196        163       NA

Viso atvejų

    ## # A tibble: 26 x 5
    ##    day        `2020-03-24` `2020-03-25` `2020-03-26` historic
    ##    <date>            <dbl>        <dbl>        <dbl>    <int>
    ##  1 2020-03-11            2            2            2        3
    ##  2 2020-03-12            3            4            4        3
    ##  3 2020-03-13            5            7            7        6
    ##  4 2020-03-14            8           12           12        7
    ##  5 2020-03-15           12           19           19       12
    ##  6 2020-03-16           18           28           29       17
    ##  7 2020-03-17           26           40           41       26
    ##  8 2020-03-18           37           55           57       34
    ##  9 2020-03-19           53           74           76       48
    ## 10 2020-03-20           74           97          100       69
    ## # … with 16 more rows

Modelių koeficentai. Eksponentinis augimas yra p = 1. K yra suminis visų
atvejų skaičius.

    ##       r     p
    ## 1 0.595 0.855
    ## 2 0.527 0.893
    ## 3 0.920 0.729
    ## 4 1.017 0.702

Savaitinis R įvertis. R\<1 reiškia kad epidemija perėjo į kritimą.
Daryta pagal šitą
[straipsnį](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3816335/) su R
paketu
[EpiEstim](https://cran.r-project.org/web/packages/EpiEstim/index.html).
Daryta pagal pavyzdį iš šio
[blogo](https://timchurches.github.io/blog/posts/2020-02-18-analysing-covid-19-2019-ncov-outbreak-data-with-r-part-1/#fitting-an-sir-model-to-the-hubei-province-data).

![](ggm_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

Ta pati informacija lentelėje

    ##   t_start t_end  Mean(R)   Std(R)
    ## 1       2     8 4.944614 3.614973
    ## 2       3     9 4.634622 3.016236
    ## 3       4    10 4.351596 2.574382
    ## 4       5    11 4.642082 2.539940
    ## 5       6    12 4.275967 2.289917
    ## 6       7    13 3.874018 2.035516
    ## 7       8    14 3.712020 1.879207
    ## 8       9    15 2.991564 1.454033
    ## 9      10    16 2.580247 1.126539

[Serijiniai intervalai](https://en.wikipedia.org/wiki/Serial_interval)
(intervalai tarp užsikrėtimų)

![](ggm_files/figure-gfm/unnamed-chunk-13-1.png)<!-- -->
