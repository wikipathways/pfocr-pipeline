# Make files for Shiny app

# "genes" and "annots" files are ready to go

# "table" is a renamed subset of "figures", plus authors from reftext
# tbl <- readRDS("~/git/wikipathways/pathway-figure-ocr/shiny-25years/pfocr_table.rds")
figs <- readRDS("../pfocr_figures_draft.rds")
tbl2 <- dplyr::select(figs, c('figid','pmcid','papertitle','reftext','year','number','figtitle','figlink'))
tbl2 <- tbl2 %>%
  dplyr::rename(paper.title = papertitle) %>%
  dplyr::rename(figure.title = figtitle) %>%
  dplyr::rename(figure.link = figlink) %>%
  dplyr::rename(first.author = reftext) %>%
  rowwise() %>%
  dplyr::mutate(first.author = str_split(first.author,"\\.")[[1]][1]) 
  

saveRDS(tbl2, "../pfocr_table_draft.rds")

# "years" is just 2 col and NAs removed
# yrs <- readRDS("~/git/wikipathways/pathway-figure-ocr/shiny-25years/pfocr_years.rds")
yrs2 <- figs %>%
  dplyr::select(c(figid,year)) %>%
  na.omit()
saveRDS(yrs2, "../pfocr_years_draft.rds")
