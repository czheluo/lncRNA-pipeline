#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue,$strand);
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
my $fami ="$fout/06.lnc_family";
mkdir $fami if (!-d $fami);
$fami=ABSOLUTE_DIR($fami);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open Out,">$wsh/06.lncfamily.sh";
my $cms="/mnt/ilustre/users/caiping.shi/software/infernal-1.1.2/src/cmscan";
my $cla= "/mnt/ilustre/users/caiping.shi/software/infernal-1.1.2/testsuite/Rfam.12.1.clanin";
my $rfam= "/mnt/ilustre/users/caiping.shi/software/Rfam/Rfam.cm ";
print Out "cd $fami && $cms --rfam --cut_ga --nohmmonly --tblout $fami/lncRNA.tblout --fmt 2 --clanin $cla --oskip $rfam $fout/05.cm_lnc_mRNA/lncRNA.fa";
close Out;
#my $job="qsub-slurm.pl  --Queue $queue --Resource mem=5G  $wsh/06.lncfamily.sh";
#`$job`;
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
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
