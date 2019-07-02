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
			) or &USAGE;
&USAGE unless ($fout);
my $pcar ="$fout/10.pca";
mkdir $pcar if (!-d $pcar);
mkdir $wsh if (!-d $wsh);
$pcar=ABSOLUTE_DIR($pcar);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open Out,">$wsh/10.pca.sh";
my $cor="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline_v16/script/sample_group.pearson.r";
my $pca="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline_v16/script/sample_pca_group.r";
print Out "Rscript $cor $fout/05.cm_lnc_mRNA/mRNA.fpkm.xls  $pcar/cor.pdf $fout/group.list \n";
print Out "Rscript $pca $fout/05.cm_lnc_mRNA/mRNA.fpkm.xls  $pcar/pca $fout/group.list";
close Out;
#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G  $wsh/10.pca.sh";
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
