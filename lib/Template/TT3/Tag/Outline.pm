package Template::TT3::Tag::Outline;

use Template::TT3::Grammar::TT3;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag',
    import    => 'class',
    utils     => 'numlike',
    constants => ':chomp SPACE REGEX NONE CODE',
    constant  => {
        GRAMMAR     => 'Template::TT3::Grammar::TT3',
        SKIP_TAG    => 0,
        CONTINUE    => 1,
    },
    messages  => {
        bad_chomp => 'Invalid %s_chomp option specified: %s',
        bad_flag  => 'Invalid flag at %s of tag: %s',
    };


#-----------------------------------------------------------------------
# Custom initialistion method for generating matching patterns that work
# OK when we get to the end of line.
#-----------------------------------------------------------------------
 
sub init_patterns {
    my ($self, $start, $end) = @_;
    my $eol = qr/[^\n]*/;

    # comments start '#' and extend to the end of line (or end of tag)
    my $blank   = qr/[[:blank:]]/;
    my $comment = qr/ (?: ^$blank*|$blank+ ) \# [^\n]* /mx;

    # whitespace can contain ignorable comments
    my $wspace = qr/ (?:$comment|$blank)+ /x;

    # now construct table of regexen for matching various operators and 
    # other tokens, accounting for any whitespace/comments surrounding
    my $patterns = {
        nothing      => qr/ \G /x,
        to_eol       => qr/ \G ([^\n]*) /x,
        comment      => qr/ \G ($comment) /x,
        whitespace   => qr/ \G ($wspace) /x,
    };

    # add regexen for matching end of tag and everything up to the tag end
    $patterns->{ at_end } = qr/ \G (\n|$) /sx;
    $patterns->{ to_end } = qr/ \G (.*) (\n|$) /sx;

    return $patterns;
}


1;

