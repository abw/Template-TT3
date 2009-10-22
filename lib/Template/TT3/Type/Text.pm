#========================================================================
#
# Template::TT3::Type::Text
#
# DESCRIPTION
#   Object implementing a trivial object wrapper around a text reference.
#   It allows a text string to be passed around by reference (to avoid
#   copying) while also providing an auto-stringification method to 
#   de-reference the text.  On top of that, it provides a bunch of useful
#   methods which either wrap around the Perl equivalents or implement 
#   variations thereof.  Most (if not all) of these methods can be 
#   exported as a vtable for use as virtual methods.  That allows them 
#   to be called as subroutines, passing a non-ref text string as the 
#   first argument instead of a $self object reference.
#
# NOTES
#   Speed is of the essence.  May of these methods are effectively useless 
#   because they add nothing more than a wrapper around the existing core 
#   Perl functionality.  So to keep the overhead to a minimum, we try to 
#   avoid shifting arguments off the stack into local variables wherever 
#   possible.  Instead we work directly on the $_[$n] argument list.  Be 
#   warned that this makes the code harder to both read and write, so tread 
#   carefully.  This *isn't* an example of good coding style, but it *is*
#   a good example of compromising style for the sake of performance. For 
#   any non-trivial methods, the overhead is less significant so we don't
#   worry about it too much and instead focus on clarity.  We also have to
#   be careful to explicitly scope any calls to ambiguous subroutines,
#   e.g. CORE::length vs &length
# 
# TODO
#   Switch around some of the non-destructive methods so that they
#   work on the original reference rather than first taking a copy.
#
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Type::Text;

use Template::TT3::Class
    version  => 3.00,
    debug    => 0,
    base     => 'Template::TT3::Type',
    utils    => 'blessed md5_hex is_object',
    patterns => '$LAST_LINE',
    as_text  => \&text,             # overload stringification operator
    is_true  => 1,                  # always evaluate true in boolean context
    overload => {                   # overload comparison ops
        qw|<=>|  => \&compare,
        cmp      => \&compare,
    },
    constant => {                   # define constant subs/methods
        TEXT => __PACKAGE__,
        type => 'Text',             # use capitalised name 'Text' instead of 
    },                              # 'text' 'cos we're a formal type (of sorts) 
    methods  => {
        *center    => \&centre,     # alias for folk speaking US english
        *tt_expand => \&text,       # special method for TT to use
    },
    exports  => {
        any  => 'TEXT Text',        # class name and constructor sub
    },
    vars     => {                   # TODO: move to T::Type::Source
        LINE_LENGTH => 72,          # package variable providing defaults
        SHOW_AFTER  => 20,          # for location()/whereabout() methods
        TRIMMED     => '...',
    };


# Define a lexical scope with a $METADATA table for storing any out-of-band
# information about text objects.  The methods defined below can be called 
# as subroutines (as part of the vmethod mechanism), so the first argument
# can be a non-reference text string in place of the usual $self object
# reference (which itself is just a blessed reference to a scalar text
# string).  To handle this case, we use an md5_hex encoding of the text
# to determine a unique handle for it (or close enough to unique for 
# practical purposes)

{
    my $METADATA = { };
    sub metadata {
        $METADATA->{ $_ && ref $_[0] ? refaddr $_[0] : md5_hex($_[0]) } ||= { }
    }
}


# The master vtable of methods that this module allows to be called as 
# virtual methods (i.e. as a subroutine with a regular chunk of text passed
# instead of an object reference).

our $METHODS = {
    'new'      => \&new,
    
    # methods to convert from one type to another
    'item'     => \&item,
    'text'     => \&text,
    'list'     => \&list,
    'hash'     => \&hash,

    # general inspection methods
    'defined'  => \&defined,
    'length'   => \&length,
    'size'     => \&size,

    # comparison and pattern matching methods
    'equals'   => \&equals,
    'compare'  => \&compare,
    'before'   => \&before,
    'after'    => \&after,
    'match'    => \&match,
    'search'   => \&search,
    'replace'  => \&replace,
    'remove'   => \&remove,
    
    # methods for splitting and taking substrings
    'split'    => \&split,
    'chunk'    => \&chunk,
    'substr'   => \&substr,

    # more text munging methods
    'upper'    => \&upper,
    'lower'    => \&lower,
    'capital'  => \&capital,
    'capitals' => \&capitals,
    'chop'     => \&chop,
    'chomp'    => \&chomp,
    'collapse' => \&collapse,
    'trim'     => \&trim,
    'truncate' => \&truncate,
    'repeat'   => \&text_repeat,
    'prepend'  => \&prepend,
    'append'   => \&append,

    # formatting methods
    'centre'   => \&centre,   # keep the Europeans happy
    'center'   => \&centre,   # keep the Americans happy
    'left'     => \&left,
    'right'    => \&right,
    'format'   => \&format,
};



#-----------------------------------------------------------------------
# Text($text) - exportable subroutine to upcast $text to a Text object
#-----------------------------------------------------------------------

sub Text {
    # if we only have one argument and it's already TEXT then return it,
    # otherwise forward all arguments to the TEXT constructor.
    if (@_ == 1 && is_object(TEXT, $_[0])) {
        return $_[0];
    }
    else {
        return TEXT->new(@_) 
    };
}


#-----------------------------------------------------------------------
# Constructor methods
#-----------------------------------------------------------------------

sub new {
    my $class = shift;
    $class = CORE::ref($class) || $class;

    # ignore any undefined values
    shift(@_) while @_ && ! defined $_[0];
    
    # shift one single value, or concatentate multiple values
    my $text  = (@_ == 1) ? shift 
              :  @_       ? join('', @_)
              : undef;

#    my ($text, $item);
#    foreach (@_) {
#        next unless defined $_;
#        $item = ref($_) ? $$_ : $_;
#        if (defined $text) {
#            $text .= $item;
#        }
#        else {
#            $text = $item;
#        }
#    }

    # return a reference that is already a Template::TT3::Text object
    return $text if is_object($class, $text);

    my $self = CORE::ref($text) ? $text : \$text;
    bless $self, $class;
}


sub init {
    my $self = shift;
    $$self = join('', @_);
}


sub copy {
    my $self  = shift;
    my $class = CORE::ref $self || __PACKAGE__;
    my $text  = CORE::ref $self ? $$self : $self;
    return $class->new($text, @_);
}


#-----------------------------------------------------------------------
# methods to convert from one type to another
#-----------------------------------------------------------------------

sub text {
    return CORE::ref $_[0] ? ${$_[0]} : $_[0];
}


sub item {
    return $_[0];
}


sub list {
    return [ $_[0] ];
}


sub hash {
    my ($text, $key, @args) = @_;
    $key = 'text' unless CORE::defined $key;
    return { $key => $text, @args };
}


#-----------------------------------------------------------------------
# general inspection methods
#-----------------------------------------------------------------------

sub defined {
    return CORE::defined(CORE::ref $_[0] ? ${$_[0]} : $_[0]);
}


sub length {
    return CORE::length(CORE::ref $_[0] ? ${$_[0]} : $_[0]);
}


sub size {
    return 1;
}


#-----------------------------------------------------------------------
# comparison methods
#-----------------------------------------------------------------------

sub compare {
    return (CORE::ref $_[0] ? ${$_[0]} : $_[0])
       cmp (CORE::ref $_[1] ? ${$_[1]} : $_[1]);
}


sub equals {
    return (CORE::ref $_[0] ? ${$_[0]} : $_[0])
        eq (CORE::ref $_[1] ? ${$_[1]} : $_[1]);
}


sub before {
    shift->compare(shift) < 0;
}


sub after {
    shift->compare(shift) > 0;
}


#-----------------------------------------------------------------------
# pattern matching methods
#-----------------------------------------------------------------------

sub match {
    my ($self, $pattern, $global) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    return $text unless CORE::defined $text and CORE::defined $pattern;
#    my @matches = $global ? ($text =~ /$pattern/g) : ($text =~ /$pattern/);
    # just do it globally all the time
    my @matches = ($text =~ /$pattern/g);
    return @matches ? \@matches : '';
}


sub search { 
    my ($self, $pattern) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    return $text unless CORE::defined $text and CORE::defined $pattern;
    return $text =~ /$pattern/;
}


sub replace {
    my ($self, $pattern, $replace, $global) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    $text    = '' unless CORE::defined $text;
    $pattern = '' unless CORE::defined $pattern;
    $replace = '' unless CORE::defined $replace;
    $global  = 1  unless CORE::defined $global;

    if ($replace =~ /\$\d+/) {
        # replacement string may contain backrefs
        my $expand = sub {
            my ($chunk, $start, $end) = @_;
            $chunk =~ s{ \\(\\|\$) | \$ (\d+) }{
                $1 ? $1
                    : ($2 > $#$start || $2 == 0) ? '' 
                    : CORE::substr($text, $start->[$2], $end->[$2] - $start->[$2]);
            }exg;
            $chunk;
        };
        if ($global) {
            $text =~ s{$pattern}{ &$expand($replace, [@-], [@+]) }eg;
        } 
        else {
            $text =~ s{$pattern}{ &$expand($replace, [@-], [@+]) }e;
        }
    }
    else {
        if ($global) {
            $text =~ s/$pattern/$replace/g;
        } 
        else {
            $text =~ s/$pattern/$replace/;
        }
    }
    return $text;
}


sub remove { 
    my ($self, $pattern) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    return $text unless CORE::defined $text and CORE::defined $pattern;
    $text =~ s/$pattern//g;
    return $text;
}


#-----------------------------------------------------------------------
# methods for splitting and taking substrings
#-----------------------------------------------------------------------

sub split {
    my ($self, $split, $limit) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    
    # we have to be very careful about spelling out each possible 
    # combination of arguments because split() is very sensitive
    # to them, for example C<split(' ', ...)> behaves differently 
    # to C<$space=' '; split($space, ...)>
    
    if (CORE::defined $limit) {
        return [ CORE::defined $split 
               ? CORE::split($split, $text, $limit)
               : CORE::split(' ', $text, $limit) ];     # TODO: \s+ instead of ' '?
    }
    else {
        return [ CORE::defined $split 
               ? CORE::split($split, $text)
               : CORE::split(' ', $text) ];            # ditto
    }
}


sub chunk {
    my ($self, $size) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    my @list;
    $size ||= 1;
    
    if ($size < 0) {
        # sexeger!  It's faster to reverse the string, search
        # it from the front and then reverse the output than to 
        # search it from the end, believe it nor not!
        $text = CORE::reverse $text;
        $size = -$size;
        unshift(@list, scalar CORE::reverse $1) 
            while ($text =~ /((.{$size})|(.+))/g);
    }
    else {
        push(@list, $1) while ($text =~ /((.{$size})|(.+))/g);
    }
    return \@list;
}


sub substr {
    my ($self, $offset, $length, $replacement) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    $offset ||= 0;
    
    if (CORE::defined $length) {
        if (CORE::defined $replacement) {
            CORE::substr($text, $offset, $length, $replacement);
            return $text;
        }
        else {
            return CORE::substr($text, $offset, $length);
        }
    }
    else {
        return CORE::substr($text, $offset);
    }
}


#-----------------------------------------------------------------------
# more text munging methods
#-----------------------------------------------------------------------

sub upper {
    return uc(ref($_[0]) ? ${$_[0]} : $_[0]);
}


sub lower {
    return lc(ref($_[0]) ? ${$_[0]} : $_[0]);
}


sub capital {
    my $self = shift;
    my $text = CORE::ref $self ? $$self : $self;
    $text =~ s/(\w)/\U$1/;
    return $text;    
}


sub capitals {
    my $self = shift;
    my $text = CORE::ref $self ? $$self : $self;
    $text =~ s/(\w)(\w*)/\U$1\E$2/g;
    return $text;    
}


sub chop {
    my $self = shift;
    my $text = CORE::ref $self ? $$self : $self;
    CORE::chop $text;
    return $text;
}


sub chomp {
    my $self = shift;
    my $text = CORE::ref $self ? $$self : $self;
    CORE::chomp $text;
    return $text;
}


sub collapse {
    my $self = shift;
    my $text = CORE::ref $self ? $$self : $self;
    for ($text) {
        s/^\s+//; 
        s/\s+$//; 
        s/\s+/ /g 
    }
    return $text;    
}


sub trim {
    my $self = shift;
    my $text = CORE::ref $self ? $$self : $self;
    for ($text) {
        s/^\s+//; 
        s/\s+$//; 
    }
    return $text;    
}


sub truncate {
    my ($self, $length, $suffix) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    $suffix = '' unless defined $suffix;
    return $text unless CORE::defined($text) && CORE::defined($length);
    return $text if CORE::length $text <= $length;
    return CORE::substr($text, 0, $length - CORE::length($suffix)) . $suffix;
}


sub repeat { 
    my ($self, $count) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    $text = '' unless CORE::defined $text;
    return '' unless $count;
    $count ||= 1;
    return $text x $count;
}


sub append {
    my ($self, @args) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    return CORE::join('', grep { defined } $text, @args);
}


sub prepend {
    my ($self, @args) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    return CORE::join('', grep { defined } @args, $text);
}


#-----------------------------------------------------------------------
# formatting methods
#-----------------------------------------------------------------------

sub centre {
    my ($self, $width) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    my $len  = CORE::length $text;
    $width ||= 0;

    if ($len < $width) {
        my $lpad = int(($width - $len) / 2);
        my $rpad = $width - $len - $lpad;
        return (' ' x $lpad) . $text . (' ' x $rpad);
    }

    return $text;
}


sub left {
    my ($self, $width) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    my $len  = CORE::length $text;
    $width ||= 0;

    if ($width > $len) {
        return $text . (' ' x ($width - $len));
    }
    else {
        return $text;
    }
}


sub right {
    my ($self, $width) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    my $len = CORE::length $text;
    $width ||= 0;

    if ($width > $len) {
        return (' ' x ($width - $len)) . $text;
    }
    else {
        return $text;
    }
}


sub format {
    my ($self, $format, @args) = @_;
    my $text = CORE::ref $self ? $$self : $self;
    $format = '%s' unless CORE::defined $format;
    sprintf($format, $text, @args);
}


sub present {
    my ($self, $view) = @_;
    return $view->view_text($$self);
}



#-----------------------------------------------------------------------
# scanning/parsing/debugging methods
#
# We might want to move these into a T::Type::Source subclass specific
# to this kind of thing.
#-----------------------------------------------------------------------

sub position {
    return ref $_[0]
         ? pos ${$_[0]} || 0
         : TEXT->error("Cannot determine position of non-reference text");
}

# There's some duplication here, but the line() method may get called 
# many times by itself (e.g. when generating perl) so we don't want the
# overhead of computing the column when we don't need it.  And vice versa.
# Still, it could probably do with being cleaned up at some point.

sub line {
    my $self = shift;
    my $pos  = position($self) || return 1;
    my $text = &substr($self, 0, $pos);
    return 1 + $text =~ tr/\n/\n/;
}

sub column {
    my $self = shift;
    my $pos  = position($self) || return 1;
    my $text = &substr($self, 0, $pos);
    $text =~ /$LAST_LINE/
        or return TEXT->error("Cannot determine column number");
    return 1 + CORE::length $1;
}

sub line_column {
    my $self = shift;
    my $pos  = position($self) || return 1;
    my $text = &substr($self, 0, $pos);
    my $line = 1 + $text =~ tr/\n/\n/;
    $text =~ /$LAST_LINE/
        or return TEXT->error("Cannot determine column number");
    my $colm = 1 + CORE::length $1;
    return ($line, $colm);
}


sub whereabouts {
    my $self    = shift;
    my $args    = @_ && ref $_[0] eq 'HASH' ? shift : { @_ };
    my $linelen = defined $args->{ line_length } ? $args->{ line_length } : $LINE_LENGTH;
    my $showaft = defined $args->{ show_after  } ? $args->{ show_after  } : $SHOW_AFTER;
    my $pos     = position($self);
    my $before  = &substr($self, 0, $pos);
    my $after   = &substr($self, $pos, $linelen);
    my $line    = 1 + $before =~ tr/\n/\n/;
    $before =~ /$LAST_LINE/ or return TEXT->error("Cannot determine column number");
    $before = $1;
    $after =~ /^(.*)(\n|$)/;
    $after = $1;
    $self->debug("before/after [$before]/[$after]\n") if $DEBUG;
    my $text    = $before . $after;
    my $length  = CORE::length($text);
    my $column  = CORE::length($before) + 1;
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
            CORE::substr($text, $linelen - CORE::length $trimmed) = $trimmed;
            $info->{ offset } = $column - 1;
        }
        elsif ($column > $length - $showaft) {
            my $tlen  = CORE::length $trimmed;
            $self->debug("trim start\n") if $DEBUG;
            # current column is within $SHOW_AFTER characters of the end of
            # line so we just need to truncate the beginning.
            my $shift = $length - $linelen;
            CORE::substr($text, 0, $shift + $tlen) = $trimmed;
            $info->{ offset } = $column - $shift - 1;
        }
        else {
            # truncate start and end of text
            my $shift = $column - $lastcol;
            my $tlen  = CORE::length $trimmed;
            $self->debug("shifting $shift\n") if $DEBUG;
            CORE::substr($text, 0, $shift + $tlen) = $trimmed;
            CORE::substr($text, $linelen - $tlen) = $trimmed;
            $info->{ offset } = $column - $shift - 1;
        }
        $info->{ extract } = $text;
    }
    else {
        $self->debug("no trim required\n") if $DEBUG;
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
    $extract = CORE::substr($extract, 0, $length) . ($append || '')
        if $length && CORE::length $extract > $length;
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

__END__

=head1 NAME

Template::TT3::Type::Text - object for representing and manipulating text

=head1 SYNOPSIS

    use Template::TT3::Text;
    
    my $text = Template::TT3::Text->new('Hello World');
    
    print "length: ", $text->length(), "\n";

=head1 DESCRIPTION

NOTE: this documentation is a quick cut-n-paste from an earlier version.
It's incomplete and almost certainly incorrect in places.  Don't trust
anything you read here.

This module implements an object for representing and manipulating
text strings.  The methods implemented by this object are made
available in templates as text virtual methods which can be called via
the dot operator.

    [% text = 'Hello World' %]
    [% text.length %]           # 11

Text object can also be created directly for those who prefer a more
strict object oriented style.

    [% text = Text.new('Hello World') %]
    [% text.length %]           # 11

=head2 Methods

=head2 append(text)

TODO: constructs and returns a new string comprising of the current text 
string (if defined) with the arguments appended to it.

=head2 capital

TODO: capitalise first letter of text

=head2 capitals

TODO: capitalise first letter of each word in text

=head2 centre(width) / center(width)

TODO: center within width characters

=head2 chomp

TODO: remove trailing newline

=head2 chop

TODO: remove trailing character

=head2 chunk(size)

This splits the text into a list of smaller chunks.  The argument
defines the maximum length in characters of each chunk.

    [% ccard_no = "1234567824683579";
       ccard_no.chunk(4).join
    %]

Output:

    1234 5678 2468 3579

If the size is specified as a negative number then the text will
be chunked from right-to-left.  This gives the correct grouping 
for numbers, for example.

    [% number = 1234567;
       number.chunk(-3).join(',')
    %]

Output:

    1,234,567

=head2 clone(text)

TODO: copy the text and return a new text object.  Any arguments provided
are appended to the end of the cloned text object.

=head2 collapse

TODO: collapsed any sequences of multiple whitespace characters into a single
space.

=head2 copy

TODO: return a copy of the text.

=head2 defined

This returns true if the text is set to some defined value, including
an empty string or the number zero.  It returns false if the text is
undefined.

    text [% text.defined ? 'is' : 'is not' %] defined

=head2 equals(text)

TODO: Return true if the text is the same as the argument passed, false otherwise.

=head2 format(format)

TODO: format text using sprintf()

=head2 hash(key)

This returns a hash reference containing the original item as the
single entry, indexed by the key C<text>.

    [% name = 'Slartibartfast';   # define text
       user = name.hash;          # convert to hash
       user.text                  # Slartibartfast
    %]     

If you want the text stored in the hash array using a different index
key, then provide it as an argument.  

    [% name = 'Slartibartfast';   
       user = name.hash('name');
       user.name 
    %]     

Any further arguments provided are also folded into the hash array.

    [% name = 'Slartibartfast';   
       user = name.hash('name', age => 13479);
       user.name;               # Slartibartfast
       user.age;                # 13479
    %]     

=head2 item

TODO: just returns a copy of self text

=head2 left(width)

TODO: format left, padded with spaces

=head2 length

This virtual method returns the number of characters in the text.

    [% IF password.length < 8 %]
       Your password is too short, please try again.
    [% END %]

=head2 list

This returns the text as a single element list.  

    [% list_of_thing = thing.list %]

The C<list> virtual method can also be called against a list and will 
return the list itself, effectively doing nothing.  Hence, if C<thing>
is already a list, then C<thing.list> will return the original list.
Either way, C<things> ends up containing a reference to a list.

Most of the time you don't need to worry about the difference between
scalars and lists.  You can call a list virtual method against any
scalar item and it will be treated as if it were a single element
list.  

The C<list> vmethod is provided for those times when you really do want
to be sure that you've got a list reference.  For example, if you are 
calling a Perl subroutine that expects a reference to a list, then adding
the C<.list> vmethod to the argument passed to it will ensure that it 
is passed a reference to a list regardless.

    [% item = 'foo';
       mysub(item.list)  # same as mysub([item])
    %]                   #  - item is a scalar

    [% item = ['foo'];
       mysub(item.list)  # same as mysub(item)
    %]                   #  - item is already a list

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

=head2 lower

TODO: return lower case version of text

=head2 match(pattern) / search(pattern)  # alias

The C<match> virtual method performs a Perl regular expression match
on the string using the pattern passed as an argument.  

    [% FOREACH serial IN ['ABC-1234', 'FOOD-4567', 'WXYZ-789'];
         IF serial.match('^\w{3}-\d{4}$');
           "GOOD serial number: $serial\n";
         ELSE;
           "BAD serial number: $serial\n";
         END;
       END
    %]

Output:

    GOOD serial number: ABC-1234
    BAD serial number: FOOD-4567
    BAD serial number: WXYZ-789
    

The pattern can contain parentheses to capture parts of the matched
string.  If the entire pattern matches then the vmethod returns a 
reference to a list of the captured strings.

    [% name = 'Arthur Dent' %]
    [% matches = name.match('(\w+) (\w+)') %]
    [% matches.1 %], [% matches.join('') %]  #  Dent, ArthurDent

In this example, the C<match> vmethod returns a list of the two strings
matched by the parenthesised patterns, C<(\w+)>.  Here they are the
values C<Arthur> and C<Dent>.

Remember that C<match> returns false if the pattern does not
match.  It does I<not> return a reference to an empty list which both
Perl and the Template Toolkit would treat as a true value, regardless
of how many entries it contains.  This allows you to test the value
returned by C<match> to determine if the pattern matched or not.

The following example shows how the results of the C<match> vmethod
can be saved in the C<matches> variable, while also testing that the
pattern matched.  The assignment statement is enclosed in parenthesis
and used as the expression for an C<IF> directive.  

    [% IF (matches = name.match('(\w+) (\w+)')) %]
       pattern matches: [% matches.join(', ') %]
    [% ELSE %]
       pattern does not match
    [% END %]

Any regular expression modifiers can be embedded in the pattern using
the C<(?imsx-imsx)> syntax.  For example, a case-insensitive match can
be specified by using the C<(?i)> construct at the start of the pattern:

    [% matched = name.match('(?i)arthur dent') %]

In the following fragment, the C<(?x)> flag is set to have whitespace
and comments in the pattern ignored:

    [% matched = name.match(
         '(?x)
            (\w+)   # match first name
             \s+    # some whitespace
            (\w+)   # match second name
         '
       )
    %]

The details of Perl's regular expressions are described in the
F<perlre>(1) manpage.  For a complete guide to learning and using
regular expressions, see "Mastering Regular Expressions" by Jeffrey
Friedl, published by O'Reilly.

=head2 prepend(text)

TODO: return new text containing all the arguments prepended onto the
beginning of the current text.

=head2 ref

TODO: returns Template::TT3::VObject::Text, just like ref()

=head2 remove(pattern)

TODO: remove from the text anything mathing the pattern passed as an argument.

=head2 repeat(count)

This virtual method returns a string containing the original text
repeated a number of times.  The repeat value should be passed as an
argument.

    [% dash = '- ';
       dash.repeat(10);       # - - - - - - - - - - 
    %]                

=head2 replace(search, replace)

This virtual method performs a global search and replace on a copy of
the text.  The first argument provides a Perl regular expression to
match part of the text.  The second argument is the replacement value.
Each occurrence of the pattern in the input string will be replaced
(hence the "global" part of "global search and replace").

    [% name = 'foo, bar & baz' %]
    [% name.replace('\W+', '_') %]    # foo_bar_baz

The C<replace> vmethod returns a copy of the text, leaving the 
original unmodified.

=head2 right(width)

TODO: format right, padded with spaces

=head2 size

This virtual method always returns 1 for scalar values.  It is provided
for consistency with the hash and list virtual methods of the same name.

=head2 split(pattern)

This virtual method splits the input text into a list of strings which is 
then returned.  It uses the regular expression passed as an argument as the
delimiter, or whitespace as default if an explicit delimiter is not provided.

    [% path  = '/here:/there:/every/where'; 
       paths = path.split(':');             
       paths.join(', ');           # /here, /there, /every/where
    %]

=head2 text

TODO: Returns the text.  This de-references the object from a scalar
reference to plain old scalar text.  It does the same thing as copy.
Dunno if we want to go into all that here...

=head2 trim

TODO: trim leading and trailing whitespace

=head2 truncate(length, suffix)

TODO: truncate at a certain length, adding an optional suffix.

    [% text = 'blah blah blah blah';
       text.truncate(12, '...')     # blah blah bl...
    %]
  
=head2 type

TODO: Returns 'Text';

=head2 upper

TODO: return UPPER CASE version of text

=head2 pop

TODO: not sure about this.

=head2 push

TODO: not sure about this.

=head2 shift

TODO: not sure about this.

=head2 unshift

TODO: not sure about this.

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


