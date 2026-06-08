# Example commands

Minimal, copy-pasteable invocations for the main steps of the accessory-pangenome
workflow. These are **illustrative one-liners**, not the production pipeline — they show
the basic shape of each tool. Real runs will be parameterised and wrapped in
Snakemake/Nextflow.

Throughout, placeholders look like `SAMPLE`, and we assume paired reads
`SAMPLE_R1.fastq.gz` / `SAMPLE_R2.fastq.gz` and the UK reference `ilPieNapi1.2.fasta`
(`GCF_905475465.1`).

> Tip: set `THREADS=8` (or whatever your machine has) and reuse it below.

```bash
THREADS=8
REF=ilPieNapi1.2.fasta
```

---

## 1. Read QC and trimming — `fastp`

```bash
fastp \
  -i SAMPLE_R1.fastq.gz -I SAMPLE_R2.fastq.gz \
  -o SAMPLE_R1.trim.fastq.gz -O SAMPLE_R2.trim.fastq.gz \
  --thread $THREADS \
  --html SAMPLE.fastp.html --json SAMPLE.fastp.json
```

Optional QC summary across all samples:

```bash
fastqc SAMPLE_R1.trim.fastq.gz SAMPLE_R2.trim.fastq.gz
multiqc .          # aggregates all fastp/fastqc reports in the folder
```

---

## 2. Index the reference and map — `bwa-mem2`

```bash
# one-time index
bwa-mem2 index $REF

# map, sort, and index the BAM
bwa-mem2 mem -t $THREADS $REF SAMPLE_R1.trim.fastq.gz SAMPLE_R2.trim.fastq.gz \
  | samtools sort -@ $THREADS -o SAMPLE.sorted.bam -
samtools index SAMPLE.sorted.bam
```

---

## 3. Extract the non-reference reads — `samtools`

Keep reads that don't confidently map, **with mate pairing intact**. We grab two classes:
both mates unmapped, and pairs where one mate is unmapped.

```bash
# (a) both mates unmapped
samtools view -b -f 12 -F 256 SAMPLE.sorted.bam > SAMPLE.both_unmapped.bam

# (b) one mate mapped, one unmapped (two complementary flag combos)
samtools view -b -f 68  -F 264 SAMPLE.sorted.bam > SAMPLE.mate1_unmapped.bam
samtools view -b -f 132 -F 264 SAMPLE.sorted.bam > SAMPLE.mate2_unmapped.bam

# merge the non-reference reads
samtools merge -f SAMPLE.nonref.bam \
  SAMPLE.both_unmapped.bam SAMPLE.mate1_unmapped.bam SAMPLE.mate2_unmapped.bam
```

Convert back to paired FASTQ (re-pair first with `collate`):

```bash
samtools collate -@ $THREADS -O SAMPLE.nonref.bam \
  | samtools fastq -1 SAMPLE.nonref_R1.fastq.gz -2 SAMPLE.nonref_R2.fastq.gz \
                   -0 /dev/null -s /dev/null -n
```

> The flag values are the part to get right (see `samtools flags` to decode them);
> this is where the definition of "accessory" actually lives.

---

## 4. Read-level taxonomy screen — `Kraken2`

```bash
kraken2 --db kraken2_db --threads $THREADS --paired \
  --report SAMPLE.kraken.report --output SAMPLE.kraken.out \
  SAMPLE.nonref_R1.fastq.gz SAMPLE.nonref_R2.fastq.gz
```

The `.report` gives the host / endosymbiont (*Wolbachia*) / microbiome breakdown per pool.

---

## 5. De novo co-assembly — `MEGAHIT` (and `metaSPAdes` for QC)

Co-assemble all pools together (comma-separate the per-pool files):

```bash
megahit \
  -1 POP1.nonref_R1.fastq.gz,POP2.nonref_R1.fastq.gz,POP3.nonref_R1.fastq.gz \
  -2 POP1.nonref_R2.fastq.gz,POP2.nonref_R2.fastq.gz,POP3.nonref_R2.fastq.gz \
  -t $THREADS -o coassembly_megahit
# contigs -> coassembly_megahit/final.contigs.fa
```

Single-pool quality check with metaSPAdes (more memory-hungry):

```bash
metaspades.py \
  -1 POP1.nonref_R1.fastq.gz -2 POP1.nonref_R2.fastq.gz \
  -t $THREADS -o POP1_metaspades
```

---

## 6. Validate: drop contigs that match the reference — `minimap2`

```bash
minimap2 -x asm5 $REF coassembly_megahit/final.contigs.fa > contigs_vs_ref.paf
```

Contigs that align well to the reference are **not** accessory and get filtered out
(downstream by a coverage/identity cutoff on the PAF).

---

## 7. Decontaminate / inspect — `BlobTools`

```bash
# map reads back to contigs to get coverage for the blob plot
minimap2 -ax sr coassembly_megahit/final.contigs.fa \
  POP1.nonref_R1.fastq.gz POP1.nonref_R2.fastq.gz \
  | samtools sort -@ $THREADS -o cov.bam
samtools index cov.bam

blobtools create -i coassembly_megahit/final.contigs.fa -b cov.bam \
  -t contigs_vs_nr.hits -o blob_out
blobtools plot -i blob_out.blobDB.json
```

GC × coverage × taxonomy plot separates host contigs from contaminants/symbionts.

---

## 8. Annotate vs NCBI NR — `DIAMOND`

```bash
# one-time: build the DIAMOND database from NR (large download)
diamond makedb --in nr.gz -d nr

# search contigs (translated) against NR
diamond blastx -d nr -q accessory_contigs.fa \
  -o accessory_contigs.nr.tsv --threads $THREADS \
  --outfmt 6 qseqid sseqid pident length evalue stitle \
  --max-target-seqs 5 --evalue 1e-5
```

> If NR is too large locally, point `--in` at a smaller arthropod/Lepidoptera RefSeq or
> UniRef set instead.

Functional + domain annotation:

```bash
emapper.py -i accessory_contigs.fa --itype metagenome \
  -o accessory --cpu $THREADS                 # eggNOG-mapper

# or, for Pfam/GO domains on predicted proteins:
interproscan.sh -i accessory_proteins.faa -f tsv -goterms
```

---

## 9. Repeat / TE annotation — `RepeatModeler` + `RepeatMasker`

```bash
BuildDatabase -name pnapi_acc accessory_contigs.fa
RepeatModeler -database pnapi_acc -threads $THREADS

RepeatMasker -lib pnapi_acc-families.fa -pa $THREADS \
  -dir repeatmasker_out accessory_contigs.fa
```

Lets us separate TE-derived accessory content from candidate novel genes.

---

## 10. Quantify across the cline — map each pool back

```bash
bwa-mem2 index accessory_contigs.fa

for POP in POP1 POP2 POP3; do
  bwa-mem2 mem -t $THREADS accessory_contigs.fa \
    ${POP}.nonref_R1.fastq.gz ${POP}.nonref_R2.fastq.gz \
    | samtools sort -@ $THREADS -o ${POP}.vs_acc.bam
  samtools index ${POP}.vs_acc.bam
  # per-contig breadth (coverage %) and mean depth
  samtools coverage ${POP}.vs_acc.bam > ${POP}.coverage.tsv
done
```

Combining the per-population `coverage.tsv` files gives the
**element × population presence/frequency matrix** (breadth → presence, normalised depth →
frequency), which then goes into PCA / clustering / clinal regression in R or Python.

---

## Decoding SAM flags

If the flag numbers in step 3 are unfamiliar, this prints what any flag means:

```bash
samtools flags 12     # PAIRED,UNMAP,MUNMAP  -> both mates unmapped
samtools flags 68     # PAIRED,UNMAP,READ1
samtools flags 132    # PAIRED,UNMAP,READ2
```
