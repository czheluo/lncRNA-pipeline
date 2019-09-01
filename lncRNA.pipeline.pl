#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
my ($ref,$out,$stop,$step,$ncrna,$queue,$fq,$wsh,$rsem,$group,$qa);
GetOptions(
	"help|?" =>\&USAGE,
	"ref:s"=>\$ref,
	"group:s"=>\$group,
	"out:s"=>\$out,
	"ncrna:s"=>\$ncrna,
	"queue:s"=>\$queue,
	"fqlist:s"=>\$fq,
	"wsh:s"=>\$wsh,
	"qa:s"=>\$qa,
	"rsem:s"=>\$rsem,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
			) or &USAGE;
&USAGE unless ($ref and $out);
########################################################
$out=ABSOLUTE_DIR($out);
mkdir $out if (!-d $out);
$wsh="$out/work_sh";
mkdir $wsh if (!-d $wsh);
$ref=ABSOLUTE_DIR($ref);
$step||=1;
$stop||=-1;
$queue||="DNA";
my $tmp=time();
open Log,">$out/work_sh/lncRNA.$tmp.log";
if ($step == 1) {
	print Log "########################################\n";
	print Log "Quality Control\n"; 
	my $time = time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/qc/fastp-QC.pl -fqlist $fq -outdir $out/01.QC -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 2) {
	print Log "########################################\n";
	print Log "hisat-mapping\n"; 
	my $time = time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/hisat.pl -fqlist $out/01.QC/01.CleanData/fastq.list -ref $ref  -out $out/02.hisat-mapping -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($qa) {
	print Log "########################################\n";
	print Log "quality_assessment\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/quality.pl  -out $out -ref $ref -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
}
if ($rsem) {
	print Log "########################################\n";
	print Log "rsem\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/rsem.pl -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
}
if ($step == 3) {
	print Log "########################################\n";
	print Log "stringtie one and two\n"; 
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/stringtie.pipeline.pl -ref $ref -strout $out/02.stringtie.first -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 4) {
	print Log "########################################\n";
	print Log "lncRNA\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/lncRNA.pl -ref $ref -out $out -ncrna $ncrna -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 5) {
	print Log "########################################\n";
	print Log "lncRNA class\n";
	my $time=time();
	print Log "########################################\n";
	#my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/class_lnc.pl -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 6) {
	print Log "########################################\n";
	print Log "compare lncRNA with mRNA\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/cmp_lnc_mRNA.pl -out $out  -wsh $wsh -ref $ref -queue $queue";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 7) {
	print Log "########################################\n";
	print Log "lncRNA Family (more time)\n";
	my $time=time();
	print Log "########################################\n";
	#my $cmp=ABSOLUTE_DIR("$out/05.cmp_lnc_mRNA");
	my $job="perl $Bin/bin/lnc_famil.pl -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 8) {
	print Log "########################################\n";
	print Log "diffexp_lnc\n";
	my $time=time();
	print Log "########################################\n";
	#my $str2=ABSOLUTE_DIR("$out/02.stringtie.second");
	my $job="perl $Bin/bin/diffexp_lnc.pl -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
}
if ($step == 9) {
	print Log "########################################\n";
	print Log "diffexp_mRNA\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/diffexp_mRNA.pl -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 10) {
	print Log "########################################\n";
	print Log "enrich mRNA \n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/enrich_mRNA.pl -out $out -wsh $wsh -ref $ref -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 11) {
	print Log "########################################\n";
	print Log "diffanno\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/diffanno.pl  -out $out -wsh $wsh -ref $ref -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 12) {
	print Log "########################################\n";
	print Log "pca\n";
	my $time=time();
	print Log "########################################\n";

	my $job="perl $Bin/bin/pca.pl  -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 13) {
	print Log "########################################\n";
	print Log "cluster (mRNA)\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/cluster_mRNA.pl  -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 14) {
	print Log "########################################\n";
	print Log "snp\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/snp.pl  -out $out -wsh $wsh -ref -$ref -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 15) {
	print Log "########################################\n";
	print Log "mRNA Alternative Splice\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/AS.pl  -out $out -ref $ref -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
}
if ($step == 16) {
	print Log "########################################\n";
	print Log "target (cis && trans)\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/target.pl -out $out -wsh $wsh -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 17) {
	print Log "########################################\n";
	print Log "target (cis && trans)\n";
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/target.pl -out $out -wsh $wsh -ref $ref -queue $queue";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
close Log;

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub ABSOLUTE_DIR #$pavfile=ABSOLUTE_DIR($pavfile);
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
		warn "Warning! just for existing file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}
sub USAGE {#
        my $usage=<<"USAGE";
Contact:        meng.luo\@majorbio.com;
Script:		$Script
Version:	$version
Description:	
Usage:
  -ref		<dir>	input ref dir
  -group <file> input group list file 
  -ncrna	<file>	nocoding RNA file which downloaded from the website
  -out		<dir>	output dir
  -fqlist	<file>	afther qc list file 
  -queue	<str>   the current nodes (default "DNA")
  -wsh		<str>  the work shell dir (default "work_sh")
  -rsem     <str> which useing rsem or stringtie for calculating the express or not (default no)
  -qa 		<str> sequence data quality assessment (default no)
  -step		<num>	pipeline control, 1-17
  -stop		<num>	pipeline control, 1-17
  -h		Help
USAGE
        print $usage;
        exit;
}
