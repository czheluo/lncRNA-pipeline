#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$ref,$wsh,$queue);
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
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
my $class ="$fout/04.class_lnc";
mkdir $class if (!-d $class);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);

#filter4.gtf was the novel.lncRNA.list
open Out,">$wsh/04.class.sh";
print Out "cp $fout/03.lncRNA/novel/{filter1.gtf,filter3.gtf,filter4.gtf} $class && cd $class && sh $Bin/bin/lncRNA_classification.sh ";
close Out;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=3G  $wsh/04.class.sh";
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

	eg: perl -int filename -out filename 
	

Usage:
  Options:
	"out:s"=>\$fout,
	"wsh:s"=>\$wsh,
	"queue:s"=>\$queue,
	-h         Help

USAGE
        print $usage;
        exit;
}
