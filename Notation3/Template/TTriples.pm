use strict;
use warnings;

package RDF::Notation3::Template::TTriples;

require 5.005_62;

############################################################

sub parse {
    my ($self, $path) = @_;

    $self->{triples} = [];

    $self->SUPER::parse($path);
}


sub get_triples {
    my ($self, $subj, $verb, $obj, $context) = @_;
    my @triples = ();

    foreach (@{$self->{triples}}) {
	if (not $subj or ($subj eq $_->[0])) {
	    if (not $verb or ($verb eq $_->[1])) {
		if (not $obj or ($obj eq $_->[2])) {
		    if (not $context or ($context eq $_->[3])) {
			push @triples, $_;
		    }
		}
	    }
	}
    }
    return \@triples;
}


1;


__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Template::TTriples - a triple generator template

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut
