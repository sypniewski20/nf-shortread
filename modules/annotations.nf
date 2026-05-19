process SPLICE_AI {
    publishDir "${params.outfolder}/${params.runID}/spliceAI/", mode: 'copy', overwrite: true
    label 'spliceAI'
	label 'mem_36GB'
	label 'core_36'
	input:
		path(vcf)
        path(tbi)
        tuple path(fasta), path(fai)

	output:
		tuple path("${vcf.baseName}_spliceAI.vcf.gz"), path("${vcf.baseName}_spliceAI.vcf.gz.tbi")
	script:
      def genome = (fasta.name =~ /(?i)GRCh38|hg38|Homo_sapiens_assembly38/) ? "grch38" : "grch37"
      def distance = params.spliceai_distance ?: 50
      
		"""

        spliceai -I ${vcf} \
                 -O ${vcf.baseName}_spliceAI.vcf \
                 -R ${fasta} \
                 -A ${genome} \
                 -D ${distance}


        bgzip ${vcf.baseName}_spliceAI.vcf
        tabix -p vcf ${vcf.baseName}_spliceAI.vcf.gz

		"""

}

process VEP_SNV {
    publishDir "${params.outfolder}/${params.runID}/vep/", mode: 'copy', overwrite: true
    label 'vep'
	label 'mem_36GB'
	label 'core_36'
	input:
		path(vcf)
        path(tbi)
        tuple path(spliceai_vcf), path(spliceai_tbi)
        tuple path(fasta), path(fai)
	output:
		path("${vcf.baseName}.vep.tsv.gz")
	script:
      def genome = (fasta.name =~ /(?i)GRCh38|hg38|Homo_sapiens_assembly38/) ? "GRCh38" : "GRCh37"
		"""

        vep \
        --cache \
        --dir_cache ${params.vep_cache} \
        --species homo_sapiens \
        --assembly ${genome} \
        --buffer_size 10000000 \
        -i ${vcf} \
        -o "${vcf.baseName}.vep.tsv.gz" \
        --format vcf \
        --compress_output bgzip \
        --fasta ${fasta} \
        --tab \
        --fork ${task.cpus} \
        --force_overwrite \
        --hgvs \
        --hgvsg \
        --symbol \
        --numbers \
        --domains \
        --protein \
        --biotype \
        --uniprot \
        --variant_class \
        --custom file=${params.clinvar},short_name=ClinVar,format=vcf,type=exact,coords=0,fields=CLNSIG%CLNREVSTAT%CLNDN%MC%CLNDISDB%CLNDISDBINC \
        --custom file=${spliceai_vcf},short_name=SpliceAI,format=vcf,type=exact,coords=0,fields=ALLELE%SYMBOL%DS_AG%DS_AL%DS_DG%DS_DL \
        --plugin dbNSFP,${params.dbNSFP},MetaRNN,AlphaMissense,MANE,VEP_canonical,gnomAD4.1_joint_NFE_AF,gnomAD4.1_joint_AF \
        --offline \
	    --cache_version ${params.cache_version} \
        --flag_pick \
        --pick_order mane_select,mane_plus_clinical,canonical,tsl,biotype,rank
        
		"""

}

process FILTER_VEP {
    publishDir "${params.outfolder}/${params.runID}/vep/", mode: 'copy', overwrite: true
    label 'vep'
	label 'mem_36GB'
	label 'core_36'
	input:
		path(tsv)
	output:
		path("${tsv.baseName}.vep.filtered.tsv.gz")
	script:
		"""

        filter_vep \
            -i ${tsv} \
            --format tab \
            --filter "PICK == 1" \
            -o - | bgzip -c > ${tsv.baseName}.vep.filtered.tsv.gz
        
		"""

}