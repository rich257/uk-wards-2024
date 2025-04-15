#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use JSON::XS;
use Data::Dumper;

# A JSON containing the property "final" which points to where the combined file is
my $config = LoadJSON("config.json");

# Load in the HexJSON
my $hexjson = LoadJSON($config->{'final'});

my ($id,$prop,$lookup,$i,$geojson,$f,$key);

$lookup = {};
# Go through hexes and find colours
foreach $id (keys(%{$hexjson->{'hexes'}})){
	msg("$id\n");
	$lookup->{$id} = $hexjson->{'hexes'}{$id}{'colour'};
	foreach $prop (keys(%{$hexjson->{'hexes'}{$id}})){
		if($prop =~ /[0-9]+CD$/){
			print "\t$prop\n";
			$lookup->{$hexjson->{'hexes'}{$id}{$prop}} = $hexjson->{'hexes'}{$id}{'colour'};
		}
	}
}

for($i = 0; $i < @{$config->{'geojson'}}; $i++){
	msg("Update <cyan>$config->{'geojson'}[$i]{'file'}<none>.\n");
	$key = $config->{'geojson'}[$i]{'key'};
	$geojson = LoadJSON($config->{'geojson'}[$i]{'file'});
	for($f = 0; $f < @{$geojson->{'features'}}; $f++){
		$id = $geojson->{'features'}[$f]{'properties'}{$key};
		$geojson->{'features'}[$f]{'properties'}{'colour'} = $lookup->{$id};
	}
	SaveJSON($geojson,$config->{'geojson'}[$i]{'file'},2);
}




#############################

sub msg {
	my $str = $_[0];
	my $dest = $_[1]||"STDOUT";
	
	my %colours = (
		'black'=>"\033[0;30m",
		'red'=>"\033[0;31m",
		'green'=>"\033[0;32m",
		'yellow'=>"\033[0;33m",
		'blue'=>"\033[0;34m",
		'magenta'=>"\033[0;35m",
		'cyan'=>"\033[0;36m",
		'white'=>"\033[0;37m",
		'none'=>"\033[0m"
	);
	foreach my $c (keys(%colours)){ $str =~ s/\< ?$c ?\>/$colours{$c}/g; }
	if($dest eq "STDERR"){
		print STDERR $str;
	}else{
		print STDOUT $str;
	}
}

sub error {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<red>ERROR:<none> /;
	msg($str,"STDERR");
}

sub warning {
	my $str = $_[0];
	$str =~ s/(^[\t\s]*)/$1<yellow>WARNING:<none> /;
	msg($str,"STDERR");
}

sub ParseJSON {
	my $str = shift;
	my $json = {};
	if(!$str){ $str = "{}"; }
	eval {
		$json = JSON::XS->new->decode($str);
	};
	if($@){ error("\tInvalid output.\n"); }
	return $json;
}

sub LoadJSON {
	my (@files,$str,@lines,$json);
	my $file = $_[0];
	open(FILE,"<:utf8",$file);
	@lines = <FILE>;
	close(FILE);
	$str = (join("",@lines));
	# Error check for JS variable e.g. South Tyneside https://maps.southtyneside.gov.uk/warm_spaces/assets/data/wsst_council_spaces.geojson.js
	$str =~ s/[^\{]*var [^\{]+ = //g;
	return ParseJSON($str);
}

# Version 1.1.1
sub SaveJSON {
	my $json = shift;
	my $file = shift;
	my $depth = shift;
	my $oneline = shift;
	if(!defined($depth)){ $depth = 0; }
	my $d = $depth+1;
	my ($txt,$fh);
	

	$txt = JSON::XS->new->canonical(1)->pretty->space_before(0)->encode($json);
	$txt =~ s/   /\t/g;
	$txt =~ s/\n\t{$d,}//g;
	$txt =~ s/\n\t{$depth}([\}\]])(\,|\n)/$1$2/g;
	$txt =~ s/": /":/g;

	if($oneline){
		$txt =~ s/\n[\t\s]*//g;
	}

	msg("Save JSON to <cyan>$file<none>\n");
	open($fh,">:utf8",$file);
	print $fh $txt;
	close($fh);

	return $txt;
}

