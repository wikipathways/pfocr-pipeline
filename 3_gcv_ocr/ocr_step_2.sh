#!/usr/bin/env bash

# chmod +x ocr_step_2.sh

# When the OCR is done, the results will be stored in the bucket.
# Download all json files to Dropbox
# replace [Output Bucket Name] with your Output Bucket Name
gsutil -m cp \
  -r gs://[Output Bucket Name]/ \
  ocr_results

# Delete the input and output buckets
# replace [Input Bucket Name] and [Output Bucket Name] with your Input and Output Bucket Names
gsutil -m rm -r gs://[Input Bucket Name]
gsutil -m rm -r gs://[Output Bucket Name]

# Split the json files to create a single json file per figure result
python split_json_output.py --input_dir ocr_results --output_dir .

###### END ###### 
