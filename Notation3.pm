use strict;
use warnings;

package RDF::Notation3;

require 5.005_62;
use File::Spec::Functions ();
use Carp;
use RDF::Notation3::Reader;

our $VERSION = '0.20';

############################################################

sub new {
    my ($class) = @_;

    my $self = {
	ansuri => 'http://gingerall.org/n3/anonymous',
    };

    bless $self, $class;
    return $self;
}


sub parse {
    my ($self, $path) = @_;
    $path = '.'   unless @_ > 1;

    $self->{ns} = {};
    $self->{context} = '<>';
    $self->{gid} = 1;
    $self->{cid} = 1;

    open(FILE, "$path") or croak "Can't open $path for reading!";
    my $fh = *FILE;
    my $t = new RDF::Notation3::Reader($fh);
    $self->{reader} = $t;

    $self->_document;

    close (FILE);
}


sub _document {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">doc starts: $next\n";
    if ($next ne ' EOF ') {
	$self->_statement_list;
    }
}


sub _statement_list {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">statement list: $next\n";

    if ($next ne ' EOF ') {
	if ($next =~ /^(|#.*)$/) {
	    $self->_space;
	    $self->_statement_list;
	} elsif ($next eq ' EOL ') {
	    $self->{reader}->get;
	    $self->_statement_list;	    
	} else {
	    $self->_statement;	    
	}
    } else {
	#print ">end\n";
    }
}


sub _space {
    my ($self) = @_;
    #print ">space: ";

    my $tk = $self->{reader}->get;
    # comment or empty string
    while ($tk ne ' EOL ') {
	#print ">$tk ";
	$tk = $self->{reader}->get;
    }
    #print ">\n";
}


sub _statement {
    my ($self, $subject) = @_;
    my $next = $self->{reader}->try;
    #print ">statement starts: $next\n";

    if ($next =~ /^(\@prefix|bind)$/) {
	$self->_directive;
	
    } else {
	$subject = $self->_node unless $subject;
	#print ">subject: $subject\n";

	my $properties = [];
	$self->_property_list($properties);
	
	$self->_process_statement($subject, $properties)
    }
    # next step
    $next = $self->{reader}->try;
    if ($next eq '.') {
	$self->{reader}->get;
	$self->_statement_list;
    }
}


sub _node {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">node: $next\n";

    if ($next =~ /^([\[\{\(])(.*)$/) {
	#print ">node is anonnode\n";
	return $self->_anonymous_node;

    } elsif ($next eq 'this') {
	#print ">this\n";
	$self->{reader}->get;
	return "$self->{context}";

    } else {
	#print ">node is uri_ref2: $next\n";
	return $self->_uri_ref2;
    }
}


sub _directive {
    my ($self) = @_;
    my $tk = $self->{reader}->get;
    #print ">directive: $tk\n";

    if ($tk eq '@prefix') {
	my $tk = $self->{reader}->get;
	if ($tk =~ /^([_a-zA-Z]\w*)*:$/) {
	    my $pref = $1;
	    #print ">nprefix: $pref\n" if $pref;

	    my $ns_uri = $self->_uri_ref2;
	    $ns_uri =~ s/^<(.*)>$/$1/;

	    if ($pref) {
		$self->{ns}->{$self->{context}}->{$pref} = $ns_uri;
	    } else {
		$self->{ns}->{$self->{context}}->{''} = $ns_uri;
	    }
	} else {
	    $self->_do_error(2,$tk);	    
	}
    } else {
	$self->_do_error(1,$tk);
    }
}


sub _uri_ref2 {
    my ($self) = @_;

    # possible end of statement, a simple . check is done
    my $next = $self->{reader}->try;
    if ($next =~ /^(.+)\.$/) {
	$self->{reader}->{tokens}->[0] = '.';
	unshift @{$self->{reader}->{tokens}}, $1;
    }

    my $tk = $self->{reader}->get;
    #print ">uri_ref2: $tk\n";

    if ($tk =~ /^<.*>$/) {
	#print ">URI\n";
	return $tk;
    } elsif ($tk =~ /^([_a-zA-Z]\w*)*:[a-zA-Z]\w*$/) {
	#print ">qname\n";
	return $tk;
    } else {
	$self->_do_error(3,$tk);
    }
}


sub _property_list {
    my ($self, $properties) = @_;
    my $next = $self->{reader}->try;
    #print ">property list: $next\n";

    if ($next eq ' EOL ') {
	$self->{reader}->get;
	$self->_property_list($properties);	    
    } elsif ($next =~ /^:-/) {
	#print ">anonnode\n";
	# TBD
    } elsif ($next eq '.') {
	#print ">void prop_list\n";
	# TBD
    } else {
	my $property = $self->_verb;
	#print ">property is back: $property\n";

	my $objects = [];
	$self->_object_list($objects);
	unshift @$objects, $property;
	push @$properties, $objects;
    }

    # next step
    $next = $self->{reader}->try;
    if ($next eq ';') {
	$self->{reader}->get;
	$self->_property_list($properties);
    }
}


sub _verb {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">verb: $next\n";

    if ($next eq 'has') {
	#print ">verb: $next\n";
	$self->{reader}->get;
	return $self->_node;

    } elsif ($next eq '>-') {
	#print ">verb: $next\n";
	$self->{reader}->get;
	my $node = $self->_node;
	my $tk = $self->{reader}->get;
	$self->_do_error(4,$tk) unless $tk eq '->';	    
	return $node;

    } elsif ($next eq 'a') {
	$self->{reader}->get;
	return 'rdf:type'

    } elsif ($next eq '=') {
	$self->{reader}->get;
	return 'daml:equivalentTo';

    } else {
	#print ">property: $next\n";
	return $self->_node;
    }
}


sub _object_list {
    my ($self, $objects) = @_;
    my $next = $self->{reader}->try;
    #print ">object list: $next\n";

    if ($next eq ' EOL ') {
	$self->{reader}->get;
	$self->_object_list($objects);	    
    } else {
	# possible end of object, a simple , check is done
	if ($next =~ /^(.+),$/) {
	    $self->{reader}->{tokens}->[0] = ',';
	    unshift @{$self->{reader}->{tokens}}, $1;
	}
	# possible end of property, a simple ; check is done
	if ($next =~ /^(.+);$/) {
	    $self->{reader}->{tokens}->[0] = ';';
	    unshift @{$self->{reader}->{tokens}}, $1;
	}
	# possible end of statement, a simple . check is done
	if ($next =~ /^(.+)\.$/) {
	    $self->{reader}->{tokens}->[0] = '.';
	    unshift @{$self->{reader}->{tokens}}, $1;
	}

	my $obj = $self->_object;
	#print ">object is back: $obj\n";
	push @$objects, $obj;

	# next step
	$next = $self->{reader}->try;
	if ($next eq ',') {
	    $self->{reader}->get;
	    $self->_object_list($objects);
	}
    }
}


sub _object {
    my ($self) = @_;
    my $next = $self->{reader}->try;
    #print ">object: $next\n";

    if ($next eq ' EOL ') {
	$self->{reader}->get;
	$self->_object;

    } elsif ($next =~ /^"(\\"|[^\"])*"$/) {
	#print ">complete string1: $next\n";
	my $tk = $self->{reader}->get;
	return $tk;

    } elsif ($next =~ /^"/) {
	#print ">start of string1: $next\n";
	my $tk = $self->{reader}->get;

	until ($tk =~ /"$/) {
	    my $next = $self->{reader}->try;
	    #print ">next part: $next\n";

	    if ($next =~ /^(\\"|[^\"])*"?[\.;,]?$/) {
		my $tk2 = $self->{reader}->get;
		$tk .= " $tk2";

		if ($tk2 =~ /"[\.;,]?$/) {
		    # possible end of object, property or statement
		    if ($tk =~ s/^(.*)\.$/$1/) {
			unshift @{$self->{reader}->{tokens}}, '.';
		    }
		    if ($tk =~ s/^(.*)\;$/$1/) {
			unshift @{$self->{reader}->{tokens}}, ';';
		    }
		    if ($tk =~ s/^(.*)\,$/$1/) {
			unshift @{$self->{reader}->{tokens}}, ',';
		    }
		    return $tk;
		}
	    } else {
		$self->_do_error(5, $next);
	    }
	}
    } else {
	#print ">object is node: $next\n";
	$self->_node;
    }
}


sub _anonymous_node {
    my ($self) = @_;
    #print ">anonnode1: $1\n";
    #print ">anonnode2: $2\n";

    $self->{reader}->get;
    unshift @{$self->{reader}->{tokens}}, $2 if $2;

    if ($1 eq '[') {
	#print ">anonnode: []\n";
	my $genid = "<$self->{ansuri}#g_$self->{gid}>";
	$self->{gid}++;
	$self->_statement($genid);

	# next step
	my $tk = $self->{reader}->get;
	if ($tk =~ /^\]([,;\.])$/) {
	    unshift @{$self->{reader}->{tokens}}, $1;
	} elsif ($tk ne ']') {
	    $self->_do_error(7, $tk);
	}
	return $genid;

    } elsif ($1 eq '{') {
	#print ">anonnode: {}\n";
	$self->_do_error(10, 'n/a');

    } else {
	#print ">anonnode: ()\n";
	$self->_do_error(11, 'n/a');
    }
}


########################################

sub _do_error {
    my ($self, $n, $tk) = @_;

    my @msg = (
	       'bind directive is obsolete, use @prefix instead', #1
	       'invalid namespace prefix', #2
	       'invalid URI reference (uri_ref2)', #3
	       'end of verb (->) expected', #4
	       'invalid characters in string', #5
	       'namespace prefix not defined', #6
	       'invalid end of annonode, ] expected', #7
	       '', #8
	       '', #9
	       'anonymous node of type {} not supported yet', #10
	       'anonymous node of type () not supported yet', #11
	      );

    my $msg = "[Error $n] line $self->{reader}->{ln}, token \"$tk\"\n"
      ."$msg[$n-1]!\n";
    croak $msg;
}


1;
