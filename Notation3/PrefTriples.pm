use strict;
use warnings;

package RDF::Notation3::PrefTriples;

require 5.005_62;
use RDF::Notation3;
use RDF::Notation3::Template::TTriples;

############################################################

@RDF::Notation3::PrefTriples::ISA = 
  qw(RDF::Notation3 RDF::Notation3::Template::TTriples);


sub _process_statement {
    my ($self, $subject, $properties) = @_;

    foreach (@$properties) {

	for (my $i = 1; $i < scalar @$_; $i++ ) {

	    push @{$self->{triples}}, 
	      [$subject, $_->[0], $_->[$i], $self->{context}];
	}
    }
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Triples - RDF/N3 generator of triples with prefixes

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut
