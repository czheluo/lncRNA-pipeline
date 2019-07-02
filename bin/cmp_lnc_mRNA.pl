#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue,$strand);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"ref:s"=>\$ref,
	"queue:s"=>\$queue,
			) or &USAGE;
&USAGE unless ($fout);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
my $cm ="$fout/05.cm_lnc_mRNA";
mkdir $cm if (!-d $cm);
mkdir $wsh if (!-d $wsh);
open LM,">$wsh/05.cmp_lm.sh";
print LM "cd $cm && python $Bin/bin/filter_gtf_with_tid.py -g $fout/02.stringtie.first/gffcomp.annotated.gtf -t $fout/03.lncRNA/known.lncRNA.list -o $cm/known_lncRNA.gtf && cat $cm/known_lncRNA.gtf $fout/03.lncRNA/novel/filter4.gtf >$cm/lncRNA.gtf";
print LM " && gtf2bed $cm/lncRNA.gtf > $cm/lncRNA.bed && ";
print LM "perl $Bin/bin/tabletools_select.pl -i $fout/03.lncRNA/lncRNA.list -t $fout/transcript_fpkm.xls -n 1 >$cm/lncRNA.fpkm.xls && ";
# get mRNA.list and gtf files
print LM "cd $cm && python $Bin/bin/filter_gtf_with_tid.py -g $fout/02.stringtie.first/gffcomp.annotated.gtf -t $fout/03.lncRNA/lncRNA.list -o $cm/mRNA.gtf -v ";
print LM "&& gtf2bed $cm/mRNA.gtf > $cm/mRNA.bed && ";
print LM "perl $Bin/bin/get.mRNA.list.pl -gtf $cm/mRNA.gtf -out mRNA.list && ";
print LM "perl $Bin/bin/tabletools_select.pl -i $cm/mRNA.list -t $fout/gene_fpkm.xls -n 1 >$cm/mRNA.fpkm.xls && ";
my $bar= "/mnt/ilustre/users/zhuo.wen/scripts/lncRNA/cmp/new/new_lncRNA_VS_mRNA_exon_number_and_length_density_barplot.pl ";
print LM "perl $bar $cm/mRNA.bed $cm/lncRNA.bed && ";

#compare expression 
my $cmp="/mnt/ilustre/users/zhuo.wen/scripts/lncRNA/cmp/new/new_lncRNA_VS_mRNA_fpkm_violin.pl";
print LM "perl $cmp $cm/mRNA.fpkm.xls $cm/lncRNA.fpkm.xls && ";
##orf 
print LM "gffread -g $ref/ref.fa $cm/lncRNA.gtf -w  $cm/lncRNA.fa && ";
print LM "gffread -g $ref/ref.fa $cm/mRNA.gtf -w  $cm/mRNA.fa && ";
my $orf ="/mnt/ilustre/users/caiping.shi/script/lncRNA/extract_longorf.pl";
print LM "perl $orf --input $cm/lncRNA.fa > $cm/lncRNA.orf && ";
print LM "perl $orf --input $cm/mRNA.fa > $cm/mRNA.orf && ";
my $orfbar="/mnt/ilustre/users/zhuo.wen/scripts/lncRNA/cmp/new/new_lncRNA_VS_mRNA_orf_boxplot.pl";
print LM "perl $orfbar $cm/mRNA.orf $cm/lncRNA.orf ";
close LM;
#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G  $wsh/05.cmp_lm.sh";
#`$job`;
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
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
