#MOLGENIS walltime=23:59:00 mem=12gb ppn=8

### variables to help adding to database (have to use weave)
#string sampleName
#string project
###
#string stage
#string checkStage

#string WORKDIR
#string projectDir
#string gatkVersion
#string dbsnpVcf
#string dbsnpVcfIdx
#string onekgGenomeFasta
#list mergeBqsrBam
#string mergedHaplotyperDir
#string mergedHaplotyperGvcf
#string mergedHaplotyperGvcfIdx
#string toolDir

echo "## "$(date)" Start $0"
echo "ID project-sampleName): ${project}-${sampleName}"

for file in "${mergeBqsrBam[@]}" "${dbsnpVcf}" "${dbsnpVcfIdx}" "${onekgGenomeFasta}"; do
#for file in "${mergeBqsrBam[@]}" "${mergeBqsrBai[@]}" "${dbsnpVcf}" "${dbsnpVcfIdx}" "${onekgGenomeFasta}"; do
	echo "getFile file='$file'"
	getFile $file
done

#Load gatk module
${stage} GATK/${gatkVersion}
${checkStage}

#sort unique and print like 'INPUT=file1.bam INPUT=file2.bam '
bams=($(printf '%s\n' "${mergeBqsrBam[@]}" | sort -u ))

inputs=$(printf ' -I %s ' $(printf '%s\n' ${bams[@]}))

mkdir -p ${mergedHaplotyperDir}

if java -Xmx12g -XX:ParallelGCThreads=8 -Djava.io.tmpdir=${mergedHaplotyperDir} -jar ${toolDir}GATK/${gatkVersion}/GenomeAnalysisTK.jar \
 -T HaplotypeCaller \
 -R ${onekgGenomeFasta} \
 --dbsnp ${dbsnpVcf}\
 $inputs \
 -dontUseSoftClippedBases \
 -stand_call_conf 10.0 \
 -stand_emit_conf 20.0 \
 -o ${mergedHaplotyperGvcf} \
 -variant_index_type LINEAR \
 -variant_index_parameter 128000 \
 --emitRefConfidence GVCF

then
 echo "returncode: $?"; 

 putFile ${mergedHaplotyperGvcf}
 putFile ${mergedHaplotyperGvcfIdx}
 echo "succes moving files";
else
 echo "returncode: $?";
 echo "fail";
fi

echo "## "$(date)" ##  $0 Done "
