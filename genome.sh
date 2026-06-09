
# genome files are here:
/mnt/griffin/chrwhe/Pieris_napi-GCA_905475465.2/

# if you want to make a link to the genome in your local folder
ln -s /mnt/griffin/chrwhe/Pieris_napi-GCA_905475465.2/GCF_905475465.1_ilPieNapi1.2_genomic.renamed.fna .

# then have a look at the scaffold names
grep '>' GCF_905475465.1_ilPieNapi1.2_genomic.renamed.fna

# the first 10 scaffolds
head GCF_905475465.1_ilPieNapi1.2_genomic.renamed.fna

# stats about the genome
/data/programs/scripts/AsmQC GCF_905475465.1_ilPieNapi1.2_genomic.renamed.fna
-------------------------------
    AssemblyQC Result  
-------------------------------
Contigs Generated :           42
Maximum Contig Length : 14,821,532
Minimum Contig Length :    9,452
Average Contig Length : 7,599,688.3 ± 6,238,799.0
Median Contig Length :  11,089,836.0
Total Contigs Length :  319,186,907
Total Number of Non-ATGC Characters :      4,900
Percentage of Non-ATGC Characters :        0.002
Contigs >= 100 bp :           42
Contigs >= 200 bp :           42
Contigs >= 500 bp :           42
Contigs >= 1 Kbp :            42
Contigs >= 10 Kbp :           41
Contigs >= 1 Mbp :            27
N50 value :     13,068,865
Generated using /mnt/griffin/chrwhe/Pieris_napi-GCA_905475465.2/GCF_905475465.1_ilPieNapi1.2_genomic.renamed.fna



##############
# details
##############

# NCBI
https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/905/475/465/GCF_905475465.1_ilPieNapi1.2/

# if you want to download

wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/905/475/465/GCF_905475465.1_ilPieNapi1.2/GCF_905475465.1_ilPieNapi1.2_genomic.fna.gz
gunzip GCF_905475465.1_ilPieNapi1.2_genomic.fna.gz
# make an index
samtools faidx GCF_905475465.1_ilPieNapi1.2_genomic.fna


grep '>' GCF_905475465.1_ilPieNapi1.2_genomic.fna
>NC_062234.1 Pieris napi chromosome 1, ilPieNapi1.2, whole genome shotgun sequence
>NC_062235.1 Pieris napi chromosome 2, ilPieNapi1.2, whole genome shotgun sequence
>NC_062236.1 Pieris napi chromosome 3, ilPieNapi1.2, whole genome shotgun sequence
>NC_062237.1 Pieris napi chromosome 4, ilPieNapi1.2, whole genome shotgun sequence


# I have renamed the genome scaffolds
grep '>' /mnt/griffin/chrwhe/Pieris_napi-GCA_905475465.2/GCF_905475465.1_ilPieNapi1.2_genomic.renamed.fna
>1
>2
>3
>4

