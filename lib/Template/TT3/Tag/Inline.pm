package Template::TT3::Tag::Inline;

use Template::TT3::Grammar::TT3;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag::Closed',
    import    => 'class',
    utils     => 'blessed',
    patterns  => ':all',
    constants => 'HASH ARRAY REGEX NONE',
    constant  => {
        GRAMMAR => 'Template::TT3::Grammar::TT3',
    };


#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------
 
sub init {
    my $self   = shift;
    my $config = shift || $self->{ config };
    $self->init_flags($config);     # inherited from T::Tag::Closed
    $self->init_tag($config);       # inherited from T::Tag
    $self->init_grammar($config);   # implemented by us
    $self->{ config } = $config;
    return $self;
}


sub init_grammar {
    my $self    = shift;
    my $config  = shift || $self->{ config };
    my $grammar = $config->{ grammar } 
               || $self->class->any_var('GRAMMAR')
               || $self->GRAMMAR;
    
    $grammar = $grammar->new($config)
        unless blessed $grammar;
    
    $self->{ grammar  } = $grammar;
    $self->{ keywords } = $grammar->keywords;
    $self->{ nonwords } = $grammar->nonwords;
    $self->{ match_nw } = $grammar->nonword_regex;

    return $self;
}



#-----------------------------------------------------------------------
# Scannning methods
#-----------------------------------------------------------------------

sub tokens {
    my ($self, $input, $output, $token, $pos) = @_;
    my $type;

    while (1) {
        $self->debug("SCAN \@$pos: ", $self->peek_to_end($input)) if DEBUG;
        
        # TODO: consider generating the tokens in here and calling
        # $output->token($token)

        if ($$input =~ /$NAMESPACE/cog) {
            $self->namespace_token($input, $output, $1, $pos);
        }
        elsif ($$input =~ /$IDENT/cog) {
            if ($type = $self->{ keywords }->{ $1 }) {
                $self->{ grammar }->matched($input, $output, $pos, $1);
                # TMP HACK
                # $output->keyword_token($1, $pos);
                # TODO:
                # $type = "${type}_token";
                # $output->$type($1, $pos);
            }
            else {
                $output->word_token($1, $pos);
            }
        }
        elsif ($$input =~ /$SQUOTE/cog) {
            $self->debug("matched single quote: $1") if DEBUG;
            $output->squote_token($1, $pos);
        }
        elsif ($$input =~ /$DQUOTE/cog) {
            $self->debug("matched double quote: $1") if DEBUG;
            $output->dquote_token($1, $pos);
        }
        elsif ($$input =~ /$self->{ match_at_end }/cg) {
            $self->debug("matched end of tag: $1") if DEBUG;

            # add the tag end token and return it to scan() so it can 
            # identify any post-chomping flags
            $output->tag_end_token($1, $pos) 
                if  defined $1 && length $1;
                
            return $1;
        }
        elsif ($$input =~ /$self->{ match_nw }/cg) {
            $self->{ grammar }->matched($input, $output, $pos, $1);
        }
        elsif ($$input =~ /$NUMBER/cog) {
            $self->debug("matched number: $1") if DEBUG;
            $output->number_token($1, $pos);
        }
        elsif ($$input =~ /$self->{ match_whitespace }/cg) {
            $output->whitespace_token($1, $pos);
        }
        else {
            return $self->error("Unexpected input: [", $self->peek_to_end($input), "]");
        }
        
        $pos = pos $$input;
    }

    return 0;
}


1;