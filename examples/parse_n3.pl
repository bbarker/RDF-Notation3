#!/usr/bin/perl

use strict;

BEGIN {
    unshift @INC, 
    "/home/petr/devel/perl-modules/RDF-Notation3/blib/lib",
    "/home/petr/devel/perl-modules/RDF-Notation3/blib/arch";
}

use RDF::Notation3::Triples;

(@ARGV == 1 ) || die ("Usage: parse_n3.pl file\n\n");

my $file = shift;

my $rdf = new RDF::Notation3::Triples;
my $rc  = $rdf->parse_file($file);

# namespaces
foreach my $c (keys %{$rdf->{ns}}) {
    foreach (keys %{$rdf->{ns}->{$c}}) {
	print "NS: $c: $_ -> $rdf->{ns}->{$c}->{$_}\n";
    }
}

# triples
my $triples = $rdf->get_triples;
 foreach (@$triples) {
    print "$_->[3]: $_->[0] - $_->[1] - $_->[2]\n";
 }

exit 0;



