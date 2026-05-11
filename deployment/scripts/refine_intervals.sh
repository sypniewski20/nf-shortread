#!/usr/bin/env bash
set -euo pipefail

BROAD_INTERVALS=$1
ENCODE_BLACKLIST=$2
UCSC_SEGDUPS=$3
REF_DICT=$4

BROAD_MD5=1790be6605825971526fff7cb3232764
ENCODE_MD5=393688b4f06c9ce26165d47433dd8c37
UCSC_SEGDUPS_MD5=c04291127b3c7e0bdb88a82193c0f404

# Verify input integrity
echo "${BROAD_MD5}  ${BROAD_INTERVALS}"   | md5sum -c - || exit 1
echo "${ENCODE_MD5}  ${ENCODE_BLACKLIST}" | md5sum -c - || exit 1
echo "${UCSC_SEGDUPS_MD5}  ${UCSC_SEGDUPS}" | md5sum -c - || exit 1

BASENAME=$(basename ${BROAD_INTERVALS})
BASENAME="${BASENAME%.interval_list}"
OUTDIR=$5

# 1. Convert interval_list to BED
gatk IntervalListToBed \
  --INPUT  ${BROAD_INTERVALS} \
  --OUTPUT ${OUTDIR}/${BASENAME}.bed

# 2. Subtract ENCODE blacklist
bedtools subtract \
  -a ${OUTDIR}/${BASENAME}.bed \
  -b ${ENCODE_BLACKLIST} \
  > ${OUTDIR}/${BASENAME}.no_blacklist.bed

# 3. Subtract segdups (stream, preserve original gz)
zcat ${UCSC_SEGDUPS} \
  | awk 'BEGIN{OFS="\t"}{print $2,$3,$4}' \
  | bedtools sort -i - \
  | bedtools merge -i - \
  > ${OUTDIR}/segdups.hg38.bed

bedtools subtract \
  -a ${OUTDIR}/${BASENAME}.no_blacklist.bed \
  -b ${OUTDIR}/segdups.hg38.bed \
  > ${OUTDIR}/${BASENAME}.clean.bed

# 4. Convert back to interval_list
gatk BedToIntervalList \
  -I  ${OUTDIR}/${BASENAME}.clean.bed \
  -SD ${REF_DICT} \
  -O  ${OUTDIR}/${BASENAME}.clean.interval_list

echo "Done: ${OUTDIR}/${BASENAME}.clean.interval_list"