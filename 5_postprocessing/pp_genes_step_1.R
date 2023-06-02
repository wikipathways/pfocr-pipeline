## Merges new PFOCR gene results with prior results

## UPDATE SCRIPT TO NEW BATCH DATE
# Find/replace: 20210515

## SET WORKING DIR to source file location after copying into new batch folder
## e.g., Dropbox (Gladstone)/Pathway Figure OCR/20210515


## Read in new genes rds
genes_new <- readRDS("../pfocr_genes_20210515.rds")

# double-check data values in all 8 columns for new entries
tail(genes_new,40) # look for <NA> in pmc_id, lexicon_term_source and hgnc_symbol
# if missing data, refer to pfocr_id and lexicon json file to generate values
genes_prior <- filter(genes_new, pfocr_year != "2021")
genes_latest <- filter(genes_new, pfocr_year == "2021")
lex <- jsonlite::read_json("../lexicon2020.json")
lex <- data.frame(ncbigene_id = unname(unlist(lex$ncbigene_id)),
                  lexicon_term_source = unname(unlist(lex$source)), 
                  lexicon_term = unname(unlist(lex$symbol)))
lex.be <- lex %>%
  dplyr::filter(lexicon_term_source == "bioentities_symbol") %>%
  dplyr::group_by(lexicon_term) %>%
  dplyr::summarise(ncbigene_id = paste(unique(ncbigene_id),collapse = ","),
                   lexicon_term_source = "bioentities_symbol")
lex.be <- rbind(lex.be, dplyr::filter(lex,lexicon_term_source != "bioentities_symbol"))

genes_latest_mapped <- as.data.frame(genes_latest %>%
                       dplyr::select(-c(lexicon_term_source, hgnc_symbol,ncbigene_id)) %>%
                       left_join(lex.be.1, by = "lexicon_term") %>% #get proper ncbigene_ids and lexicon_term_source
                       separate_rows(ncbigene_id,sep=",") %>% #expand bioentity matches
                       rowwise() %>%
                       mutate(pmc_id = str_split(pfocr_id, "__")[[1]][1]) #get pmc_id
)

lex.hgnc <- lex %>%
  dplyr::rename(hgnc_symbol = lexicon_term) %>%
  dplyr::filter(lexicon_term_source == "hgnc_symbol") %>%
  dplyr::select(-lexicon_term_source)

genes_latest_mapped <- genes_latest_mapped %>%
  left_join(lex.hgnc, by="ncbigene_id") #get hgnc_symbols
  
genes_new2 <- rbind(genes_prior,genes_latest_mapped)

  
## Read in old genes rds
genes_old <- readRDS("~/Dropbox (Gladstone)/PFOCR_25Years/pfocr_genes.rds")

## Restore original column names (if needed)
genes_new_final <- genes_new2 %>%
  select(-pfocr_year) 

names(genes_new_final) <- names(genes_old)
saveRDS(genes_new_final, "../pfocr_genes_draft.rds")
