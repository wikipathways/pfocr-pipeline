## Merges new PFOCR chemicals and diseases results with prior results

## UPDATE SCRIPT TO NEW BATCH DATE
# Find/replace: 20210515

## SET WORKING DIR to source file location after copying into new batch folder
## e.g., Dropbox (Gladstone)/Pathway Figure OCR/20210515

library(dplyr)
library(stringr)

## Read in new rds' for chemicals and diseases
chemicals_new <- readRDS("pfocr_chemicals_20210515.rds")
diseases_new <- readRDS("pfocr_diseases_20210515.rds")

# double-check data values in all columns for new entries
tail(chemicals_new,40) # look for <NA> in pfocr_id, identifier and word
tail(diseases_new,40) # look for <NA> in pfocr_id, identifier and word

## Make sure there are no dups
chemicals_new_unique <- unique(chemicals_new)
diseases_new_unique <- unique(diseases_new)

## Read in old chemicals and diseases rds
chemicals_old <- readRDS("~/Dropbox (Gladstone)/Pathway Figure OCR/LATEST/pfocr_chemicals.rds")
diseases_old <- readRDS("~/Dropbox (Gladstone)/Pathway Figure OCR/LATEST/pfocr_disease.rds")

## Check for overlap. If non-zero, then old data has to be trimmed of the data corresponding to overlapping figids before rbind
disease_overlap <- intersect(diseases_new_unique$pfocr_id, diseases_old$figid)
chem_overlap <- intersect(chemicals_new_unique$pfocr_id, chemicals_old$figure_id)

#######################
## Pre-processing of data frames for rbind
## Split data source and identifier into two new columns for new data
chemicals_new_unique[c('datasource', 'id')] <- str_split_fixed(chemicals_new_unique$identifier, ':', 2)
chemicals_new_unique <- subset(chemicals_new_unique, select = -c(identifier))
diseases_new_unique[c('datasource', 'id')] <- str_split_fixed(diseases_new_unique$identifier, ':', 2)
diseases_new_unique <- subset(diseases_new_unique, select = -c(identifier))

## New data: Rename columns
chemicals_new_unique_pp <- chemicals_new_unique %>%
  dplyr::rename(figid = pfocr_id) %>%
  dplyr::rename(identifier = id) %>%
  dplyr::rename(source = datasource)

diseases_new_unique_pp <- diseases_new_unique %>%
  dplyr::rename(figid = pfocr_id) %>%
  dplyr::rename(identifier = id) %>%
  dplyr::rename(source = datasource)

## Old data: Rename and delete columns
chemicals_old_pp <- chemicals_old %>%
  dplyr::rename(word = matched_ocr_text)
chemicals_old_pp <- subset(chemicals_old_pp, select = -c(lexicon_alias, lexicon_term, lexicon_term_source, annotations, figure_nobe_count, figure_entrez_count))

diseases_old_pp <- diseases_old %>%
  dplyr::rename(word = term) 
diseases_old_pp$word <- as.character(diseases_old_pp$word)  
diseases_old_pp[,"source"] <- NA
diseases_old_pp[,"identifier"] <- NA

## Old data: Remove figures and corresponding data that are overlapping with new data, since we only want the new data for those
chemicals_old_pp_trim <- chemicals_old_pp[!chemicals_old_pp$figid %in% chem_overlap, ]
diseases_old_pp_trim <- diseases_old_pp[!diseases_old_pp$figid %in% disease_overlap, ]

#######################

## Concatenate old and new
pfocr.chemicals.final.merged.df <- rbind(chemicals_old_pp_trim, chemicals_new_unique_pp)
pfocr.diseases.final.merged.df <- rbind(diseases_old_pp_trim, diseases_new_unique_pp)

## Save RDS
saveRDS(pfocr.chemicals.final.merged.df, "pfocr_chemicals_draft.rds")
saveRDS(pfocr.diseases.final.merged.df, "pfocr_diseases_draft.rds")
