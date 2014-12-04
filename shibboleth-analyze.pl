#!/usr/bin/perl 

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Storable qw(lock_store lock_nstore lock_retrieve);
use YAML;
use Carp;


my $debug = 0;
my $store = 0;
my $store_file = '/tmp/shib-stats-cache';
my $period = 20;
my $yaml = 0;

GetOptions("d" => \$debug,"s" => \$store,"store-file=s" => \$store_file, "yaml" => \$yaml);

my $counter;
$counter->{authentications} = 0;

while(<>) {
	chomp;
	my ($raw_date,$type,$id1,$sp,$profile,$idp,$binding,$id2,$username,$auth_type,$attrs,$id3,$id4) = split '\|';
	my @attrs = split(',',$attrs);
	$debug && print STDERR <<"EOLN";
----------------------------------
raw_date = $raw_date
type = $type
id1 = $id1
sp = $sp
profile = $profile
idp = $idp
binding = $binding
id2 = $id2
user = $username
authentication type = $auth_type
attrs = $attrs
id3 = $id3
id4 = $id4
EOLN

	$counter->{'type counter'}->{$type} ++ if defined($type);
	$counter->{'profile counter'}->{$profile} ++ if defined($profile);
	$counter->{'binding counter'}->{$binding} ++ if defined($binding);
	$counter->{'detailed counters'}->{$sp}->{$profile}->{$binding}->{$type} ++ if( defined($type) && defined($profile) && defined($binding) );

	if ( $profile eq 'urn:mace:shibboleth:2.0:profiles:saml1:sso' ) {
		$counter->{user}->{$username} += 1 if ( defined($username) && ($username ne ''));
		$counter->{sp}->{$sp} += 1 if defined($sp);
		$counter->{authentications} ++;
	}
	elsif ( $profile eq 'urn:mace:shibboleth:2.0:profiles:saml2:sso' ) {
		$counter->{user}->{$username} += 1 if ( defined($username) && ($username ne ''));
		$counter->{sp}->{$sp} += 1 if defined($sp);
		$counter->{authentications} ++;
	}
	elsif ( $profile eq 'urn:mace:shibboleth:2.0:profiles:saml1:query:attribute') {
		$counter->{'saml1 attribute queries'} ++;
	}
	elsif ( $profile eq 'urn:mace:shibboleth:2.0:profiles:saml2:query:artifact') {
		$counter->{'saml2 artifact queries'} ++;
	}
	elsif ( $profile eq 'urn:mace:shibboleth:2.0:profiles:saml2:query:attribute') {
		$counter->{'saml2 attribute queries'} ++;
	}
	else {
		print STDERR "Warning: I don't know how to handle profile $profile \n";
	}	
		
	
}

$debug && print STDERR "Collected stats follow\n",Dumper($counter);

if($store) {
	$debug && print STDERR "Storing results to $store_file \n";
	lock_store $counter,$store_file;	
}

	
if($yaml) {
	$debug && print STDERR "Dumping results in YAML format\n";
	print YAML::Dump($counter);
}

