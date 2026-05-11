include { DRAGMAP_BAM; MARK_DUPLICATES } from '../modules/mapping.nf'

// ==========================
// MULTIQC
// ==========================
workflow dragmap_workflow {

    take:
        ch_fq
    main:

        ch_fasta = Channel.value([
        file(params.fasta).parent,
        file(params.fasta),
        file("${params.fasta}.fai")
        ])

        DRAGMAP_BAM(ch_fq, ch_fasta)
        MARK_DUPLICATES(DRAGMAP_BAM.out)
    
    emit:

        // standardised outputs
        ch_bam       = MARK_DUPLICATES.out.ch_bam
        ch_metrics  = MARK_DUPLICATES.out.ch_metrics
        ch_md5       = MARK_DUPLICATES.out.ch_md5
}