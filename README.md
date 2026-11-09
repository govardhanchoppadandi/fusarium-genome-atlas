# Fusarium Genome Atlas

### A Literature-Curated Comparative Genomics Resource for Wheat-Associated *Fusarium*

## 1. Project Overview

*Fusarium* species are important fungal pathogens associated with several economically significant crop diseases, particularly Fusarium diseases of wheat. Understanding their genomic diversity, evolutionary relationships, genome architecture and pathogenicity-associated features is important for investigating fungal adaptation, host association and disease development.

The **Fusarium Genome Atlas** is a comparative genomics project focused on genome assemblies of *Fusarium* isolates reported in the scientific literature in association with wheat.

The initial dataset consists of **56 selected *Fusarium* genome assemblies**, collected and curated using published literature and publicly available NCBI resources.

The project aims to develop a structured genomic resource and perform systematic comparative analyses across these genomes.

## 2. Project Objectives

1. Compile and curate publicly available wheat-associated *Fusarium* genome assemblies.
2. Retrieve genome assembly, BioSample and BioProject metadata from NCBI.
3. Evaluate genome assembly quality and completeness.
4. Perform genome annotation and characterize genomic features.
5. Investigate repetitive DNA and transposable element distribution.
6. Identify and characterize simple sequence repeats (SSRs).
7. Explore phylogenomic relationships and evolutionary diversity.
8. Investigate candidate pathogenicity-associated genes and proteins.
9. Examine host association and geographical distribution using available metadata.
10. Develop a reproducible and expandable comparative genomics resource.

## 3. Initial Genome Dataset

The initial collection contains 56 genome assemblies selected based on published reports of *Fusarium* isolates associated with wheat.

The dataset is being organized using the following information:

- Scientific name and species identification
- Strain or isolate designation
- NCBI Assembly accession
- BioSample accession
- BioProject accession
- Genome size
- GC content
- Assembly statistics
- Genome completeness
- Host information
- Geographical location
- Published literature supporting genome selection

The dataset may be expanded as additional relevant genome assemblies are identified and evaluated.

## 4. Computational Analysis Workflow

The project will be developed in successive stages.

### Stage 1: Genome Collection and NCBI Metadata Retrieval

- Identification of publicly available genome assemblies
- Retrieval of Assembly accessions
- BioSample and BioProject identification
- Genome size and GC content retrieval
- Host and geographical metadata extraction
- Organization of the master genome dataset

### Stage 2: Genome Assembly Quality Assessment

Planned analyses:

- Assembly statistics
- Scaffold and contig counts
- N50 and L50
- Genome size and GC content
- BUSCO completeness assessment

### Stage 3: Genome Annotation

Planned analyses:

- Gene prediction
- Protein-coding gene identification
- CDS and protein sequence generation
- Functional annotation
- Genome feature characterization

Potential tools include AUGUSTUS and other suitable fungal genome annotation pipelines.

### Stage 4: Repetitive DNA and Transposable Element Analysis

Planned analyses:

- Repeat identification and classification
- Transposable element detection
- LTR retrotransposons
- DNA transposons
- Repeat abundance and genome coverage
- Comparative repeat landscapes

### Stage 5: Simple Sequence Repeat Analysis

Planned analyses:

- Microsatellite identification
- Mono- to higher-order repeat motifs
- SSR frequency and density
- Motif distribution
- GC composition of SSR regions
- SSR distribution in coding and noncoding regions

### Stage 6: Pathogenicity-Associated Protein Analysis

Candidate protein characterization will be investigated using suitable computational tools, including:

- SignalP — signal peptide prediction
- DeepTMHMM — transmembrane topology prediction
- TargetP — protein targeting prediction
- DeepLoc — protein subcellular localization
- Effector prediction tools such as EffectorP

Additional analyses may include secretome characterization, candidate effector identification, CAZyme analysis and other pathogenicity-associated protein families.

Predictions will be treated as computational candidates and not as experimental confirmation of virulence.

### Stage 7: Comparative and Evolutionary Genomics

Planned analyses:

- Whole-genome similarity
- Phylogenomic relationships
- Orthologous gene identification
- Gene family comparisons
- Genome-wide evolutionary patterns
- Comparative genomic diversity

### Stage 8: Genome Architecture and Host Association

Potential investigations:

- Genome compartmentalization
- Gene-rich and gene-sparse regions
- Repeat-rich genomic regions
- Candidate effector localization
- Host-associated genomic patterns
- Geographical distribution

## 5. Repository Structure

The repository will be organized progressively as the computational analyses are completed.

```text
fusarium-genome-atlas/
│
├── README.md
├── LICENSE
├── requirements.txt
│
├── scripts/
│   ├── metadata_retrieval/
│   ├── assembly_quality/
│   ├── genome_annotation/
│   ├── repeat_analysis/
│   ├── ssr_analysis/
│   ├── effector_prediction/
│   └── comparative_genomics/
│
├── data/
│   ├── genome_metadata/
│   └── genome_accession_list/
│
├── results/
│   ├── assembly_statistics/
│   ├── busco/
│   ├── annotation/
│   ├── repeats/
│   ├── ssr/
│   └── effectors/
│
└── docs/
    ├── methodology/
    └── references/
```

*This represents the planned structure. Directories and analysis scripts will be added as the project develops.*

## 6. Data Sources

- NCBI Assembly: https://www.ncbi.nlm.nih.gov/assembly/
- NCBI BioSample: https://www.ncbi.nlm.nih.gov/biosample/
- NCBI BioProject: https://www.ncbi.nlm.nih.gov/bioproject/
- NCBI GenBank: https://www.ncbi.nlm.nih.gov/genbank/

Genome selection will be supported by relevant scientific publications. Accession numbers and literature references will be documented to support traceability and reproducibility.

## 7. Reproducibility

Scripts, software requirements, analytical parameters and methodological documentation will be added to this repository as each stage is developed.

The project aims to maintain a transparent and reproducible computational workflow.

## 8. Project Status

**Current phase:** Initial dataset curation and NCBI metadata retrieval.

- [x] Initial literature-based selection of 56 genome assemblies
- [ ] NCBI metadata retrieval pipeline
- [ ] Assembly quality assessment
- [ ] BUSCO completeness analysis
- [ ] Genome annotation
- [ ] Repetitive DNA and TE analysis
- [ ] SSR analysis
- [ ] Candidate effector prediction
- [ ] Comparative phylogenomics
- [ ] Genome evolution and host association analysis

## 9. Future Development

The Fusarium Genome Atlas is intended to grow into an expandable comparative genomics resource for investigating genome diversity, repetitive DNA, pathogenicity-associated features and evolutionary patterns in wheat-associated *Fusarium*.

Further genome assemblies and analytical modules will be incorporated as the project progresses.

## 10. License

This project is distributed under the MIT License. Please consult the LICENSE file for details.
