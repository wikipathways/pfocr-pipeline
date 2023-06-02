library(magrittr)
library(dplyr)
library(rWikiPathways)
library(homologene)

genes <- readRDS("../pfocr_genes_draft.rds")
figs <- readRDS("../pfocr_figures_draft.rds")


##################################################################
## GMT filtered as "hgnc3" ##
#############################
# Removing bioentities, previous and alias matches, then
# filtering for 3+ genes

gmt.df <- genes %>%
  dplyr::filter(source == "hgnc_symbol") %>%
  dplyr::distinct(figid,entrez) %>%
  dplyr::add_count(figid) %>%
  dplyr::filter(n >= 3) %>%
  dplyr::left_join(figs, by="figid") %>%
  dplyr::select(figid, figtitle, entrez)

# This take ~1 minutes to complete
rWikiPathways::writeGMT(gmt.df, "../pfocr_genes_hgnc3_draft.gmt")

# Homology map to mouse
hs.ent <- unique(dplyr::pull(gmt.df, entrez))
homo.df <- homologene(hs.ent, inTax = 9606, outTax = 10090)
names(homo.df) <- c("symbol","symbol.mm","entrez","entrez.mm")
homo.df$entrez <- as.character(homo.df$entrez)
homo.df$entrez.mm <- as.character(homo.df$entrez.mm)
gmt.df2 <- gmt.df %>%
  dplyr::left_join(homo.df, by = "entrez") %>%
  dplyr::filter(!is.na(entrez.mm)) %>%
  dplyr::mutate(entrez = entrez.mm) %>%
  dplyr::distinct(figid, figtitle, entrez) %>%
  dplyr::add_count(figid) %>%
  dplyr::filter(n >= 3) %>%
  dplyr::select(-c(n))
  
# This take ~1 minutes to complete
rWikiPathways::writeGMT(gmt.df2, "../pfocr_genes_hgnc3_mm_draft.gmt")


