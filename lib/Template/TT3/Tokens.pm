#========================================================================
#
# Template::TT3::Tokens
#
# DESCRIPTION
#   Base class module implementing methods for defining patterns to 
#   match various language tokens.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Tokens;

use Template::TT3::Class
    base      => 'Template::TT3::Base',
    version   => 3.00,
    debug     => 0,
    constants => 'NONE',
    utils     => 'blessed',
    patterns  => ':punctuate $DOTOP $NUMBER $IDENT $INDEX $EMBED $INTERP';

our $TAG_STYLE = { 
    # cache for compiled regexes to match against different tag styles
};



#-----------------------------------------------------------------------
# Initialisation methods
#-----------------------------------------------------------------------

*init = \&init_tokens;

sub init_tokens {
    my ($self, $config) = @_;
    my $start = $self->{ tag_start } ||= $config->{ tag_start };
    my $end   = $self->{ tag_end   } ||= $config->{ tag_end   };
    my $style = $self->{ tag_style } = 
        ( defined($start) || defined($end) )
            ? join(' ', map { defined $_ ? $_ : '' } $start, $end)
            : NONE;

    # $style gives a canonical identifier for the tag start/end combination 
    # (e.g. '[% %]') or 'none' if the tag_start and tag_end are undefined 
    # (in case we're parsing "naked" TT code which isn't embedded in tags).
    # We compile a set of regexen to identify the various language tokens 
    # which depend on the tag start and/or end.  This includes things like 
    # comments (which continue to to the end of line or the end of tag), 
    # whitespace (which can include comments), and various operators which 
    # can have whitespace preceeding them.  This set of regexen in cached
    # in the $TAG_STYLE package variable for subsequent parser instances to
    # use.
    
    my $patterns = $TAG_STYLE->{ $style } ||= do {
        $self->debug("Compiling regexen for tag parser style: $style\n") if $DEBUG;
        $self->init_patterns($start, $end);
    };

    $self->debug("Importing match patterns") if $DEBUG;
    
    # import patterns with a match_prefix, e.g. match_whitespace
    @$self{ map { "match_$_" } keys %$patterns } = values %$patterns;
}


sub init_patterns {
    my ($self, $start, $end) = @_;
    my $eol;

    # define a regex to match to the end of the tag if tag_end is 
    # defined or to the end of line (\n) or end of file if not
    if (defined $end) {
        $end = ref $end eq 'Regexp' ? $end : quotemeta($end);
        $eol = qr/
            [^\n]*?        # capture everything on this line non-greedily
            (?: \n         # either match and consumer a newline character
              | (?=        # or look ahead for the end of the text or the        
                 $end      # end-of-tag marker
              )
            ) 
        /sx;
    }
    else {
        $eol = qr/
             [^\n]*        # anything up to end of line
            (?:\n|$)       # end of line or end of file
        /x;
    };
    
    # comments start '#' and extend to the end of line (or end of tag)
    my $comment = qr/ \# $eol /sx;

    # whitespace can contain ignorable comments
    my $wspace = qr/ \s* (?:$comment\s*)* /sx;

    # now construct table of regexen for matching various operators and 
    # other tokens, accounting for any whitespace/comments surrounding
    my $patterns = {
        nothing      => qr / \G /x,
        to_eol       => qr/ \G ($eol) /x,
        whitespace   => qr/ \G ((?:\s+|$comment)+) /x,
#        whitespace   => qr/ \G ($wspace) /sx,
        dotop        => qr/ \G $wspace ($DOTOP) /sx,
        separator    => qr/ \G $wspace ($SEPARATOR) /sx,
        separators   => qr/ \G (?: $wspace $SEPARATOR )* /sx,
        delimiter    => qr/ \G $wspace (?: ($DELIMITER) $wspace)+ /sx,
        eof          => qr/ \G \z /sx,
#       pluspath     => qr/ \G $wspace $PLUSPATH $wspace /x,
#       assign       => qr/ \G $wspace ($ASSIGN) $wspace /x,
    };

    # add regex for matching start of a nested tag
    if (defined $start) {
        $start = ref $start eq 'Regexp' ? $start : quotemeta($start);
        $patterns->{ tag_start } = qr/ \G $wspace ($start) /sx;
    }

    # add regexen for matching end of tag and everything up to the tag end
    if (defined $end) {
        # NOTE: we used to lookahead... I don't think we need to now
#       $patterns->{ at_end } = qr/ \G $wspace (?= $end ) /sx;
        $patterns->{ at_end } = qr/ \G $wspace ($end) /sx;
        # NOTE: we capture the end to avoid exponential slowdown from 
        # lookahead - this caused some problems in testing.  Need to confirm
        # that this is the right thing to do here.
#       $patterns->{ to_end } = qr/ \G $wspace (.*?) ($end) /sx;
        $patterns->{ to_end } = qr/ \G (.*?) ($end) /sx;
    }
    else {
        $patterns->{ at_end } = qr/ \G $wspace $ /sx;
        $patterns->{ to_end } = qr/ \G $wspace (.*) $ /sx;
    }

    return $patterns;
}


#-----------------------------------------------------------------------
# Token matching methods
#-----------------------------------------------------------------------

sub match_whitespace {
    my ($self, $text) = @_;

    # skip whitespace and ignorable comments
    return $$text =~ /$self->{ match_whitespace }/cg
        ? $1 
        : undef;
}


sub match_to_end {
    my ($self, $text) = @_;
    return $1 if $$text =~ /$self->{ match_to_end }/gc;
}


sub match_to_eol {
    my ($self, $text) = @_;
    return $1 if $$text =~ /$self->{ match_to_eol }/gc;
}


sub match_to_eof {
    my ($self, $text) = @_;
    return $1 if $$text =~ / \G (.*) $ /gcsx;
}



1;


