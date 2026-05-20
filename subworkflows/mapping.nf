include { DRAGMAP_BAM; 
          BWA_BAM;
          MARK_DUPLICATES } from '../modules/mapping.nf'

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

        if (params.mapper == 'dragmap') {
            ch_bam = DRAGMAP_BAM(ch_fq, ch_fasta)
        } else if (params.mapper == 'bwa') {
            ch_bam = BWA_BAM(ch_fq, ch_fasta)
        } else {
            error "Unsupported mapper specified: ${params.mapper}. Supported mappers are 'dragmap' and 'bwa'."
        }

        MARK_DUPLICATES(ch_bam)
    
    emit:

        // standardised outputs
        ch_bam       = MARK_DUPLICATES.out.ch_bam
        ch_metrics  = MARK_DUPLICATES.out.ch_metrics
        ch_md5       = MARK_DUPLICATES.out.ch_md5
}