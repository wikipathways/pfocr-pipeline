# Step 3: Optical Character Recognition (OCR)

This step uses Google Cloud Vision (GCV) Optical Character Recognition (OCR) to extract text from the 23,107 images which were predicted as pathway diagrams in the previous step. The ```images:asyncBatchAnnotate``` GCV OCR method is used to run asynchronous image detection and annotation for a list of images. A ```images:asyncBatchAnnotate``` request allows up to 2,000 images per request. Additionally, each request is processed in batches of 100. So, for 23,107 images there are 12 batches which results in 232 json output files. 

### Useful links
- https://cloud.google.com/functions/docs/tutorials/ocr
- https://cloud.google.com/vision/docs/ocr#vision_set_endpoint-drest
- https://cloud.google.com/vision/docs/batch#vision_async_batch_annotate_images-python
- https://cloud.google.com/vision/docs/reference/rest/v1/images/asyncBatchAnnotate

### Next Step

PFOCR NLP/NER is performed on the predicted pathway diagrams.
