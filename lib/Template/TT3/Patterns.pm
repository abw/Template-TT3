#========================================================================
#
# Template::TT3::Patterns
#
# DESCRIPTION
#   Library of regular expression that match the tokens of the Template
#   Toolkit markup language.  This has been inherited from an earlier 
#   incarnation of TT3 and large parts of it may be redundant.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
#========================================================================

package Template::TT3::Patterns;

use Template::TT3::Class
    base    => 'Badger::Exporter',
    version => 3.00,
    exports => {
        tags => {
            space     => '$TO_EOL $COMMENT $WHITESPACE $LAST_LINE',
            punctuate => '$SEPARATOR $DELIMITER $PAIR $DOTOP', # $EQUALS $COLON ',
            groups    => '$GROUPS $LGROUP $RGROUP $LPAREN $RPAREN $LBRACKET $RBRACKET $LBRACE $RBRACE',
            numbers   => '$HEXNUM $SIGN $FLOAT $EXPONENT $NUMBER $INTEGER $INDEX',
            quotes    => '$SQ $SQUOTE $SQUOTEND $DQ $DQUOTE $DQUOTEND $BADQUOTE',
            regex     => '$RX $RXFLAGS $REGEX $REGEND $BADREGEX',
            sigils    => '$EXPAND $INTERP $EMBED $UNEMBED',
            names     => '$IDENT $KEYWORD $STATIC $FILEPATH $RESOURCE $NAMESPACE',
            pathops   => '$PLUSPATH',
        },
    };


#-----------------------------------------------------------------------
# $TO_EOL is a regex to match everything up to the end of line.  
# $COMMENT starts with a '#' and continues to the end of line.
# $SPACE skips over whitespace and comments.  This is re-defined by
# Template::TT3::Parser::_init_regexen() to account for the end token of a
# tag which can appear before the EOL, e.g. 
#     [% foo   # this is a comment %] some more text
# $LAST_LINE is used for matching everything on the last line of the 
# text, following the final newline or start of string.
#-----------------------------------------------------------------------

our $TO_EOL     = qr/ (?-s).* /x;
our $COMMENT    = qr/ \# $TO_EOL /ox;
our $WHITESPACE = qr/ \G \s* (?:$COMMENT\s*)* /ox;
our $LAST_LINE  = qr/(?:\n|^)([^\n]*)\z/;


#-----------------------------------------------------------------------
# Various constructs (lists, hashes, etc) can include the $SEPARATOR ',' 
# between items.  The $DELIMITER marks the end of one expression and the
# start of the next.  
#-----------------------------------------------------------------------

our $SEPARATOR  = ',';
our $DELIMITER  = ';';
our $DOTOP      = qr/ \.(?!\.) /x;

#our $EQUALS     = qr/ \s* =>? \s* /sx;
#our $COLON      = qr/ \s* : \s* /sx;
our $PAIR       = qr/ \s* (?: : | =>? ) \s* /sx;


#------------------------------------------------------------------------
# $GROUPS is a hash mapping left brackets to right, $LGROUP is a
# regex to match any left bracket, and $RGROUP is a hash mapping
# left brackets to regexen matching the corresponding right brackets, 
# capturing any intermediate text in the process
#------------------------------------------------------------------------

our $GROUPS = { qw! / / ' ' " " ( ) [ ] { } < > ! };
our $LGROUP = join('', map { quotemeta } keys %$GROUPS);
    $LGROUP = qr/ \G ([$LGROUP]) /ox;
our $RGROUP = {
    map { 
        my $end = quotemeta($GROUPS->{ $_ });
        $end = qr/ \G ( (?: \\$end | [^$end] )* ) $end /x;
#        $end = qr/ \G ([^$end]*) $end /x;
        ($_, $end);
    } keys %$GROUPS,
};

#------------------------------------------------------------------------
# $QWLIST defines a regex to match quoted lists(qw(...)).  $LIST and
# $ENDLIST match the start and end of regular lists ([...]), $HASH and
# $ENDHASH do the same for hash arrays ({...}), $PAREN and $ENDPAREN
# for parenthesis ((...)).
#------------------------------------------------------------------------

#our $QWLIST   = qr/ \G qw ($LGROUP) /ox;
our $LPAREN   = qr/ \G \( /x;           # -> LPAREN
our $RPAREN   = qr/ \G \) /x;
our $LBRACKET = qr/ \G \[ /x;           # -> LBRACKET
our $RBRACKET = qr/ \G \] /x;
our $LBRACE   = qr/ \G \{ /x;           # -> LBRACE
our $RBRACE   = qr/ \G \} /x;



#------------------------------------------------------------------------
# regexen to match decimal and hexadecimal numbers, integers and
# floats, with optionals signs and exponents
#------------------------------------------------------------------------

our $HEXNUM   = qr/ 0[xX][\dA-Fa-f]+ /x;
our $SIGN     = qr/ [+-]? /x;
our $FLOAT    = qr/ (?: \.\d+ )? /x;
our $EXPONENT = qr/ (?: [eE][+-]?\d+ )? /x;
our $NUMBER   = qr/ \G ( $SIGN (?: $HEXNUM | \d+ $FLOAT $EXPONENT ) ) /ox;
our $INTEGER  = qr/ \G ( $SIGN (?: $HEXNUM | \d+ ) ) /ox;
our $INDEX    = qr/ \G ( -? \d+ ) /x;


#------------------------------------------------------------------------
# Regexen to match single and double quoted strings.  $SQ and $DQ define
# the permitted content for single and double quoted strings.  $SQUOTE 
# and $DQUOTE match them at the current regex position complete with 
# enclosing quote characters.  $SQUOTEND and $DQUOTEND match from just
# inside the opening quote up to and including the closing quote.
# There's also a regex to match unterminated strings for the purposes of 
# detecting and reporting this common error.
#------------------------------------------------------------------------

our $SQ       = qr/ (?: \\' | [^'] )* /x;               # TODO non-greedy?
our $DQ       = qr/ (?: \\\\ | \\" | . | \n )*? /x;     # or greedy?
our $SQUOTE   = qr/ \G ' ($SQ) ' /x;
our $DQUOTE   = qr/ \G " ($DQ) " /x;
our $SQUOTEND = qr/ \G ($SQ) ' /x;
our $DQUOTEND = qr/ \G ($DQ) " /x;
our $BADQUOTE = qr/ \G ('|") /x;


#-----------------------------------------------------------------------
# Regexen to match regexen.  $RX matches the guts of a regex, $REGEX 
# matches a complete regex including the enclosing / / at the current 
# position.  $REGEND matches from just inside the opening / up to and
# including the closing / and any flags.
#-----------------------------------------------------------------------

our $RX       = qr{ (?: \\/ | [^/] )* }x;
our $RXFLAGS  = qr{ (?: [cgimosx]+\b )? }x;   # any flags must have word boundary
our $REGEX    = qr{ \G / ($RX) / ($RXFLAGS) }ox;
our $REGEND   = qr{ \G ($RX) / ($RXFLAGS) }ox;
our $BADREGEX = qr{ \G / }x;  


#------------------------------------------------------------------------
# regexen to match a leading '@' or '$' on a variable, or 
# ${...} enclosing an embedded variable.
#------------------------------------------------------------------------

our $EXPAND   = qr/ \G (\@) /x;
our $INTERP   = qr/ \G (\$) (?= \w+ ) /x;
our $EMBED    = qr/ \G \${ /x;
our $UNEMBED  = qr/ \G } /x;


#------------------------------------------------------------------------
# regexen to match various unquoted strings.  $IDENT matches a simple
# identifier (e.g. foo), while $KEYWORD adds the requirement of a word
# boundary at the end (TODO: this isn't used any more).  $STATIC matches
# a static variable name or dot operation: a word or numerical index.
# $FILEPATH allows dots, slashes and colon (e.g. /foo/bar.txt) and 
# $RESOURCE is a special case of this with an explicit leading resource 
# identifier (e.g.  file:foo.txt).  $NAMESPACE is the prefix by itself.
#------------------------------------------------------------------------

our $IDENT     = qr/ \G ( [[:alpha:]^_] \w* ) /x;
our $KEYWORD   = qr/ \G $IDENT \b /x;
our $STATIC    = qr/ \G ( [[:alpha:]] \w* | -? \d+ ) /x;
our $FILEPATH  = qr/ \G ( [\w\.\/:]+ ) /x;
our $RESOURCE  = qr/ \G ( \w+ ) : ( [\w\.\/:]+ ) /x;
our $NAMESPACE = qr/ \G ( \w+ ) : /x;


#------------------------------------------------------------------------
# Regexen to match the dot operator (making sure that another dot
# doesn't follow, preventing it from mistakenly identifying the list
# range op '..'), the '|' pipe operator and the '+'operator for joining
# multiple paths
#------------------------------------------------------------------------

our $DOT    = qr/ \G \.(?!\.) /x;
our $PIPE   = qr/ \G \| /x;
our $PLUS   = qr/ \G \+ /x;


#our $LIST     = qr/ \G \[ /x;
#our $HASH     = qr/ \G \{ /x;
#our $PAREN    = qr/ \G \( /x;
#our $ENDLIST  = qr/ \G \] /x;
#our $ENDHASH  = qr/ \G \} /x;
#our $ENDPAREN = qr/ \G \) /x;


1;

__END__

=head1 NAME

Template::TT3::Patterns - regular expression patterns to match language tokens 

=head1 SYNOPSIS

    use Template::TT3::Patterns '$KEYWORD';
    
    # some text to match
    my $text = "foo";
    
    # see if the text contains a keyword
    if ($text =~ /$KEYWORD/) {
        print "got a keyword: $1\n";
    }

=head1 DESCRIPTION

This module defines a number of regular expression for matching the basic
tokens of the Template Toolkit markup language.

The first few iterations of the TT3 parser used a straightforward recursive
descent approach and relied on these patterns extensively.  More recent
implementations are based around a generic operator precedence model with
a configurable grammar.  We now automatically generate regular expressions 
to match operators rather than using pre-defined patterns.  This means that
many of the above patterns are no longer used and will eventually be cleared
out. 

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
