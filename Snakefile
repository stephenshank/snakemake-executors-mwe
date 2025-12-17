configfile: "config.yaml"

rule all:
    input:
        expand("results/{sample}_biopython.json", sample=config["samples"]),
        expand("results/{sample}_seqkit.txt", sample=config["samples"]),
        "results/combined_report.txt"

# Biopython rule - proves Python dependency works
rule biopython_stats:
    input:
        "data/{sample}.fasta"
    output:
        "results/{sample}_biopython.json"
    conda:
        "envs/bioenv.yaml"
    resources:
        mem_mb=2000,
        runtime=10
    shell:
        """
        echo "Running Biopython on $(hostname) at $(date)"
        python scripts/parse_fasta.py {input} {output}
        """

# seqkit rule - proves CLI tool dependency works
rule seqkit_stats:
    input:
        "data/{sample}.fasta"
    output:
        "results/{sample}_seqkit.txt"
    conda:
        "envs/bioenv.yaml"
    resources:
        mem_mb=1000,
        runtime=5
    shell:
        """
        echo "Running seqkit on $(hostname) at $(date)" > {output}
        echo "---" >> {output}
        seqkit stats {input} >> {output}
        echo "---" >> {output}
        seqkit fx2tab --length --gc {input} >> {output}
        """

# Combine results - runs after both complete
rule combine_reports:
    input:
        bp=expand("results/{sample}_biopython.json", sample=config["samples"]),
        sk=expand("results/{sample}_seqkit.txt", sample=config["samples"])
    output:
        "results/combined_report.txt"
    conda:
        "envs/bioenv.yaml"
    shell:
        """
        echo "=== Combined Report ===" > {output}
        echo "Generated on $(hostname) at $(date)" >> {output}
        echo "" >> {output}

        echo "--- Biopython Results ---" >> {output}
        for f in {input.bp}; do
            echo "File: $f" >> {output}
            cat "$f" >> {output}
            echo "" >> {output}
        done

        echo "--- Seqkit Results ---" >> {output}
        cat {input.sk} >> {output}
        """
