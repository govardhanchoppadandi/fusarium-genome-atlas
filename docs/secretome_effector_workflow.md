# Secretome and Effector Prediction Workflow

## Overview

The Fusarium Genome Atlas project will implement a computational secretome and effector prediction workflow based on the methodology described in Govardhan et al. (2026).

The workflow will be implemented using locally executable Bash and Python scripts rather than relying on manual submission of protein sequences to online prediction servers.

## Workflow

The analysis consists of the following sequential stages:

1. **Gene and protein prediction:** AUGUSTUS-predicted protein sequences are used as input.
2. **Protein FASTA chunking:** Large protein FASTA datasets are divided into manageable batches.
3. **Signal peptide prediction:** SignalP 6.0 identifies proteins predicted to contain signal peptides.
4. **Transmembrane filtering:** DeepTMHMM identifies proteins containing transmembrane regions.
5. **GPI-anchor filtering:** NetGPI identifies proteins predicted to contain GPI anchors.
6. **Subcellular localization:** TargetP and DeepLoc are used to characterize protein targeting and localization.
7. **Effector prediction:** EffectorP 3.0 identifies candidate fungal effector proteins.
8. **Candidate refinement:** Custom Python scripts assess small-protein and cysteine-rich characteristics.
9. **Functional characterization:** Candidate proteins undergo BLASTp, InterProScan and Gene Ontology (GO) annotation.
10. **Final candidate set:** A characterized collection of predicted effector candidates is generated.

## Software implementation

Each analysis stage will be maintained as a separate software module under `scripts/secretome_analysis/`.

The modules will subsequently be integrated into a master Bash workflow to support reproducible batch processing across the selected Fusarium genomes.

## Methodological reference

Govardhan et al. (2026). [Full bibliographic details and DOI to be added.]

The workflow is based on the methodology described in this publication, with implementation and integration for comparative analysis of wheat-associated Fusarium genomes.

## Scientific interpretation

The computational workflow identifies candidate secreted proteins and putative fungal effectors. These predictions require appropriate functional interpretation and experimental validation before biological activity or pathogenicity can be established.
