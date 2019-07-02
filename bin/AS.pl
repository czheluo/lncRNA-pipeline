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
	"ref:s"=>\$ref,
			) or &USAGE;
&USAGE unless ($fout);
my $as ="$fout/13.AS";
mkdir $as if (!-d $as);
$as=ABSOLUTE_DIR($as);
mkdir $fout if (!-d $fout);
mkdir $wsh if (!-d $wsh);
$fout=ABSOLUTE_DIR($fout);
$wsh=ABSOLUTE_DIR($wsh);
open Out,">$wsh/10.as.sh";
open In,"<$fout/01.hisat_mapping/bam.list";
my $as ="/mnt/ilustre/users/dongmei.fu/scripts/eurref/ASprofile/extract-as";
my $sum="/mnt/ilustre/users/dongmei.fu/scripts/eurref/ASprofile/summarize_as.pl";
my $head="/mnt/ilustre/users/dongmei.fu/scripts/eurref/ASprofile/as.head";
my $pie="/mnt/ilustre/users/bingxu.liu/workspace/RNA_Pipeline/script/Highchart.pl";
while (<In>) {
	chomp;
	my ($id,undef)=split/\s+/,$_;
	print Out "mkdir -p $as/$id & cd $as/$id && $as $fout/02.stringtie.first/$id/$id.gtf $ref/ref.fa.hdrs >$as/$id/as && ";
	print Out "perl $sum $fout/02.stringtie.first/$id/$id.gtf $as/$id/as -p $as/$id/$id && ";
	print Out "less $as/$id/$id.as.nr |sed \'s/\_ON\|\|\_OFF//g\' >$as/$id/AS_result.xls && ";
	print Out "less $as/$id/$id.as.nr |sed \'s/\_ON\|\|\_OFF//g\'|cut -f 2 |sort |uniq -c > $as/$id/AS_statistics.xls"
	print Out "less $as/$id/AS_statistics.xls| awk -F \" \" \'OFS=\"\t\" \{print \$2,\$1\}\' |sed \'2d\'  >$as/$id/1 && mv $$as/$id/1 $$as/$id/AS_statistics.xls && ";
	print Out "cat  $head $as/$id/AS_statistics.xls >$as/$id/a && mv a $as/$id/AS_statistics.xls && ";
	print Out "sed -i \'$d\' $as/$id/AS_statistics.xls && ";
	print Out "perl $pie -t $as/$id/AS_statistics.xls -type pie -title "AS events Distribution" \n";
}

close Out;
my $job="qsub-slurm.pl  --Queue $queue --Resource mem=10G --CPU 3 $wsh/10.as.sh";
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
