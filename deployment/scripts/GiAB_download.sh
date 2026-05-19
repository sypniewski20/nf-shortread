#!/usr/bin/env bash
set -euo pipefail

input=$1

mkdir -p ${input}/truth_vcfs

FTPDIR=ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio

curl ${FTPDIR}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed > ${input}/truth_vcfs/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
curl ${FTPDIR}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz > ${input}/truth_vcfs/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
curl ${FTPDIR}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi > ${input}/truth_vcfs/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

curl ${FTPDIR}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed > ${input}/truth_vcfs/HG003_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
curl ${FTPDIR}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz > ${input}/truth_vcfs/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
curl ${FTPDIR}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi > ${input}/truth_vcfs/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

curl ${FTPDIR}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed > ${input}/truth_vcfs/HG004_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
curl ${FTPDIR}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz > ${input}/truth_vcfs/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
curl ${FTPDIR}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi > ${input}/truth_vcfs/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

mkdir -p ${input}/bams
HTTPDIR=https://storage.googleapis.com/deepvariant/case-study-testdata

curl ${HTTPDIR}/HG002.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam > ${input}/bams/HG002.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam
curl ${HTTPDIR}/HG002.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam.bai > ${input}/bams/HG002.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam.bai

curl ${HTTPDIR}/HG003.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam > ${input}/bams/HG003.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam
curl ${HTTPDIR}/HG003.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam.bai > ${input}/bams/HG003.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam.bai

curl ${HTTPDIR}/HG004.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam > ${input}/bams/HG004.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam
curl ${HTTPDIR}/HG004.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam.bai > ${input}/bams/HG004.novaseq.pcr-free.35x.dedup.grch38_no_alt.chr20.bam.bai