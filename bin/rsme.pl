#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue);
use Data::Dumper;
use FindBin qw($bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	"ref:s"=>\$ref,
			) or &USAGE;
&USAGE unless ($fout and $fin);
my $rsem=ABSOLUTE_DIR("$fout/12.rsem");
$fin =ABSOLUTE_DIR("$fout/01.hisat_mapping/bam.list");
mkdir $rsem if (!-d $rsem);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
my $rse="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/Pipeline/rsem.sh";
my $matrix="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/Pipeline/abundance_estimates_to_matrix.pl";
if ($step == 1) {
	open In,$fin;
	open SH,">$wsh/rs1.sh";
	print SH "rsem-prepare-reference  --gtf $ref/ref_genome.gtf $ref/ref.fa $rsem/rsem.gene --bowtie2 ";
	close SH;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G $wsh/rs1.sh";
	`$job`;
	$step++ if ($step ne $stop);
}

if ($step == 2) {
	open In,$fin;
	open SH,">$wsh/rs2.sh";
	while (<In>) {
		chomp;
		my ($id,undef,$fq1,$fq2)=split/\s+/,$_;
		print SH "cd $rsem && bash $rse $id $fq1 $fq2 \n";
	}
	close In;
	close SH;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 6 $wsh/rs2.sh";
	`$job`;
	$step++ if ($step ne $stop);
}

if ($step == 3) {
	open In,$fin;
	open SH1,">$wsh/matrix.sh";
	print SH1 "cd $rsem && $matrix --est_method RSEM ";
	while (<In>) {
		chomp;
		my ($id,undef,$fq1,$fq2)=split/\s+/,$_;
		print SH1 "$id.genes.results ";
	}
	print SH1 " --out_prefix rsem.gene";
	close In;
	close SH1;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=5G $wsh/matrix.sh";
	`$job`;
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

	eg: perl -int filename -out filename 
	

Usage:
  Options:
	"help|?" =>\&USAGE,
	"fqlist:s"=>\$fin,
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
