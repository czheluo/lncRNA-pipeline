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
	"ref:s"=>\$ref,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
			) or &USAGE;
&USAGE unless ($fout);
my $diffanno ="$fout/09.diffanno";
mkdir $diffanno  if (!-d $diffanno);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
$diffanno=ABSOLUTE_DIR($diffanno);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open Out,">$wsh/09.diffanno.sh";
my $tool="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410";
my @files=glob("$fout/07.diffexp_mRNA/replicates_exp/*.diff.exp.xls");
foreach my $file (@files) {
	my $fln=basename($file);
	print Out "$tool de_go $ref/unigene_GO.list $fout/07.diffexp_mRNA/replicates_exp/$fln >$diffanno/$fln.go.log 2>&1 \n";
	print Out "$tool de_kegg $ref/unigene_pathway.txt $fout/07.diffexp_mRNA/replicates_exp/$fln >$diffanno/$fln.kegg.log 2>&1 \n";
}
close Out;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 4 $wsh/09.diffanno.sh";
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
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
