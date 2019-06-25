#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue,$strand);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Cwd;
use Cwd 'abs_path';
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"fqlist:s"=>\$fin,
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"wsh:s"=>\$wsh,
	"strand:s"=>\$strand,
	"queue:s"=>\$queue,
			) or &USAGE;
&USAGE unless ($fout and $fin);
$fin=abs_path($fin);
$ref=abs_path($ref);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
$wsh=abs_path($wsh);
$fout=abs_path($fout);
$strand||="RF";
$queue||="DNA";
open In,$fin;
open Out,">$fout/hisat.list";
while (<In>) {
	chomp;
	my ($id,$fq1,$fq2)=split/\s+/,$_;
	print Out "$id\tPE\t$fq1\t$fq2\n";
}
close In;
close Out;
open SH,">$wsh/hisat.sh";
my $hisat="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/Pipeline/03.lncRNA/bin/bin/hisat2.py";
if ($strand && $strand eq "FR") {
	print SH "cd $fout && python $hisat $ref/ref_index $fout/hisat.list -p 8 -s $strand \n";
}elsif ($strand && $strand eq "RF") {
	print SH "cd $fout && python $hisat $ref/ref_index $fout/hisat.list -p 8 -s $strand \n";
}else{
	print SH "cd $fout && python $hisat $ref/ref_index $fout/hisat.list -p 8 \n";
}
close SH;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=50G --CPU 8 $wsh/hisat.sh";
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

	eg: 
nohup perl /mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/Pipeline/03.lncRNA/bin/hisat.pl -fqlist fastq.list -ref ref/ -wsh work_sh -out 01.hisat-mapping &
	

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
