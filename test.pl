# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { unshift @INC, 'blib/lib', 'examples'; }
BEGIN { $| = 1; print "1..9\n"; }
END {print "There were problems!\n" unless $sum == @r;}
END {print "Passed\n" if $sum == @r;}

use RDF::Notation3::Triples;
use RDF::Notation3::PrefTriples;
use RDF::Notation3::XML;
use MyHandler;
use MyErrorHandler;

# 1
$r[0] = 1;
print "not ok 1\n" unless $r[0];
print "ok 1\n" if $r[0];

# 2
$rdf = new RDF::Notation3::Triples;
$rc = $rdf->parse_file('examples/test01.n3');
$r[1] = 1 if $rc;
print "not ok 2\n" unless $r[1];
print "ok 2\n" if $r[1];

# 3
$rc = $rdf->parse_file('examples/test02.n3');
$r[2] = 1 if $rc;
print "not ok 3\n" unless $r[2];
print "ok 3\n" if $r[2];

# 4
$rc = $rdf->parse_file('examples/test03.n3');
$r[3] = 1 if $rc;
print "not ok 4\n" unless $r[3];
print "ok 4\n" if $r[3];

# 5
$rc = $rdf->parse_file('examples/test04.n3');
$r[4] = 1 if $rc;
print "not ok 5\n" unless $r[4];
print "ok 5\n" if $r[4];


##################################################
my $rdf = new RDF::Notation3::PrefTriples;

# 6
$rc = $rdf->parse_file('examples/test04.n3');
$r[5] = 1 if $rc;
print "not ok 6\n" unless $r[5];
print "ok 6\n" if $r[5];


##################################################
my $rdf = new RDF::Notation3::XML;

# 7
$rc = $rdf->parse_file('examples/test03.n3');
$r[6] = 1 if $rc;
print "not ok 7\n" unless $r[6];
print "ok 7\n" if $r[6];

# 8
$rc = $rdf->parse_file('examples/test04.n3');
$r[7] = 1 if $rc;
print "not ok 8\n" unless $r[7];
print "ok 8\n" if $r[7];

##################################################
# SAX
# 9
eval { require XML::SAX };
if ($@) {
    $r[8] = 1;
    print "9 skipped (XML::SAX not found)\n";
} else { 
    chdir('examples');
    my $ret = `perl sax.pl test04.n3`;
    chdir('..');
    $ret =~ /(\d+)$/ and my $rc = $1;
    $r[8] = 1 if $rc == 17;
    print "not ok 9\n" unless $r[8];
    print "ok 9\n" if $r[8];
}

##################################################
# add_prefix/triple
# 10
$rdf = new RDF::Notation3::Triples;
$rc = $rdf->parse_file('examples/test01.n3');
$rdf->add_prefix('x','http://www.example.org/x');
$rc = $rdf->add_triple('<uri>','x:prop','"literal"');
$r[9] = 1 if $rc == 5;
print "not ok 10\n" unless $r[9];
print "ok 10\n" if $r[9];

##################################################
# test string parsing
# 11
$rc = $rdf->parse_file('examples/test05.n3');
$r[10] = 1 if $rc;
print "not ok 11\n" unless $r[10];
print "ok 11\n" if $r[10];

$sum = 0;
foreach (@r) {
    $sum += $_;
}
