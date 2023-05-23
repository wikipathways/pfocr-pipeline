# This py script splits the batch json files from gcv ocr to create a single json file per figure result
# This script takes 2 inputs:
#   1. --input_dir: Path to the directory containing the input batch JSON file outputs from gcv ocr
#   2. --output_dir: Path to the directory to save the output JSON files per figure result

#import packages
import argparse
import json
import os

#the split function to create a single json file per figure result
def split_json(json_file, output_dir):
    with open(json_file, 'r') as file:
        data = json.load(file)

    if 'responses' not in data:
        print(f"Error: 'responses' key not found in the json file: {json_file}")
        return

    responses = data['responses']
    if not responses:
        print(f"Error: No responses found in the json file: {json_file}")
        return

    for index, response in enumerate(responses, start=1):
        # Check if 'textAnnotations' are present for a figure, otherwise skip it
        if 'textAnnotations' not in response:
            print(f"No OCR results for {response['context']['uri'].split('/')}.")
            continue

        new_json = response['textAnnotations']

        # Extract the figure ID from the URI and use it as the output JSON file name
        split_parts = response['context']['uri'].split('/')
        file_name, file_extension = os.path.splitext(split_parts[-1])
        new_file_name = f'{file_name}.json'
        new_file_path = os.path.join(output_dir, new_file_name)

        with open(new_file_path, 'w') as new_file:
            json.dump(new_json, new_file)

# Create argument parser
parser = argparse.ArgumentParser(description='Split JSON files into separate files.')
parser.add_argument('--input_dir', type=str, required=True, help='Path to the directory containing the input JSON files')
parser.add_argument('--output_dir', type=str, required=True, help='Path to the directory to save the output JSON files')

# Parse the arguments
args = parser.parse_args()

# Retrieve all json file paths in the input directory
json_files = [f for f in os.listdir(args.input_dir) if f.endswith('.json')]

# Create the output directory if it does not exist
if not os.path.exists(args.output_dir):
    os.makedirs(args.output_dir)

# Process each json file
for json_file in json_files:
    json_file_path = os.path.join(args.input_dir, json_file)
    split_json(json_file_path, args.output_dir)
