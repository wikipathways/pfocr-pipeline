## Examine and clean up figure titles

## Read in PFOCR analysis set
pfocr.df <- readRDS("~/Dropbox (Gladstone)/PFOCR_25Years/exports/pfocr_figures_original.rds") 


## Read in curated set of title, a subset of original, to generate preamble examples
pfocr.cur.df <- readRDS("~/Dropbox (Gladstone)/PFOCR_25Years/titles/pfocr_curated.rds")

## Read in latest pre-processed rds
pfocr.figs.df <- readRDS("~/Dropbox (Gladstone)/Pathway Figure OCR/20210515/pfocr_figures_20210515_unmerged_pp.rds") 
# pfocr.figs.ar.df <- readRDS("~/Dropbox (Gladstone)/Pathway Figure OCR/20210515/pfocr_figures_20210515_unprocessed.rds") ##not sure what this is

# ## Prep figid lists
# fig.list <- unlist(unname(as.list(pfocr.df[,1])))  ##should this be updated to latest rds?
# fig.list.done <- pfocr.cur.df[,1, drop=TRUE]
# todo<-base::setdiff(fig.list, fig.list.done)
# done<-base::intersect(fig.list, fig.list.done)

## Prep preambles
df.cur <- pfocr.cur.df
df.ori <- as.data.frame(pfocr.df %>%
                          filter(figid %in% df.cur$figid))
df.diff <- merge(df.ori, df.cur, by="figid")
df.diff <- droplevels(df.diff)
sub_v <- Vectorize(sub, c("pattern", "x"))
df.diff <- df.diff %>%
  mutate(diff = unname(sub_v(tolower(gsub("[\\[\\]]","",figtitle.y, perl=T)), "XXXXXX", tolower(gsub("[\\[\\]]","",figtitle.x, perl=T))))) %>%
  tidyr::separate(diff, c("diff.pre","diff.suf"),"XXXXXX", remove = F, fill="right") %>%
  mutate(diff.pre = ifelse(diff.pre == diff|diff.pre == "", NA, diff.pre))
pre.20 <- names(sort(table(df.diff$diff.pre),decreasing = T)[1:40])
pre.20 <- pre.20[order(nchar(pre.20), pre.20, decreasing = T)]

## Replace all NA and <10 or >250 titles
## Work with a smaller data frame
pfocr.curating.df <- pfocr.figs.df %>%
  dplyr::mutate(figtitle = ifelse(is.na(figtitle) | nchar(as.character(figtitle))<10 | nchar(as.character(figtitle))>250 ,
                                  as.character(papertitle), as.character(figtitle))) %>%
  dplyr::select(figid, figtitle) %>%
  as.data.frame()

## Ungreek titles and remove periods
pfocr.curating.df <- pfocr.curating.df %>%
  dplyr::mutate(figtitle = ungreekText(figtitle)) %>%
  dplyr::mutate(figtitle = removePeriod(figtitle)) %>%
  as.data.frame()

## Remove preambles
pfocr.curating.df <- pfocr.curating.df %>%
  rowwise() %>%
  dplyr::mutate(figtitle = removePreamble(figtitle)) %>%
  as.data.frame()

## Label exclusions
pfocr.curating.df <- pfocr.curating.df %>%
  rowwise() %>%
  dplyr::mutate(plant = checkPlant(figtitle)) %>%
  dplyr::mutate(latin = checkLatinOrg(figtitle)) %>%
  as.data.frame()

##############################################################################
## Combine back with the full data frame

df.merge <- merge(pfocr.figs.df, pfocr.curating.df, by="figid")
df.merge <- df.merge %>%
  dplyr::rename(figtitle = figtitle.y) %>%
  dplyr::select(-"figtitle.x")

## Not sure we need to write this out here
saveRDS(df.merge, "pfocr_figures_20210515_curating.rds")
#df.merge <- readRDS("pfocr_figures_20210515_curating.rds")

##########################################################
# QC Checks
df.merge.2 <- df.merge

#Check for missing titles
df.merge.2 %>% filter(is.na(figtitle)) %>% nrow() ##should be zero
df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250) %>% nrow()  ##should be zero
df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10) %>% nrow()  ##should be zero

#Check for (A) at start of title
df.merge.2 %>% filter(grepl("^\\(A\\)",figtitle)) %>% dplyr::select(figid,figtitle) 

##Create data frames for problem titles for easy access
shorttitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10)
longtitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250)

#Manual curation of titles that are > 250 or < 10. 
#For each listed in "shorttitles" and "longtitles", run each separately by manually editing the existing figtitle as the "newfigtitle", and add the relevant figid as "fixfigid". 
newfigtitle <- "Protective effects of sirtuin 3 on titanium particle-induced osteogenic inhibition by regulating the NLRP3 inflammasome via the GSK-3β/β-catenin signalling pathway."
fixfigid <- "PMC8005659__sc1.jpg"
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(figtitle = ifelse(figid == fixfigid , newfigtitle, figtitle))

df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250) %>% nrow() ##should be one less than last time
longtitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250)

#df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10) %>% nrow()  ##should be one less than last time
#shorttitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10)

##QC Checks to see that dplyr didn't mess something up
#df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250) %>% nrow() ##should be zero
#df.merge.2 %>% filter(figid == fixfigid)

#Check for [,] artifacts at end of title
df.merge.2 %>% filter(grepl("\\[.{0,1}\\]",figtitle)) %>% dplyr::select(figid,figtitle) 

# If the checks are not zero, then adapt stripArtifacts function to fix the new cases. Iterate with next chunk:
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(figtitle = stripArtifacts(figtitle)) %>%
  as.data.frame()

##########################################################

####### Updated: This is to reconcile organism, latin and plant columns and to merge new content with original content

##First step: Fill in "Homo sapiens" for any missing in "latin"
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(latin = ifelse(is.na(latin) , as.character("Homo sapiens"), as.character(latin)))

##Second step: Overwrite "Homo sapiens" with "plant" if available, rename "latin" to "organism"                                                        
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(latin = ifelse(!is.na(plant) , as.character(plant), as.character(latin))) %>%
  rename(organism = latin) %>%
  dplyr::select(-"plant", -"paper_url")


##Write final rds
saveRDS(df.merge.2, "pfocr_figures_20210515_final.rds") 
#df.merge.2 <- readRDS("pfocr_figures_20210515_final.rds")
#############################################################################
###############
## FUNCTIONS ##
###############
stripArtifacts <- function(cur.title){
  new.title <- sub("^\\(A\\)","", cur.title, ignore.case = T)
  new.title <- sub("\\[.{0,1}\\]","", new.title, ignore.case = T)
  return(new.title)
}

ungreekText <- function(input.text){
  ungreek.text <- input.text
  ungreek.text <- gsub("α-", "Alpha-", ungreek.text)
  ungreek.text <- gsub("β-", "Beta-", ungreek.text)
  ungreek.text <- gsub("γ-", "Gamma-", ungreek.text)
  ungreek.text <- gsub("Ω-", "Omega-", ungreek.text)
  ungreek.text <- gsub("ω-", "omega-", ungreek.text)
  ungreek.text <- gsub("(-)?α", "A", ungreek.text)
  ungreek.text <- gsub("(-)?β", "B", ungreek.text)
  ungreek.text <- gsub("(-)?γ", "G", ungreek.text)
  ungreek.text <- gsub("(-)?δ", "D", ungreek.text)
  ungreek.text <- gsub("(-)?ε", "E", ungreek.text) #latin
  ungreek.text <- gsub("(-)?ϵ", "E", ungreek.text )#greek
  ungreek.text <- gsub("(-)?κ", "K", ungreek.text)
  return(ungreek.text)
}

removePreamble <- function(cur.title){
  # cur.title <- as.character(cur.title)
  new.title.list <- sapply(pre.20, function(x){
    sub(paste0("^",x),"", cur.title, ignore.case = T)
  })
  new.title.list <- new.title.list[order(nchar(new.title.list), new.title.list, decreasing = F)]
  new.title <- unname(new.title.list[1])

  if (!nchar(new.title) < nchar(cur.title)){
    new.title <- cur.title
  } else {
    ## capitalize first characters
    substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
  }
  return(new.title)
}

## CAREFUL. THIS ONE TAKES BIG BITES.
removePhrases<-function(cur.title){
  pattern <- "^(.*\\s(of|by|between)\\s((the|which)\\s)?)"
  if (grepl(pattern, cur.title)){
    new.title <- gsub(pattern, "", cur.title)
    substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
  } else {
    new.title <- cur.title
  }
  return(new.title)
}

removePeriod <- function(cur.title){
  return(sub("\\.$", "", cur.title))
}

checkXXXPathway <- function(cur.title){
  pattern <- "^.*?\\s*?([A-Za-z0-9_/-]+\\s([Ss]ignaling\\s)*pathway).*$"
  if (grepl(pattern, cur.title)){
    new.title <- gsub(pattern, "\\1", cur.title)
    substr(new.title, 1, 1) <- toupper(substr(new.title, 1, 1))
    return(new.title)
  } else {
    return(NA)
  }
}

checkLatinOrg <- function(cur.title){
  pattern <- "\\b[A-Z]\\.\\s[A-Za-z]+\\b"  #E. coli
  res <- str_extract(cur.title, pattern)
  if(!is.na(res))
    return(res)
  else 
    return(NA)
}

checkPlant <- function(cur.title){
  pattern <- "\\bplant\\b"  
  res <- str_extract(cur.title, pattern)
  if(!is.na(res))
    return(res)
  else 
    return(NA)
}


