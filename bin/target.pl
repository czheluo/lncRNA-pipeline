#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fout,$cm,$ref,$queue,$stop,$step,$wsh);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"queue:s"=>\$queue,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
	"wsh:s"=>\$wsh,
			) or &USAGE;
&USAGE unless ($fout);
$fout=ABSOLUTE_DIR($fout);
my $target="$fout/10.target";
mkdir $target if (!-d $target);
my $cis="$target/cis";
mkdir $cis if (!-d $cis);
my $trans="$target/trans";
mkdir $trans if (!-d $trans);
$fout=ABSOLUTE_DIR($fout);
$cis=ABSOLUTE_DIR($cis);
$trans=ABSOLUTE_DIR($trans);
$ref=ABSOLUTE_DIR($ref);
$step||=1;
$stop||=-1;
$queue||="DNA";
if ($step == 1) {
	##target
	open TA,">$wsh/TA.sh";
	print TA "cat $fout/07.diffexp_lnc/replicates_exp/*.DE.list |sort |uniq > $target/lncRNA.DE.list && ";
	print TA "perl $Bin/bin/filter_gene_list.pl $target/lncRNA.DE.list $fout/05.cm_lnc_mRNA/lncRNA.bed $target/lncRNA.DE.bed && ";
	print TA "bedtools getfasta -fi $ref/ref.fa -bed $fout/05.cm_lnc_mRNA/lncRNA.bed -fo $target/lncRNA.fa -name -split && ";
	print TA "perl $Bin/bin/chooseseq.pl $target/lncRNA.fa $target/lncRNA.DE.list > $target/lncRNA.DE.fa \n";
	print TA "cat $fout/07.diffexp_mRNA/replicates_exp/*.DE.list |sort |uniq > $target/mRNA.DE.list && ";
	print TA "perl $Bin/bin/filter_gene_list.pl $target/mRNA.DE.list $fout/05.cm_lnc_mRNA/mRNA.bed $target/mRNA.DE.bed && ";
	print TA "bedtools getfasta -fi $ref/ref.fa -bed $fout/05.cm_lnc_mRNA/mRNA.bed -fo $target/mRNA.fa -name -split && ";
	print TA "perl $Bin/bin/chooseseq.pl $target/mRNA.fa $target/mRNA.DE.list > $target/mRNA.DE.fa \n";
	close TA;
	#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=3G --CPU 1 $wsh/TA.sh";
	#`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 2) {
	##target
	open SH,">$wsh/cis.sh";
	print SH "perl $Bin/bin/lncRNA_cistarget.pl $target/lncRNA.DE.bed $fout/05.cm_lnc_mRNA/mRNA.bed 10000 $cis/LncRNA.DE.cistarget \n";
	print SH "perl $Bin/bin/fasta_clean.pl $target/lncRNA.DE.fa $trans/new.lncRNA.DE.fa dna && split -a 5 -d -l 100 $trans/new.lncRNA.DE.fa $trans/lnctar \n";
	close SH;
	#my $job1="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 4 $wsh/cis.sh";
	#`$job1`;
	$step++ if ($step ne $stop);
}

if ($step == 3){
	##target
	my @lncs=glob("$trans/lnctar*");
	open OUT,">$trans/RNAplex.cmds";
	my $n=0;
	foreach my $lncs (@lncs) {
		print OUT "RNAplex -q $lncs -t $target/mRNA.DE.fa -e -30 -c 30 > $trans/lnctar00000$n\_targets.out\n";
		$n++;
	}
	open TR,">$wsh/trans.sh";
	print TR "cd $trans && ParaFly -c $trans/RNAplex.cmds -CPU 20";
	close TR;
	close OUT;
	#my $job1="qsub-slurm.pl  --Queue $queue --Resource mem=50G --CPU 20 $wsh/trans.sh;
	#`$job1`;
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

	eg: perl $Script -out ./ -ref ref -wsh work_sh/
	

Usage:
  Options:
	"help|?" =>\&USAGE,
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"queue:s"=>\$queue,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
	"wsh:s"=>\$wsh,
	-h         Help

USAGE
        print $usage;
        exit;
}
