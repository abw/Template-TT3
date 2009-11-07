# NOTE: this is redundant now.  I just want to extract the quote escaping
# subs before trashing it.
#========================================================================
#
# Template::TT3::Parser
#
# DESCRIPTION
#   This is a work in progress based on a previous incarnation of the 
#   TT3 parser.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Parser;

use Template::TT3::Ops;
use Template::TT3::Class
    base      => 'Template::TT3::Tokens',
    version   => 3.00,
    debug     => 0,
    import    => 'class',
    constants => ':whitespace :op_slots REGEX',
    utils     => 'blessed',
    patterns  => ':all',
    constant  => {
        OPS_FACTORY => 'Template::TT3::Ops',
    },
    messages  => {
        missing        => "Missing '%s' %s",
        missing_at     => "Missing '%s' at %s",
        missing_at_got => "Missing '%s' at %s, got: %s",
#        not_a_var     => "'%s' is not a variable",
#        not_a_var_msg => "'%s' is not a variable (%s)",
#        bad_symbol    => 'Invalid symbol scanned: %s',
    };


our $NAMESPACES = {
    var => \&parse_variable,
    q   => \&parse_q,
};

our $QUOTED_ESCAPES = {
    n    => "\n",
    r    => "\r",
    t    => "\t",
    '\\' => '\\',
    '"'  => '"',
};



#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------

*init = \&init_parser;

sub init_parser {
    my ($self, $config) = @_;
    $self->init_tokens($config);        # inherited from T::Tokens mixin
    
    $self->{ ops_factory } = $config->{ ops_factory } || $self->OPS_FACTORY;
    $self->{ ops         } = $self->{ ops_factory }->new($config);
    $self->{ make_op     } = $self->{ ops }->constructors;
    $self->{ keywords    } = $config->{ keywords   };
    $self->{ namespaces  } = $self->class->hash_vars( 
        NAMESPACES => $config->{ namespaces } 
    );
    
    return $self;
}


#-----------------------------------------------------------------------
# parsing methods
#-----------------------------------------------------------------------

sub parse {
    my ($self, $source) = @_;
    my $text = ref $source 
        ? $source
        : \$source;
    return $self->parse_exprs($text);
}


sub parse_exprs {
    my ($self, $text) = @_;
    my ($expr, @exprs);
    
    while (1) {
        $$text =~ /$self->{ match_delimiter }/cg;
        last unless $expr = $self->parse_expr($text);
        push(@exprs, $expr);
    }
    
    return @exprs
        ? [ EXPRS => \@exprs ]
        : undef;
}


sub parse_expr {
    # TODO: look out for end of tag and handle rollover
    # Ha ha.  That's not easy at all.
    shift->parse_term(@_);
}

    
sub parse_term {
    my ($self, $text) = @_;

    $self->debug_parse($text, 'parse_term()') if DEBUG;
    
    $$text =~ /$self->{ match_whitespace }/cg;
    
    my $pos = pos $$text;
    my $term;
    
    if ($$text =~ /$NAMESPACE/cog) {
        return $self->parse_namespace($text, $1, $pos);
    }
    elsif ($$text =~ /$IDENT/cog) {
        return $self->{ keywords }->{ $1 }
            ? $self->parsed_keyword($text, $1, $pos)
            : $self->parse_variable($text, $1, $pos);
    }
    elsif ($$text =~ /$NUMBER/cog) {
        return $self->parsed_number($text, $1, $pos);
    }
    elsif ($$text =~ /$SQUOTE/cog) {
        return $self->parsed_squote($text, $1, $pos);
#        return $self->parsed_text($text, $self->unescape($1, "'"), $pos);
    }
    elsif ($$text =~ /$DQUOTE/cog) {
        return $self->parsed_dquote($text, $1, $pos);
#        return $self->parsed_dquote($text, $self->unescape($1, '"'), $pos);
    }
    elsif ($$text =~ /$LBRACKET/cog) {
        $self->todo('list parser');
    }
    elsif ($$text =~ /$LBRACE/cog) {
        $self->todo('hash parser');
    }
    elsif ($$text =~ /$LPAREN/cog) {
        $self->todo('paren parser');
    }
}    


sub parse_variable {
    my $self = shift;
    my $text = $_[0];
    my ($dot, $dotter);
    
    $self->debug_parse($text, 'parse_variable()') if DEBUG;

    my $first = $self->parse_varnode(@_) 
        || return;

#    $first = [ VARIABLE => $first ];

    $first = $self->{ make_op }->{ variable }->(
        $first->[TEXT], $first->[POS], $first
    );
    
    while ($$text =~ /$self->{ match_dotop }/cg) {
        my $next = $self->parse_varnode($text);
        
        # we should call $first->dot_op($right)
        $dotter ||= $self->{ make_op }->{ dot };
        $first = $dotter->( '.', pos($$text) - 1, $first, $next );
#       $first = [ DOTOP => $first, $next ];
    }
    
    return $first;
}


sub parse_varnode {
    my ($self, $text, $name, $pos) = @_;
    my $args;

    $self->debug_parse($text, 'parse_varnode()') if DEBUG;

    unless (defined $name) {
        $$text =~ /$self->{ match_whitespace }/cg;
        $pos ||= pos $$text;
        $$text =~ /$IDENT/cog
            || return;
        $name = $1;
    }

    $self->debug("found varnode: [$name]") if DEBUG;

    # TODO: accept multiple parens
    if ($$text =~ /$LPAREN/cog) {
        $self->debug("found parens on varnode") if DEBUG;
        $args = $self->parse_args($text);
        $$text =~ /$self->{ match_whitespace }/cg;
        $$text =~ /$RPAREN/cog
            || return $self->parse_error_msg($text, missing_at_got => ')', 'end of arguments' );
    }
    else {
        $self->debug("no parens, returning $name") if DEBUG;
    }

    return $self->{ make_op }->{ var_node }->(
        $name, $pos, $name, $args
    );

#    return [ VARNODE => $name, $args ];
}


sub parse_args {
    my ($self, $text) = @_;
    my $pos = pos $$text;
    my ($arg, @args);

    $self->debug_parse($text, 'parse_args()') if DEBUG;

    $$text =~ /$self->{ match_whitespace }/cg;

    while ($arg = $self->parse_term($text)) {
        $self->debug("got arg: $arg ") if DEBUG;
        push(@args, $arg);
        $self->debug_parse($text, "parse_args()  arg:$arg ") if DEBUG;
        $$text =~ /$self->{ match_separator }/cg;
        $self->debug_parse($text, "after separator ") if DEBUG;
    }
    
    $self->debug("got ", scalar(@args), " args") if DEBUG;

    return \@args;
}


sub parse_namespace {
    my ($self, $text, $name, $pos) = @_;

    $self->debug_parse($text, 'parse_varnode()') if DEBUG;

    unless (defined $name) {
        $$text =~ /$self->{ match_whitespace }/cg;
        $pos ||= pos $$text;
        $$text =~ /$NAMESPACE/cog
            || return;
        $name = $1;
    }
    
    my $space = $self->{ namespaces }->{ $name }
        || return $self->error_msg( invalid => namespace => $name );
    
    return $self->$space($text)
        || $self->error_msg( missing => expression => "for namespace: $name" );
}


sub parse_enclosed {
    my ($self, $text, $unescape) = @_;
    $self->debug_parse($text, 'parse_enclosed()') if DEBUG;
    
    if ($$text =~ /$LGROUP/cog) {
        my $left  = $1;
        my $match = $RGROUP->{ $left }
            || return $self->error("No right paren match for '$left'");
        $$text =~ /$match/cg
            || return $self->error_msg( missing => $GROUPS->{ $left } );
            
        return $unescape
            ? $self->unescape($1, $GROUPS->{ $left })
            : $1;
    }
    
    return undef;
}


sub parse_q {
    my ($self, $text) = @_;
    my $term = $self->parse_enclosed($text, 1);
    return defined $term
        ? $self->parsed_text($text, $term)
        : undef;
}


sub parse_qq {
    my ($self, $text) = @_;
    my $term = $self->parse_enclosed($text);
    $term =~ s/\\([nrt])/$QUOTED_ESCAPES->{$1}/ge;

    return defined $term
        ? $self->parsed_text($text, $term)
        : undef;
}


#-----------------------------------------------------------------------
# opcode generators
#-----------------------------------------------------------------------

sub unescape {
    my ($self, $text, $match, $replace) = @_;
    
    $match = quotemeta $match
        unless ref $match eq REGEX;

#    $match = qr/\\(\\|$match)/;
    $match = qr/\\($match)/;
#    $self->debug(" pre: $text");
#    $self->debug("  qm: $match");
    $text =~ s/$match/($replace && $replace->{ $1 }) || $1/ge;
#    $self->debug("post: $text");
    return $text;
}

sub parsed_number {
    my ($self, $text, $num, $pos) = @_;
    return $self->{ make_op }->{ number }->($num, $pos);
#   return [ NUMBER => $_[2] ];
}

sub parsed_text {
    my ($self, $text, $chunk, $pos) = @_;
    return $self->{ make_op }->{ text }->($chunk, $pos);
#    return [ TEXT => $chunk ];
}
    
sub parsed_squote {
    my ($self, $text, $quoted, $pos) = @_;
    return $self->parsed_text($text, $self->unescape($quoted, qr/[\\']/), $pos);
#   return [ SQUOTE => $quoted ];
}

sub parsed_dquote {
    my ($self, $text, $quoted, $pos) = @_;
    $self->debug("  dquoted: $quoted") if DEBUG;
    $quoted =~ s/\\([\\nrt"])/$QUOTED_ESCAPES->{$1}/ge;
    $self->debug("unescaped: $quoted") if DEBUG;

    if ($quoted =~ /\$/) {
        # TODO: look for '$' and expand
        return [ DQUOTE => $quoted, $pos ];
    }
    else {
        return $self->parsed_text($text, $quoted, $pos);
    }
}

sub parsed_ident {
    my ($self, $text, $ident, $pos) = @_;
    return [ IDENT => $ident, $pos ];
}

sub parsed_keyword {
    my ($self, $text, $keyword, $pos) = @_;
    return [ KEYWORD => $keyword, $pos ];
}

    



#-----------------------------------------------------------------------
# extra methods 
#-----------------------------------------------------------------------

sub remaining_text {
    my ($self, $text) = @_;
    my $pos = pos $$text;
#    $self->rewind_pending($text);
    # we should be using the proper match_to_end regex but that ignores
    # off leading whitespace which we're trying to preserve for the sake
    # of testing...
    #   my $result = ($$text =~ /$self->{ match_to_end }/gcsx);
    my $result = $$text =~ /\G(.*)/gcsx;
    pos $$text = $pos;
    return $result ? $1 : '';
}

sub debug_parse {
    my $self = shift;
    my $text = shift;
    $self->debug(@_, ' [', $self->remaining_text($text), ']');
}

sub parse_error_msg {
    my ($self, $text, @args) = @_;
    $self->error_msg(@args, $self->remaining_text($text));
}

    

1;


