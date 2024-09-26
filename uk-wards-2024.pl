#!/usr/bin/perl

use utf8;
use JSON::XS;
use Data::Dumper;

# A JSON containing the property "final" which points to where the combined file is
$config = getJSON("config.json");

if($ARGV[0] eq "split"){
	splitRegions();
}elsif($ARGV[0] eq "combine"){
	combineRegions();
}

simplify();




#############################

sub getJSON {
	my (@files,$str,@lines);
	my $file = $_[0];
	open(FILE,$file);
	@lines = <FILE>;
	close(FILE);
	$str = join("",@lines);
	return JSON::XS->new->decode($str);	
}

sub makeJSON {
	my $json = shift;
	
	$txt = JSON::XS->new->utf8->canonical(1)->pretty->space_before(0)->encode($json);
	
	$txt =~ s/   /\t/g;

	$txt =~ s/(\t{3}.*)\n/$1/g;
	$txt =~ s/\,\t{3}/\, /g;
	$txt =~ s/\t{2}\}(\,?)\n/ \}$1\n/g;
	$txt =~ s/\{\n\t{3}/\{ /g;
	
	$txt =~ s/\"\: /\"\:/g;
	$txt =~ s/\, \"/\,\"/g;
	$txt =~ s/":\{ "/":\{"/g;
	$txt =~ s/\" \},/\"\},/g;
	
	return $txt;
}

sub simplify {
	print "Simplifying the content of $config->{'final'}\n";
	my ($regions,$id,$region,$fh);
	my $hexjson = getJSON($config->{'final'});
	
	foreach $id (keys(%{$hexjson->{'hexes'}})){
		foreach $d (keys(%{$hexjson->{'hexes'}{$id}})){
			if($d ne "q" && $d ne "r"){
				delete $hexjson->{'hexes'}{$id}{$d};
			}
		}
	}
	my $simple = makeJSON($hexjson);
	$simple =~ s/\t//gs;
	$simple =~ s/ \}/\}/gs;
	open($fh,">","simple.hexjson");
	print $fh $simple;
	close($fh);
}

sub splitRegions {
	print "Splitting regions in $config->{'final'}\n";
	my ($regions,$id,$region,$fh);
	my $hexjson = getJSON($config->{'final'});
	
	foreach $id (keys(%{$hexjson->{'hexes'}})){
#		print "$id\n";
		$region = $hexjson->{'hexes'}{$id}{'RGN24CD'};
		if(!$regions->{$region}){
			$regions->{$region} = {'layout'=>$hexjson->{'layout'},'hexes'=>{}};
		}
		$regions->{$region}{'hexes'}{$id} = $hexjson->{'hexes'}{$id};
	}
	
	foreach $region (sort(keys(%{$regions}))){
		print $region."\n";
		open($fh,">",$region.".hexjson");
		print $fh makeJSON($regions->{$region});
		close($fh);
	}
}

sub combineRegions {
	my ($tmp,$dh,$filename,$json,$hex,$fh);
	$json = {'layout'=>'odd-r','hexes'=>{}};
	opendir($dh,"./");
	while(($filename = readdir($dh))){
		if($filename =~ /[ENSW][0-9]{8}.hexjson$/){
			print "Read from $filename\n";
			$tmp = getJSON($filename);
			foreach $hex (keys(%{$tmp->{'hexes'}})){
				$json->{'hexes'}{$hex} = $tmp->{'hexes'}{$hex};
			}
		}
	}
	closedir($dh);

	open($fh,">",$config->{'final'});
	print $fh makeJSON($json);
	close($fh);
}