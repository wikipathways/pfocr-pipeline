## Using enrichment analysis to annotate PFOCR gene sets
#  with Jensen Disease.

## SET WD to source file dir

## Libraries
load.libs <- c(
  "DOSE",
  "GO.db",
  "GSEABase",
  "org.Hs.eg.db", ## Human-specific
  "clusterProfiler",
  "plyr", 
  "dplyr",
  "tidyr",
  "magrittr",
  "stringr",
  "rWikiPathways")
options(install.packages.check.source = "no")
options(install.packages.compile.from.source = "never")
if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(load.libs, update = TRUE, character.only = TRUE)
status <- sapply(load.libs,require,character.only = TRUE)
if(all(status)){
  print("SUCCESS: You have successfully installed and loaded all required libraries.")
} else{
  cat("ERROR: One or more libraries failed to install correctly. Check the following list for FALSE cases and try again...\n\n")
  status
}

####################
## Collect gene sets
####################


## Process Jensen disease file to gmt and save
download.file("https://download.jensenlab.org/human_disease_knowledge_filtered.tsv",
              "human_disease_knowledge_filtered.tsv")
jensen_know <- read.csv("./human_disease_knowledge_filtered.tsv", sep="\t", stringsAsFactors = F)[ ,c(2,4)]
colnames(jensen_know) <- c("symbol", "disease")
jensen_know2 <- jensen_know %>%
  dplyr::group_by(disease) %>%
  dplyr::filter(n() > 7) %>%
  dplyr::summarise(symbol_all = paste(symbol,collapse="\t"))
write.table(jensen_know2, file = "./jensen_know.gmt", append = FALSE, quote = FALSE, sep = "\t",
           na = "NA", dec = ".", row.names = FALSE,
            col.names = FALSE)

## Prepare list of gene sets from JENSEN GMTs 
gmt.file <- "jensen_know.gmt"
gmt <- clusterProfiler::read.gmt(gmt.file)
gmt.entrez <- bitr(gmt$gene,fromType = "SYMBOL",toType = "ENTREZID",OrgDb = org.Hs.eg.db)
gmt <-gmt %>%
  dplyr::left_join(gmt.entrez, by=c("gene" = "SYMBOL")) %>%
  dplyr::filter(!is.na(ENTREZID)) %>%
  dplyr::select(term, ENTREZID)
gmt.lists <- gmt %>% group_by(term) %>%
  dplyr::summarize(cnt = n(),
                   genes = list(ENTREZID))
gmt.all.genes <- unique(gmt$ENTREZID)

## also make TERM2GENE object
jensen2gene <- gmt 

####################
## Prepare PFOCR GMT
####################

## Read GMT of PFOCR to serve as enrichment database
pfocr.gmt.file <- "../pfocr_genes_hgnc3_draft.gmt"
pfocr.gmt <- clusterProfiler::read.gmt(pfocr.gmt.file)
pfocr2gene<-pfocr.gmt
pfocr2name<- rWikiPathways::readGMTnames(pfocr.gmt.file)

## Also make gene list
pfocr.lists <- pfocr.gmt %>% group_by(term) %>%
  dplyr::summarize(cnt = n(),
                   genes = list(gene))
pfocr.all.genes <- unique(as.character(pfocr.gmt$gene))

#####################
## Perform Enrichment
#####################
### gene sets against PFOCR

# Apply to each gene set in list  
# Note: takes 2 minutes to complete
gmt.pfocr.overlaps <- plyr::ldply(gmt.lists$term, function(t){
  
  gmt.term.genes <- gmt %>%
    dplyr::filter(term == t) %>%
    dplyr::select(ENTREZID)
  
  ## PFOCR Analysis
  ewp <- clusterProfiler::enricher(
    gene = gmt.term.genes$ENTREZID,
    universe = gmt.all.genes,
    pAdjustMethod = "fdr",
    pvalueCutoff = 0.05, #p.adjust cutoff
    minGSSize = 2,
    maxGSSize = 500,
    TERM2GENE = pfocr2gene,
    TERM2NAME = pfocr2name)
  #ewp <- DOSE::setReadable(ewp, org.Hs.eg.db, keyType = "ENTREZID")
  #head(ewp, 20)
  
  ## stash results
  if (!is.null(ewp)){
    res <- ewp@result %>%
      dplyr::filter(p.adjust < 0.05)
    if (nrow(res) > 0){
      res <- res %>%
        mutate (term = t,
                cnt = gmt.lists$cnt[which(gmt.lists$term == t)],
                genes = paste(unlist(gmt.lists$genes[which(gmt.lists$term == t)]), collapse = ", "),
                figid = ID,
                pf.overlap.cnt = Count,
                pf.overlap.genes = str_replace_all(geneID, "/",", ")
        ) %>%
        dplyr::select(term, cnt, genes, figid, pf.overlap.cnt, pf.overlap.genes)
    }
  }
})

# saveRDS(gmt.pfocr.overlaps, "raw/gmt-pfocr-overlaps.RDS")
# gmt.pfocr.overlaps <- readRDS("raw/gmt-pfocr-overlaps.RDS")

## Basic counts
gmt.pfocr.overlaps.genes <- gmt.pfocr.overlaps %>% 
  dplyr::select(1,6) %>% 
  mutate(genes = strsplit(pf.overlap.genes, ",", fixed = T)) %>% 
  unnest(genes) %>% 
  dplyr::select(c(1,3))
sprintf("Unique figures with hits: %i/%i (%.0f%%)",
        length(unique(gmt.pfocr.overlaps$figid)),
        length(unique(pfocr2name$term)),
        length(unique(gmt.pfocr.overlaps$figid))/length(unique(pfocr2name$term))*100)
sprintf("Unique enriched disease genes: %i/%i (%.0f%%)",
        length(unique(gmt.pfocr.overlaps.genes$genes)),
        length(unique(jensen2gene$ENTREZID)),
        length(unique(gmt.pfocr.overlaps.genes$genes))/length(unique(jensen2gene$ENTREZID))*100)
sprintf("Unique enriched disease terms: %i/%i (%.0f%%)",
        length(unique(gmt.pfocr.overlaps$term)),
        length(unique(jensen2gene$term)),
        length(unique(gmt.pfocr.overlaps$term))/length(unique(jensen2gene$term))*100)

## hgnc3-jensenknow7:
# "Unique figures with hits: 21908/35485 (62%)"
# "Unique enriched disease genes: 2796/3110 (90%)"
# "Unique enriched disease terms: 165/168 (98%)"

## Filter for n+ hits
gmt.pfocr.overlaps.n <- filter(gmt.pfocr.overlaps, pf.overlap.cnt >= 3)

## COUNTS
total.figids <- length(unique(gmt.pfocr.overlaps.n$figid))
total.terms <- length(unique(gmt.pfocr.overlaps.n$term))
ont.terms <- gmt.pfocr.overlaps.n %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
figs <- gmt.pfocr.overlaps.n %>% dplyr::group_by(figid) %>% dplyr::summarise(count=n())
sprintf("Unique figures with n+ hits: %i/%i (%.0f%%)",
        total.figids,
        nrow(pfocr2name),
        total.figids/nrow(pfocr2name)*100)
sprintf("Unique enriched disease terms: %i/%i (%.0f%%)",
        total.terms,
        nrow(gmt.lists),
        total.terms/nrow(gmt.lists)*100)
sprintf("Average pathway hits per term: %f",mean(ont.terms$count))
sprintf("Average disease terms per figure: %f",mean(figs$count))

# n=3 
# "Unique figures with n+ hits: 4955/35485 (14%)"
# "Unique enriched disease terms: 149/168 (89%)"
# "Average pathway hits per term: 59.342282"
# "Average disease terms per figure: 1.784460"

#########################
## TOP TEN DISEASE
# with exclusion to reduce redundancy
# with n+ hits
#########################

gmt.pf.temp <- gmt.pfocr.overlaps.n
for(i in 1:10){
  dis <- gmt.pf.temp %>% dplyr::group_by(term) %>% dplyr::summarise(count=n())
  dis.arr <- arrange(dis, desc(count))
  top.term <- dis.arr$term[1]
  top.term.figids <- dis.arr$count[1]
  print(sprintf("#%i. %s %i (%.0f%%)",i, top.term, top.term.figids, top.term.figids/total.figids*100))
  rm.figs <- gmt.pf.temp %>% filter(term == top.term)
  gmt.pf.temp <- gmt.pf.temp %>% filter(!figid %in% rm.figs$figid)
}

other.figids <- length(unique(gmt.pf.temp$figid))
sprintf("#%i. %s %i (%.0f%%)",11, "Other", other.figids, other.figids/total.figids*100)

# know7_hgnc3_n=3:
#
# [1] "#1. Cancer 2077 (42%)"
# [1] "#2. Epilepsy 304 (6%)"
# [1] "#3. Rheumatoid arthritis 304 (6%)"
# [1] "#4. Cholangiocarcinoma 269 (5%)"
# [1] "#5. Breast cancer 197 (4%)"
# [1] "#6. Urinary bladder cancer 147 (3%)"
# [1] "#7. Alopecia areata 137 (3%)"
# [1] "#8. Diabetes mellitus 105 (2%)"
# [1] "#9. Aortic aneurysm 96 (2%)"
# [1] "#10. Age related macular degeneration 90 (2%)"
# [1] "#11. Other 1229 (25%)"

gmt.pfocr.overlaps.n <- dplyr::select(gmt.pfocr.overlaps.n, c("figid","term"))
names(gmt.pfocr.overlaps.n) <- c("figid","jensenknow7")
saveRDS(gmt.pfocr.overlaps.n, "../pfocr_annots_draft.rds")
