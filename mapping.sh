
# data
column -t /mnt/griffin/Pierinae_genomes/poolseq_data/pool_metadata.tsv
pop                                                         code      haploid_size
Pieris_napi.CHF.13.StMoritz.Field.Thorax.24                 C13stmor  48
Pieris_napi.ESP.12.Aiguamolls.Field.Thorax.24               E12aigua  48
Pieris_napi.SWE.14.Skane_Kullaberg.Field_females.Thorax.24  S14skanF  48
Pieris_napi.SWE.14.Skane_Kullaberg.Field.Thorax.24_Males    S14skanM  48
Pieris_napi.SWE.15.Lulea_Avan.Field.Thorax.30               S15lulea  60
Pieris_napi.SWE.15.Stockholm_SU.Field_earlyAug.Abdomen.30   S15stoEA  60
Pieris_napi.SWE.15.Stockholm_SU.Field_lateAug.Abdomen.36    S15stoLA  72
Pieris_napi.SWE.15.Sundsvall.Field.Thorax.29                S15sunds  58
Pieris_napi.SWE.15.Umeå.Field.Thorax.30                     S15umea   60
Pieris_napi.SWE.2015.Stockholm_SU.Field_midJuly.Abdomen.35  S15stoMJ  70




# make a mapping folder
mkdir mapping
cd mapping

# get a copy of the genome here
ln -s ../../Pieris_napi-GCA_905475465.2/GCF_905475465.1_ilPieNapi1.2_genomic.fna .
# sanity check
ls # should see it (if in red, its does not have a good path)

###########
# index
###########
# rename reference to your reference and rootname to what you want your final bamfile to have as a suffix.
reference=GCF_905475465.1_ilPieNapi1.2_genomic.fna
/data/programs/bwa-mem2-2.3_x64-linux/bwa-mem2 index $reference

###########
# map
###########
suffix=ilPieNapi1.2
# here using "--dryrun" to get preview of commands that will be sent to the cores
sed 1d ../CTQ_Read_Data/pool_metadata.tsv | parallel --dryrun --colsep "\t" -j 3 "/data/programs/bwa-mem2-2.3_x64-linux/bwa-mem2 mem -t 15 $reference ../CTQ_Read_Data/{1}_1.ctq.fq.gz ../CTQ_Read_Data/{1}_2.ctq.fq.gz | samtools view -Sb -@6 - -o {2}_v_$suffix.bam"

# always good to test one, to see if it works: passed
# /mnt/griffin/kaltun/software/bwa-mem2-2.0pre2_x64-linux/bwa-mem2 mem -t 15 GCF_905475465.1_ilPieNapi1.2_genomic.fna /mnt/griffin/Pierinae_genomes/poolseq_data/Pieris_napi.SWE.2015.Stockholm_SU.Field_midJuly.Abdomen.35_1.ctq.fq.gz /mnt/griffin/Pierinae_genomes/poolseq_data/Pieris_napi.SWE.2015.Stockholm_SU.Field_midJuly.Abdomen.35_2.ctq.fq.gz | samtools view -Sb -@6 - -o S15stoMJ_v_ilPieNapi1.2.bam

# run all by using same parallel command above, but without the "--dryrun"


###########
# sort and index bamfiles
###########
# see what this does
ls *bam | xargs -n1 basename -s "_v_ilPieNapi1.2.bam" 
# larger command
ls *bam | xargs -n1 basename -s "_v_ilPieNapi1.2.bam"| parallel --dryrun "/data/programs/samtools-1.9/samtools sort -@ 5 -o {}_v_ilPieNapi1.2.srt.bam {}_v_ilPieNapi1.2.bam; /data/programs/samtools-1.9/samtools index -@ 5 {}_v_ilPieNapi1.2.srt.bam"
# test, works
/data/programs/samtools-1.9/samtools sort -@ 5 -o C13stmor_v_ilPieNapi1.2.srt.bam C13stmor_v_ilPieNapi1.2.bam; /data/programs/samtools-1.9/samtools index -@ 5 C13stmor_v_ilPieNapi1.2.srt.bam

# remove unsorted bams
rm *2.bam

# list of the mapped, sorted, indexed
C13stmor_v_ilPieNapi1.2.srt.bam
E12aigua_v_ilPieNapi1.2.srt.bam
S14skanF_v_ilPieNapi1.2.srt.bam
S14skanM_v_ilPieNapi1.2.srt.bam
S15lulea_v_ilPieNapi1.2.srt.bam
S15stoEA_v_ilPieNapi1.2.srt.bam
S15stoLA_v_ilPieNapi1.2.srt.bam
S15stoMJ_v_ilPieNapi1.2.srt.bam
S15sunds_v_ilPieNapi1.2.srt.bam
S15umea_v_ilPieNapi1.2.srt.bam
