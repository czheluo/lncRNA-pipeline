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
my $clus ="$fout/13.cluster_mRNA";
mkdir $clus if (!-d $clus);
$clus=ABSOLUTE_DIR($clus);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open In,"<$fout/01.hisat_mapping/bam.list";
my $cluster="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410 cluster";
open SH,">$wsh/13.cluster.sh";
print SH "cat $fout/07.diffexp_mRNA/replicates_exp/*.DE.list >$fout/13.cluster_mRNA/list && sort $fout/13.cluster_mRNA/list|uniq >$fout/13.cluster_mRNA/DE.list && ";
print SH "perl $Bin/bin/get.matrix.pl -l $fout/13.cluster_mRNA/DE.list -t $fout/05.cm_lnc_mRNA/lncRNA.fpkm.xls -o $fout/13.cluster_mRNA/DE.matrix && ";
print SH "cp $Bin/bin/heatmap.r $fout/13.cluster_mRNA && cd $fout/13.cluster_mRNA && $cluster $fout/13.cluster_mRNA/DE.matrix -type n heatmap \n";
close SH;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G  $wsh/13.cluster_mRNA.sh";
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
