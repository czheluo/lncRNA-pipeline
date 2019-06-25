#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fout,$ref,$cpu,$stor,$string,$wsh,$queue,$step,$stop);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"ref:s"=>\$ref,
	"out:s"=>\$fout,
	"strout:s"=>\$string,
	"cpu:s"=>\$cpu,
	"stor:s"=>\$stor,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
			) or &USAGE;
&USAGE unless ($fout);
$queue||="DNA";
$cpu||=4;
$stor||="8G";
$fout=ABSOLUTE_DIR($fout);
$ref=ABSOLUTE_DIR($ref);
mkdir $string if(!-d $string);
$string=ABSOLUTE_DIR($string);
$step||=1;
$stop||=-1;
my %gro;
if ($step == 1) {
	open In,"<$fout/group.list";
	my @gr;
	while (<In>) {
		chomp;
		my ($rep,$go)=split/\s+/,$_;
		push @gr,join("\t",$go);
		$gro{$go}=1;
	}
	close In;
	open In,"<$fout/01.hisat-mapping/bam.list";
	open SH,">$wsh/stringtie.1.sh";
	open GO,">$string/gtf.list";
	while (<In>) {
		chomp;
		my ($bm,$bam)=split/\s+/,$_;
		#foreach my $bm (@gr) {
		if (exists $gro{$bm}) {
			print SH "mkdir -p $string/$bm && stringtie -p $cpu $bam -G $ref/ref_genome.gtf -o $string/$bm/$bm.gtf --rf \n ";
			print GO "$string/$bm/$bm.gtf\n";
			#last;
		}else{
			next;
		}
		#}
	}
	close In;
	close SH;
	close GO;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=50G --CPU 8 $wsh/stringtie.1.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 2) {
	open ME,">$wsh/megre.sh";
	print ME "stringtie --merge -G $ref/ref_genome.gtf $string/gtf.list -o $string/merged.gtf && /mnt/ilustre/app/rna/bin/gffcompare -r $ref/ref_genome.gtf -o $string/gffcomp $string/merged.gtf && ";
	print ME "python /mnt/ilustre/users/deqing.gu/myscripts/class_code_filter_gtf.py -i $string/gffcomp.annotated.gtf -o $string/Novel_transcripts.gtf -t iuxoj && ";
	print ME "gffread -g $ref/ref.fa $string/Novel_transcripts.gtf -w $string/Novel_transcripts.fa";
	close ME;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G  $wsh/megre.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
my $str2;
if ($step == 3) {
	$str2="$fout/02.stringtie.second";
	mkdir $str2 if (!-d $str2);
	open In,"<$fout/01.hisat-mapping/hisat.list";
	open SH,">$wsh/stringtie2.sh";
	my $n=1;
	while (<In>) {
		chomp;
		my ($id,undef)=split/\s+/,$_,2;
		print SH "mkdir -p $str2/$id && cd $str2/$id && stringtie -p 8 --rf -G $string/gffcomp.annotated.gtf -e -B -o $str2/$id/$id.gtf -l $id $fout/01.hisat-mapping//$id/$id.sorted.bam\n";
		$n++;
	}
	close In;
	close SH;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=50G --CPU 8 $wsh/stringtie.2.sh";
	`$job`;
}
if ($step == 4) {
	open SH,">$wsh/stringtie.exp.sh";
	print SH "python $Bin/bin/extract_strtie_exp.py -i $str2 -g2t $ref/ref_genome.gtf.gene2transcript.txt";
	close SH;
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 2 $wsh/stringtie.exp.sh";
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

	eg: perl stringtie.Pipeline.pl -bam bam.list -gro group.list -ref ref_genome.gtf -out /mnt/ilustre/users/meng.luo/project/RNA/lncRNA/gaopengfei_MJ20181109081/stringtie
	

Usage:
  Options:
	"ref:s"=>\$ref,
	"out:s"=>\$fout, <dir> output dir 
	"strout:s"=>\$string, <dir> first stringtie dir 
	"cpu:s"=>\$cpu, <CPU> default the number of CPU was 4  
	"stor:s"=>\$stor, <memory> default 8G 
	"wsh:s"=>\$wsh, <dir> shell work dir 
	"queue:s"=>\$queue,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
	-h         Help

USAGE
        print $usage;
        exit;
}
