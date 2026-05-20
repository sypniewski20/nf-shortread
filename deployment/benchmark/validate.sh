#!/bin/bash
set -eo pipefail

DEPLOYMENT_DIR=$1

mkdir -p ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/validation/

for i in HG002 HG003 HG004; do \
	singularity run  \
	${DEPLOYMENT_DIR}/singularity/sif/happi.sif \
	/opt/hap.py/bin/hap.py \
	${DEPLOYMENT_DIR}/benchmark/truth_vcfs/${i}_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
	${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/test_run/deep_variant/${i}_deepvariant.vcf.gz \
	-f ${DEPLOYMENT_DIR}/benchmark/truth_vcfs/${i}_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
	-r ${DEPLOYMENT_DIR}/reference/fasta/Homo_sapiens_assembly38.fasta \
	-o ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/validation/${i}_happy.output \
	--engine=vcfeval \
	--pass-only \
	-l chr20
done