#!/usr/bin/env bash

# chmod +x step_1.sh

# First download automl_train_15k_20200224 to your local machine from Dropbox

# Install gsutil from https://cloud.google.com/storage/docs/gsutil_install

# Create a bucket. Keep bucket name secret. Caution: delete bucket after training.

# Upload images to the google cloud storage, replace [Bucket Name] with your Bucket Name
gsutil -m cp -r automl_train_15k_20200224 gs://[Bucket Name]
