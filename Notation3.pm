use strict;
use warnings;

package RDF::Notation3;

require 5.005_62;
use File::Spec::Functions ();
use Carp;
use RDF::Notation3::ReaderFile;
use RDF::Notation3::ReaderString;

our $VERSION = '0.30';

############################################################

sub new {
    my ($class) = @_;

    my $self = {
	ansuri => '#',
    };

    bless $self, $class;
    return $self;
}


sub parse_file {
    my ($self, $path) = @_;

    $self->{ns} = {};
    $self->{context} = '<>';
    $self->{gid} = 1;
    $self->{cid} = 1;

    open(FILE, "$path") or $self->_do_error(2, $path);
    my $fh = *FILE;
    my $t = new RDF::Notation3::ReaderFile($fh);
    $self->{reader} = $t;

    $self->_document;

    close (FILE);
}


sub parse_string {
    my ($self, $str) = @_;

    $self->{ns} = {};
    $self->{context} = '<>';
    $self->{gid} = 1;
    $self->{cid} = 1;

    my $t = new RDF::Notation3::ReaderString($str);
    $self->{reader} = $t;

    $self->_document;
}


sub anonymous_ns_uri {
    my ($self, $uri) = @_;
    if (@_ > 1) {
	$self->{ansuri} = $uri;
    } else {
	return $self->{ansuri};
    }
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

    while ($next eq ' EOL ') {
	$self->{reader}->get;
	$next = $self->{reader}->try;
    }

    if ($next ne ' EOF ') {
	if ($next =~ /^(|#.*)$/) {
	    $self->_space;
	    $self->_statement_list;

	} elsif ($next =~ /^}/) {
	    #print ">end of nested statement list: $next\n";

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
	    $self->_do_error(102,$tk);	    
	}
    } else {
	$self->_do_error(101,$tk);
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
	#print ">qname ($1:)\n" if $1;

	my $pref = '';
	$pref = $1 if $1;
	if ($pref eq '_') {  #prefix can be in use
	    $self->{ns}->{$self->{context}}->{_} = $self->{ansuri}
		unless $self->{ns}->{$self->{context}}->{_};

	}
	return $tk;

    } else {
	$self->_do_error(103,$tk);
    }
}


sub _property_list {
    my ($self, $properties) = @_;
    my $next = $self->{reader}->try;
    #print ">property list: $next\n";

    while ($next eq ' EOL ') {
	$self->{reader}->get;
	$next = $self->{reader}->try;
    }

    if ($next =~ /^:-/) {
	#print ">anonnode\n";
	# TBD
	$self->_do_error(202, $next);

    } elsif ($next eq '.') {
	#print ">void prop_list\n";
	# TBD

    } else {
	#print ">prop_list with verb\n";
	my $property = $self->_verb;
	#print ">property is back: $property\n";

	my $objects = [];
	$self->_object_list($objects);
	unshift @$objects, $property;
	unshift @$objects, 'i' if ($next eq 'is' or $next eq '<-');
	#print ">inverse mode\n" if ($next eq 'is' or $next eq '<-');
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
	$self->{reader}->get;
	return $self->_node;

    } elsif ($next eq '>-') {
	$self->{reader}->get;
	my $node = $self->_node;
	my $tk = $self->{reader}->get;
	$self->_do_error(104,$tk) unless $tk eq '->';	    
	return $node;

    } elsif ($next eq 'is') {
	$self->{reader}->get;
	my $node = $self->_node;
	my $tk = $self->{reader}->get;
	$self->_do_error(109,$tk) unless $tk eq 'of';
	return $node;

    } elsif ($next eq '<-') {
 	$self->{reader}->get;
 	my $node = $self->_node;
 	my $tk = $self->{reader}->get;
 	$self->_do_error(110,$tk) unless $tk eq '-<';	    
 	return $node;

    } elsif ($next eq 'a') {
	$self->{reader}->get;
	$self->{ns}->{$self->{context}}->{rdf} #prefix can be in use
	  = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' 
	    unless $self->{ns}->{$self->{context}}->{rdf};
	return 'rdf:type'

    } elsif ($next eq '=') {
	$self->{reader}->get;
	$self->{ns}->{$self->{context}}->{daml} #prefix can be in use
	  = 'http://www.daml.org/2000/10/daml-ont#' 
	    unless $self->{ns}->{$self->{context}}->{daml};
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

    while ($next eq ' EOL ') {
	$self->{reader}->get;
	$next = $self->{reader}->try;
    }

    if ($next =~ /^#/) { # comment inside object list
	$self->_space;	
	
    } else {
	# possible end of entity, check for sticked next char is done
	while ($next =~ /^(.+)([,;\.\}\]\)])$/) {
	    $self->{reader}->{tokens}->[0] = $2;
	    unshift @{$self->{reader}->{tokens}}, $1;
	    $next = $1;
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

    while ($next eq ' EOL ') {
	$self->{reader}->get;
	$next = $self->{reader}->try;
    }

    if ($next =~ /^"(\\"|[^\"])*"$/) {
	#print ">complete string1: $next\n";
	my $tk = $self->{reader}->get;
	return $tk;

    } elsif ($next =~ /^"""(.*)"""$/) {
	#print ">complete string2: $next\n";
	my $tk = $self->{reader}->get;
	return $tk;

    } elsif ($next eq '"' or $next =~ /^"[^\"]+/) {
	#print ">start of string1: $next\n";
	my $tk = $self->{reader}->get;
	$tk = $tk . ' ' . $self->{reader}->get if $tk eq '"';
	until ($tk =~ /"[\.;,\]\}\)]?$/) {
	    my $next = $self->{reader}->try;
	    #print ">next part: $next\n";
	    my $tk2;
	    if ($next =~ /^(\\"|[^\"])*"?([\.;,\]\}\)])?$/) {
		$tk2 = $self->{reader}->get;
		$tk .= " $tk2";
	    } else {
		$self->_do_error(105, $next);
	    }
	    $self->_do_error(111, $tk2) if $tk2 eq ' EOF ';
	}
	if ($tk =~ s/^(.*)"([\.;,\]\}\)])$/$1"/) {
	    unshift @{$self->{reader}->{tokens}}, $2;
	}
	$self->_do_error(114, $tk) if $tk =~ / EOL /;
	return $tk;

    } elsif ($next eq '"""' or $next =~ /^"""[^\"]+/) {
	#print ">start of string2: $next\n";
	my $tk = $self->{reader}->get;
	$tk = $tk . ' ' . $self->{reader}->get if $tk eq '"""';
	until ($tk =~ /"""[\.;,\]\}\)]?$/) {
	    my $next = $self->{reader}->try;
	    #print ">next part: $next\n";
	    my $tk2;
	    if ($next =~ /^(.)*(""")?([\.;,\]\}\)])?$/) {
		$tk2 = $self->{reader}->get;
		$tk .= " $tk2";
	    } else {
		$self->_do_error(112, $next);
	    }
	    $self->_do_error(113, $tk2) if $tk2 eq ' EOF ';
	}
	if ($tk =~ s/^(.*)"""([\.;,\]\}\)])$/$1"/) {
	    unshift @{$self->{reader}->{tokens}}, $2;
	}
	$tk =~ s/  EOL  /\n/g;
	return $tk;

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
	my $genid = "<$self->{ansuri}g_$self->{gid}>";
	$self->{gid}++;
	$self->_statement($genid);

	# next step
	my $tk = $self->{reader}->get;
	if ($tk =~ /^\]([,;\.])$/) {
	    unshift @{$self->{reader}->{tokens}}, $1;
	} elsif ($tk ne ']') {
	    $self->_do_error(107, $tk);
	}
	return $genid;

    } elsif ($1 eq '{') {
	#print ">anonnode: {}\n";
	my $genid = "<$self->{ansuri}c_$self->{cid}>";
	$self->{cid}++;

	# ns mapping is passed to inner context
	$self->{ns}->{$genid} = {};
	foreach (keys %{$self->{ns}->{$self->{context}}}) {
	    $self->{ns}->{$genid}->{$_} = 
	      $self->{ns}->{$self->{context}}->{$_};
	    #print ">prefix '$_' passed to inner context\n";
	}

	my $parent_context = $self->{context};
	$self->{context} = $genid;
	$self->_statement_list;
	$self->{context} = $parent_context;

	# next step
 	my $tk = $self->{reader}->get;
 	$tk = $self->{reader}->get if $tk eq ' EOL ';

	if ($tk =~ /^\}([,;\.])?$/) {
	    unshift @{$self->{reader}->{tokens}}, $1 if $1;
	} else {
	    $self->_do_error(108, $tk);
	}
	return $genid;

    } else {
	#print ">anonnode: ()\n";
	$self->_do_error(201, 'n/a');
    }
}


########################################

sub _do_error {
    my ($self, $n, $tk) = @_;

    my %msg = (
	1   => 'file not specified',
	2   => 'file not found',
	3   => 'string not specified',

	101 => 'bind directive is obsolete, use @prefix instead',
	102 => 'invalid namespace prefix',
	103 => 'invalid URI reference (uri_ref2)',
	104 => 'end of verb (->) expected',
	105 => 'invalid characters in string1',
	106 => 'namespace prefix not bound',
	107 => 'invalid end of annonode, ] expected',
	108 => 'invalid end of annonode, } expected',
	109 => 'end of verb (of) expected',
	110 => 'end of verb (-<) expected',
	111 => 'string1 is not terminated',
	112 => 'invalid characters in string2',
	113 => 'string2 is not terminated',
	114 => 'string1 can\'t include newlines',

	201 => 'anonymous node of type () not supported yet',
	202 => ':- token not supported yet',
	);

    my $msg = "[Error $n]";
    $msg .= " line $self->{reader}->{ln}, token" if $n > 100;
    $msg .= " \"$tk\"\n";
    $msg .= "$msg{$n}!\n";
    croak $msg;
}


1;

