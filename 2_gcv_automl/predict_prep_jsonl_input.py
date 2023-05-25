# This py script convert gs url csv file to jsonl file. Google cloud only accepts jsonl.

import csv
import json

csv_file = 'predict_images.csv'
jsonl_file = 'predict_images.jsonl'

with open(csv_file, 'r') as f_csv, open(jsonl_file, 'w') as f_jsonl:
    csv_reader = csv.reader(f_csv)
    next(csv_reader)
    for row in csv_reader:
        image_url = row[0]
        metadata = {'content': image_url, 'mimeType': 'image/jpeg'}
        json.dump(metadata, f_jsonl)
        f_jsonl.write('\n')
