# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { unshift @INC, 'blib/lib'; }
BEGIN { $| = 1; print "1..5\n"; }
END {print "There were problems!\n" unless $sum == 5;}
END {print "Passed\n" if $sum == 5;}

use RDF::Notation3::Triples;

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

$sum = 0;
foreach (@r) {
    $sum += $_;
}


