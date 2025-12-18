FROM mambaorg/micromamba:1.5-jammy

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

# Install snakemake with AWS plugins + all workflow dependencies in one environment
COPY --chown=$MAMBA_USER:$MAMBA_USER envs/aws-batch-container.yaml /tmp/environment.yaml
RUN micromamba install -y -n base -f /tmp/environment.yaml && \
    micromamba clean --all --yes

# Copy workflow scripts into container
COPY --chown=$MAMBA_USER:$MAMBA_USER scripts/ /opt/workflow/scripts/
ENV PATH="/opt/workflow/scripts:$PATH"

# Verify installation
RUN snakemake --version && python -c "from Bio import SeqIO" && seqkit version

WORKDIR /tmp/workdir
