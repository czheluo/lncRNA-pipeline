#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	"ref:s"=>\$ref,
			) or &USAGE;
&USAGE unless ($fout);
my $snp =ABSOLUTE_DIR("$fout/11.snp");
mkdir $snp if (!-d $snp);
mkdir $wsh if (!-d $wsh);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open In,"<$fout/01.hisat_mapping/bam.list";
open out,">$wsh/11.snp.sh";
my $fileter="/mnt/ilustre/app/rna/sequence_tool/samtools-0.1.19/bcftools/vcfutils.pl";
my $gtft="/mnt/ilustre/users/bingxu.liu/workspace/laiting_tools/annovar/gtfToGenePred";
my $var="/mnt/ilustre/users/caiping.shi/software/annovar/convert2annovar.pl";
my $ann="/mnt/ilustre/users/caiping.shi/software/annovar/annotate_variation.pl";
while (<In>) {
	chomp;
	my ($id,$bam)=split/\s+/,$_;
	print out "mkdir -p $snp/$id && cd $snp/$id && samtools mpileup -q 10 -Q 20 -u -D -C 50 -f $ref/ref.fa $bam | bcftools view -vcg - > $snp/$id/$id.vcf && ";
	print out " perl $fileter varFilter -d 5 -Q 20 -1 1e-100 -3 1e-100 -4 1e-100 $snp/$id/$id.vcf > $snp/$id/$id.vcf.filter && ";
	print out "$gtft -genePredExt $ref/ref_genome.gtf $snp/$id/$id.genes_refGene.tmp.txt && awk \'\{print 1\"\t\"\$0\}\' $snp/$id/$i.genes_refGene.tmp.txt  > $snp/$id/$id\_refGene.txt && ";
	print out "mkdir -p $snp/$id/exampledb && mv $snp/$id/$id.genes_refGene.tmp.txt $snp/$id/$id\_refGene.txt $snp/$id/$id\_refGeneMrna.fa $snp/$id/exampledb/ ";
	#print out ""
	print out "perl $var -format vcf4 $snp/$id/$id.vcf.filter > $snp/$id/$id.avinput && ";
	print out "perl $ann -buildver $snp/$id/$id -dbtype refGene $snp/$id/$id.avinput $snp/$id/exampledb && ";
	print out "less $snp/$id/$id.avinput.variant_function|awk -F \"\t\" \'OFS=\"\t\"\{print \$3\,\$4\,\$5\,\$6,\$7,\$1,\$2\}\' > $snp/$id/$id.avinput.variant_function.new && ";
	print out "awk -F\'\t\' \'BEGIN\{print \"CHROM\tSTART\tEND\tREF\tALT\tANNO\tGENE(in or nearby)\tMUT_type\tMUT_info\"\}NR==FNR\{a[\$4\"\t\"\$5\"\t\"\$6]=\$2\"\t\"\$3; next\}\{if(\$1\"\t\"\$2\"\t\"\$3 in a)\{print \$0\"\t\"a[\$1\"\t\"\$2\"\t\"\$3]\}else\{\print \$0\"\t\.\t\.\"}\}\' $snp/$id/$id.avinput.exonic_variant_function $snp/$id/$id.avinput.variant_function.new > $snp/$id/$id.snp.anno.xls";
	print out "more $snp/$id/$id.snp.anno.xls | cut -f 6 \| sort | uniq \-c | awk \'\{print \$2\"\t\"\$1\}\' > $snp/$id/$id.snp.anno.xls.stat \n";
}
close In;
close out;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G  $wsh/11.snp.sh";
`$job`;
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}
sub USAGE {#
        my $usage=<<"USAGE";
Contact:        meng.luo\@majorbio.com;
Script:			$Script
Description:

	eg: perl -int filename -out filename 
	

Usage:
  Options:
	"help|?" =>\&USAGE,
	"fqlist:s"=>\$fin,
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"wsh:s"=>\$wsh,
	"strand:s"=>\$strand,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
