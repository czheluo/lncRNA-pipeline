#!/usr/bin/perl -w

use strict;
use warnings;
use Carp;
use DBI;
use Getopt::Long;
use List::Util qw ( sum);
my %opts;
my $VERSION = "1.0";
my $dbhost  = "localhost";    #
my $dbuser  = "blast2go";     #
my $dbpass  = "blast4it";     #
my $dbname  = "b2g";          #
my $dbport  = "3306";         #
my $dbh;
my @orf;
my %golist;

my $orfname;
my $goid;
GetOptions(
	\%opts, "i=s", "d=s", "l=i", "h=s","list=s",
	"p=s",  "u=s", "port=i", "help!"
);

my $usage = <<"USAGE";
       Program : $0
       Version : $VERSION
       Contact : quan.guo\@majorbio.com
       Usage :perl $0 [options]
                -i* 	[GO files from Interpro-extract]
                -l*		[GO level 1-10 ]
                -list  listfile  listall genenames for all the GO terms of this level 
                -h		[Mysql database host:Defualt "localhost"]
                -u		[Mysql database username:Defualt "blast2go"]
                -p		[Mysql database passwod:Defualt "blast4it"]
                -d		[Mysql GO database name:Defualt "b2g"]
                -port	[Mysql database port:Defualt "3306"]
                -help	Display this usage information
                * 		must be given Argument 
       example:gene-ontology.pl -i go.txt -l 2 
USAGE

die $usage
  if ( !( $opts{i} && $opts{l} ) || $opts{help} );
$dbhost = $opts{h}    if ( $opts{h} );
$dbuser = $opts{u}    if ( $opts{u} );
$dbpass = $opts{p}    if ( $opts{p} );
$dbname = $opts{d}    if ( $opts{d} );
$dbport = $opts{port} if ( $opts{port} );
if ( $opts{l} > 10 || $opts{l} < 1 ) {
	die "GO level must between 1-10\n";
}

open( FILE, "<$opts{i}" ) || die "Can't open $opts{i} or file not exsit!\n";
while (<FILE>) {
	chomp;
	@orf = split( /\s+/, $_ );
	if ( $#orf < 1 ) { next }
	if ( $orf[0] =~ /^GO:\d+$/ ) {
		die "$opts{i} file format error!\n";
	}
	else {
		for ( my $n = 1 ; $n <= $#orf ; $n++ ) {
			if($orf[$n]=~/\;/){
				my @b=split(/;\s*/,$orf[$n]);
				push( @{ $golist{ $orf[0] }{'GO'} }, @b);
			}
			#until ( $orf[$n] =~ /^GO:\d+$/ ) {
				#die "$opts{i} file format error!\n";
			#}
			else{
				push( @{ $golist{ $orf[0] }{'GO'} }, $orf[$n] );
			}
		}
	}
}
close FILE;

$dbh = DBI->connect( "DBI:mysql:database=$dbname;mysql_socket=/var/lib/mysql/mysql.sock;host=$dbhost;port=$dbport",
	$dbuser, $dbpass )
  || die "Could not connect to database: $DBI::errstr";


my %seqlist;

foreach $orfname ( keys(%golist) ) {
	foreach $goid ( @{ $golist{$orfname}{'GO'} } ) {
		my $sth = $dbh->prepare(
"SELECT DISTINCT ancestor.*, graph_path.term1_id AS ancestor_id FROM term INNER JOIN graph_path ON (term.id=graph_path.term2_id) INNER JOIN term AS ancestor ON (ancestor.id=graph_path.term1_id)  WHERE term.acc='$goid';"
		);
		if ( !$sth ) {
			die "Error:" . $dbh->errstr . "\n";
		}
		if ( !$sth->execute ) {
			die "Error:" . $sth->errstr . "\n";
		}
		my $ref = $sth->fetchall_hashref('id');

		#print scalar(keys(%$ref))." \n";
		foreach my $id ( keys(%$ref) ) {

			#print("$ref->{$id}->{'name'} \t $ref->{$id}->{'acc'} \n");
			my $termname = $ref->{$id}->{'name'};
			#unless ( exists( $seqlist{$termname}{$orfname} ) ) {
				#$terms{$termname}++;
				#$golist{$orfname}{$termname} = $ref->{$id}->{'acc'};
				$seqlist{$termname}{$orfname}{$goid}=1;
			#}
		}
		$sth->finish;
	}
}

sub getDescendants() {
	my ($name) = @_;
	my %goterm;
	my $goname;
	my $sth1 = $dbh->prepare(
	"SELECT DISTINCT descendant.acc, descendant.name, descendant.term_type FROM  term  INNER JOIN graph_path ON (term.id=graph_path.term1_id)  INNER JOIN term AS descendant ON (descendant.id=graph_path.term2_id) WHERE distance = 1 and term.name=".$dbh->quote($name).";") or die "Error:" . $dbh->errstr . "\n";
	$sth1->execute();
	my $ref = $sth1->fetchall_hashref('acc');
	foreach my $acc ( keys(%$ref) ) {
		$goname = $ref->{$acc}->{'name'};
		$goterm{$goname} = $acc;
	}
	return %goterm;
	$sth1->finish;
}
my $sum =scalar keys(%golist);
print "total seqs number with gos: $sum \n";
my (%bcm);
$bcm{'molecular_function'}{'1'}{'molecular_function'} = "GO:0003674";
$bcm{'biological_process'}{'1'}{'biological_process'} = "GO:0008150";
$bcm{'cellular_component'}{'1'}{'cellular_component'} = "GO:0005575";
if ( $opts{l} == 1 ) {
	#my $f =$terms{'molecular_function'};
	my $f=scalar(keys %{$seqlist{'molecular_function'}});
	#my $p = $terms{'biological_process'};
	my $p=scalar(keys %{$seqlist{'biological_process'}});
	#my $c = $terms{'cellular_component'};
	my $c=scalar(keys %{$seqlist{'cellular_component'}});
	print "term\tnumber\tpercent\tGO\n";
	my $percent=$f/($f+$p+$c);
	print "molecular_function\t$f\t$percent\tGO:0003674\n";
	$percent=$p/($f+$p+$c);
	print "biological_process\t$p\t$percent\tGO:0008150\n";
	$percent=$c/($f+$p+$c);
	print "cellular_component\t$p\t$percent\tGO:0005575\n";
}
else {
	my $x =$opts{l};
	$x--;
	print "term_type\tterm\tnumber\tpercent\tGO\n";
	foreach my $key ( keys(%bcm) ) {
		for ( my $i = 1 ; $i<= $x ; $i++ ) {
			foreach my $tname ( keys( %{ $bcm{$key}{$i} } ) ) {
				my %newterm = &getDescendants($tname);
				foreach my $m ( keys(%newterm) ) {
					$bcm{$key}{ $i + 1 }{$m} = $newterm{$m};
				}
			}
		}
		 my %zterms;
		 foreach my $lterm (keys( %{ $bcm{$key}{$opts{l}} } )){
		   if (exists($seqlist{$lterm})){
		   	$zterms{$lterm}=scalar(keys %{$seqlist{$lterm}});
		   }		   
	     }
	    if($opts{list}){
	    	open LIST, ">> $opts{list}" or die "Error:Cannot open file $opts{list} : $! \n";
	    	foreach my $nterm (keys(%zterms)){
	    		my @seqs;
	    		foreach my $x (keys %{$seqlist{$nterm}}){
	    			push(@seqs,$x."(".join(",",keys %{$seqlist{$nterm}{$x}}).")");
	    		}
	    		print LIST "$key\t$nterm\t".$bcm{$key}{$opts{l}}{$nterm}."\t".$zterms{$nterm}."\t".join(";",@seqs)."\n";
	    	}
	    	close LIST;
	    }
		
	     foreach my $nterm (keys(%zterms)){
	     	my $m = $zterms{$nterm};
	     	my $percent=$m/$sum;
	     	print "$key\t$nterm\t$m\t$percent\t$bcm{$key}{$opts{l}}{$nterm}\n";
	     }
	}
}

$dbh->disconnect();
