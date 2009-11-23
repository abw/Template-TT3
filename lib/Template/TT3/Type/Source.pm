#========================================================================
#
# Template::TT3::Type::Source
#
# DESCRIPTION
#   Subclass of Template::TT3::Type::Text used to represent the source text
#   of a template.  It provides additional methods relating to scanning
#   the text (e.g. returning the current position, line number, etc) and
#   maintaining a list of scanned tokens.
#   
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Type::Source;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Type::Text',
    utils     => 'is_object params self_params',
    patterns  => '$LAST_LINE',
    constants => 'HASH LAST',
    constant  => {                   
        SOURCE => __PACKAGE__,      # class name
        id     => 'Source',         # yak!   
        type   => 'Source',
    },                              
    exports   => {
        any   => 'SOURCE Source',    # class name and constructor sub
    },
    vars      => {
        LINE_LENGTH => 72,          # package variable providing defaults
        SHOW_AFTER  => 20,          # for location()/whereabout() methods
        TRIMMED     => '...',
    };

#-----------------------------------------------------------------------
# Source($text) - exportable subroutine to upcast $text to a Source object
#-----------------------------------------------------------------------

sub Source {
    # if we only have one argument and it's already TEXT then return it,
    # otherwise forward all arguments to the TEXT constructor.
    if (@_ == 1 && is_object(SOURCE, $_[0])) {
        return $_[0];
    }
    else {
        return SOURCE->new(@_) 
    };
}


#-----------------------------------------------------------------------
# scanning/parsing/debugging methods
#-----------------------------------------------------------------------

sub position {
    pos ${$_[0]} || 0;
}


# There's some duplication here, but the line() method may get called 
# many times by itself (e.g. when generating perl) so we don't want the
# overhead of computing the column when we don't need it.  And vice versa.
# Still, it could probably do with being cleaned up at some point.

sub line {
    my $self = shift;
    my $pos  = shift || pos $$self || return 1;
    my $text = substr($$self, 0, $pos);
    return 1 + $text =~ tr/\n/\n/;
}


sub column {
    my $self = shift;
    my $pos  = shift || pos $$self || return 1;
    my $text = substr($$self, 0, $pos);
    $text =~ /$LAST_LINE/
        or return $self->error("Cannot determine column number");
    return 1 + length $1;
}


sub line_column {
    my $self = shift;
    my $pos  = shift || pos $$self || return 1;
    my $text = substr($$self, 0, $pos);
    my $line = 1 + $text =~ tr/\n/\n/;
    $text =~ /$LAST_LINE/
        or return $self->error("Cannot determine column number");
    my $colm = 1 + length $1;
    return ($line, $colm);
}


sub whereabouts {
    my $self    = shift;
    my $args    = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $linelen = defined $args->{ line_length } ? $args->{ line_length } : $LINE_LENGTH;
    my $showaft = defined $args->{ show_after  } ? $args->{ show_after  } : $SHOW_AFTER;
    my $pos     = defined $args->{ position    } ? $args->{ position    } : pos $$self || 0;
    my $before  = substr($$self, 0, $pos);
    my $after   = substr($$self, $pos, $linelen);
    my $line    = 1 + $before =~ tr/\n/\n/;

    $before =~ /$LAST_LINE/ 
        or return $self->error("Cannot determine column number");
    $before = $1;
    $after =~ /^(.*)(\n|$)/;
    $after = $1;
    $self->debug("before/after [$before]/[$after]\n") if DEBUG;
    
    my $text    = $before . $after;
    my $length  = length($text);
    my $column  = length($before) + 1;
    my $info = {
        text     => $text,
        position => $pos,
        line     => $line,
        column   => $column,
    };
    
    if ($linelen && $length > $linelen) {
        my $trimmed = defined $args->{ trimmed } ? $args->{ trimmed } : $TRIMMED;
        my $lastcol = $linelen - $showaft + 1;
        # the line of text exceeds the requested line length so we must
        # truncate it, ensuring that the current point is somewhere in the
        # middle of what we return.
        if ($column <= $lastcol) {
            $self->debug("trim end\n") if $DEBUG;
            # current column is early enough to fit in $LINE_LENGTH, leaving
            # enough room for the extra $SHOW_AFTER characters after it, so 
            # we just need to truncate the end of the text
            substr($text, $linelen - length $trimmed) = $trimmed;
            $info->{ offset } = $column - 1;
        }
        elsif ($column > $length - $showaft) {
            my $tlen  = length $trimmed;
            $self->debug("trim start\n") if DEBUG;
            # current column is within $SHOW_AFTER characters of the end of
            # line so we just need to truncate the beginning.
            my $shift = $length - $linelen;
            substr($text, 0, $shift + $tlen) = $trimmed;
            $info->{ offset } = $column - $shift - 1;
        }
        else {
            # truncate start and end of text
            my $shift = $column - $lastcol;
            my $tlen  = length $trimmed;
            $self->debug("shifting $shift\n") if $DEBUG;
            substr($text, 0, $shift + $tlen) = $trimmed;
            substr($text, $linelen - $tlen) = $trimmed;
            $info->{ offset } = $column - $shift - 1;
        }
        $info->{ extract } = $text;
    }
    else {
        $self->debug("no trim required\n") if DEBUG;
        $info->{ extract } = $text;
        $info->{ offset  } = $column - 1;
    }
    return $info;
}


sub location {
    my $where = &whereabouts(@_);
    return "at line $where->{ line } "
         . "column $where->{ column }:\n  $where->{ extract }\n  "
         . ' ' x $where->{ offset } . '^';
}

    
sub lookahead {
    my ($self, $length, $append) = @_;
    my $text = ref $self ? $self : \$self;

    # save current position, match remaining text, restore position
    my $pos  = pos $$text;
    $$text =~ / \G (.+) /cgsx || return '';
    pos $$text = $pos;
    
    # chop it down to size if a maximum $length specified and add $append
    my $extract = $1;
    $extract = substr($extract, 0, $length) . ($append || '')
        if $length && length $extract > $length;
    return $extract;
}


sub debug_lookahead {
    my ($self, $length, $append) = @_;
    $length ||= 16;
    $append ||= '...';
    my $extract = lookahead($self, $length, $append);
    $extract =~ s/\n/\\n/g;
    return $extract;
}


1;

__END__

=head1 NAME

Template::TT3::Type::Source - object for representing template source code

=head1 SYNOPSIS

    use Template::TT3::Type::Source;
    
    my $source = Template::TT3::Text::Source->new(
        "Hello [% name or 'World' %]"
    );
    
=head1 DESCRIPTION

** TODO **

=head1 QUICK NOTES

A source object is a text object.  It's a reference to a text string.
You can match against it like this

    if ($$source =~ / \G (\W+) /) {
        ...
    }

You can query the current position, line number and column number.

    $source->position;
    $source->line;
    $source->column;

=head2 Methods

The following methods are defined in addition to those inherited from
the L<Template::TT3::Type::Text> base class.

** TODO **

=head2 position()

Returns the current regex match position in the source text.

=head2 line()

Returns the line number of the current regex match position.

=head2 column()

Returns the column number of the current regex match position.

=head2 line_column()

Returns the line and column numbers of the current regex match position.

=head2 whereabouts()

Returns a reference to a hash array containing information about the 
current match position.

    text            The source text
    position        The current position
    line            The current line
    column          The current column
    extract         Text extract around current position.
    
The hash array contains an C<extract> item containing an extract of the 
current line around the regex match position.

If the line is sufficiently short (less than L<$LINE_LENGTH> which defaults
to 72 characters) then it will be returned intact.  If longer, then an extra
of the line will be shown.

=head2 location()

Returns a string describing the current regex match position, complete with
a text extract.

    at line 36 column 17:
      This is the source template [%* oops! %]
                                    ^

=head2 lookahead($length)

Returns the next C<$length> characters following the current global
regular expression matching point (C<\G>).  See L<perlre> for further
information on what that is and how it's used.

If C<$length> is unspecified then it returns all remaining text.

    [% text = Text('Foo Bar Baz');
       text.match(/\(w+)\s/g).0;    # Foo
       text.lookahead;              # Bar Baz
       text.match(/\(w+)\s/g).0;    # Bar
       text.lookahead;              # Baz
    %]

=head2 debug_lookahead()

This method allows you to peek ahead from the current regex match position
to see what will be matched next.  It is primarily used for debugging.

Returns the output of L<lookahead(16)> with all newlines converted to 
the literal string 'C<\n>'.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2008 Andy Wardley.  All Rights Reserved.

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


