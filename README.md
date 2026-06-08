# *Pieris napi* accessory pangenome from Pool-seq across a European cline

Recovering, assembling, annotating, and comparing **non-reference (accessory) genomic
content** from population Pool-seq data sampled across a European cline, taking a
pangenomic rather than SNP-centric view of among-population variation.

> **Question:** How much does accessory genomic content — sequence *not* present in the
> single UK reference genome — vary among populations, and is that variation structured
> along the cline?

---

## Background

We have Pool-seq datasets (~20 individuals per pool) sampled across Europe — primarily
**Sweden**, plus **Switzerland (CHF)** and **Spain (ES)**. These were previously mapped to
a single UK reference to call SNPs and study allele-frequency variation among populations.

This project takes a **pangenomics perspective**: instead of asking how shared positions
vary, we ask what sequence each population carries that the reference *lacks*. For each
pool we identify reads that do **not** map to the reference, assemble them into contigs,
and treat that as the candidate accessory content of the sampled population. We then build
a shared catalogue, quantify it across populations, and ask whether it is functional
(genes, gene families, transposable elements) and clinally structured.

Because Pool-seq yields **population allele frequencies** rather than individual genotypes,
the natural unit is the *frequency* of an accessory element in a population — which plugs
directly into the existing cline framework.

## Study system & data

| Item | Value |
|------|-------|
| Organism | *Pieris napi* (green-veined white butterfly) |
| Reference | `GCF_905475465.1` — assembly `ilPieNapi1.2` (UK, chromosome-level, Darwin Tree of Life) |
| Data | Illumina paired-end Pool-seq, ~500 bp insert, ~20 individuals/pool |
| Sampling | Sweden (multiple pools) + Switzerland (CHF) + Spain (ES) |
| Compute | Local environment |

## Approach (high level)

```
Raw Pool-seq reads (per population)
        │  QC + trim (fastp)
        ▼
Map to UK reference (bwa-mem2)
        │
        ├── mapped reads ──► existing SNP / allele-freq work
        │
        └── extract NON-reference reads
                 (both-mate-unmapped + one-mate-mapped pairs; soft-clips audited separately)
                 │  read-level taxonomy screen (Kraken2): host / endosymbiont / microbiome
                 ▼
        De novo CO-ASSEMBLY of all pools (MEGAHIT; metaSPAdes as QC)
                 │  validate: drop contigs aligning to reference (minimap2)
                 │  decontaminate: BlobTools + Kraken2
                 ▼
        Non-reference "pan-accessory" contig catalogue
                 │
                 ├── Annotation: DIAMOND vs NR · eggNOG/InterProScan · RepeatModeler/Masker (TEs)
                 │
                 └── Quantify across cline: map each pool back → breadth/depth
                          → element × population presence/frequency matrix
                          → PCA · clustering · clinal regression · enrichment
```

A full rationale, a graphical workflow, the bioinformatic decision table, and caveats are
in **[`accessory_pangenome_proposal.html`](accessory_pangenome_proposal.html)**.

## Key design decisions

- **Don't use `samtools view -f 4` alone.** Unmapped-only filtering discards the most
  informative reads. We keep both-mate-unmapped pairs *and* one-mate-mapped pairs (the
  latter anchor accessory insertions to reference coordinates), and treat large soft-clips
  separately.
- **Co-assembly, not per-population assembly**, for the shared catalogue → one common
  coordinate system and a single comparable matrix. Per-population assemblies are kept as a
  QC / population-private-contig check.
- **Metagenome-aware assembler** (a pool of 20 individuals is a multi-haplotype mixture,
  not an isolate). MEGAHIT is the local-compute default; metaSPAdes on subsets for quality.
- **Two mandatory contig filters:** realign to the reference (drop reference-similar
  contigs) and decontaminate (BlobTools + Kraken2).
- **Separate transposable elements from novel genes** — in Lepidoptera much accessory
  content is TE-derived; conflating the two would misstate the result.
- **Presence = breadth of coverage; frequency = normalised depth**, with depth normalised
  by per-pool sequencing effort and pool size.
- **Endosymbionts are an in-scope side result** — per-population *Wolbachia*/symbiont
  read fraction (and strain where depth allows) is reported, not silently discarded.

## Caveats to keep in mind

- All "accessory" content is defined **relative to the UK reference**; reference distance
  can inflate apparent novelty in more-diverged populations.
- Pooled polymorphism fragments assemblies → a long tail of short, hard-to-annotate
  contigs; length/coverage thresholds matter.
- Coverage thresholds effectively *define* presence/absence — they must be set
  transparently and tested for sensitivity.
- Contamination and symbionts can masquerade as accessory novelty — decontamination is
  not optional.
- Uneven sampling/depth across the cline must be normalised before any "region X has more
  accessory content" claim.

## Planned tools

`fastp` · `FastQC`/`MultiQC` · `bwa-mem2` · `samtools` · `Kraken2` · `MEGAHIT` /
`metaSPAdes` · `minimap2` / `nucmer` · `BlobTools` · `DIAMOND` (vs NCBI NR) ·
`eggNOG-mapper` / `InterProScan` · `RepeatModeler` / `RepeatMasker` · R/Python for
matrices, ordination, and clinal modelling. Pipeline to be wrapped in Snakemake or
Nextflow for reproducibility.

## Scope / status

- **v1 (current):** recover & quantify accessory content → the element × population matrix.
- **Phase 2:** annotation + clinal modelling + symbiont track.

**Status:** proposal under discussion (v0.2). See the HTML proposal for open items —
notably per-region pool counts & depths, local hardware specs (RAM/disk → NR vs reduced
annotation DB), and whether a closer (Swedish) *P. napi* assembly is available as an
optional second reference.

## Repository contents

| File | Description |
|------|-------------|
| `accessory_pangenome_proposal.html` | Full analysis proposal: rationale, graphical workflow, decision table, caveats |
| `README.md` | This file |

## License / contact

Internal research project (intern-led). Contact the PI before reuse.
