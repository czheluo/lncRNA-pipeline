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
	"queue:s"=>\$queue,
			) or &USAGE;
&USAGE unless ($fout);
my $diflnc ="$fout/07.diffexp_lnc";
mkdir $diflnc  if (!-d $diflnc);
$diflnc=ABSOLUTE_DIR($diflnc);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open Out,">$wsh/07.lnc_diffexp.sh";
my $tool="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410";
print Out "cp $fout/05.cm_lnc_mRNA/{lncRNA.count.xls,lncRNA.fpkm.xls} $diflnc && cd $diflnc && $tool edgeR -groupfile $fout/group.list -count lncRNA.count.xls -fpkm lncRNA.fpkm.xls \n";
close Out;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 4 $wsh/07.lnc_diffexp.sh";
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
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
