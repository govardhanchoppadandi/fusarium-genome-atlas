"""
Fusarium Genome Metadata Extraction Pipeline
--------------------------------------------
Retrieves NCBI Assembly and BioSample metadata for GCA/GCF accessions.

Input:
  Excel workbook containing an "Assembly Accession" column.
  Optional columns include BioSample, BioProject, Host,
  Geographical Location, Coordinate, Genome Size (MB), GC content (%).

Output:
  FUSARIUM_COMPLETE_NCBI_METADATA.xlsx
  FUSARIUM_INCOMPLETE_RECORDS.xlsx

Install:
  py -m pip install -r requirements.txt

Run:
  py HOST.py
"""

import os
import re
import time
import requests
import pandas as pd
import xml.etree.ElementTree as ET
from tqdm import tqdm

# =====================================================
# CONFIGURATION: EDIT THESE PATHS
# =====================================================

INPUT_EXCEL = r"F:\fusarium WGS\META DATA\FUSARIUM_FINAL_MASTER.xlsx"

OUTPUT_EXCEL = (
    r"F:\fusarium WGS\META DATA"
    r"\FUSARIUM_COMPLETE_NCBI_METADATA.xlsx"
)

PENDING_EXCEL = (
    r"F:\fusarium WGS\META DATA"
    r"\FUSARIUM_INCOMPLETE_RECORDS.xlsx"
)

# Optional NCBI API key. Leave blank if you do not have one.
API_KEY = ""

BASE_URL = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
REQUEST_DELAY = 0.35
MAX_RETRIES = 5

# =====================================================
# HELPERS
# =====================================================

def is_missing(value):
    if value is None:
        return True
    try:
        if pd.isna(value):
            return True
    except (TypeError, ValueError):
        pass
    return str(value).strip().lower() in {"", "nan", "none", "null"}


def clean(value):
    return "" if is_missing(value) else str(value).strip()


def ncbi_request(endpoint, params):
    params = dict(params)
    params["tool"] = "FusariumGenomeMetadata"
    if API_KEY:
        params["api_key"] = API_KEY

    last_error = None
    for attempt in range(MAX_RETRIES):
        try:
            response = SESSION.get(
                BASE_URL + endpoint,
                params=params,
                timeout=90
            )
            if response.status_code == 429:
                time.sleep(5 * (attempt + 1))
                continue
            response.raise_for_status()
            time.sleep(REQUEST_DELAY)
            return response
        except requests.RequestException as exc:
            last_error = exc
            if attempt == MAX_RETRIES - 1:
                raise
            time.sleep(2 ** attempt)

    raise RuntimeError(f"NCBI request failed: {last_error}")


# =====================================================
# NCBI ASSEMBLY LOOKUP
# =====================================================

ASSEMBLY_CACHE = {}
BIOSAMPLE_CACHE = {}


def get_assembly_metadata(accession):
    """Return linked BioSample/BioProject and assembly size/GC."""
    if accession in ASSEMBLY_CACHE:
        return ASSEMBLY_CACHE[accession].copy()

    result = {
        "BioSample": "",
        "BioProject": "",
        "Total_Length": "",
        "GC_Percent": "",
        "Assembly_Status": ""
    }

    try:
        search = ncbi_request(
            "esearch.fcgi",
            {
                "db": "assembly",
                "term": f'"{accession}"[Assembly Accession]',
                "retmode": "json"
            }
        )
        ids = search.json().get("esearchresult", {}).get("idlist", [])

        if not ids:
            result["Assembly_Status"] = "Assembly not found in NCBI"
            ASSEMBLY_CACHE[accession] = result
            return result.copy()

        summary = ncbi_request(
            "esummary.fcgi",
            {
                "db": "assembly",
                "id": ",".join(ids),
                "retmode": "json"
            }
        ).json().get("result", {})

        for uid in ids:
            doc = summary.get(uid, {})
            if doc.get("assemblyaccession", "") != accession:
                continue

            result["BioSample"] = clean(doc.get("biosampleaccn", ""))
            result["BioProject"] = clean(doc.get("bioprojectaccn", ""))
            result["Total_Length"] = doc.get("total_length", "")
            result["GC_Percent"] = doc.get("gc_percent", "")
            result["Assembly_Status"] = "Success"
            break

        if not result["Assembly_Status"]:
            result["Assembly_Status"] = "Exact assembly accession not matched"

    except Exception as exc:
        result["Assembly_Status"] = f"ERROR: {exc}"

    ASSEMBLY_CACHE[accession] = result
    return result.copy()


# =====================================================
# NCBI BIOSAMPLE LOOKUP
# =====================================================

def get_biosample_metadata(biosample):
    """Return all BioSample Attribute values from the XML record."""
    if biosample in BIOSAMPLE_CACHE:
        return BIOSAMPLE_CACHE[biosample].copy()

    metadata = {}
    response = ncbi_request(
        "efetch.fcgi",
        {
            "db": "biosample",
            "id": biosample,
            "retmode": "xml"
        }
    )
    root = ET.fromstring(response.text)

    for attr in root.iter("Attribute"):
        key = attr.attrib.get("attribute_name") or attr.attrib.get("harmonized_name")
        value = (attr.text or "").strip()
        if key:
            if key in metadata and metadata[key]:
                metadata[key] += "; " + value
            else:
                metadata[key] = value

    BIOSAMPLE_CACHE[biosample] = metadata
    return metadata.copy()


def get_attribute(metadata, names):
    lookup = {str(key).lower(): value for key, value in metadata.items()}
    for name in names:
        value = lookup.get(name.lower(), "")
        if not is_missing(value):
            return value
    return ""


def extract_coordinates(metadata, original_coordinate):
    latitude = get_attribute(metadata, ["latitude"])
    longitude = get_attribute(metadata, ["longitude"])
    lat_lon = get_attribute(metadata, ["lat_lon", "coordinates"])

    if latitude and longitude:
        coordinate = f"{latitude}, {longitude}"
    elif lat_lon:
        coordinate = str(lat_lon).strip()
        # Parse simple "latitude, longitude" forms.
        match = re.search(
            r"(-?\d+(?:\.\d+)?)\s*[NS]?\s*[,;/]\s*"
            r"(-?\d+(?:\.\d+)?)\s*[EW]?",
            coordinate,
            re.IGNORECASE
        )
        if match:
            latitude = latitude or match.group(1)
            longitude = longitude or match.group(2)
    else:
        coordinate = original_coordinate or ""

    return latitude, longitude, coordinate


# =====================================================
# MAIN PIPELINE
# =====================================================

def main():
    if not os.path.isfile(INPUT_EXCEL):
        raise FileNotFoundError(
            f"Input Excel file was not found:\n{INPUT_EXCEL}\n\n"
            "Edit INPUT_EXCEL at the top of HOST.py to match your computer."
        )

    print("Reading input Excel...")
    df = pd.read_excel(INPUT_EXCEL)

    if "Assembly Accession" not in df.columns:
        raise ValueError(
            'Required column "Assembly Accession" was not found. '
            f"Columns detected: {list(df.columns)}"
        )

    df["_Original_Order"] = range(len(df))
    records = []

    print(f"Total input rows: {len(df)}")
    print("Starting NCBI metadata extraction...")

    for _, row in tqdm(
        df.iterrows(),
        total=len(df),
        desc="Processing assemblies"
    ):
        record = row.to_dict()

        accession = clean(row.get("Assembly Accession", ""))
        biosample = clean(row.get("BioSample", ""))
        bioproject = clean(row.get("BioProject", ""))

        original_host = clean(row.get("Host", ""))
        original_location = clean(row.get("Geographical Location", ""))
        original_coordinate = clean(row.get("Coordinate", ""))
        original_genome_size = row.get("Genome Size (MB)", "")
        original_gc = row.get("GC content (%)", "")

        # Explicit provenance columns
        record["BioSample_Source"] = (
            "Input Excel" if biosample else ""
        )
        record["BioProject_Source"] = (
            "Input Excel" if bioproject else ""
        )
        record["Host_Source"] = (
            "Input Excel" if original_host else ""
        )
        record["Location_Source"] = (
            "Input Excel" if original_location else ""
        )
        record["Coordinate_Source"] = (
            "Input Excel" if original_coordinate else ""
        )

        metadata = {}
        assembly_status = ""
        biosample_status = ""

        if not accession:
            assembly_status = "Missing Assembly Accession"
            biosample_status = "Not attempted"
        else:
            assembly = get_assembly_metadata(accession)
            assembly_status = assembly["Assembly_Status"]

            if not biosample and assembly["BioSample"]:
                biosample = assembly["BioSample"]
                record["BioSample_Source"] = "NCBI Assembly"

            if not bioproject and assembly["BioProject"]:
                bioproject = assembly["BioProject"]
                record["BioProject_Source"] = "NCBI Assembly"

            total_length = assembly["Total_Length"]
            if not is_missing(total_length):
                try:
                    genome_size = float(total_length) / 1_000_000
                except (TypeError, ValueError):
                    genome_size = original_genome_size
            else:
                genome_size = original_genome_size

            gc_value = assembly["GC_Percent"]
            gc_content = (
                gc_value if not is_missing(gc_value) else original_gc
            )

            if biosample:
                try:
                    metadata = get_biosample_metadata(biosample)
                    biosample_status = (
                        "Success" if metadata else "No attributes found"
                    )
                except Exception as exc:
                    biosample_status = f"ERROR: {exc}"
            else:
                biosample_status = "No linked BioSample found"

        # Original values are fallbacks; provenance is labelled.
        host = get_attribute(metadata, ["host"])
        if host:
            record["Host_Source"] = "NCBI BioSample"
        else:
            host = original_host

        host_taxid = get_attribute(metadata, ["host_taxid"])
        host_disease = get_attribute(metadata, ["host_disease"])

        location = get_attribute(
            metadata,
            ["geo_loc_name", "geographic_location", "country"]
        )
        if location:
            record["Location_Source"] = "NCBI BioSample"
        else:
            location = original_location

        collection_date = get_attribute(metadata, ["collection_date"])
        isolation_source = get_attribute(metadata, ["isolation_source"])

        latitude, longitude, coordinate = extract_coordinates(
            metadata, original_coordinate
        )
        if latitude or longitude or get_attribute(metadata, ["lat_lon", "coordinates"]):
            record["Coordinate_Source"] = "NCBI BioSample"

        # Keep every BioSample attribute without overwriting original columns.
        for key, value in metadata.items():
            if key not in record:
                record[key] = value
            else:
                record[f"{key}_BioSample"] = value

        record["Assembly Accession"] = accession
        record["BioSample"] = biosample
        record["BioProject"] = bioproject
        record["Genome Size (MB)"] = genome_size if accession else original_genome_size
        record["GC content (%)"] = gc_content if accession else original_gc
        record["Host"] = host
        record["Host_Taxonomy_ID"] = host_taxid
        record["Host_Disease"] = host_disease
        record["Geographical Location"] = location
        record["Collection Date"] = collection_date
        record["Isolation Source"] = isolation_source
        record["Latitude"] = latitude
        record["Longitude"] = longitude
        record["Coordinate"] = coordinate
        record["Assembly_Status"] = assembly_status
        record["BioSample_Status"] = biosample_status

        records.append(record)

    out = pd.DataFrame(records)
    out = out.sort_values("_Original_Order").reset_index(drop=True)

    priority_columns = [
        "Organism   Scientific Name",
        "Abbreviation",
        "Genome Size (MB)",
        "GC content (%)",
        "Organism Qualifier (Strain)",
        "Taxonomy ID",
        "Assembly Name",
        "Assembly Accession",
        "BioProject",
        "BioSample",
        "Host",
        "Host_Taxonomy_ID",
        "Host_Disease",
        "Geographical Location",
        "Collection Date",
        "Isolation Source",
        "Latitude",
        "Longitude",
        "Coordinate",
        "BioSample_Source",
        "BioProject_Source",
        "Host_Source",
        "Location_Source",
        "Coordinate_Source",
        "Assembly_Status",
        "BioSample_Status"
    ]

    priority_columns = [c for c in priority_columns if c in out.columns]
    other_columns = [
        c for c in out.columns
        if c not in priority_columns and c != "_Original_Order"
    ]
    out = out[priority_columns + other_columns]

    # Ensure output directory exists.
    output_dir = os.path.dirname(OUTPUT_EXCEL)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    out.to_excel(OUTPUT_EXCEL, index=False)

    # Incomplete means missing any of these three fields.
    incomplete_mask = (
        out["BioSample"].fillna("").astype(str).str.strip().eq("")
        | out["Host"].fillna("").astype(str).str.strip().eq("")
        | out["Geographical Location"].fillna("").astype(str).str.strip().eq("")
    )
    incomplete = out.loc[incomplete_mask].copy()
    incomplete.to_excel(PENDING_EXCEL, index=False)

    print("\n==========================================")
    print("FUSARIUM METADATA EXTRACTION COMPLETED")
    print("==========================================")
    print("Total assemblies:", len(out))
    print("BioSample available:", out["BioSample"].fillna("").astype(str).str.strip().ne("").sum())
    print("BioProject available:", out["BioProject"].fillna("").astype(str).str.strip().ne("").sum())
    print("Genome size available:", out["Genome Size (MB)"].apply(lambda x: not is_missing(x)).sum())
    print("GC content available:", out["GC content (%)"].apply(lambda x: not is_missing(x)).sum())
    print("Host available:", out["Host"].fillna("").astype(str).str.strip().ne("").sum())
    print("Location available:", out["Geographical Location"].fillna("").astype(str).str.strip().ne("").sum())
    print("Coordinates available:", out["Coordinate"].fillna("").astype(str).str.strip().ne("").sum())
    print("Incomplete records:", len(incomplete))
    print("\nComplete output:", OUTPUT_EXCEL)
    print("Incomplete report:", PENDING_EXCEL)

    SESSION.close()


SESSION = requests.Session()
SESSION.headers.update({
    "User-Agent": "FusariumGenomeMetadata/1.0 (academic research)"
})

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted by user. No complete output is guaranteed.")
    except Exception as exc:
        print(f"\nFATAL ERROR: {exc}")
        raise
    finally:
        SESSION.close()
