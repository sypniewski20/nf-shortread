 include { EXCLUSION_BED;
            DELLY_CALL;
            DELLY_SITE_MERGE;
            DELLY_GENOTYPE;
            DELLY_FILTER;
            DELLY_TO_VCF;
            DELLY_TO_TSV } from '../modules/delly.nf'

workflow delly_workflow {
    take:
        ch_bam
    
    main:
        ch_fasta = Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")
            ])
        
        bed = Channel.value(file(params.bed))

        EXCLUSION_BED(bed, ch_fasta)

        DELLY_CALL(
            ch_bam,
            ch_fasta,
            EXCLUSION_BED.out
        )

        // collect all BCFs and their indices separately but in stable order
        bcfs_ch = DELLY_CALL.out.bcf.map { sample, bcf, csi -> bcf }.collect()
        csis_ch = DELLY_CALL.out.bcf.map { sample, bcf, csi -> csi }.collect()

        DELLY_SITE_MERGE(bcfs_ch, csis_ch)

        DELLY_GENOTYPE(
            ch_bam,
            ch_fasta,
            EXCLUSION_BED.out,
            DELLY_SITE_MERGE.out.sites
        )

        gt_bcfs_ch = DELLY_GENOTYPE.out.bcf.map { sample, bcf, csi -> bcf }.collect()
        gt_csis_ch = DELLY_GENOTYPE.out.bcf.map { sample, bcf, csi -> csi }.collect()

        DELLY_FILTER(gt_bcfs_ch, gt_csis_ch)

        DELLY_TO_VCF(
            DELLY_FILTER.out.bcf,
            DELLY_FILTER.out.csi
        )

        DELLY_TO_TSV(DELLY_TO_VCF.out.vcf)

}