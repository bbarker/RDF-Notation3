use strict;
use warnings;

package RDF::Notation3::Reader;

require 5.005_62;

############################################################

sub new {
    my ($class, $fh) = @_;

    my $self = {
		FILE => $fh,
		tokens => [],
		ln => 0,
	       };

    bless $self, $class;
    return $self;
}

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


sub _new_line {
    my ($self) = @_;

    my $fh = $self->{FILE};
    my $line = <$fh>;
    $self->{ln}++;

    if ($line) {
	$line =~ s/^\s*(.*)$/$1/;

	push @{$self->{tokens}}, split /\s+/, $line 
	  unless $line =~ /^\s*$/;
	push @{$self->{tokens}}, ' EOL ';
	push @{$self->{tokens}}, ' EOF ' if eof;
    } else {
	return if eof;
	$self->_new_line;
    }
}


1;

__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::Reader - RDF Notation3 file reader

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut

