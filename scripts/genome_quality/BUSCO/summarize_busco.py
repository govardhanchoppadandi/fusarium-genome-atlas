#!/usr/bin/env python3
from pathlib import Path
import argparse, csv, re
from collections import defaultdict
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

METRICS = ["C","S","D","F","M","N","Complete_count","Single_count",
           "Duplicated_count","Fragmented_count","Missing_count","Internal_stop_count"]
HEADERS = [
"Abbreviation","Assembly Accession","Sample",
"Genome Complete %","Genome Single-copy %","Genome Duplicated %","Genome Fragmented %","Genome Missing %",
"Genome Total BUSCOs","Genome Complete Count","Genome Single-copy Count","Genome Duplicated Count",
"Genome Fragmented Count","Genome Missing Count","Genome Internal Stop Codons",
"Protein Complete %","Protein Single-copy %","Protein Duplicated %","Protein Fragmented %","Protein Missing %",
"Protein Total BUSCOs","Protein Complete Count","Protein Single-copy Count","Protein Duplicated Count",
"Protein Fragmented Count","Protein Missing Count","Protein Internal Stop Codons",
"Genome Decision","Protein Decision","FINAL DECISION"]

def parse_summary(path):
    txt = path.read_text(errors="replace")
    m = re.search(r"C:([\d.]+)%\[S:([\d.]+)%,D:([\d.]+)%\],F:([\d.]+)%,M:([\d.]+)%,n:(\d+)", txt)
    if not m: return None
    v = m.groups()
    d = dict(zip(["C","S","D","F","M","N"],
                 [float(v[0]),float(v[1]),float(v[2]),float(v[3]),float(v[4]),int(v[5])]))
    pats = {
      "Complete_count":r"(\d+)\s+Complete BUSCOs",
      "Single_count":r"(\d+)\s+Complete and single-copy BUSCOs",
      "Duplicated_count":r"(\d+)\s+Complete and duplicated BUSCOs",
      "Fragmented_count":r"(\d+)\s+Fragmented BUSCOs",
      "Missing_count":r"(\d+)\s+Missing BUSCOs"}
    for k,p in pats.items():
        x=re.search(p,txt); d[k]=int(x.group(1)) if x else None
    x=re.search(r"(\d+)\s+of\s+\d+\s+Complete matches.*?contain internal stop codons",
                txt,re.I|re.S)
    d["Internal_stop_count"]=int(x.group(1)) if x else None
    return d

def load_sources(csv_path, root):
    with open(csv_path,newline="",encoding="utf-8-sig") as f:
        rows=list(csv.DictReader(f))
    if not rows or not {"genome_dir","protein_dir"} <= set(rows[0]):
        raise ValueError("Sources CSV requires genome_dir,protein_dir headers")
    return ([root/r["genome_dir"] for r in rows],
            [root/r["protein_dir"] for r in rows])

def collect(dirs,label):
    candidates=defaultdict(list)
    for folder in dirs:
        if not folder.exists():
            print(f"[WARNING] {label} folder missing: {folder}"); continue
        for p in folder.rglob("short_summary*.txt"):
            d=parse_summary(p)
            if d is not None:
                candidates[p.parent.name].append((p.stat().st_mtime,d,p))
            else: print(f"[WARNING] Could not parse {p}")
    out={}
    for sample,items in candidates.items():
        items.sort(key=lambda x:x[0],reverse=True)
        if len(items)>1:
            print(f"[DUPLICATE] {label} {sample}; newest summary selected:")
            for _,_,p in items: print("  ",p)
        out[sample]=items[0][1]
    return out

def metadata_map(path):
    out={}
    if not path: return out
    with open(path,newline="",encoding="utf-8-sig") as f:
        for r in csv.DictReader(f):
            s=(r.get("sample") or "").strip()
            if s: out[s]={"abbreviation":(r.get("abbreviation") or "").strip(),
                          "assembly_accession":(r.get("assembly_accession") or "").strip()}
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--root",required=True)
    ap.add_argument("--sources",required=True)
    ap.add_argument("--metadata")
    ap.add_argument("--output",default="BUSCO_GENOME_PROTEIN_SUMMARY.xlsx")
    ap.add_argument("--threshold",type=float,default=95)
    a=ap.parse_args()
    root=Path(a.root).expanduser().resolve()
    gd,pd=load_sources(Path(a.sources).resolve(),root)
    print("[INFO] Reading genome summaries")
    genome=collect(gd,"GENOME")
    print("[INFO] Reading protein summaries")
    protein=collect(pd,"PROTEIN")
    meta=metadata_map(Path(a.metadata).resolve() if a.metadata else None)
    samples=sorted(set(genome)|set(protein))
    wb=Workbook(); ws=wb.active; ws.title="BUSCO Summary"; ws.append(HEADERS)
    for sample in samples:
        g,p=genome.get(sample),protein.get(sample)
        md=meta.get(sample,{})
        ab=md.get("abbreviation","") or (sample.split("_",1)[0] if "_" in sample else "")
        gdsc="KEEP" if g and g["C"]>=a.threshold else "REMOVE"
        pdsc="KEEP" if p and p["C"]>=a.threshold else "REMOVE"
        final="KEEP" if gdsc=="KEEP" and pdsc=="KEEP" else "REMOVE"
        ws.append([ab,md.get("assembly_accession",""),sample,
          *[g.get(k) if g else None for k in METRICS],
          *[p.get(k) if p else None for k in METRICS],
          gdsc,pdsc,final])
    navy=PatternFill("solid",fgColor="1F4E78")
    gf=PatternFill("solid",fgColor="DDEBF7"); pf=PatternFill("solid",fgColor="E2F0D9")
    kf=PatternFill("solid",fgColor="C6EFCE"); rf=PatternFill("solid",fgColor="FFC7CE")
    for c in ws[1]:
        c.fill=navy; c.font=Font(bold=True,color="FFFFFF")
        c.alignment=Alignment(horizontal="center",vertical="center",wrap_text=True)
    for r in range(2,ws.max_row+1):
        for c in range(4,16): ws.cell(r,c).fill=gf
        for c in range(16,28): ws.cell(r,c).fill=pf
        for c in (28,29,30):
            cell=ws.cell(r,c)
            cell.fill=kf if cell.value=="KEEP" else rf
            cell.font=Font(bold=True,color="006100" if cell.value=="KEEP" else "9C0006")
    for c in [4,5,6,7,8,16,17,18,19,20]:
        for r in range(2,ws.max_row+1): ws.cell(r,c).number_format='0.0"%"'
    ws.freeze_panes="D2"; ws.auto_filter.ref=ws.dimensions; ws.row_dimensions[1].height=55
    for c in range(1,31): ws.column_dimensions[get_column_letter(c)].width=20
    ws.column_dimensions["A"].width=18; ws.column_dimensions["B"].width=23
    ws.column_dimensions["C"].width=32; ws.column_dimensions["AD"].width=18
    output=Path(a.output).expanduser()
    if not output.is_absolute(): output=Path.cwd()/output
    output.parent.mkdir(parents=True,exist_ok=True); wb.save(output)
    keep=sum(ws.cell(r,30).value=="KEEP" for r in range(2,ws.max_row+1))
    remove=sum(ws.cell(r,30).value=="REMOVE" for r in range(2,ws.max_row+1))
    print(f"\nSamples: {len(samples)} | Genome results: {len(genome)} | Protein results: {len(protein)}")
    print(f"KEEP: {keep} | REMOVE: {remove} | threshold: {a.threshold}% for both")
    print(f"Excel created: {output}")

if __name__=="__main__": main()
