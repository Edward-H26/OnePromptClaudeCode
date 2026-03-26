---
name: pdf-processing-pro
description: PDF processing with forms, tables, OCR, and validation. Use when working with PDF workflows, extracting data from PDFs, or processing form fields.
---

# pdf-processing-pro

PDF processing toolkit for form analysis, table extraction, OCR, and document workflows.

## Quick Start

### Extract text from PDF

```python
import pdfplumber

with pdfplumber.open("document.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

### Analyze PDF form (using included script)

```bash
python scripts/analyze_form.py input.pdf --output fields.json
```

## Included Script

**analyze_form.py** - Extract form field information
```bash
python scripts/analyze_form.py input.pdf [--output fields.json] [--verbose]
```

## Reference Guides

- [FORMS.md](FORMS.md) - Complete form processing guide
- [TABLES.md](TABLES.md) - Advanced table extraction
- [OCR.md](OCR.md) - Scanned PDF processing

## Common Workflows

### Extract data from reports

```python
import pdfplumber

with pdfplumber.open("report.pdf") as pdf:
    for page in pdf.pages:
        tables = page.extract_tables()
        text = page.extract_text()
```

### Batch processing

```python
import glob
from pathlib import Path
import pdfplumber

for pdf_file in glob.glob("invoices/*.pdf"):
    with pdfplumber.open(pdf_file) as pdf:
        text = pdf.pages[0].extract_text()
```

## Dependencies

```bash
pip install pdfplumber pypdf pillow pytesseract pandas
```

Optional for OCR:
```bash
# macOS: brew install tesseract
# Ubuntu: apt-get install tesseract-ocr
```

## Performance Tips

- Process page by page for large PDFs to avoid memory issues
- Use batch processing for multiple PDFs
- Cache extracted data to avoid re-processing
- Validate inputs early to fail fast
