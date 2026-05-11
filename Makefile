SINGULARITY ?= singularity
GSUTIL      ?= gsutil
WGET		?= wget
R           ?= Rscript

# ── Scripts ──────────────────────────────────────────────────────────────────────
RSCRIPT = Rscript

# ── Dirs ──────────────────────────────────────────────────────────────────────
DEPLOYMENT_DIR :=deployment
REF_DIR    := ${DEPLOYMENT_DIR}/reference
STRAT_DIR  := $(REF_DIR)/giab_stratifications
TRUTH_DIR  := $(REF_DIR)/truth
READS_DIR  := $(REF_DIR)/reads
FASTA_DIR  := $(REF_DIR)/fasta
ADD_RESOURCES    := $(REF_DIR)/additional_resources

# ── Manifests ─────────────────────────────────────────────────────────────────
STRAT_MANIFEST := ${DEPLOYMENT_DIR}/manifests/giab_strat_manifest.csv
TRUTH_MANIFEST := ${DEPLOYMENT_DIR}/manifests/truth_manifest.csv
READS_MANIFEST := ${DEPLOYMENT_DIR}/manifests/reads_manifest.csv
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

HAPPY_DOCKER := docker://mgibio/hap.py:v0.3.12

# ── Additional Resources ───────────────────────────────────────────────────────
PLOIDY_PRIORS := gs://gatk-sv-resources-public/hg38/v0/sv-resources/resources/v1/hg38.contig_ploidy_priors_homo_sapiens.tsv
PON_1K_GENOMES := gs://gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz
BROAD_INTERVALS := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/wgs_calling_regions.hg38.interval_list
ENCODE_BLACKLIST := https://www.encodeproject.org/files/ENCFF356LFX/@@download/ENCFF356LFX.bed.gz
UCSC_SEGDUPS := https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/genomicSuperDups.txt.gz

########################################################

.PHONY: all setup containers \
        strat truth fasta \
        validate clean data

all: setup data

setup: containers strat truth fasta add_resources

# ── Containers ────────────────────────────────────────────────────────────────
containers: $(CORE_SIF) $(QC_SIF) $(HAPPY_SIF) $(MANTA_SIF)

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

# ── References ────────────────────────────────────────────────────────────────
strat:
	$(RSCRIPT) scripts/download_and_verify.R --manifest $(STRAT_MANIFEST) --dir $(STRAT_DIR) --snapshot_dir $(STRAT_DIR)

truth:
	$(RSCRIPT) scripts/download_and_verify.R --manifest $(TRUTH_MANIFEST) --dir $(TRUTH_DIR) --snapshot_dir $(TRUTH_DIR)

fasta:
	$(RSCRIPT) ${DEPLOYMENT_DIR}/scripts/download_and_verify.R --manifest $(FASTA_MANIFEST) --dir $(FASTA_DIR) --snapshot_dir $(FASTA_DIR)

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


# ── Reads (manual step — too large for default pipeline) ─────────────────────
data:
	${DEPLOYMENT_DIR}/scripts/ashkenazim_trio_download.sh ${READS_DIR}

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	rm -rf $(OUTPUT_DIR) reference logs singularity/*.sif