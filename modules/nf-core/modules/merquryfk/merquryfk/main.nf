process MERQURYFK_MERQURYFK {
    tag "$meta.id"
    label 'process_medium'

    if (params.enable_conda) {
        error "Conda environments cannot be used when using the FastK tool. Please use docker or singularity containers."
    }
    container 'ghcr.io/nbisweden/fastk_genescopefk_merquryfk:1.1'

    input:
    tuple val(meta), path(fastk_hist), path(fastk_ktab), path(assembly)

    output:
    tuple val(meta), path("${prefix}.completeness.stats")    , emit: stats
    tuple val(meta), path("${prefix}.*_only.bed")            , emit: bed
    tuple val(meta), path("${prefix}.*.qv")                  , emit: assembly_qv
    tuple val(meta), path("${prefix}.*.spectra-cn.fl.png")   , emit: spectra_cn_fl_png,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.fl.pdf")   , emit: spectra_cn_fl_pdf,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.ln.png")   , emit: spectra_cn_ln_png,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.ln.pdf")   , emit: spectra_cn_ln_pdf,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.st.png")   , emit: spectra_cn_st_png,  optional: true
    tuple val(meta), path("${prefix}.*.spectra-cn.st.pdf")   , emit: spectra_cn_st_pdf,  optional: true
    tuple val(meta), path("${prefix}.qv")                    , emit: qv
    tuple val(meta), path("${prefix}.spectra-asm.fl.png")    , emit: spectra_asm_fl_png, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.fl.pdf")    , emit: spectra_asm_fl_pdf, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.ln.png")    , emit: spectra_asm_ln_png, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.ln.pdf")    , emit: spectra_asm_ln_pdf, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.st.png")    , emit: spectra_asm_st_png, optional: true
    tuple val(meta), path("${prefix}.spectra-asm.st.pdf")    , emit: spectra_asm_st_pdf, optional: true
    tuple val(meta), path("${prefix}.false_duplications.tsv"), emit: false_duplications
    tuple val(meta), path("${prefix}.cni.gz")                , emit: cn_histogram
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def FASTK_VERSION = 'f18a4e6d2207539f7b84461daebc54530a9559b0'
    def MERQURY_VERSION = '8ae344092df5dcaf83cfb7f90f662597a9b1fc61'
    """
    MerquryFK \\
        $args \\
        -T$task.cpus \\
        ${fastk_ktab.find{ it.toString().endsWith(".ktab") }} \\
        $assembly \\
        $prefix

    mv .cni ${prefix}.cni
    awk -v asm_ploidy=${assembly instanceof List ? assembly.size() : 1} \\
        -f $projectDir/bin/false_duplications.awk ${prefix}.cni \\
        > ${prefix}.false_duplications.tsv
    gzip ${prefix}.cni

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastk: $FASTK_VERSION
        merquryfk: $MERQURY_VERSION
        r: \$( R --version | sed '1!d; s/.*version //; s/ .*//' )
    END_VERSIONS
    """
}
