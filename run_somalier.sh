#!/bin/sh -x
############################
# Pipeline Somalier
# Evelin Gonzalez
#
# Date: 2022-11-03
# Descripción: A partir de archivos fastq situados en un directorio --input-dir, este pipeline
# calcula el parentesco entre las muestra utilizando SOMALIER
# EXAMPLE: Comando: sh run_somlier.sh --input--dir ${INDIR} --threads ${THREAD} --step ${STEP} --output--dir ${OUTDIR}
############################


#### LOAD INPUT DATA
### SI OCURRE ALGUN ERROR DENTRO EL PIPELINE, ESTE SE DETIENE.

hg19_fa="/home/administrador/Documentos/BD_TumorSec/hg19.fa"
sites_hg19="/home/administrador/Documentos/WorkSpace_2022/040922_Somalier_DECIPHERD-UDD-102_UDD-105/sites.hg19.vcf.gz"

#PIPELINE_TUMORSEC="/home/egonzalez/workSpace/PipelineTumorSec
LOG="0_logs"
MAPPING="1_mapping"
SOMALIER_EXTRACT="2_somalier_extract"
SOMALIER_RELATE="3_somalier_relate"

abort()
{
    echo >&3 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&3
    exit 1
}
trap 'abort' 0
#abort on error
set -e
#set -o errexit

### PARAMETROS DE ENTRADAS A TRAVES DE LINEA DE COMANDOS
PARAMS=""
#echo "1:$#"
while (( "$#" )); do
  case "$1" in
    -i|--input--dir)
      shift&&INDIR=$1
      #echo "1:$#"
      ;;
    -o|--output--dir)
      shift&&OUTDIR=$1
      #echo "1:$#"
      ;;
    -t|--threads)
       shift&&THREAD=$1
       #echo "3:$#"
      ;;
    -s|--step)
       shift&&STEP=$1
       #echo "5:$#"
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&3
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

if [ -z "$OUTDIR" ]; then
	echo ""
	echo "Enter the output directory:"
	read OUTDIR
fi
if [ -z "$INDIR" ]; then
	echo ""
	echo "Enter the FASTQ directory:"
	read INDIR
fi

if [ -z "$STEP" ]; then
	echo ""
	echo "What steps do you want to execute?"
	echo "1. Mapping"
	echo "2. Somalier extract"
	echo "3. Somalier relate"
	echo "Example, all pipeline -> 1-3, only mapping -> 1, from mapping to Somalier extract -> 1-2"
	read STEP
fi

if [ -z "$THREAD" ]; then
	echo ""
	echo "Threads:"
	read THREAD
fi

## agregar log por paso. (funcion), cambiar entrada de pasos. agregar comandos al log. poner tiempo por paso ejecutado.
echo ""
echo "############################################"
echo "     Welcome to the somalier pipeline      "
echo "############################################"
echo ""
echo "== Extract informative sites, evaluate relatedness, and perform quality-control  =="

#set -xv
#trap read debug  

#### función de creación de log por cada paso del pipeline
#0 - stdin
#1 - stdout
#2 - stderr

exec 3>&1 4>&2

### funcion que revise que esta todo bien antes de correr el siguiente paso.
# en caso que no sea asi¡, debe enviar un mensaje de error.

step(){

	STEP=$1
 	START=$(echo $STEP | awk -F "-" '{print $1}')
	END=$(echo $STEP | awk -F "-" '{print $2}')

	if [ -z "$END" ]; then
		END=$START
	fi
	
	if (( $START > $END )); then
		echo "Error: The ${START} must by less than ${END} in step parameter ${STEP}" >&3
		exit
	fi
}

start_log(){
	n_step=$1
	string_step=$2
	
	if [ ! -d "${OUTDIR}/${LOG}" ]; then 
		mkdir "${OUTDIR}/${LOG}"
	fi
	
	log_output="${OUTDIR}/${LOG}/${n_step}_log_${string_step}.out"
	echo "$(date) : step ${n_step} - start - ${string_step}" >&3
	echo "$(date) : step ${n_step} - logfile - ${log_output}" >&3
	exec 1>$log_output 2>&1
}

end_log(){
	n_step=$1
	string_step=$2
	echo "$(date) : step ${n_step} - finished - ${string_step}" >&3
	echo "##############"
	echo "DONE-somalier"
	echo "##############"
}

check_log(){

	n_step=$1
	string_step=$2
	log_output="${OUTDIR}/${LOG}/${n_step}_log_${string_step}.out"

	## Si existe el archivo, se debe buscar el string "DONE-somalier" en el log
	if [ ! -f "${log_output}" ]; then
           echo "$(date) : ## Error ## - file ${log_output} not found"
           exit
    fi
	check=$(grep "DONE-somalier" $log_output | wc -l)
	
	if (($check == 0)); then
		echo "$(date): ## Error ## - Step ${n_step} ${string_step} with error, it don't finished." >&3
		echo "$(date): ## Error ## - Check log : ${log_output}"
		exit
	fi 
}

get_samples(){
	cd "${INDIR}"
	echo $PWD
	#GET SAMPLES ID FROM FASTQ FILES
	SAMPLES=$(ls *R1_*.fastq.gz| awk '{split($0,array,"_")} {print array[1]}')
}

step $STEP

#################################
#								#
#    MAPPING OF READS (BWA)     #
#################################

if (( $START <= 1 )) && (( $END >= 1 )); then

start_log 1 "mapping"
get_samples

	if [ ! -d "${INDIR}/${MAPPING}" ]; then
                mkdir "${INDIR}/${MAPPING}"
        else
                echo "The ${INDIR}/${MAPPING} directory alredy exists"
    fi
    
	for sample in $SAMPLES
	do	
		echo "Running bwa for $sample"
        mapping_sam="${OUTDIR}/${MAPPING}/${sample}.sam"
  		mapping_bam="${OUTDIR}/${MAPPING}/${sample}.bam"
		fastq_R1="${INDIR}/${sample}_R1.fastq.gz"
		fastq_R2="${INDIR}/${sample}_R2.fastq.gz"
		sorted_bam="${OUTDIR}/${MAPPING}/${sample}.sorted.bam"
		
		echo "time nice -n 11  bwa mem \
		-t $THREAD \
		-R \"@RG\tID:${sample}\tSM:${sample}\tPL:Illumina\tPU:unit1\tLB:lib1\" \
		$hg19_fa \
		$fastq_R1 \
		$fastq_R2 > $mapping_sam"
		
		#work in parallel, quitar el echo
		time nice -n 11  bwa mem \
		-t $THREAD \
		-R "@RG\tID:${sample}\tSM:${sample}\tPL:Illumina\tPU:unit1\tLB:lib1" \
		$hg19_fa \
		$fastq_R1 \
		$fastq_R2 > $mapping_sam
		           
		#work in parallel
        samtools view -@ $THREAD -bS $mapping_sam > $mapping_bam
		samtools sort -@ $THREAD -o $sorted_bam -O BAM $mapping_bam
		#don't work in parallel
		samtools index $sorted_bam
		rm $mapping_sam
		rm $mapping_bam
	done
	
end_log 1 "mapping"

fi

#################################
#								#
#  EXTRACT SITIES (SOMALIER)    #
#################################

if (( $START <= 2 )) && (( $END >= 2 )); then

check_log 1 "mapping"
start_log 2 "somalier-extract"
get_samples

        for sample in $SAMPLES
	    do
	    DIR_SOM="${OUTDIR}/${SOMALIER_EXTRACT}"
	    echo "Running somalier extract for $sample"
        somalier extract \
        -d $DIR_SOM \
        --sites $sites_hg19 \
        -f $hg19_fa
        done

end_log 2 "somalier-extract"

fi

#################################
#								#
#  EXTRACT SITIES (SOMALIER)    #
#################################

if (( $START <= 3 )) && (( $END >= 3 )); then

check_log 2 "somalier-extract"
start_log 3 "somalier-relate" 


	    DIR_SOM="${OUTDIR}/${SOMALIER_EXTRACT}/*.somalier"
	    DIR_RESULTS="${OUTDIR}/${SOMALIER_RELATE}"
	    echo "Running somalier relate"
	    somalier relate \
	    --infer -i $DIR_SOM \
	    -d $DIR_RESULTS

end_log 3 "somalier-relate"

fi


trap : 0

echo >&3 '
*********************
*** DONE-somalier *** 
*********************
'


