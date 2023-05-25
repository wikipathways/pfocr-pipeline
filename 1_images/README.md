# Step 1. Images

The [PFOCR PMC Figure Bot](https://github.com/wikipathways/pfocr-pmcfigurebot) collects images and metadata as paired jgp and yml files monthly. These can be collected into a single Dropbox folder (e.g., under pfocr-pipeline) for future processing.

### Next step

Pathway classification by machine learning is performed on collected images in order to predict the liklihood that a given image is actually a pathway diagram. This can reuse the manual classification data collected in February of 2020 (see automl_train_model_20200224.csv).