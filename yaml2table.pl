#!/usr/local/bin/perl 

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Getopt::Long;
use YAML;


my $data = YAML::Load( do { local $/; <> } );

print STDERR Dumper($data);

print "authentications\t",$data->{authentications},"\n";

for my $item (keys %{$data->{sp}}){
	print $item,"\t".$data->{sp}->{$item},"\n";
}

