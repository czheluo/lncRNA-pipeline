#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fin,$fout,$min);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"int:s"=>\$fin,
	"out:s"=>\$fout,
			) or &USAGE;
&USAGE unless ($fin);
open In,$fin;
my @rgens;
while (<In>) {
	chomp;
	my (undef,undef,$trans,undef,undef,undef,undef,undef,$gene)=split/\s+/,$_,9;
	next if($trans ne "transcript");
	my @gen=split/\;/,$gene;
	foreach my $gens (@gen) {
		#next if($gens =~ "transcript_id");
		if ($gens =~ "ref_gene_id") {
			my (undef,$geneid,$mid)=split/\s+/,$gens;
			$mid=~s/"//g;
			push @rgens,join("\n",$mid);
			#print Out "$mid\n";
		}else{
			next;
		}
	}
}
close In;
@rgens=uniq(@rgens);
open Out,">$fout/mRNA.list";
foreach my $ge (@rgens) {
	print Out "$ge\n";
}
close Out;
#my $sca=scalar @rgens;
#print $sca;die;
#print Dumper @rgens;die;
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
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
sub USAGE {#
        my $usage=<<"USAGE";
Contact:        meng.luo\@majorbio.com;
Script:			$Script
Description:

	eg: perl -int filename -out filename 
	

Usage:
  Options:
	-int input file name
	-out ouput file name 
	-h         Help

USAGE
        print $usage;
        exit;
}
