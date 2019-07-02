#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fout,$ncrna,$stringtie,$ref,$wsh,$queue,$step,$stop);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"norna:s"=>\$ncrna,
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
			) or &USAGE;
&USAGE unless ($fout);
$ref=ABSOLUTE_DIR($ref);
$wsh=ABSOLUTE_DIR($wsh);
mkdir $fout if(!-d  $fout);
$fout=ABSOLUTE_DIR($fout);
my $lnc="$fout/03.lncRNA";
mkdir $lnc if (!-d $lnc);
$stringtie=ABSOLUTE_DIR("$fout/02.stringtie.first");
my $type ||="yes";
$ncrna=ABSOLUTE_DIR($ncrna);
my ($fileter,$cpc,$cnci,$Pfam,$venn);
$step||=1;
$stop||=-1;
if ($step == 1) {
	if ($type eq "yes") {
		`grep ">" $ncrna |egrep '3prime_overlapping_ncrna|ambiguous_orf|antisense|antisense_RNA|lincRNA|ncrna_host|non_coding|non_stop_decay|processed_transcript|retained_intron|sense_intronic|sense_overlapping|bidirectional_promoter_lncRNA|macro_lncRNA' | cut -d " " -f1  | sed 's/>//' >$lnc/known.lncRNA.list`;
		open KW,">$wsh/known.sh";
		print KW "python /mnt/ilustre/centos7users/dna/.env/RNA/filter_gtf_with_tid.py -g $stringtie/gffcomp.annotated.gtf -t $lnc/known.lncRNA.list -o $lnc/known.lncRNA.gtf && ";
		print KW "gtf_to_fasta $lnc/known.lncRNA.gtf $ref/ref.fa $lnc/known.lncRNA.gtf.fa && ";
		print KW "cd $lnc && perl /mnt/ilustre/centos7users/dna/.env/RNA/handle_known_lncRNA.fa.pl ";
		close KW;
	}else{
		die "please gave a type (yes or not): $!";
	}
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 4 $wsh/known.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 2) {
	if ($type eq "yes") {
		$fileter="$lnc/novel";
		mkdir $fileter if (!-d $fileter);
		open FR,">$wsh/fileter.sh";
		print FR "python /mnt/ilustre/users/deqing.gu/myscripts/class_code_filter_gtf.py -i $stringtie/gffcomp.annotated.gtf -o $fileter/filter1.gtf -t iux && ";
		print FR "gtf2bed $fileter/filter1.gtf >$fileter/filter1.bed && " ;
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/extract_long_and_filter_exon.pl $fileter/filter1.bed && ";
		print FR "bedtools getfasta -fi $ref/ref.fa -bed $fileter/filter2.bed -fo $fileter/filter2.fa -name -split && ";
		##orf
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/extract_longorf.pl --input $fileter/filter2.fa > $fileter/filter2.getorf.list && ";
		print FR " awk \'(\$2>300){print \$1}\' $fileter/filter2.getorf.list > $fileter/filter2.longorf.list && ";
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/filter_gene_list.pl $fileter/filter2.longorf.list $fileter/filter2.bed $fileter/filter3.bed && ";
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/extract_GTF_isoform.pl $fileter/filter1.gtf $fileter/filter3.bed $fileter/filter3.gtf && ";
		print FR "gffread -g $ref/ref.fa $fileter/filter3.gtf -w $fileter/filter3.fa && ";
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/seq2protein.pl $fileter/filter3.fa > $fileter/filter3.aa.fa && ";
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/filter_gene_list.pl $lnc/known.lncRNA.list  $fileter/filter3.bed $fileter/filter4.bed && ";
		print FR "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/extract_GTF_isoform.pl $fileter/filter1.gtf $fileter/filter4.bed $fileter/filter4.gtf ";
		close FR;
	}else{
		die "please gave a type (yes or not): $!";
	}
	my $job="qsub-slurm.pl  --Queue $queue --Resource mem=5G $wsh/fileter.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 3) {
	#CPC (need more time)
	$cpc="$lnc/novel/CPC";
	mkdir $cpc if (!-d $cpc);
	open CP1,">$wsh/cpc1.sh";
	print CP1 "python /mnt/ilustre/users/penny.yang/script/lncRNA/split_fa.py -i $fileter/filter3.fa -n 100 -o $cpc/chaifen";
	close CP1;
	my $job="qsub-slurm.pl  --Queue $queue  $wsh/cpc1.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 4) {
	my @caifen=glob("$cpc/chaifen*.fa");
	open CP2,">$wsh/cpc2.sh";
	foreach my $caif (@caifen) {
		my $fil=basename($caif);
		my ($name,undef)=split/\./,$fil;
		my $sh="/mnt/ilustre/users/caiping.shi/software/cpc-0.9-r2/bin/run_predict.sh";
		print CP2 "mkdir -p $cpc/$name && cd $cpc/$name && $sh $fileter/$name.fa $cpc/$name/cpc_result $cpc/$name \n";
	}
	#
	close CP2;
	my $job="qsub-slurm.pl  --Queue $queue  $wsh/cpc2.sh";
	`$job`;
	$step++ if ($step ne $stop);
}

if ($step == 5) {
	open CP3,">$wsh/cpc3.sh";
	print CP3 "cat $cpc/*/cpc_result > $cpc/total_cpc_result && less $cpc/total_cpc_result |grep \"noncoding\" |awk \'{print $1}\' > $cpc/CPC_filter_result";
	close CP3;
	my $job="qsub-slurm.pl  --Queue $queue  $wsh/cpc3.sh";
	`$job`;
	$step++ if ($step ne $stop);
}

##CNCI 
if ($step == 6) {
	$cnci="$lnc/novel/cnci";
	mkdir $cnci if (!-d $cnci);
	open SH,">$wsh/cnci.sh";
	my $CN="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/CNCI_package/";
	print SH "cd $cnci && cp -r $CN $cnci && python ./CNCI_package/CNCI.py -f $fileter/filter3.fa -o CNCI -m ve -p 8 ";
	close SH;
	my $job="qsub-slurm.pl  --Queue $queue  $wsh/cnci.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 7) {
	open In,"<$cnci/CNCI/CNCI.index";
	open Out,">$cnci/CNCI/CNCI_filter_result";
	while (<In>) {
		chomp;
		next if ($_ =~ "Transcript");
		my ($id,$coding,undef)=split/\s+/,$_,3;
		print Out "$id\n";
	}
	close In;
	close Out;
	$step++ if ($step ne $stop);
}
##PfamScan
if ($step == 8) {
	$Pfam="$lnc/novel/PfamScan";
	mkdir $Pfam if (!-d $Pfam);
##more time
#$Pfam=ABSOLUTE_DIR($Pfam);
	open PF,">$wsh/Pfam.sh";
	my $pfa="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/PfamScan/pfam_scan.pl";
	my $db="/mnt/ilustre/centos7users/meng.luo/Pipeline/RNA/PfamScan/pfam_db/";
	print PF "perl $pfa -dir $db -outfile $Pfam/pfamscan_result -pfamB -fasta $fileter/filter3.aa.fa -cpu 8 && ";
	##no spplit
	##`cat */pfamscan_result | grep TCON > total_PfamScan_result`;
	my $se="/mnt/ilustre/users/caiping.shi/script/lncRNA/pfam_select.pl ";
	print PF "perl $se $Pfam/pfamscan_result $Pfam/PfamScan_result_1 $Pfam/PfamScan_result_NA && ";
	print PF "less $Pfam/PfamScan_result_1 | awk \'{print \$1}\' | awk -F \"-\" \'{print \$1}\' | sort | uniq > $Pfam/PfamScan_signicant_list && ";
	print PF "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/filter_list.pl $fileter/filter3.bed $Pfam/PfamScan_signicant_list $Pfam/PfamScan_filter_result ";
	close PF;
	my $job="qsub-slurm.pl  --Queue $queue $wsh/Pfam.sh";
	`$job`;
	$step++ if ($step ne $stop);
}
if ($step == 9) {
	my $venn="$lnc/novel/venn";
	mkdir $venn if (!-d $venn);
	my $tool="RNAseq_ToolBox_v1410 venn";
	open LT,">$wsh/venn.sh";
	print LT " $tool $cnci/CNCI/CNCI_filter_result,$cpc/CPC_filter_result,$Pfam/PfamScan_filter_result CNCI,CPC,PfamScan  $venn/advance_filter_venn && ";
	print LT "awk -F \"\t)\" \'{if (\$2==1 && \$3==1 && \$4==1 && \$5==1) {print \$1}}\' $venn/advance_filter_venn.xls > $venn/advance_filter_list ";
	print LT "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/select_gene_list.pl $venn/advance_filter_list $fileter/filter3.bed $fileter/filter4.bed &&";
	print LT "perl /mnt/ilustre/users/caiping.shi/script/lncRNA/extract_GTF_isoform.pl $fileter/filter1.gtf $venn/filter4.bed $fileter/filter4.gtf && ";
	print LT "gffread -g $ref/ref.fa $venn/filter4.gtf -w $venn/filter4.fa ";
	print LT "cat $lnc/known.lncRNA.list $venn/advance_filter_list > $lnc/lncRNA.list ";
	close LT;
	my $job="qsub-slurm.pl  --Queue $queue  $wsh/venn.sh";
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

	eg: nohup perl $Script -norna ref/Mus_musculus.GRCm38.ncrna.fa -out ./ -ref ref/ -wsh work_sh/ &
	

Usage:
  Options:
	"norna:s"=>\$ncrna,
	"out:s"=>\$fout,
	"ref:s"=>\$ref,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	"step:s"=>\$step,
	"stop:s"=>\$stop,
	-h         Help

USAGE
        print $usage;
        exit;
}
