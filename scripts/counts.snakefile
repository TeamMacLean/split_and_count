'''
Snakefile for running kraken and kallisto on RNAseq reads of mixed sample of Magnaporthe and Rice.

    Pipeline:
        1. extract reads matching Mo from raw Fastq (kraken)
        2. count reads extracted
        3. count extracted reads per Mo transcript per sample
        4. process count files into count matrix
        5. summarise number of reads extracted

Run from do_count_matrix.sh
'''


samples = []
fq1 = []
fq2 = []
with open("lib/samples_to_files.csv") as csv:
    for l in csv:
        l = l.rstrip("\n")
        if not l.startswith("name"):
            els = l.split(",")
            samples.append(els[3])
            fq1.append( els[6] )
            fq2.append( els[7] )

def sample_to_read(sample, samples, reads):
    return reads[samples.index(sample)]

configfile: "config.yaml"


rule counts:
    input: 
        counts="results/all_samples_tpm_matrix.txt",
        metadata="results/run_metadata.txt",
        rawreadcount="results/read_counts.txt",
        percentspertaxid="results/percent_reads_per_taxid.txt"

rule count_reads_in_fq:
    input:
        raw=expand(config['scratch'] + "{sample}/raw_file_read_count.txt", sample=samples),
        extracted=expand(config['scratch'] + "{sample}/extracted_read_count.txt", sample=samples)
    threads: 1
    params:
        mem="16G",
        queue="tsl-short"
    output: "results/read_counts.txt"
    shell: "bash scripts/readcountsummary.sh {input.raw} {input.extracted} > {output}"

rule extract_percent_per_taxid:
    input:
        krakenreports=expand(config['scratch'] + "{sample}/kraken_extract/report.class", sample=samples)
    output: "results/percent_reads_per_taxid.txt"
    threads: 1
    params:
        mem="16G",
        queue="tsl-short"
    shell: "bash scripts/percentreadspertaxid.sh {input.krakenreports} > {output}"

rule count_raw_reads_in_fq:
    input:
        fq1=lambda wildcards: sample_to_read(wildcards.sample, samples, fq1)
    output:
        count=config['scratch'] + "{sample}/raw_file_read_count.txt"
    threads: 1
    params:
        queue="tsl-short",
        mem="16G"
    shell: "zcat {input.fq1} | wc -l > {output.count}"

rule run_kraken:
    input: 
        fq1=lambda wildcards: sample_to_read(wildcards.sample, samples, fq1),
        fq2=lambda wildcards: sample_to_read(wildcards.sample, samples, fq2)
    output:
        output=temp(config['scratch'] + "{sample}/kraken_extract/output.class"),
        report=config['scratch'] + "{sample}/kraken_extract/report.class"
    params:
        db = config['kraken_db'],
        mem = "32G",
        queue="tsl-short"
    threads: 3
    shell: "bash scripts/kraken.sh {params.db} {threads} {output.output} {output.report} {input.fq1} {input.fq2}"

rule extract_reads:
    input:
        krakenout=config['scratch'] + "{sample}/kraken_extract/output.class",
        krakenreport=config['scratch'] + "{sample}/kraken_extract/report.class",
        fq1=lambda wildcards: sample_to_read(wildcards.sample, samples, fq1),
        fq2=lambda wildcards: sample_to_read(wildcards.sample, samples, fq2)
    output: 
        fq1=temp(config['scratch'] + "{sample}/kraken_extract/extracted_1.fq.gz"),
        fq2=temp(config['scratch'] + "{sample}/kraken_extract/extracted_2.fq.gz")
    params:
        taxid=config['tax_id'],
        mem="32G",
        queue="tsl-short"
    threads: 1
    shell: "bash scripts/extract_reads.sh {input.krakenout} {input.krakenreport} {input.fq1} {input.fq2} {params.taxid} {output.fq1} {output.fq2}"

rule count_extracted_reads_in_fq:
    input:
        fq1=config['scratch'] + "{sample}/kraken_extract/extracted_1.fq.gz"
    output:
        count=config['scratch'] + "{sample}/extracted_read_count.txt"
    threads: 1
    params:
        mem="16G",
        queue="tsl-short"
    shell: "wc -l {input.fq1} > {output.count}"

rule kallisto_quant:
    input: 
        idx=config['scratch'] + "kallisto_indices/magnaporthe.idx",
        fq1=config['scratch'] + "{sample}/kraken_extract/extracted_1.fq.gz",
        fq2=config['scratch'] + "{sample}/kraken_extract/extracted_2.fq.gz"
    output: config['scratch'] + "{sample}/kallisto/abundance.tsv",
    params:
        folder=config['scratch'] + "{sample}/kallisto",
        mem="16G",
        queue="tsl-long",
        bootstraps=100
    threads: 1
    shell: "bash scripts/kallisto.sh {input.idx} {threads} {params.bootstraps} {input.fq1} {input.fq2} {params.folder}"


rule kallisto_index:
    input: config['reference_genome']
    output: config['scratch'] + "kallisto_indices/magnaporthe.idx"
    params:
        mem="32G",
        queue="tsl-short"
    shell: "bash scripts/idx.sh {input} {output}"

rule combine_counts:
    input: expand(config['scratch'] + "{sample}/kallisto/abundance.tsv", sample=samples)
    output: "results/all_samples_tpm_matrix.txt"
    params:
        mem="16G",
        queue="tsl-short"
    threads: 1
    shell: "python scripts/combine_tpm.py {input} > {output} "

rule sleuth_files:
    input: expand(config['scratch'] + "{sample}/kallisto/abundance.tsv", sample=samples)
    output:
        gz="results/kallisto_abundances.gz",
        meta="results/run_metadata.txt"
    params:
        mem="16",
        queue="tsl-short",
        temp_dir=config['scratch'] + "/tmp/"
    threads: 1
    shell: "python scripts/make_metadata.py {params.temp_dir} {output.gz} {input} > {output.meta}"