use strict;
use warnings;

package RDF::Notation3::ReaderString;

require 5.005_62;
use RDF::Notation3::Template::TReader;

############################################################

@RDF::Notation3::ReaderString::ISA = qw(RDF::Notation3::Template::TReader);

sub new {
    my ($class, $str) = @_;
    my @lines = split /[\n\r]+/, $str;

    my $self = {
		lines => \@lines,
		tokens => [],
		ln => 0,
	       };

    bless $self, $class;
    return $self;
}

sub _new_line {
    my ($self) = @_;

    my $line = shift @{$self->{lines}};
    $self->{ln}++;

    if ($line) {
	$line =~ s/^\s*(.*)$/$1/;

	push @{$self->{tokens}}, split /\s+/, $line 
	  unless $line =~ /^\s*$/;
	push @{$self->{tokens}}, ' EOL ';
	push @{$self->{tokens}}, ' EOF ' unless scalar @{$self->{lines}};
    } else {
	return unless scalar @{$self->{lines}};
	$self->_new_line;
    }
}


1;

__END__
# Below is a documentation.

=head1 NAME

RDF::Notation3::ReaderString - RDF Notation3 string reader

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

perl(1), RDF::Notation3.

=cut

