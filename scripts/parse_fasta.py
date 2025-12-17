#!/usr/bin/env python
"""Parse FASTA, compute basic stats with Biopython."""

import sys
from pathlib import Path
from Bio import SeqIO
from Bio.SeqUtils import gc_fraction
import json

def analyze_fasta(input_path, output_path):
    records = list(SeqIO.parse(input_path, "fasta"))

    stats = {
        "file": Path(input_path).name,
        "num_sequences": len(records),
        "total_length": sum(len(r.seq) for r in records),
        "sequences": []
    }

    for rec in records:
        stats["sequences"].append({
            "id": rec.id,
            "length": len(rec.seq),
            "gc_percent": round(gc_fraction(rec.seq) * 100, 2)
        })

    stats["mean_length"] = round(stats["total_length"] / len(records), 2) if records else 0
    stats["mean_gc"] = round(
        sum(s["gc_percent"] for s in stats["sequences"]) / len(records), 2
    ) if records else 0

    with open(output_path, "w") as f:
        json.dump(stats, f, indent=2)

    print(f"Processed {stats['num_sequences']} sequences from {input_path}")

if __name__ == "__main__":
    analyze_fasta(sys.argv[1], sys.argv[2])
