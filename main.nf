#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ============================================================
// CLINICAL IVD GERMLINE PIPELINE
// ============================================================

include { readSamplesheet; readBam }      from './modules/functions.nf'
include { dragmap_workflow }      from './subworkflows/mapping.nf' 
include { fastq_QC_workflow; mosdepth_workflow; multiqc_workflow }     from './subworkflows/qc.nf'
include { hc_workflow }           from './subworkflows/HC.nf'
include { deepvariant_workflow } from './subworkflows/deepvariant.nf'
include { manta_workflow }        from './subworkflows/manta.nf'
include {delly_workflow }         from './subworkflows/delly.nf'
include {cnvkit_workflow }         from './subworkflows/cnvkit.nf'
include { gCNV_workflow }         from './subworkflows/gCNV.nf'
include { annotation_workflow } from './subworkflows/annotation.nf'

def run_modes = params.run_mode?.split(',')*.trim()

workflow {

// 1. INPUT LAYER
    ch_fastqc_reports = Channel.empty()
    ch_mapping_stats  = Channel.empty()
    ch_mosdepth       = Channel.empty()
    ch_bam            = Channel.empty()

    if (params.input_type == 'fastq') {
        

            // --- STANDARD LOCAL FASTQ MODE ---
        ch_fq = readSamplesheet(params.samplesheet)
        ch_fq_qc = fastq_QC_workflow(ch_fq)

        filtered_fq = ch_fq_qc.fastq
        qc_results = ch_fq_qc.fastp
        ch_fastqc_reports = ch_fq_qc.fastqc

        mapping_results = dragmap_workflow(filtered_fq)

        // --- COMMON POST-MAPPING LAYER ---
        mosdepth_results = mosdepth_workflow(mapping_results.ch_bam)
        
        ch_bam           = mapping_results.ch_bam
        ch_mapping_stats = mapping_results.ch_metrics.collect()
        ch_mosdepth      = mosdepth_results.ch_mosdepth.collect()

        multiqc_input = Channel.empty()
            .mix(
                ch_fastqc_reports,
                ch_mapping_stats,
                ch_mosdepth,
                qc_results
            )
            .flatten()
            .collect()

        multiqc_workflow(multiqc_input)

    } else if (params.input_type == 'bam') {
        ch_bam = readBam(params.samplesheet)

        ch_mosdepth = mosdepth_workflow(ch_bam).ch_mosdepth.collect()
        multiqc_workflow(ch_mosdepth)
    }

    ch_final_vcf = Channel.empty()
    ch_final_tbi = Channel.empty()

    hc_results = null

    if ('HC' in run_modes) {
        
        hc_results = hc_workflow(ch_bam)

        if (params.annotate == true) {
            annotation_workflow(hc_results.ch_vcf, hc_results.ch_tbi)
        }
        
    }

    if ('DV' in run_modes) {

        dv_results = deepvariant_workflow(ch_bam)

        if (params.annotate == true) {
            annotation_workflow(dv_results.ch_vcf, dv_results.ch_tbi)
        }

    }
    
    if ('SV' in run_modes) {
        manta_workflow(ch_bam)
        delly_workflow(ch_bam)
        cnvkit_workflow(ch_bam)
    }

    if ('gCNV' in run_modes) {
        gCNV_workflow(ch_bam)
    }

}