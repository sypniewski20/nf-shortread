include {
    DEEP_VARIANT;
    GLNEXUS;
    NORM_MULTISAMPLE;
    DV_EXTRACT_GT
} from '../modules/deepvariant.nf'

workflow deepvariant_workflow {
    take:
        ch_bam    
    main:

        ch_fasta= Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")

        ])

        DEEP_VARIANT(ch_bam, ch_fasta)

        ch_gvcf = DEEP_VARIANT.out.gvcf
                                .map{sample, gvcf, tbi -> gvcf}
                                .collect()
        ch_gvcf_tbi = DEEP_VARIANT.out.gvcf
                                    .map{sample, gvcf, tbi -> tbi}
                                    .collect()

        GLNEXUS(ch_gvcf, ch_gvcf_tbi)

        NORM_MULTISAMPLE(GLNEXUS.out, ch_fasta)

        DV_EXTRACT_GT(NORM_MULTISAMPLE.out.vcf, NORM_MULTISAMPLE.out.tbi)

    emit:
        ch_vcf = NORM_MULTISAMPLE.out.vcf
        ch_tbi = NORM_MULTISAMPLE.out.tbi
}