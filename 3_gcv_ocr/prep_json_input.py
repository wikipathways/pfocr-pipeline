# images:asyncBatchAnnotate request allows up to 2000 images per request 
# Each request is processed in batches of 100
# This py script convert gs url csv file to json files
# Each json file has 2000 images

# Replace [Output Bucket Name] with your Output Bucket Name

#import packages
import csv
import json
import math
import os

#define file names
csv_file = 'ocr_images.csv'

# Create an empty list to store image URIs
image_uris = []

# Read image URIs from a CSV file
with open(csv_file, 'r') as file:
    reader = csv.reader(file)
    for row in reader:
        image_uris.append(row[0])  # the URIs are in the first column of the CSV


# Define the batch size
batch_size = 2000

#create output directory
if not os.path.exists("ocr_images_json"):
    os.mkdir("ocr_images_json")
os.chdir("ocr_images_json")

# Calculate the number of batches
num_batches = math.ceil(len(image_uris) / batch_size)

# Generate and write JSON data for each batch
for batch_num in range(num_batches):
    start_index = batch_num * batch_size
    end_index = (batch_num + 1) * batch_size
    batch_image_uris = image_uris[start_index:end_index]

    # Create a list to store the request objects
    requests = []

    # Generate the request objects for each image in the batch
    for image_uri in batch_image_uris:
        request = {
            "image": {
                "source": {
                    "imageUri": image_uri
                }
            },
            "features": [
                {
                    "type": "TEXT_DETECTION"
                }
            ]
        }
        requests.append(request)

    # Create the JSON data structure for the batch, replace [Output Bucket Name] with your Output Bucket Name
    data = {
        "requests": requests,
        "outputConfig": {
            "gcsDestination": {
                "uri": f"gs://[Output Bucket Name]/batch{batch_num + 1}_"
            },
            "batchSize": 100
        }
    }

    # Write the data to a JSON file for the batch
    filename = f"ocr_images_batch{batch_num + 1}.json"
    with open(filename, "w") as file:
        json.dump(data, file, indent=4)

    print(f"JSON data for batch {batch_num + 1} has been written to {filename}.")

