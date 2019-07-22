#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue,$step,$stop);
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
	"step:s"=>\$step,
	"stop:s"=>\$stop,
			) or &USAGE;
&USAGE unless ($fout);
$step||=1;
$stop||=-1;
$ref=ABSOLUTE_DIR($ref);
mkdir $fout if (!-d $fout);
$fout=ABSOLUTE_DIR($fout);
my $rsem="$fout/rsem";
$fin ="$fout/01.hisat-mapping/bam.list";
mkdir $rsem if (!-d $rsem);
$rsem=ABSOLUTE_DIR($rsem);
mkdir $wsh if (!-d $wsh);
$wsh=ABSOLUTE_DIR($wsh);
my $rse="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/Pipeline/bin/rsem.sh";
my $matrix="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/Pipeline/bin/abundance_estimates_to_matrix.pl";
if ($step == 1) {
	open In,$fin;
	open SH,">$wsh/rsem1.sh";
	print SH "cd $rsem && rsem-prepare-reference  --gtf $ref/ref_genome.gtf $ref/ref.fa $rsem/rsem.gene --bowtie2 ";
	close SH;
	#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G $wsh/rs1.sh";
	#`$job`;
	$step++ if ($step ne $stop);
}

if ($step == 2) {
	open In,"<$fout/01.hisat-mapping/hisat.list";
	open SH,">$wsh/rsem2.sh";
	while (<In>) {
		chomp;
		my ($id,undef,$fq1,$fq2)=split/\s+/,$_;
		print SH "cd $rsem && bash $rse $id $fq1 $fq2 \n";
	}
	close In;
	close SH;
	#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 6 $wsh/rs2.sh";
	#`$job`;
	$step++ if ($step ne $stop);
}

if ($step == 3) {
	open In,"<$fout/01.hisat-mapping/hisat.list";
	open SH1,">$wsh/rsem3.sh";
	print SH1 "cd $rsem && $matrix --est_method RSEM ";
	while (<In>) {
		chomp;
		my ($id,undef,$fq1,$fq2)=split/\s+/,$_;
		print SH1 "$id.genes.results ";
	}
	print SH1 " --out_prefix rsem.gene";
	close In;
	close SH1;
	#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=5G $wsh/matrix.sh";
	#`$job`;
	$step++ if ($step ne $stop);
}
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

	eg: perl $Script -out ./ -wsh work_sh/ -ref ref
	

Usage:
  Options:
	"help|?" =>\&USAGE,
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	"ref:s"=>\$ref,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
	-h         Help

USAGE
        print $usage;
        exit;
}
