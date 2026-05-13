def readSamplesheet(samplesheet) {
    return Channel
        .fromPath(samplesheet)
        .splitCsv(header: true, strip: true)
        .map { row ->

            // --- validate required fields ---
            if (!row.SM) error "Missing SM in samplesheet row: ${row}"
            if (!row.R1) error "Missing R1 in samplesheet row: ${row}"
            if (!row.R2) error "Missing R2 in samplesheet row: ${row}"

            def sm = row.SM
            def lb = row.LB ?: "lib_${sm}"
            def id = row.ID ?: "${sm}_${lb}"    
            def pl = row.PL ?: "ILLUMINA"       
            def pu = row.PU ?: "${id}.unknown"  

            tuple(
                sm, id, lb, pl, pu,
                file(row.R1, checkIfExists: true),
                file(row.R2, checkIfExists: true)
            )
        }
}

def readBam(bam_sheet) {

    Channel
        .fromPath(bam_sheet)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            tuple(
                row.sampleID,
                file(row.bam, checkIfExists: true),
                file(row.bai, checkIfExists: true)
            )
        }
}