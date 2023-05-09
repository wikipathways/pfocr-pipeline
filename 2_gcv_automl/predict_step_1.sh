#!/usr/bin/env bash

# chmod +x step_1.sh

# First download automl_train_15k_20200224 to your local machine from Dropbox

# Upload images to the google cloud storage, replace [Bucket Name] with your Bucket Name
gsutil -m cp -r 20230401/1_images gs://[Bucket Name]
