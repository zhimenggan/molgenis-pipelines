#MOLGENIS walltime=23:59:00 mem=8gb nodes=1 ppn=2

### variables to help adding to database (have to use weave)
#string project
###
#string stage
#string checkStage

#string WORKDIR
#string projectDir
#string beagleDir
#string genotypedChrVcfGLFiltered
#string genotypedChrVcfShapeitInputPrefix
#string genotypedChrVcfShapeitInputPostfix
#string genotypedChrVcfBeagleGenotypeProbabilitiesFiltered
#string GLibVersion
#string ngsutilsVersion
#string zlibVersion
#string bzip2Version
#string GCCversion
#string tabixVersion
#string CHR
#string prepareGenFromBeagle4Version
#string beagleShapeitDir
#string genotypedChrVcfBeagleGenotypeProbabilities

echo "## "$(date)" Start $0"


${stage} tabix/${tabixVersion}
${stage} prepareGenFromBeagle4/${prepareGenFromBeagle4Version}
# Glib is also set as dependency of prepareGenFromBeagle4 but still needs to be loaded after
${stage} GLib/${GLibVersion}
${checkStage}

mkdir -p ${beagleShapeitDir}

# had to be gzipped again otherwise it will not read the last line
zcat ${genotypedChrVcfBeagleGenotypeProbabilitiesFiltered} > $TMPDIR/$(basename ${genotypedChrVcfBeagleGenotypeProbabilitiesFiltered%.gz})
gzip $TMPDIR/$(basename ${genotypedChrVcfBeagleGenotypeProbabilitiesFiltered%.gz})

#Run conversion script beagle vcf to .hap.gzeit format
prepareGenFromBeagle4 \
 --likelihoods ${genotypedChrVcfGLFiltered} \
 --posteriors $TMPDIR/$(basename ${genotypedChrVcfBeagleGenotypeProbabilitiesFiltered}) \
 --output ${genotypedChrVcfShapeitInputPrefix}${CHR}${genotypedChrVcfShapeitInputPostfix}

echo "returncode: $?";
# these output files are NOT gzipped, so rename them to filename without gz

cd ${beagleShapeitDir}
# want to have the base path, not full path in the md5sum file, so cd to output dir and md5sum the basepath
bname=$(basename ${genotypedChrVcfShapeitInputPrefix}${CHR}${genotypedChrVcfShapeitInputPostfix}.gen.gz)
md5sum ${bname} > ${bname}.md5
bname=$(basename ${genotypedChrVcfShapeitInputPrefix}${CHR}${genotypedChrVcfShapeitInputPostfix}.gen.sample)
md5sum ${bname} > ${bname}.md5
bname=$(basename ${genotypedChrVcfShapeitInputPrefix}${CHR}${genotypedChrVcfShapeitInputPostfix}.hap.gz)
md5sum ${bname} > ${bname}.md5
bname=$(basename ${genotypedChrVcfShapeitInputPrefix}${CHR}${genotypedChrVcfShapeitInputPostfix}.hap.sample)
md5sum ${bname} > ${bname}.md5
cd -
echo "succes moving files";

# Do additional unzipping, bgzipping and tabixing of posterior probabilities VCF to use it in next step
cd ${beagleDir}
gunzip ${genotypedChrVcfBeagleGenotypeProbabilities}.vcf.gz
bgzip ${genotypedChrVcfBeagleGenotypeProbabilities}.vcf
tabix ${genotypedChrVcfBeagleGenotypeProbabilities}.vcf.gz
#Generate checksums
bname=$(basename ${genotypedChrVcfBeagleGenotypeProbabilities}.vcf.gz)
md5sum ${bname} > ${bname}.md5
bname=$(basename ${genotypedChrVcfBeagleGenotypeProbabilities}.vcf.gz.tbi)
md5sum ${bname} > ${bname}.md5
cd -
echo "succes bgzipping, tabixing and moving VCF files";

echo "## "$(date)" ##  $0 Done "

