# NCBI Genome and BioSample Metadata Retrieval

## 1. Overview

This module retrieves and integrates genome assembly and associated biological metadata for wheat-associated *Fusarium* isolates using the National Center for Biotechnology Information (NCBI) databases.

It is the first computational module of the Fusarium Genome Atlas project.

The pipeline uses NCBI Assembly accession numbers (GCA/GCF) to retrieve linked BioSample and BioProject accessions, genome assembly size, GC content, and associated sample-level information.

## 2. Objectives

- Retrieve NCBI Assembly metadata using GCA/GCF accessions.
- Identify associated BioSample and BioProject accessions.
- Retrieve genome assembly total length and GC percentage.
- Extract host and geographical information from BioSample records.
- Retrieve collection date, isolation source and available coordinate information.
- Integrate retrieved information with the original Excel dataset.
- Generate a separate report of incomplete records.

## 3. Data Sources

The pipeline uses the following NCBI resources:

- NCBI Assembly: https://www.ncbi.nlm.nih.gov/assembly/
- NCBI BioSample: https://www.ncbi.nlm.nih.gov/biosample/
- NCBI BioProject: https://www.ncbi.nlm.nih.gov/bioproject/
- NCBI E-utilities: https://www.ncbi.nlm.nih.gov/books/NBK25501/

## 4. Methodology

### 4.1 Assembly accession-based retrieval

The pipeline uses the Assembly accession of each *Fusarium* genome to search the NCBI Assembly database.

### 4.2 Assembly metadata extraction

The following information is retrieved when available:

- Assembly accession
- BioSample accession
- BioProject accession
- Total assembly length
- GC percentage

Total assembly length is converted from base pairs to megabases (MB), using 1 MB = 1,000,000 bp.

### 4.3 BioSample metadata extraction

Linked BioSample records are retrieved in XML format.

Available attributes are examined for:

- Host
- Host taxonomy ID
- Host disease
- Geographical location
- Collection date
- Isolation source
- Latitude
- Longitude
- Other submitted sample attributes

### 4.4 Metadata integration

Retrieved information is integrated into the original Excel master dataset.

Existing input values are retained as fallbacks when corresponding NCBI information is unavailable. Provenance columns are included to help distinguish selected input values from retrieved values.

### 4.5 Incomplete-record identification

A separate Excel report is generated for records missing one or more of the following:

- BioSample accession
- Host information
- Geographical location

Missing information is not inferred from unrelated metadata.

## 5. Input Requirements

The input Excel workbook must contain the following column:

`Assembly Accession`

The workbook may also contain existing organism, strain, BioSample, BioProject, host, location, coordinate, genome size and GC content information.

## 6. Output Files

### Complete metadata workbook

`FUSARIUM_COMPLETE_NCBI_METADATA.xlsx`

Contains the original dataset integrated with retrieved NCBI metadata.

### Incomplete-record report

`FUSARIUM_INCOMPLETE_RECORDS.xlsx`

Contains records missing at least one of the selected key metadata fields.

## 7. Software Requirements

- Python
- pandas
- requests
- openpyxl
- tqdm

Install dependencies:

```bash
py -m pip install -r requirements.txt
```

## 8. Execution

Run the script:

```bash
python HOST.py
```

Before execution, update the input and output file paths in the configuration section of `HOST.py`.

## 9. Data Interpretation and Limitations

- Not every Assembly record has an associated BioSample or BioProject.
- BioSample attributes depend on information submitted by the original data providers.
- Host, geographical location and coordinates may be unavailable.
- Retrieved host information does not independently establish pathogenicity on wheat.
- Genome size and GC content are reported from NCBI Assembly summaries when available.
- Original input values are retained as fallbacks and identified through provenance columns.
- NCBI records may be updated after the analysis.

## 10. Role in the Fusarium Genome Atlas

This module establishes the metadata foundation for subsequent comparative genomic analyses, including:

- Genome assembly quality assessment
- BUSCO completeness analysis
- Genome annotation
- Repetitive DNA and transposable element analysis
- SSR identification
- Candidate effector prediction
- Comparative phylogenomics
- Genome evolution and host association analysis

## 11. Reproducibility

The Python script, package requirements, input format and output definitions are documented in this repository.

Researchers should retain the original accession list and record the date of NCBI data retrieval when reproducing the analysis.
