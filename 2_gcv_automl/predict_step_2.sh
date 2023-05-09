#!/usr/bin/env bash

# chmod +x predict_step_2.sh

# Get images urls in the bucket
 gsutil ls -r gs://[Bucket Name]/1_images > predict_images.csv

# Put this csv back to the bucket
gsutil -m cp -r predict_images.csv gs://[Bucket Name]
