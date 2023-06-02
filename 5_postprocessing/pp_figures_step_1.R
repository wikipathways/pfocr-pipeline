## This script prepares results output from PFOCR pipeline to be merged with previous PFOCR content.
## This includes renaming columns, adding/removing columns and formatting PMC image names for use in NDEx.

## LOAD FUNCTIONS at the end of this script. Highlight code and run.

# install.packages("tidyverse")
library(tidyverse)
library(stringr)
library(RCurl)

##############################################################################
## Read in new PFOCR output and previous PFOCR data and format new data.
##############################################################################

## Read in latest rds
pfocr_new <- readRDS(paste0("../pfocr_figures_ocr.rds"))

##Rename columns to match old rds (if needed)
pfocr_new_pp <- pfocr_new %>%
  dplyr::rename(number = figure_number) %>%
  dplyr::rename(pmcid = pmc_id) %>%
  ##dplyr::rename(pfocr_year = pfocr_year) %>% ##seems like this does nothing
  ##dplyr::rename(year = publication_year) %>%  ##publication_year was not included in the latest rds
  dplyr::rename(caption = figure_caption) %>%
  dplyr::rename(figtitle = figure_title) %>%
  dplyr::rename(reftext = reference) %>%
  dplyr::rename(papertitle = paper_title) %>%
  dplyr::rename(figlink = figure_page_url) %>%
  dplyr::rename(pmc_ranked_result_index = pmc_search_index)

##Add one new column
pfocr_new_pp[,"filename"] <- NA

## Remove unnecessary columns
pfocr_new_pp <- subset (pfocr_new_pp, select = -c(pfocr_year,figure_thumbnail_url))

##Format the data in the columns for NDEx
pfocr_new_pp <- pfocr_new_pp %>%
  dplyr::mutate(filename = removePMCPrefix(figid)) %>%
  dplyr::mutate(figlink = formatFigLink(figlink))


##############################################################################
## Examine and clean up figure titles
##############################################################################

# ## Read in original PFOCR analysis set
# pfocr.df <- readRDS("~/Dropbox (Gladstone)/PFOCR_25Years/exports/pfocr_figures_original.rds") 
#
# ## Read in curated set of title, a subset of original, to generate preamble examples
# pfocr.cur.df <- readRDS("~/Dropbox (Gladstone)/PFOCR_25Years/titles/pfocr_curated.rds")
# 
# ## Prep preambles
# df.cur <- pfocr.cur.df
# df.ori <- as.data.frame(pfocr.df %>%
#                           filter(figid %in% df.cur$figid))
# df.diff <- merge(df.ori, df.cur, by="figid")
# df.diff <- droplevels(df.diff)
# sub_v <- Vectorize(sub, c("pattern", "x"))
# df.diff <- df.diff %>%
#   mutate(diff = unname(sub_v(tolower(gsub("[\\[\\]]","",figtitle.y, perl=T)), "XXXXXX", tolower(gsub("[\\[\\]]","",figtitle.x, perl=T))))) %>%
#   tidyr::separate(diff, c("diff.pre","diff.suf"),"XXXXXX", remove = F, fill="right") %>%
#   mutate(diff.pre = ifelse(diff.pre == diff|diff.pre == "", NA, diff.pre))
# pfocr_preambles <- names(sort(table(df.diff$diff.pre),decreasing = T)[1:40])
# pfocr_preambles <- pfocr_preambles[order(nchar(pfocr_preambles), pfocr_preambles, decreasing = T)]
# save(pfocr_preambles, file="pfocr_preambles.RData")

load("~/Dropbox (Gladstone)/PFOCR_25Years/pfocr_preambles.RData")

## Replace all NA and <10 or >250 titles in latest data
## Work with a smaller data frame
pfocr.curating.df <- pfocr_new_pp %>%
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

#######################################################################
## Extract additional figure numbers and make figid_alias and figtype
######################################################################
pfocr.curating.df <- pfocr.curating.df %>%
  dplyr::mutate(number = normalizeFigNumber(number,figlink,filename)) %>%
  dplyr::mutate(figid_alias = paste(pmcid,number,sep = "__")) %>%
  as.data.frame()

dup_count <- nrow(pfocr.curating.df) - length(unique(pfocr.curating.df$figid_alias))

if (dup_count > 0){
  
  sprintf("There are %i sets of duplicates!", dup_count)
  
  # filter for duplicate cases
  duplicates.df <- pfocr.curating.df %>%
    group_by(figid_alias) %>%
    arrange(., figid_alias) %>%
    filter(n() > 1) %>%
    as.data.frame()
  
  ## FIRST, programmatically confirm the existence of these "duplicate" files. 
  ## Often, one has been removed/replaced by PMC and is not acutally available.
  ## Remove these missing figures from the database
  for(i in 1:nrow(duplicates.df)){
    url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",
                  duplicates.df[i,"pmcid"],
                  "/bin/",
                  duplicates.df[i,"filename"])
    if (!url.exists(url)) {
      message("Removing ",duplicates.df[i,"figid"])
      pfocr.curating.df <- pfocr.curating.df %>%
        filter(!grepl(paste0("^", duplicates.df[i,"figid"]), figid))
    }
  }

  ## Check for remaining duplicates
  duplicates.df <- pfocr.curating.df %>%
    group_by(figid_alias) %>%
    arrange(., figid_alias) %>%
    filter(n() > 1) %>%
    as.data.frame()
  
  if (nrow(duplicates.df) > 0){
    sprintf("There are %i sets of duplicates!", nrow(duplicates.df))
  }
}

## Only if necessary, manually check remaining duplicates and fix "number" or remove if actual duplicate or erroneous file
duplicates.df

# Case by case, check original "number" as possible source of duplicate info
pfocr_new_pp[which(pfocr_new_pp$pmcid =="PMC7158350"),]

# If actual duplicate or wrong file (e.g,. removed/replaced by PMC), then remove from PFOCR
figids.to.remove <- c("PMC4277084__rsif20140937-g2.jpg")
pfocr.curating.df <- pfocr.curating.df %>%
  filter(!grepl(paste0("^(", paste(figids.to.remove, collapse = "|"), ")"), figid))

#########################
# Final checks on number
#########################

## Manually check cases not matching a simple F\\d+ pattern for unexpected characters
head(pfocr.curating.df[grep("^F\\d+", pfocr.curating.df$number, invert = TRUE),"number"],1000)
tail(pfocr.curating.df[grep("^F\\d+", pfocr.curating.df$number, invert = TRUE),"number"],1000)

## Manually check the longest and shortest numbers for unexpected values
tail(pfocr.curating.df[order(nchar(pfocr.curating.df$number)),"number"],20)
head(pfocr.curating.df[order(nchar(pfocr.curating.df$number)),"number"],20)

# Case by case, check full record for suspicious "numbers" 
pfocr.curating.df[which(pfocr.curating.df$number =="F20140937"),]

###################################
## Add type based on figure prefix
##################################
type.list <- list(F="Figure",
                  S="Scheme",
                  SF="Supplemental figure",
                  GA="Graphical abstract",
                  AF="Appendix figure",
                  EV="Extended view")

extracted_type_names <- str_extract(pfocr.curating.df$number, "^[A-Za-z]+")
match_index <- match(extracted_type_names, names(type.list))
pfocr.curating.df$figtype <- unlist(type.list[match_index])

##############################################################################
## Combine back with the original columns from new rds (new PFOCR content)
##############################################################################

df.merge <- merge(pfocr_new_pp, pfocr.curating.df, by="figid")
df.merge <- df.merge %>%
  dplyr::rename(figtitle = figtitle.y) %>%
  dplyr::select(-"figtitle.x")

##########################################################
# QC Checks
# Step through these lines manually and iteratively
##########################################################

df.merge.2 <- df.merge

## Check for missing titles
df.merge.2 %>% filter(is.na(figtitle)) %>% nrow() ##should be zero
df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250) %>% nrow()  ##should be zero
df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10) %>% nrow()  ##should be zero

## Check for (A) at start of title
df.merge.2 %>% filter(grepl("^\\(A\\)",figtitle)) %>% dplyr::select(figid,figtitle) 

## Create data frames for problem titles for easy access
shorttitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10)
longtitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250)

## Manual curation of titles that are > 250 or < 10. 
## For each listed in "shorttitles" and "longtitles", run each separately. 
## Get the "caption" or "paper title" from the dataframe, edit it to a 
## reasonable length, then assign it as "newfigtitle". Update the "fixfigid" 
## to be the relevant figid. 
newfigtitle <- "Protective effects of sirtuin 3 on titanium particle-induced osteogenic inhibition by regulating the NLRP3 inflammasome via the GSK-3β/β-catenin signalling pathway."
fixfigid <- "PMC8005659__sc1.jpg"
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(figtitle = ifelse(figid == fixfigid , newfigtitle, figtitle))

## FIXING LONG TITLES (toggle comment to skip)
df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250) %>% nrow() ##should be one less than last time
longtitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) > 250)

## FIXING SHORT TITLES
df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10) %>% nrow()  ##should be one less than last time
shorttitles <- df.merge.2 %>% filter(nchar(as.character(figtitle)) < 10)

## Check for [,] artifacts at end of title
df.merge.2 %>% filter(grepl("\\[.{0,1}\\]",figtitle)) %>% dplyr::select(figid,figtitle) 

## Iterate with next chunk:
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(figtitle = stripArtifacts(figtitle)) %>%
  as.data.frame()

##########################################################
## Reconcile organism, latin and plant columns and to merge new content with original content
##########################################################

## First step: Fill in "Homo sapiens" for any missing in "latin"
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(latin = ifelse(is.na(latin) , as.character("Homo sapiens"), as.character(latin)))

## Second step: Overwrite "Homo sapiens" with "plant" if available, rename "latin" to "organism"                                                        
df.merge.2 <- df.merge.2 %>%
  dplyr::mutate(latin = ifelse(!is.na(plant) , as.character(plant), as.character(latin))) %>%
  rename(organism = latin) %>%
  dplyr::select(-"plant", -"paper_url")


## Write cleaned up rds of latest content
saveRDS(df.merge.2, paste0("../pfocr_figures_",batch.date,"_processed.rds"))

## Merge new data with "latest" rds 
pfocr.df <- readRDS("../../LATEST/pfocr_figures.rds")
pfocr.figures.final.merged.df <- rbind(df.merge.2, pfocr.df)

## Final QC Check
nrow(pfocr.figures.final.merged.df)
nrow(unique(pfocr.figures.final.merged.df$figid)) ## should be same number

## Share new total counts
print("Total number of figures:")
nrow(pfocr.figures.final.merged.df)
print("Total number of papers:")
length(unique(pfocr.figures.final.merged.df$pmcid))

saveRDS(pfocr.figures.final.merged.df, "../pfocr_figures_draft.rds")

#############################################################################
## FUNCTIONS ##
###############
normalizeFigNumber <- function(number, figlink, filename){
  #trash cases with decimals; they're unreliable
  number <- ifelse(grepl("\\d+\\.\\d+", number),"",number)
  #process other figure numbers extracted from PMC  
  fig_num <- ifelse(sub("\\D*(\\d+[a-zA-Z]?).*", "\\1", number) == number, 
                    NA, #if not digit; use other columns below
                    ifelse(sub(".*Scheme (\\d+[a-zA-Z]?)\\D*", "\\1", number) == number, 
                           ifelse(sub("^Figure (\\d+[a-zA-Z]?)\\D*supplement (\\d+[a-zA-Z]?)", "\\1", number) == number,  #if not scheme; check elife
                                  ifelse(sub(".*[Ss]upp\\D*(\\d+[a-zA-Z]?)\\D*", "\\1", number) == number,  #if not elife; check supplement
                                         ifelse(sub(".*S(\\d+[a-zA-Z]?)\\D*", "\\1", number) == number,  #if not supplement; check supplement type S
                                                ifelse(sub(".*A(\\d+[a-zA-Z]?)\\D*", "\\1", number) == number,  #if not supplements; check appendix
                                                       ifelse(sub(".*EV(\\d+[a-zA-Z]?)\\D*", "\\1", number) == number,  #if not appendix; check expanded view
                                                              ifelse(sub("Box|Chart (\\d+[a-zA-Z]?)", "\\1", number) == number,  #if not appendix; check box
                                                                     sub("\\D*(\\d+[a-zA-Z]?).*", "F\\1", number), #if not Box|Chart, then F+digits
                                                                     NA), #then Box|Chart; use other columns below
                                                              sub(".*EV(\\d+[a-zA-Z]?)\\D*", "EV\\1", number)), # then expanded view figure
                                                       sub(".*A(\\d+[a-zA-Z]?)\\D*", "AF\\1", number)), # then appendix figure
                                                sub(".*S(\\d+[a-zA-Z]?)\\D*", "SF\\1", number)), # then supplement type S
                                         sub(".*[Ss]upp\\D*(\\d+[a-zA-Z]?)\\D*", "SF\\1", number)), # then supplement
                                  sub("^Figure (\\d+[a-zA-Z]?)\\D*supplement (\\d+[a-zA-Z]?)", "SF\\1_\\2", number)), # then elife
                           sub(".*Scheme (\\d+[a-zA-Z]?)\\D*", "S\\1", number))) # then scheme
# if NA try filename
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub("gr(\\d+[a-zA-Z]?).*\\.jpg", "\\1", filename) == filename, 
                           NA, sub("gr(\\d+[a-zA-Z]?).*\\.jpg", "F\\1", filename)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*_?[Ff](ig)?(\\d+[a-zA-Z]?)[-_].*", "\\2", filename) == filename, 
                           NA, sub(".*_?[Ff](ig)?(\\d+[a-zA-Z]?)[-_].*", "F\\2", filename)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*0+(\\d+[a-zA-Z]?)\\.jpg", "\\1", filename) == filename, 
                           NA, sub(".*0+(\\d+[a-zA-Z]?)\\.jpg", "F\\1", filename)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), #Graphical Abstract
                    ifelse(sub(".*abs[Ff](ig)?(\\d+[a-zA-Z]?)\\.jpg", "\\2", filename) == filename, 
                           NA, sub(".*abs[Ff](ig)?(\\d+[a-zA-Z]?)\\.jpg", "GA\\2", filename)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*[Ff](ig)?(\\d+[a-zA-Z]?)\\.jpg", "\\2", filename) == filename, 
                           NA, sub(".*[Ff](ig)?(\\d+[a-zA-Z]?)\\.jpg", "F\\2", filename)), 
                    fig_num)
  # if still NA try figlink
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*/FU*(\\d+[a-zA-Z]?)/", "\\1", figlink) == figlink, 
                           NA, sub(".*/FU*(\\d+[a-zA-Z]?)/", "F\\1", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), # Scheme
                    ifelse(sub(".*/[Ss]ch(\\d+[a-zA-Z]?)/", "\\1", figlink) == figlink, 
                           NA, sub(".*/[Ss]ch(\\d+[a-zA-Z]?)/", "S\\1", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), # Scheme
                    ifelse(sub(".*/F(SI+)/", "\\1", figlink) == figlink, 
                           NA, sub(".*/F(SI+)/", "\\1", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*[Ff](\\d+)/", "\\1", figlink) == figlink, 
                           NA, sub(".*[Ff](\\d+)/", "F\\1", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*/f(ig)?(\\d+)-.+/", "\\2", figlink) == figlink, 
                           NA, sub(".*/f(ig)?(\\d+)-.+/", "F\\2", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), #Graphical Abstract
                    ifelse(sub(".*/[FG](ig)?([aA])/", "\\2", figlink) == figlink, 
                           NA, sub(".*/[FG](ig)?([aA])/", "GA", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), #Graphical Abstract
                    ifelse(sub(".*/undfig(\\d+)/", "\\1", figlink) == figlink, 
                           NA, sub(".*/undfig(\\d+)/", "GA\\1", figlink)), 
                    fig_num)
  fig_num <- ifelse(is.na(fig_num), 
                    ifelse(sub(".*[Ff]ig(ure)?(\\d+[a-zA-Z]?)/", "\\2", figlink) == figlink, 
                           NA, sub(".*[Ff]ig(ure)?(\\d+[a-zA-Z]?)/", "F\\2", figlink)), 
                    fig_num)
  # if still NA give and use "0"
  fig_num <- ifelse(is.na(fig_num), "F0", fig_num)
  
  # clean up preceding zeros
  fig_num <- ifelse(sub("(\\D+)0+(?=[1-9])", "\\2", fig_num, perl=TRUE) == fig_num,
                    fig_num,
                    sub("(\\D+)0+(?=[1-9])", "\\1\\2", fig_num, perl=TRUE))
  
  # fix roman numerials
  fig_num <- ifelse(grepl("II", fig_num),
                    gsub("II", "2", fig_num),
                    gsub("I", "1", fig_num))
    
  return(fig_num)
}

removePMCPrefix <- function(input.txt){
  return(sub("PMC\\d+__", "", input.txt))
}

formatFigLink <- function(input.txt){
  return(sub("^https://www\\.ncbi\\.nlm\\.nih\\.gov/", "", input.txt))
}

stripArtifacts <- function(cur.title){
  new.title <- sub("^\\(A\\)","", cur.title, ignore.case = T)
  new.title <- sub("\\[.{0,1}\\]","", new.title, ignore.case = T) #TODO: try gsub
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
  #cur.title <- as.character(cur.title)
  new.title.list <- sapply(pfocr_preambles, function(x){
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

extractYear <- function(reftext){
  str_match(reftext, ".*[,\\. ][; ]([0-9]{4})[ ;:].+")[,2]
}

