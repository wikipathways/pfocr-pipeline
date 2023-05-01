#!/usr/bin/env bash

# First download automl_train_15k_20200224 to your local machine from Dropbox

# Install gsutil from https://cloud.google.com/storage/docs/gsutil_install

# Upload images to the google cloud storage, replace [Bucket Name] with your Bucket Name
gsutil -m cp -r automl_train_15k_20200224 gs://[Bucket Name]

# Download all gsutil URI from Bucket as csv file
gsutil ls -r gs://[Bucket Name] > gsutil_url.csv
