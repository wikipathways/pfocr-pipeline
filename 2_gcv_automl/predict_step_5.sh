#!/usr/bin/env bash

# chmod +x predict_step_5.sh
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @predict_request.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/[Project Name]/locations/us-central1/batchPredictionJobs"
