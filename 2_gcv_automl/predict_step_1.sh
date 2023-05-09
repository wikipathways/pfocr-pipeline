#!/usr/bin/env bash

# chmod +x predict_step_1.sh

# First download 20230401/1_images to your local machine from Dropbox

# Upload images to the google cloud storage, replace [Bucket Name] with your Bucket Name
gsutil -m cp -r 20230401/1_images gs://[Bucket Name]
