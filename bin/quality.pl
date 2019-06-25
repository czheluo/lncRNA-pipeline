#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($bam,$fout,$gtf);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"bam:s"=>\$bam,
	"out:s"=>\$fout,
	"bed:s"=>\$gtf,
			) or &USAGE;
&USAGE unless ($fout);

$bam=ABSOLUTE_DIR($bam);
$fout=ABSOLUTE_DIR($fout);
$gtf=ABSOLUTE_DIR($gtf);
open In,$bam;
my $qul="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/RNAseq_ToolBox_v1410";
open SH,">$fout/qul.sh";
while (<In>) {
	chomp;
	my ($samid,$bams)=split/\s+/,$_;
	print SH "$qul rand $fout/$samid/$samid $bams $gtf \n";
	print SH "$qul dupl $fout/$samid/$samid $bams \n";
	print SH "$qul satur $fout/$samid/$samid $gtf  $bams \n";
}
close In;
close SH;
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
	"bam:s"=>\$bam,
	"out:s"=>\$fout,
	"bed:s"=>\$gtf,
	-h         Help

USAGE
        print $usage;
        exit;
}
