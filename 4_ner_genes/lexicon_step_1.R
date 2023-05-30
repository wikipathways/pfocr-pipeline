# Using gene_info file from NCBI by species or groups of species:
# https://ftp.ncbi.nlm.nih.gov/gene/DATA/GENE_INFO/

library(tidyverse)
library(readr)
library(stringr)
library(jsonlite)

## READ GENE_INFO.GZ FILE
# Homo_sapiens.gene_info.gz
raw <- readr::read_tsv("Homo_sapiens.gene_info.gz",na = c("", "-"))

symbols <- raw %>%
  dplyr::select(1:3,5) %>%
  dplyr::rename(tax_id=`#tax_id`) %>%
  dplyr::filter(tax_id=='9606') %>%
  dplyr::filter(!grepl("^LOC\\d{9}$", Symbol)) %>%
  dplyr::filter(!grepl("'", Symbol))%>%
  as.data.frame()

## QC SYMBOLS - visually inspect these results
# Anything odd in sorted ends of Symbol list?
sort(unique(symbols$Symbol))[1:5]
sort(unique(symbols$Symbol), decreasing = T)[1:5]

# Counts seem reasonable?
sprintf("Rows: %i", nrow(symbols))
sprintf("Unique IDs: %i", length(unique(symbols$GeneID)))
sprintf("Unique Symbols: %i", length(unique(symbols$Symbol)))

# Any odd characters that might affect later parsing?
print("Unique characters in Symbols:")
print(unique(unlist(strsplit(symbols$Symbol, ""))))

## PROCESS SYNONYMS
synonyms <- symbols %>%
  tidyr::separate_rows(Synonyms, sep = "\\|") %>%
  dplyr::filter(!grepl("^LOC\\d{9}$", Synonyms)) %>%
  dplyr::filter(!grepl("'|,|;| ", Synonyms))%>%
  tidyr::drop_na() %>%
  as.data.frame()

## QC SYNONYMS - visually inspect these results
# Anything odd in sorted ends of Symbol list?
sort(unique(synonyms$Synonyms))[1:5]
sort(unique(synonyms$Synonyms), decreasing = T)[1:5]

# Counts seem reasonable?
sprintf("Rows: %i", nrow(synonyms))
sprintf("Unique IDs: %i", length(unique(synonyms$GeneID)))
sprintf("Unique Symbols: %i", length(unique(synonyms$Symbol)))
sprintf("Unique Synonyms: %i", length(unique(synonyms$Synonyms)))

# Any odd characters that might affect later parsing?
print("Unique characters in Symbols:")
print(unique(unlist(strsplit(synonyms$Synonyms, ""))))

## PREPARE BIOENTITIES
# FamPlex
url <- "https://github.com/wikipathways/famplex/raw/master/relations.csv"
famplex <- as.data.frame(readr::read_csv(url, col_names = F))
colnames(famplex) <- c("typeA","symA","rel","typeB","symB")
# separate
famplex.dict <- dplyr::filter(famplex, typeA=="FPLX")
famplex <- dplyr::filter(famplex, typeA!="FPLX")  
# rejoin, replace and append, repeatedly
row.count <- nrow (famplex)
na.count <- nrow(filter(famplex, is.na(symB)))
famplex.append <- famplex
while (na.count < row.count) {
  famplex.append <- left_join(famplex.append, famplex.dict, by = c("symB" = "symA"),
                     relationship = "many-to-many")
  row.count <- nrow (famplex.append)
  na.count <- nrow(filter(famplex.append, is.na(symB.y)))
  print(sprintf("%i : %i", row.count, na.count))
  famplex.append <- famplex.append %>%
    mutate(symB = if_else(!is.na(symB.y), symB.y, symB)) %>%
    select(1:5) %>%
    drop_na()
  colnames(famplex.append) <- names(famplex)
  famplex<-rbind(famplex, famplex.append)
  famplex<-distinct(famplex)
}

# Duplicate and strip "_family" and "_complex" entries
famplex_dup <- famplex %>%
  filter(str_detect(symB, "_family$|_complex$"))
famplex_dup <- famplex_dup %>%
  mutate(symB = str_replace(symB, "_family$|_complex$", ""))
famplex <- bind_rows(famplex, famplex_dup)
famplex<-distinct(famplex)

# Add NCBIGENE IDs
# Which HGNC symbols are NOT found among ncbigene_symbols?
# These will be excluded, so it shouldn't be too many.
# Check these cases for outdated HGNC symbols.
setdiff(unique(famplex$symA), unique(symbols$Symbol))

famplex.id <- left_join(famplex, symbols[,2:3], by = c("symA" = "Symbol"),
                        relationship = "many-to-many")

## QC - BIOENTITIES
# Anything odd in sorted ends of Symbol list?
sort(unique(famplex$symB))[1:5]
sort(unique(famplex$symB), decreasing = T)[1:5]

# Counts seem reasonable?
sprintf("Rows: %i", nrow(famplex))
sprintf("Unique hgnc_symbols: %i", length(unique(famplex$symA)))
sprintf("Unique symbols: %i", length(unique(famplex$symB)))

# Any odd characters that might affect later parsing?
print("Unique characters in symbols:")
print(unique(unlist(strsplit(famplex$symB, ""))))

################################################################################

## CONSTRUCT LEXICON
# Include all synonyms, allowing multiple hits for a given symbol
lex.symbols <- symbols %>%
  dplyr::select("GeneID","Symbol") %>%
  dplyr::rename(ncbigene_id = GeneID) %>%
  dplyr::mutate(hgnc_symbol = Symbol) %>%
  dplyr::rename(symbol = Symbol) %>%
  dplyr::mutate(source = "hgnc_symbol")

lex.synonyms <- synonyms %>%
  dplyr::select("GeneID","Symbol","Synonyms") %>%
  dplyr::rename(ncbigene_id = GeneID) %>%
  dplyr::rename(hgnc_symbol = Symbol) %>%
  dplyr::rename(symbol = Synonyms) %>%
  dplyr::mutate(source = "hgnc_alias_symbol")

lex.famplex <- famplex.id %>%
  dplyr::select("GeneID","symB","symA") %>%
  dplyr::rename(ncbigene_id = GeneID) %>%
  dplyr::rename(hgnc_symbol = symA) %>%
  dplyr::rename(symbol = symB) %>%
  dplyr::mutate(source = "bioentities_symbol")
  
lexicon <- rbind(lex.symbols,lex.synonyms,lex.famplex)

jsonlite::write_json(lexicon, "lexicon2023.json",
                     pretty = T)
