Generate GMTs
  - Run pfocr_gmt.R
  - Produce "filtered" gmt with hgnc3 subset for human and mouse.

Generate annots from Jensen enrichment
  - Run pforc_enrich.R
  - Uses gmt from prior step
  - check printed stats along the way. Certainly room for improvement here.
  - Produce pfocr_annots_draft.rds
  
Update ShinyApps.io
  - Run pfocr_shiny.R
  - Uses genes, figures, and annots from prior steps
  - Copy draft rds over to shiny app dir and rename (remove _draft)
  - Test app and publish to shinyapps.io

Push to NDEx
  - TODO

Publish on Figshare?
  - TODO
