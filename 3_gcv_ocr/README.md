# Step 3: Optical Character Recognition (OCR)

This protocol uses Google Cloud Vision (GCV) OCR to extract text from the 23,107 images which were predicted as pathway diagrams in the previous step. The images:asyncBatchAnnotate GCV OCR request allows up to 2,000 images per request. Additionally, each request is processed in batches of 100. So, for 23,107 images there are 12 batches which results in 232 json output files. 

### Useful links
- https://cloud.google.com/functions/docs/tutorials/ocr
- https://cloud.google.com/vision/docs/ocr#vision_set_endpoint-python
- https://cloud.google.com/vision/docs/detect-labels-image-command-line
- https://cloud.google.com/vision/docs/batch#vision_async_batch_annotate_images-python
- https://cloud.google.com/vision/product-search/docs/auth
- https://cloud.google.com/vision/docs/reference/rest/v1/images/asyncBatchAnnotate
- https://cloud.google.com/vision/docs/ocr#vision_set_endpoint-drest

### Next Step

PFOCR NLP/NER is performed on the predicted pathway diagrams.
