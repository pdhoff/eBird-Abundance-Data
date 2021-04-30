#' Functions to download eBird observations by region and date. 
#' The main function downloads data from complete checklists only. 
#' 
#' Notes:
#' 1) To download data you need to have an eBird API key and set it as an 
#' environment variable with `Sys.setenv(EBIRD_KEY = "xxxxxxxx")`.
#' 2) There are some duplicates (friends who collect and report the same data).
#' This should be fixed.
#' 3) Some birders just report presence without number. Counts for these 
#' entries have been imputed. 
#' 4) The eBird API only allows 200 checklists to be downloaded per request. 
#' If this limit is reached then only the first 200 lists are included in the 
#' dataset, and a warning message is printed.  
#'
#' Author: Peter Hoff
#' Last modified: 2020-08-01



#' Load or download eBird names table
if( any(system("ls",intern=TRUE)=="eBirdNames.csv")){
  eBirdNames<-read.csv("eBirdNames.csv") 
} else{ 
  eBirdNames<-read.csv("https://api.ebird.org/v2/ref/taxonomy/ebird")[,c("COMMON_NAME","SPECIES_CODE")] 
}



#' Download generic data and leave it in json/list format
eBirdGetURL<-function(url){ 

  ## check for key 
  if( nchar(Sys.getenv("EBIRD_KEY"))==0 ){
    stop("Error: environment variable EBIRD_KEY needs to be set.\n") 
  }     
  
  rjson<-httr::GET(URLencode(url),
         httr::add_headers("X-eBirdApiToken"=Sys.getenv("EBIRD_KEY")))
  tdat<-httr::content(rjson,as="text",encoding="UTF-8")
  jsonlite::fromJSON(tdat,FALSE)
}



#' Download complete checklists from a given region on a given date 
eBirdGetData<-function(region,date,commonName=exists("eBirdNames")){ 

  ## region ; character ; a recognized eBird region code
  ## date ; character ; the date in yyyy-mm-dd format
  ## commonName ; logical ; use common names or species code

  # construct url and download list of checklists
  date<-gsub("-","/",date)
  url<-"https://api.ebird.org/v2/product/lists/"
  url<-paste0(url,region,"/",date,"?maxResults=200") 
  dat<-eBirdGetURL(url) 
  if(length(dat)==200){ cat("Warning: max results returned - there may be additional observations\n") }

  odat<-mdat<-list()  
  for(i in seq_along(dat))
  { 

    subId<-dat[[i]]$subId 
    url<-paste0("https://api.ebird.org/v2/product/checklist/view/",subId)
    cldat<-eBirdGetURL(url)

    if(cldat$allObsReported)
    { 

      ## meta data 
      meta<-list(
        id=cldat$subId,
        date=cldat$obsDt,
        durationHours=cldat$durationHrs,
        latitude=dat[[i]]$loc$latitude,
        longitude=dat[[i]]$loc$longitude,
        loc1=dat[[i]]$loc$countryCode,
        loc2=dat[[i]]$loc$subnational1Code,
        loc3=dat[[i]]$loc$subnational2Code)
      meta[sapply(meta,is.null)]<-NA 
      mdat[[ length(mdat)+1 ]]<-meta 

      obs<-data.frame(
            speciesCode=sapply(cldat$obs,function(x){ x$speciesCode }),
            howManyStr=suppressWarnings(
            as.numeric(sapply(cldat$obs,function(x){x$howManyStr})))  )

      odat[[ length(odat)+1 ]]<-obs
    }        
  }

  ## convert data to numeric matrix and frame
  mdat<-data.frame( id=sapply(mdat,function(x){x$id}), 
                    date=sapply(mdat,function(x){x$date}),
                    duration=sapply(mdat,function(x){x$duration}), 
                    latitude=sapply(mdat,function(x){x$latitude}), 
                    longitude=sapply(mdat,function(x){x$longitude}),
                    loc1=sapply(mdat,function(x){x$loc1}),
                    loc2=sapply(mdat,function(x){x$loc2}),
                    loc3=sapply(mdat,function(x){x$loc3}) ) 

  ## combine obs data 
  bnames<-sort(unique(unlist(sapply(odat,function(x){x$speciesCode})))) 
  bnull<-rep(0,length(bnames)) ; names(bnull)<-bnames 
  odat<-t(sapply(odat,function(x){ y<-bnull ; y[match(x[,1],bnames)]<-x[,2] ; y } ) ) 

  # MC edit 2021-04-30
  if(dim(odat)[1] == 1 & dim(odat)[2] > 1 & length(unique(bnames)) == 1){
    odat <- t(odat)
    colnames(odat) <- bnames
  }
  # end MC edit 

  rownames(odat)<-mdat$id 
  if(ncol(odat)==0){ odat<-matrix(nrow=0,ncol=0) }


  ## impute NAs 
  isna<-which(is.na(odat),arr.ind=TRUE)    
  if(nrow(isna)>0){  
    for(k in 1:nrow(isna)){ 
      i<-isna[k,1] ; j<-isna[k,2] 

      hi<-mdat$duration[k] 
      totalj<-sum( odat[,j],na.rm=TRUE )
      totalh<-sum( mdat$duration[ !is.na(odat[,j]) ] )  
      odat[i,j]<-max(round(hi*totalj/totalh + .5) -.5,1.5) 
    }
  }
     
  ## common names
  if(commonName){ 
    colnames(odat)<-eBirdNames$COMMON_NAME[match(colnames(odat),
                    eBirdNames$SPECIES_CODE)]  
  }

list(obsData=odat,metaData=mdat)  

}
    



eBirdMergeData<-function(dat1,dat2)
{
  if(is.null(dat1)){ dat12<-dat2 } else{ 
    mdat<-rbind(dat1$metaData,dat2$metaData)
    o1<-dat1$obsData ; o2<-dat2$obsData 
    s1<-seq(1,nrow(o1),length=nrow(o1)) ; s2<-seq(1,nrow(o2),length=nrow(o2))
    cnames<-sort( unique(c(colnames(o1),colnames(o2))) )
    odat<-matrix(0,nrow=nrow(mdat),ncol=length(cnames))  
    odat[s1,match(colnames(o1),cnames)] <- o1
    odat[nrow(o1)+s2,match(colnames(o2),cnames)] <- o2
    rownames(odat)<-mdat$id
    colnames(odat)<-cnames 
    dat12<-list(obsData=odat,metaData=mdat)
  }
  dat12
}


