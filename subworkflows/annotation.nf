include {
    VEP_GERMLINE_SNV; SPLICE_AI; FILTER_VEP
} from '../modules/annotations.nf'

workflow annotation_workflow {
    take:
        ch_vcf
        ch_tbi
    main:
        ch_fasta = Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")
            ])


        SPLICE_AI(ch_vcf,
                  ch_tbi,
                  ch_fasta)

        VEP_GERMLINE_SNV(ch_vcf, 
                ch_tbi,
                SPLICE_AI.out,
                ch_fasta
                )
        
        FILTER_VEP(VEP_GERMLINE_SNV.out)

}