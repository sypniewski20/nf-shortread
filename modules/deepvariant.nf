process DEEP_VARIANT {
    publishDir "${params.outfolder}/${params.runID}/deep_variant", mode: 'copy', overwrite: true
    tag "${sample}"
    label 'deepvariant'
    label 'xlarge'

    input:
        tuple val(sample), path(bam), path(bai)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}_deepvariant.vcf.gz"), path("${sample}_deepvariant.vcf.gz.tbi"), emit: vcf
        tuple val(sample), path("${sample}_deepvariant.gvcf.gz"), path("${sample}_deepvariant.gvcf.gz.tbi"), emit: gvcf
    script:
        """
        /opt/deepvariant/bin/run_deepvariant \
        --model_type ${params.seq_type} \
        --ref ${fasta} \
        --reads ${bam} \
        --output_vcf ${sample}_deepvariant.vcf.gz \
        --output_gvcf ${sample}_deepvariant.gvcf.gz \
        --num_shards ${task.cpus}
        """
}

process GLNEXUS {
    publishDir "${params.outfolder}/${params.runID}/deep_variant", mode: 'copy', overwrite: true
    label 'glnexus'
    label 'large'
	input:
		path(gvcf)
		path(gvcf_tbi)
	output:
		path("glnexus_deepvariant.bcf")
	script:
		"""

		glnexus_cli \
		--threads ${task.cpus} \
		--config DeepVariant${params.seq_type} \
		${vcf} > glnexus_deepvariant.bcf

		"""

}

process NORM_MULTISAMPLE {
    publishDir "${params.outfolder}/${params.runID}/deep_variant", mode: 'copy', overwrite: true
    label 'gatk'
    label 'large'
	input:
		path(bcf)
        tuple path(fasta), path(fai)
	output:
		path("norm_${bcf.simpleName}.vcf.gz"), emit: vcf
        path("norm_${bcf.simpleName}.vcf.gz.tbi"), emit: tbi
	script:
		"""

        bcftools norm -f ${fasta} -m -any ${bcf} -Ou | \
        bcftools +fill-tags -Ou -- -t AC,AF,AN | \
        bcftools sort -Oz -o norm_${bcf.simpleName}.vcf.gz

        tabix -p vcf norm_${bcf.simpleName}.vcf.gz

		"""

}

process DV_EXTRACT_GT {
    label 'tiny'
    label 'gatk'
    publishDir "${params.outfolder}/${params.runID}/deep_variant", mode: 'copy', overwrite: true

    input:
        path(vcf)
        path(tbi)
    output:
        path("${vcf.simpleName}_gt.table"), emit: ch_gt_table
        path("${vcf.simpleName}_gt.table.md5"), emit: ch_gt_table_md5
    script:
    """
    gatk VariantsToTable \
        -V ${vcf} \
        -F CHROM -F POS -F ID -F REF -F ALT -GF GT -GF DP \
        -O ${vcf.simpleName}_gt.table

    md5sum ${vcf.simpleName}_gt.table > ${vcf.simpleName}_gt.table.md5
    """
}