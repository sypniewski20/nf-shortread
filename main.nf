#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ============================================================
// CLINICAL IVD GERMLINE PIPELINE
// ============================================================

include { Read_samplesheet; Read_bam }      from './modules/functions.nf'
include { dragmap_workflow }      from './subworkflows/mapping.nf' 
include { fastq_QC_workflow; mosdepth_workflow; multiqc_workflow }     from './subworkflows/qc.nf'
include { hc_workflow }           from './subworkflows/HC.nf'
include { manta_workflow }        from './subworkflows/manta.nf'
include {delly_workflow }         from './subworkflows/delly.nf'
include {cnvkit_workflow }         from './subworkflows/cnvkit.nf'
include { gCNV_workflow }         from './subworkflows/gCNV.nf'
include { germline_calibration_workflow }  from './subworkflows/calibration.nf'
include { annotation_workflow } from './subworkflows/annotation.nf'

def run_modes = params.run_mode?.split(',')*.trim()

workflow {

// 1. INPUT LAYER
    ch_fastqc_reports = Channel.empty()
    ch_mapping_stats  = Channel.empty()
    ch_mosdepth       = Channel.empty()
    ch_bam            = Channel.empty()

    if (params.input_type == 'fastq') {
        
        // --- NEW LOGIC FOR CALIBRATION / STREAMING MODE ---
        if ('calibration' in run_modes) {
            // 1. Parse the NIST-style samplesheet (URLs + MD5 as RGID)
            ch_raw_stream = Read_samplesheet(params.samplesheet)

            // 4. Align grouped chunks into single Sample BAMs
            mapping_results = dragmap_workflow(ch_raw_stream)

        } else {
            // --- STANDARD LOCAL FASTQ MODE ---
            ch_fq = Read_samplesheet(params.samplesheet)
            ch_fq_qc = fastq_QC_workflow(ch_fq)

            filtered_fq = ch_fq_qc.fastq
            qc_results = ch_fq_qc.fastp
            ch_fastqc_reports = ch_fq_qc.fastqc

            mapping_results = dragmap_workflow(filtered_fq)
        }

        // --- COMMON POST-MAPPING LAYER ---
        mosdepth_results = mosdepth_workflow(mapping_results.ch_bam)
        
        ch_bam           = mapping_results.ch_bam
        ch_mapping_stats = mapping_results.ch_metrics.collect()
        ch_mosdepth      = mosdepth_results.ch_mosdepth.collect()

        multiqc_input = Channel.empty()
            .mix(
                ch_fastqc_reports,
                ch_mapping_stats,
                ch_mosdepth
            )
            .flatten()
            .collect()

        multiqc_workflow(multiqc_input)

    } else if (params.input_type == 'bam') {
        ch_bam = Read_bam(params.samplesheet)
    }

    ch_final_vcf = Channel.empty()
    ch_final_tbi = Channel.empty()

    hc_results = null

    if ('SNV' in run_modes || 'calibration' in run_modes) {
        
        hc_results = hc_workflow(ch_bam)
        ch_final_vcf = hc_results.hc_vcf
        ch_final_tbi = hc_results.hc_tbi

        annotation_workflow(ch_final_vcf, ch_final_tbi)
        
    }

    bams_count = ch_bam.map { sample, bam, bai -> bam }.count()
    
    if ('SV' in run_modes) {
        manta_workflow(ch_bam)
        delly_workflow(ch_bam)
        cnvkit_workflow(ch_bam)
    
        // Gate ch_bam: only emit if count >= 40, otherwise emit empty
        ch_bam_for_gcnv = ch_bam
            .combine(bams_count)
            .filter { sample, bam, bai, count ->
                if (count < 40) {
                    log.warn("Skipping gCNV: samples < 40 (got ${count})")
                    return false
                }
                return true
            }
            .map { sample, bam, bai, count -> [sample, bam, bai] }
    
        gCNV_workflow(ch_bam_for_gcnv)
    }

    if ('calibration' in run_modes) {

        germline_calibration_workflow(hc_results.hc_vcf)

    }

}