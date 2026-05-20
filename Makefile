SINGULARITY ?= singularity
GSUTIL      ?= gsutil
WGET		?= wget
R           ?= Rscript

# ── Scripts ──────────────────────────────────────────────────────────────────────
RSCRIPT = Rscript

# ── Dirs ──────────────────────────────────────────────────────────────────────
DEPLOYMENT_DIR := deployment
REF_DIR    := ${DEPLOYMENT_DIR}/reference
FASTA_DIR  := $(REF_DIR)/fasta
ADD_RESOURCES    := $(REF_DIR)/additional_resources
BENCHMARK_DIR := ${DEPLOYMENT_DIR}/benchmark

# ── Manifests ─────────────────────────────────────────────────────────────────
FASTA_MANIFEST := ${DEPLOYMENT_DIR}/manifests/fasta_manifest.csv

# ── Images ────────────────────────────────────────────────────────────────────

CORE_SIF  := ${DEPLOYMENT_DIR}/singularity/sif/core.sif
QC_SIF    := ${DEPLOYMENT_DIR}/singularity/sif/qc.sif
HAPPY_SIF := ${DEPLOYMENT_DIR}/singularity/sif/happi.sif
MANTA_SIF := ${DEPLOYMENT_DIR}/singularity/sif/manta.sif
DELLY_SIF := ${DEPLOYMENT_DIR}/singularity/sif/delly.sif
CNVKIT_SIF := ${DEPLOYMENT_DIR}/singularity/sif/cnvkit.sif
VEP_SIF := ${DEPLOYMENT_DIR}/singularity/sif/vep115.sif
STR_SIF := ${DEPLOYMENT_DIR}/singularity/sif/str.sif
SPLICEAI_SIF := deploment/singularity/sif/spliceai.sif
DEEP_VARIANT_SIF := ${DEPLOYMENT_DIR}/singularity/sif/deepvariant.sif
GLNEXUS_SIF := ${DEPLOYMENT_DIR}/singularity/sif/glnexus.sif

HAPPY_DOCKER := docker://mgibio/hap.py:v0.3.12
DEEP_VARIANT_DOCKER := docker://google/deepvariant:1.5.0

# ── Fasta ───────────────────────────────────────────────────────

FASTA_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta \
FAI_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.fai \
ANN_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.ann \
AMB_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.amb \
BWT_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.bwt \
STR_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.str \

# ── Additional Resources ───────────────────────────────────────────────────────
PLOIDY_PRIORS := gs://gatk-sv-resources-public/hg38/v0/sv-resources/resources/v1/hg38.contig_ploidy_priors_homo_sapiens.tsv
PON_1K_GENOMES := gs://gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz
BROAD_INTERVALS := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/wgs_calling_regions.hg38.interval_list
ENCODE_BLACKLIST := https://www.encodeproject.org/files/ENCFF356LFX/@@download/ENCFF356LFX.bed.gz
UCSC_SEGDUPS := https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/genomicSuperDups.txt.gz

########################################################

.PHONY: all setup containers fasta add_resources benchmark_download run_benchmark

all: setup data

setup: containers fasta add_resources

benchmark: benchmark_download run_benchmark

# ── Containers ────────────────────────────────────────────────────────────────
containers: $(CORE_SIF) $(QC_SIF) $(HAPPY_SIF) $(MANTA_SIF) $(DEEP_VARIANT_SIF) $(GLNEXUS_SIF) $(VEP_SIF)

$(CORE_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/core.def

$(QC_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/qc.def

$(HAPPY_SIF):
	$(SINGULARITY) build --disable-cache $@ $(HAPPY_DOCKER)
 
$(MANTA_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/manta.def

$(DELLY_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/delly.def

$(CNVKIT_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/cnvkit.def

$(VEP_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/vep115.def

$(STR_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/str.def

$(SPLICEAI_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/spliceai.def

$(DEEP_VARIANT_SIF):
	$(SINGULARITY) build --disable-cache $@ $(DEEP_VARIANT_DOCKER)

$(GLNEXUS_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/glnexus.def



# ── References ────────────────────────────────────────────────────────────────

fasta:
	$(WGET) -P ${FASTA_DIR} ${FASTA_URL}
	$(WGET) -P ${FASTA_DIR} ${FAI_URL}
	$(WGET) -P ${FASTA_DIR} ${ANN_URL}
	$(WGET) -P ${FASTA_DIR} ${AMB_URL}
	$(WGET) -P ${FASTA_DIR} ${BWT_URL}
	$(WGET) -P ${FASTA_DIR} ${STR_URL}
	
	# Build the hash table for the reference FASTA file
	$(SINGULARITY) run $(CORE_SIF) dragen-os --build-hash-table true \
											 --ht-reference ${FASTA_DIR}/*.fasta  \
											 --output-directory ${FASTA_DIR}

add_resources:
	$(GSUTIL) cp ${PLOIDY_PRIORS} ${ADD_RESOURCES}/
	$(GSUTIL) cp ${PON_1K_GENOMES} ${ADD_RESOURCES}/
	$(WGET) -P ${ADD_RESOURCES} ${BROAD_INTERVALS}
	$(WGET) -P ${ADD_RESOURCES} ${ENCODE_BLACKLIST}
	$(WGET) -P ${ADD_RESOURCES} ${UCSC_SEGDUPS}

	# Refine intervals

	$(SINGULARITY) run $(CORE_SIF) ${DEPLOYMENT_DIR}/scripts/./refine_intervals.sh \
															$(ADD_RESOURCES)/wgs_calling_regions.hg38.interval_list \
															$(ADD_RESOURCES)/ENCFF356LFX.bed.gz \
															$(ADD_RESOURCES)/genomicSuperDups.txt.gz \
															$(FASTA_DIR)/*.dict \
															$(ADD_RESOURCES)


benchmark_download:
	bash ${DEPLOYMENT_DIR}/scripts/GiAB_download.sh $(BENCHMARK_DIR)

run_benchmark:
	nextflow run main.nf \
		--input_type bam \
		--seq_type WGS \
		--run_mode DV \
		-profile singularity \
		--singularity_path ${DEPLOYMENT_DIR}/singularity/sif \
		--samplesheet ${DEPLOYMENT_DIR}/benchmark/benchmark_manifest.csv \
		--outfolder ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results \
		--runID test_run \
		-resume \
		-w ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/work \
		--seq_type WGS \
		--fasta ${DEPLOYMENT_DIR}/reference/fasta/Homo_sapiens_assembly38.fasta \
		--bed ${DEPLOYMENT_DIR}/reference/fasta/wgs_calling_regions.hg38.interval_list \
		--annotate false

validate:
	bash ${DEPLOYMENT_DIR}/benchmark/validate.sh ${DEPLOYMENT_DIR}

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	rm -rf ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results reference logs singularity/*.sif