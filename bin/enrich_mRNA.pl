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
my $merich ="$fout/08.enrich_mRNA";
mkdir $merich  if (!-d $merich);
$merich=ABSOLUTE_DIR($merich);
mkdir $wsh if (!-d $wsh);
$fout=ABSOLUTE_DIR($fout);
$ref=ABSOLUTE_DIR($ref);
$wsh=ABSOLUTE_DIR($wsh);
open Out,">$wsh/08.mRNA_enrich.sh";
my $tool="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410";
print Out "cd $merich && cp $fout/07.diffexp_mRNA/replicates_exp/*.DE.list $merich && cp $ref/all.gene.list && $tool enrich $merich  $ref/unigene_GO.list $ref/unigene_pathway.txt out";
close Out;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=5G --CPU 2 $wsh/08.mRNA_enrich.sh";
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
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"ref:s"=>$ref,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
