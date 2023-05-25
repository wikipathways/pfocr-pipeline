# Step 4A: Named entity recognition (NER) with custom lexicon

This step utilizes a lexicon file containing all the symbol<->idenifier mappings for the genes and proteins in the PFOCR pathway diagrams. The lexicon file is used to perform named entity recognition (NER) on the PFOCR pathway diagrams. 

The NER step also utilizes a folder of `transforms` that are used to clean up the OCR output and make it more amenable to NER. The `transforms` folder contains a list of files that contain a list of regular expressions. Each file is named after the type of transform it contains. For example, the `swaps` file contains a list of substitutions that are used to transform the OCR output into recognizable gene symbols.

### Next Step

Use PubTator to annotate the PFOCR pathway diagrams with chemicals and diseases.