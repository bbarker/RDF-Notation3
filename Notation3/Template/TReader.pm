use strict;
#use warnings;

package RDF::Notation3::Template::TReader;

require 5.005_62;

############################################################


sub get {
    my ($self) = @_;

    unless ($self->{tokens}->[0]) {
	$self->_new_line;
    }

    return shift @{$self->{tokens}};
}

sub try {
    my ($self) = @_;

    unless ($self->{tokens}->[0]) {
	$self->_new_line;
    }

    return $self->{tokens}->[0];
}

1;

__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Template::TReader - RDF Notation3 file reader template

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut

