# NCBI
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/905/475/465/GCF_905475465.1_ilPieNapi1.2/

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/905/475/465/GCF_905475465.1_ilPieNapi1.2/GCF_905475465.1_ilPieNapi1.2_genomic.fna.gz
gunzip GCF_905475465.1_ilPieNapi1.2_genomic.fna.gz
samtools faidx GCF_905475465.1_ilPieNapi1.2_genomic.fna


# Bedtools needs an index of our scaffolds and their lengths:
/data/programs/exonerate-2.2.0/src/util/fastalength GCF_905475465.1_ilPieNapi1.2_genomic.fna | awk 'BEGIN {FS=" "}{print $2,"\t",$1}' > GCF_905475465.1_ilPieNapi1.2.bedgenome

head /mnt/griffin/chrwhe/Pieris_napi-GCA_905475465.2/GCF_905475465.1_ilPieNapi1.2.bedgenome
NC_062234.1      14821532
NC_062235.1      14218065
NC_062236.1      13690485
NC_062237.1      13663050
NC_062238.1      13535449


