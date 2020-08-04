eBird Abundance Data
================
Peter Hoff
04 August, 2020

### Summary

The file `eBirdAPI.r` provides a few R functions to download and wrangle
data from the [eBird
project](https://ebird.org/science/download-ebird-data-products), using
their API. The functions include the following:

  - `eBirdGetURL`: Download generic data and leave it in json/list
    format
  - `eBirdGetData` : Download *complete* checklists from a given region
    on a given date. Returns a list that includes
      - `obsData`: numeric matrix of bird counts by checklist and
        species;
      - `metaData`: dataframe of checklist metadata.
  - `eBirdMergeData`: Merge two lists that have the format returned by
    `eBirdGetData`;
  - `eBirdNames` : Not a function, but a table that matches the bird
    codes used by eBird to common names.

### Comments:

1)  To download data from eBird you need to have an eBird API key, and
    set it as an environment variable with `Sys.setenv(EBIRD_KEY =
    "xxxxxxxx")`.  
2)  There are some duplicates (friends who collect and report the same
    data). This should be fixed in the future.
3)  Some birders just report presence without a numeric count. For these
    cases, numeric counts are imputed, but all imputed values end in
    `.5` so that they can be identified.
4)  The eBird API only allows 200 checklists to be downloaded per
    request. If this limit is reached then only the first 200 lists are
    included in the dataset, and a warning message is printed.  
5)  There exist a couple of R packages for accessing eBird data:
    [rebird](https://github.com/ropensci/rebird) and
    [auk](https://github.com/CornellLabofOrnithology/auk/). The latter
    assumes you have already downloaded a super-large eBird database.
    The former uses the API (like the code in this repo), but doesn’t
    seem to provide access to information on checklist completeness
    (which is important to know for statistical analysis).

### How to use

Load in the functions and see what they are:

``` r
#source("https://raw.githubusercontent.com/pdhoff/eBirdGetData/master/eBirdAPI.r")

source("eBirdAPI.r")

objects()
```

    ## [1] "eBirdGetData"   "eBirdGetURL"    "eBirdMergeData" "eBirdNames"

Download and merge one week of data from some NC counties:

``` r
# Durham, Brunswick, Beaufort, Dare, Wake and Orange counties
counties<-c("US-NC-063","US-NC-019","US-NC-013","US-NC-055","US-NC-183","US-NC-135") 
dates<-as.Date(0:6,origin = "2020-05-01")

eBdat<-NULL
for(i in seq_along(counties)){
  for(j in seq_along(dates)){
    eBdat<-eBirdMergeData(eBdat,eBirdGetData(region=counties[i],date=dates[j]))
    cat(counties[i],dates[j],"\n")
}}
```

    ## US-NC-063 18383 
    ## US-NC-063 18384 
    ## US-NC-063 18385 
    ## US-NC-063 18386 
    ## US-NC-063 18387 
    ## US-NC-063 18388 
    ## US-NC-063 18389 
    ## US-NC-019 18383 
    ## US-NC-019 18384 
    ## US-NC-019 18385 
    ## US-NC-019 18386 
    ## US-NC-019 18387 
    ## US-NC-019 18388 
    ## US-NC-019 18389 
    ## US-NC-013 18383 
    ## US-NC-013 18384 
    ## US-NC-013 18385 
    ## US-NC-013 18386 
    ## US-NC-013 18387 
    ## US-NC-013 18388 
    ## US-NC-013 18389 
    ## US-NC-055 18383 
    ## US-NC-055 18384 
    ## US-NC-055 18385 
    ## US-NC-055 18386 
    ## US-NC-055 18387 
    ## US-NC-055 18388 
    ## US-NC-055 18389 
    ## US-NC-183 18383 
    ## US-NC-183 18384 
    ## US-NC-183 18385 
    ## US-NC-183 18386 
    ## US-NC-183 18387 
    ## US-NC-183 18388 
    ## US-NC-183 18389 
    ## US-NC-135 18383 
    ## US-NC-135 18384 
    ## US-NC-135 18385 
    ## US-NC-135 18386 
    ## US-NC-135 18387 
    ## US-NC-135 18388 
    ## US-NC-135 18389

Examine metaData a bit:

``` r
eBdat$metaData[1:3,]
```

    ##          id             date duration latitude longitude loc1  loc2      loc3
    ## 1 S68271265 2020-05-01 19:30    0.083 35.90281 -79.00055   US US-NC US-NC-063
    ## 2 S68215893 2020-05-01 18:49    0.650 35.92115 -78.94957   US US-NC US-NC-063
    ## 3 S68209974 2020-05-01 17:27    0.600 36.00304 -78.94707   US US-NC US-NC-063

``` r
plot(eBdat$metaData$long,eBdat$metaData$lat,xlab="longitude",ylab="latitude") 
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

Examine obsData a bit:

``` r
eBdat$obsData[1:3,1:6] 
```

    ##           Acadian Flycatcher Accipiter sp. American Bittern American Black Duck
    ## S68271265                  0             0                0                   0
    ## S68215893                  0             0                0                   0
    ## S68209974                  0             0                0                   0
    ##           American Coot American Crow
    ## S68271265             0             0
    ## S68215893             0             7
    ## S68209974             0             1

``` r
## Obtain counts per hour of effort 
obsPH<-sweep(eBdat$obsData,1,eBdat$metaData$duration,"/") 

## Top 20 birds in Durham
sort(apply(obsPH[eBdat$metaData$loc3==counties[1],],2,mean),decreasing=TRUE)[1:20]  
```

    ##      Northern Cardinal     Carolina Chickadee       Downy Woodpecker 
    ##               3.029230               2.244862               2.199182 
    ##               Blue Jay  Blue-gray Gnatcatcher          Carolina Wren 
    ##               2.159292               2.092961               2.000572 
    ##              Fish Crow           Canada Goose          American Crow 
    ##               1.910612               1.586330               1.566858 
    ##          House Sparrow     American Goldfinch             Barred Owl 
    ##               1.536071               1.514350               1.461825 
    ##         Eastern Towhee        Tufted Titmouse Red-bellied Woodpecker 
    ##               1.448340               1.368253               1.315154 
    ##  Brown-headed Nuthatch         American Robin       Great Blue Heron 
    ##               1.311144               1.291383               1.267440 
    ##         Summer Tanager   Brown-headed Cowbird 
    ##               1.209919               1.144337

``` r
## Top 20 birds in Beaufort 
sort(apply(obsPH[eBdat$metaData$loc3==counties[2],],2,mean),decreasing=TRUE)[1:20]  
```

    ##                 Killdeer        Northern Cardinal                 Blue Jay 
    ##                6.0839776                4.8791295                4.6240859 
    ##            Carolina Wren    Brown-headed Nuthatch     Northern Mockingbird 
    ##                4.6035148                4.0350263                3.4285391 
    ##       Carolina Chickadee              Great Egret            American Crow 
    ##                3.1477513                2.2005186                2.0771078 
    ##         Eastern Bluebird           Brown Thrasher            Mourning Dove 
    ##                1.9509811                1.7476243                1.3497883 
    ##              House Finch Great Crested Flycatcher     Brown-headed Cowbird 
    ##                1.3321502                1.2858990                1.2228459 
    ##            Black Vulture          Painted Bunting              Green Heron 
    ##                1.1580193                1.0708233                0.8638049 
    ##         Downy Woodpecker    Blue-gray Gnatcatcher 
    ##                0.8423402                0.7538042
