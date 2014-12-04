#!/usr/bin/perl 

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Getopt::Long;
use Storable qw(lock_store lock_nstore lock_retrieve);
use YAML;


my $debug = 0;
my $period = 20;
my $yaml = 0;
my $previous_file = '/tmp/differ-previous-file';
my $output_file = '/tmp/differ-output';
my $factor = 1000;

GetOptions("d" => \$debug, "period=i" => \$period, "file=s" => \$previous_file, "out=s" => \$output_file, "factor=i" => \$factor);

my $current = YAML::Load ( do { local $/; <STDIN> } );

$debug && print STDERR "Got input: \n".Dumper($current);


my $previous;
my $elapsed;

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($previous_file);

if(defined($mtime)) { #file does exist

	$debug && print STDERR "$previous_file mtime = $mtime \n";
	$elapsed = time - $mtime;
	$debug && print STDERR "Elapsed time is $elapsed \n"; 
	if( $elapsed > (60*$period) ) {
		$debug && print STDERR "$previous_file too old. It will be updated\n";
		#now try to load the file
		eval { $previous = YAML::LoadFile($previous_file) }; 
		if($@) {
			$debug && print STDERR "Previous data not available. Maybe $previous_file is corrupted? It will be updated\n";
		}
		else {
			$debug && print STDERR "Previous data was: \n".Dumper($previous);
		}
	}
	else {
		$debug && print STDERR "$previous_file too young.\n";
		exit 0;
	}
}
else { #mtime is not defined -- file does not exist
	$debug && print STDERR "$previous_file does not seem to exist. It will be created\n";
}
		

$debug && print STDERR "Updating $previous_file \n";
YAML::DumpFile($previous_file,$current);
my $diff =  diff($previous,$current,1,$elapsed,$factor);
$debug && print STDERR "Updating $output_file. Output is: \n".YAML::Dump($diff),"\n";
YAML::DumpFile($output_file,$diff);



sub diff {
	my $previous = shift;
	my $current = shift;
	defined( my $level = shift ) or croak "incorrect call to diff";
	defined( my $period = shift ) or croak "incorrect call to diff";
	defined( my $factor = shift ) or croak "incorrect call to diff";

	my $spacer = ' 'x$level;

	if( ! defined($previous)) {
		$debug && print STDERR $spacer,"previous undefined, returning trivial result\n";
		return diff($current,$current,$level,$period,$factor);
	}
	if( ! defined($current)) {
		$debug && print STDERR $spacer,"current undefined, returning trivial result\n";
		return diff($previous,$previous,$level,$period,$factor);
	}
	

	if( (ref($previous) eq '') && ( ref($current) eq '') ) {
		$debug && print STDERR $spacer,"Comparing $previous and $current \n";
		my $result = int $factor*($current - $previous)/($period);
		return ($result >= 0)? $result : 0;
	}
	elsif( (ref($previous) eq 'HASH') && ( ref($current) eq 'HASH') ) {
		$debug && print STDERR $spacer,"Comparing two hashes\n";
		my $return_hash_ref = {};
		for my $item (keys %{$current}) {
			$debug && print STDERR $spacer,"key $item\n";
			$return_hash_ref->{$item} = diff($previous->{$item},$current->{$item},$level+1,$period,$factor);
		}
		return $return_hash_ref;
	}
	else {
		croak "Cannot compare a ".ref($previous)." and a ".ref($current)."\n";
	}
	
}

