#!/usr/bin/env bash

# chmod +x ocr_step_1.sh

# First download 1_images to your local machine from Dropbox

# Install gsutil from https://cloud.google.com/storage/docs/gsutil_install

# Create buckets for input. Keep bucket name secret. 
gsutil mb gs://[Input Bucket Name]

# Create buckets for output. Keep bucket name secret. 
gsutil mb gs://[Output Bucket Name]

# Upload images to the google cloud storage input bucket, replace [Input Bucket Name] with your Input Bucket Name
cd ../1_images/
gsutil -m cp -r "*.jpg" gs://[Input Bucket Name]

# Go the folder where the scripts are
cd ../3_gcv_ocr/ 

# Get images urls in the bucket
gsutil ls -r gs://[Input Bucket Name]/ > ocr_images.csv

# images:asyncBatchAnnotate request allows up to 2000 images per request 
# Each request is processed in batches of 100
# Use py script to convert gs url csv file to json files 
# Each json file has 2000 images
chmod +x prep_json_input.py
python prep_json_input.py

# Specify the folder path where the json files are located
folder_path="ocr_images_json"

# Find all json files in the folder
json_files=$(find "$folder_path" -type f -name "*.json")

# Go to folder with the json files
cd $folder_path

# Loop through each json file and run OCR on each file
for file in $json_files; do
    filename=$(basename "$file")
    echo "Processing file: $filename"
    curl -X POST \
		-H "Authorization: Bearer $(gcloud auth print-access-token)" \
		-H "x-goog-user-project:pfocr-384122" \
		-H "Content-Type: application/json; charset=utf-8" \
		-d @"$filename" \
		"https://us-vision.googleapis.com/v1/projects/pfocr-384122/locations/us/images:asyncBatchAnnotate"
    echo "-----------------------------------------"
done
