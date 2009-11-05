# deprecated

package Template::TT3::Tokeniser;

use Template::TT3::Class
    base      => 'Template::TT3::Tokens',
    version   => 3.00,
    debug     => 0,
    import    => 'class',
    constants => ':whitespace :op_slots REGEX',
    utils     => 'blessed',
    patterns  => ':all',
    constant  => {
        FACTORY => 'Template::TT3::Tokens',
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

*init = \&init_tokeniser;

sub init_tokeniser {
    my ($self, $config) = @_;
    $self->init_tokens($config);
    $self->{ match_op } = qr{ \G (\+|\-|\*|\/) }x;
    $self->{ ops } = {
        '+' => 'plus',
        '-' => 'minus',
        '*' => 'multiply',
        '/' => 'divide',
    };
    return $self;
}


#-----------------------------------------------------------------------
# parsing methods
#-----------------------------------------------------------------------

sub tokenise {
    my ($self, $source) = @_;
    my $text = ref $source 
        ? $source
        : \$source;
    return $self->tokens($text);
}


sub tokens {
    my ($self, $text) = @_;
    my (@tokens, $token, $type, $pos);
    
    while (1) {
        $pos = pos $$text;
        
        if ($$text =~ /$NAMESPACE/cog) {
            $token = $self->namespace_token($text, $1, $pos);
        }
        elsif ($$text =~ /$IDENT/cog) {
            if ($type = $self->{ keywords }->{ $1 }) {
                $token = [$type => $1];
            }
            else {
                $token = [ word => $1 ];
            }
        }
        elsif ($$text =~ /$NUMBER/cog) {
            $token = [ number => $1 ];
        }
        elsif ($$text =~ /$SQUOTE/cog) {
            $token = [ squote => $1 ];
        }
        elsif ($$text =~ /$DQUOTE/cog) {
            $token = [ dquote => $1 ];
        }
        elsif ($$text =~ /$self->{ match_op }/cg) {
            $type = $self->{ ops }->{ $1 }
                || return $self->error_msg( invalid => op => $1 );
            $token = [ $type => $1 ];
        }
        elsif ($$text =~ /$self->{ match_whitespace }/cg) {
            $token = [ whitespace => $1 ];
        }
        elsif ($$text =~ / \G \z /sxcg) {
            $self->debug("matched EOF");
            last;
        }
        else {
            return $self->error("Unexpected input: [", $self->remaining_text($text), "]");
        }
        
#        $self->debug('+ ', $token->[0], ' => ', $token->[1]);
        push(@tokens, $token);
    }

    return \@tokens;
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


