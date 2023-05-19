#!/usr/bin/env bash

# When the OCR is done, the results will be stored in the bucket.
# Download all json files to Dropbox.
gsutil -m cp \
  -r gs://[Output Bucket Name]/ \
  /Users/aagrawal/Dropbox\ \(Gladstone\)/pfocr-pipeline/20230401/3_gcv_ocr/

# Delete the input and output buckets
gsutil -m rm -r gs://[Input Bucket Name]
gsutil -m rm -r gs://[Output Bucket Name]
