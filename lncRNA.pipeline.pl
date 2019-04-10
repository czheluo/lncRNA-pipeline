#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.6.0";
my ($ref,$out,$dsh,$chr,$stop,$step,$gff,$num,$type);
GetOptions(
	"help|?" =>\&USAGE,
	"ref:s"=>\$ref,
	"gff:s"=>\$gff,
	"chr:s"=>\$chr,
	"out:s"=>\$out,
	"num:s"=>\$num,
	"type:s"=>\$type,
	"step:s"=>\$step,
	"stop:s"=>\$stop
			) or &USAGE;
&USAGE unless ($ref and $out);
########################################################
mkdir $out if (!-d $out);
$out=ABSOLUTE_DIR($out);
mkdir "$out/work_sh" if (!-d "$out/work_sh");
$ref=ABSOLUTE_DIR($ref);
$step||=1;
$stop||=-1;
if ( defined $type && $type eq 'pro' && $step < 4){
	$step = 3;
	mkdir "$out/01.newref" if (!-d "$out/01.newref");
	`cp $ref $out/01.newref/ref.pro.fa`;
}else{
	if (defined $chr) {
	    $chr=ABSOLUTE_DIR($chr);
	}
	if (defined $gff) {
		$gff=ABSOLUTE_DIR($gff);
	}
}
open Log,">$out/work_sh/anno.$BEGIN_TIME.log";
if ($step == 1) {
	print Log "########################################\n";
	print Log "ref-rename\n"; 
	my $time = time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/step01.new-ref.pl -ref $ref -gff $gff -out $out/01.newref -dsh $out/work_sh";
	if ($chr) {
		$job .= " -chr $chr ";
	}
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
	print Log "reference prepare\n"; 
	my $time=time();
	print Log "########################################\n";
	my $job="perl $Bin/bin/step02.ref-config.pl -ref $out/01.newref/ref.fa -gff $out/01.newref/ref.gff  -out $out/02.ref-config -dsh $out/work_sh ";
	print Log "$job\n";
	`$job`;
	my $check=glob"$out/02.ref-config/ref/*.bin";
	if (!$check){
		print "Ref-config gets trouble! Check, please.\n";
		$step = 12;
	}
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 3) {
	print Log "########################################\n";
	print Log "enzyme cut\n";
	my $time=time();
	print Log "########################################\n";
	my $fa;
	if (defined $type && $type eq 'pro'){
		$fa=ABSOLUTE_DIR("$out/01.newref/ref.pro.fa");
	}else{
		$fa=ABSOLUTE_DIR("$out/01.newref/ref.new.mRNA.fa");
	}
	my $job="perl $Bin/bin/step03.split-fa.pl -fa $fa -out $out/03.split -dsh $out/work_sh";
	if (defined $num){
		$job .= " -num $num";
	}
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
	print Log "NR ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step04.nr-anno.pl -fa $fa -out $out/04.NR -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
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
	print Log "KEGG ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step05.kegg-anno.pl -fa $fa -out $out/05.KEGG -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
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
	print Log "GO ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step06.go-anno.pl -fa $fa -out $out/06.GO -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 7) {
	print Log "########################################\n";
	print Log "Uniref ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step07.uniref-anno.pl -fa $fa -out $out/07.Uniref -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
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
	print Log "EGGNOG ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step08.eggnog-anno.pl -fa $fa -out $out/08.Eggnog -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step == 9) {
	print Log "########################################\n";
	print Log "Pfam ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step09.pfam-anno.pl -fa $fa -out $out/09.Pfam -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
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
	print Log "interPro ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $job="perl $Bin/bin/step10.interpro-anno.pl -fa $fa -out $out/10.InterPro -dsh $out/work_sh";
	if (defined $type){
		$job .= " -type $type";
	}
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
	print Log "merge ANNO\n";
	my $time=time();
	print Log "########################################\n";
	my $fa=ABSOLUTE_DIR("$out/03.split/fasta.list");
	my $nr=ABSOLUTE_DIR("$out/04.NR/NR.anno");
	my $kegg=ABSOLUTE_DIR("$out/05.KEGG/KEGG.anno");
	my $go=ABSOLUTE_DIR("$out/06.GO/GO.anno");
	my $uniprot=ABSOLUTE_DIR("$out/07.Uniref/Uni.anno");
	my $eggnog=ABSOLUTE_DIR("$out/08.Eggnog/EGGNOG.anno");
	my $pfam=ABSOLUTE_DIR("$out/09.Pfam/Pfam.anno");
	my $interpro=ABSOLUTE_DIR("$out/10.InterPro/InterPro.anno");
	my $ref=ABSOLUTE_DIR("$out/01.newref");
	my $job="perl $Bin/bin/step11.merge-result.pl -nr $nr -kegg $kegg -go $go -eggnog $eggnog -uniprot $uniprot -pfam $pfam -interpro $interpro -ref $ref -out $out/11.result";
	if (defined $type){
	    $job .= " -type $type"
	}
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
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

  -ref		<file>	input ref file
  -gff		<file>  input gff file
  -chr		<file>  input chr file, required for chr level
  -out		<dir>	output dir
  -type		<str>	nuc or pro, default nuc
  -num		<num>   input split fa number, default 20
  -step		<num>	pipeline control, 1-11
  -stop		<num>	pipeline control, 1-11
  -h		Help

USAGE
        print $usage;
        exit;
}
