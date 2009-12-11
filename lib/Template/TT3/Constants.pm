package Template::TT3::Constants;

use Badger::Class 
    version  => 3.00,
    base     => 'Badger::Constants',
    constant => {
        # Chomp flags for removing whitespace around tags
        CHOMP_NONE          => 0,   # do not remove whitespace
        CHOMP_ONE           => 1,   # remove one line of whitespace
        CHOMP_ALL           => 2,   # remove all whitespace including newlines
        CHOMP_SPACE         => 3,   # collapse whitespace to single space
        CHOMP_TAG           => 4,   # remove the tag (e.g. [%# comment %])
        
        # Mappings from above constants to the start/end tags that they 
        # represet.  Note that the order is critical.  The 0th item must
        # correlate to CHOMP_NONE, the 1st to CHOMP_ONE, and so on
        PRE_CHOMP_FLAGS     => [ qw( + - ~ = ), '#' ],
        POST_CHOMP_FLAGS    => [ qw( + - ~ = ) ],

        # cache controls
        CACHE_ALL           => -1,       # no limit to size of template cache
        CACHE_NONE          =>  0,       # no caching

        # template sources
        FROM_TEXT           => 'template text',
        FROM_CODE           => 'template code',
        FROM_HANDLE         => 'template read from file handle',
        
        # template provider schemes
        TEXT_SCHEME         => 'text',
        FILE_SCHEME         => 'file',
        CODE_SCHEME         => 'code',
        NAME_SCHEME         => 'name',
        COLON               => ':',
        
        # service names
        INPUT_SERVICE       => 'input',
        OUTPUT_SERVICE      => 'output',

        # parsing constants
        ARG_PRECEDENCE      => 200,
        CMD_PRECEDENCE      => 100,

        #
        CMD_ELEMENT         => 'cmd_%s',
        
        # flags used by elements
        FORCE               => 1,   # used to override operator precedence

        
    },
    exports => {
        any  => 'FORCE CMD_ELEMENT',
        tags => {
            chomp        => 'CHOMP_NONE CHOMP_ONE CHOMP_ALL CHOMP_SPACE
                             CHOMP_TAG PRE_CHOMP_FLAGS POST_CHOMP_FLAGS',
            cache        => 'CACHE_ALL CACHE_NONE',
            from         => 'FROM_TEXT FROM_CODE FROM_HANDLE',
            scheme       => 'TEXT_SCHEME FILE_SCHEME CODE_SCHEME NAME_SCHEME COLON',
            service      => 'INPUT_SERVICE OUTPUT_SERVICE',
            precedence   => 'ARG_PRECEDENCE CMD_PRECEDENCE',
            lookup_slots => {
                ID       => '=0',
                EXPIRES  => '=1',
            },
            type_slots  => {
                # variable slots
                META    => '=0',
                CONTEXT => '=1',
                NAME    => '=2',
                VALUE   => '=3',
                PARENT  => '=4',
                # variable metadata slots
                CONFIG  => '=0',
                VARS    => '=1',
                METHODS => '=2',
                
                # some dupliction here - needs sorting out
                SELF    => '=0',    # zeroth argument is always $self
            },


            elements  => {
                # element slots - the first 4 are common to all elements
                META     => '=0',
                NEXT     => '=1',
                TOKEN    => '=2',
                POS      => '=3',

                # remaining slots have different meanings depending on 
                # the element type
                EXPR     => '=4',    # unary expression and expr/block...
                BLOCK    => '=5',    # ... expressions use EXPR and/or BLOCK
                LHS      => '=4',    # binary expressions use LHS and RHS
                RHS      => '=5',
                ARGS     => '=6',    # arguments
                BRANCH   => '=7',    # extra branch (e.g. if/else)
                FRAGMENT => '=8',    # e.g. for#outer ... end#outer

                # element metadata slots
                CONFIG   => '=0',    # configuration parameters
                ELEMS    => '=1',    # reference to elements factory
                LPREC    => '=2',    # leftward precedence
                RPREC    => '=3',    # rightward precedence
                LEFT     => '=-1',   # binds left    # NOT USED?
                RIGHT    => '=1',    # binds right   # NOT USED?

                # evaluation parameters - move these back to being separate
                # constant set and merge them in
                SELF      => '=0',  # zeroth argument is always $self
                CONTEXT   => '=1',  # first argument is content/visitor/genr
            },
        },
    };

1;

__END__

=head1 NAME

Template::TT3::Constants - defines constants for other TT3 modules

=head1 SYNOPSIS

    use Template::TT3::Constants ':chomp';
    print CHOMP_ALL;     # 2

=head1 DESCRIPTION

This module defines a number of constants used by other modules in the
Template Toolkit.  It is a subclass of L<Badger::Constants> and inherits
all of the default constants defined therein.

Constants can be used by specifying the L<Template::TT3::Constants> package 
explicitly as part of the name:

    use Template::TT3::Constants;
    print Template::TT3::Constants::CHOMP_ALL;   # 2

Constants may be imported into the caller's namespace by naming them as 
options to the C<use Template::TT3::Constants> statement:

    use Template::TT3::Constants 'CHOMP_ALL';
    print CHOMP_ALL;   # 2

Alternatively, one of the tagset identifiers may be specified
to import different sets of constants.

    use Template::TT3::Constants ':chomp';
    print CHOMP_ALL;   # 2

=head1 EXPORTABLE TAG SETS

The following tag sets and associated constants are defined: 

=head2 :chomp

Constants used as whitespace chomping options.

    CHOMP_NONE          # do not remove whitespace
    CHOMP_ONE           # remove one line of whitespace
    CHOMP_ALL           # remove all whitespace including newlines
    CHOMP_SPACE         # collapse whitespace to single space
    CHOMP_TAG           # remove the tag (e.g. [%# comment %])
    PRE_CHOMP_FLAGS     # array ref of pre-chomp flags, e.g. '+', '-', '~', etc.
    POST_CHOMP_FLAGS    # ditto for post-chomp flags

=head2 :cache

Constants used to control caching.

    CACHE_ALL           # cache everything
    CACHE_NONE          # cache nothing

=head2 :from

Constants that define the default names for templates read from text
strings and file handles, or constructed as wrappers around existing
subroutines.

    FROM_TEXT           # template text
    FROM_CODE           # template code
    FROM_HANDLE         # template read from file handle

=head2 :scheme

Constants used as the C<scheme:> prefix when constructing URIs for templates

    TEXT_SCHEME         # text
    FILE_SCHEME         # file
    CODE_SCHEME         # code
    NAME_SCHEME         # name
    COLON               # :

=head2 :service

Constants defining the names of the core services that
L<Template::TT3::Engine::TT3> fetches from L<Template::TT3::Services> to 
construct a template service pipeline.

    INPUT_SERVICE       # input
    OUTPUT_SERVICE      # output

=head2 :precedence

Constants used by various L<Template::TT3::Element> module to denote 
pre-define operator precedence levels

    ARG_PRECEDENCE      # 200
    CMD_PRECEDENCE      # 100

=head2 :lookup_slots

These constants define semantic aliases for the array offsets used by 
C<Template::TT3::Templates> in its internal path lookup cache.

    ID                  # 0
    EXPIRES             # 1

=head2 :type_slots

Constants that represent the offsets of particular slots within array based
objects.  In this case they are the slots used by data types.

TODO: They need a good cleanup and the name should possible be changed to 
something more suitable.

    # variable data slots
    META                # 0
    CONTEXT             # 1
    NAME                # 2
    VALUE               # 3
    PARENT              # 4

    # variable metadata slots
    CONFIG              # 0
    VARS                # 1
    METHODS             # 2

=head2 :elements

Constants that represent the offsets of particular slots within L<Template::TT3::Element>
objects.  The first 4 slots are common to all element types.

    META                # 0
    NEXT                # 1
    TOKEN               # 2
    POS                 # 3

The remaining slots have different meanings depending on the element type.
Unary expressions (including those with blocks) refer to the next 2 slots
as C<EXPR> and C<BLOCK>

    EXPR                # 4
    BLOCK               # 5

Binary expressions use C<LHS> and C<RHS> instead.

    LHS                 # 4
    RHS                 # 5

Expressions that have additional arguments put them in the next slot.

    ARGS                # 6

Those that have an additional branch (e.g. the C<else> hanging off an C<if>
block) store it in the C<BRANCH> slot.

    BRANCH              # 7

Any that have a fragment (e.g. C<end#for>) store it in C<FRAGMENT>.

    FRAGMENT            # 8

The first slot in an element (C<META>) contains a reference to a metadata
structure which is also an array reference (an entry in the grammar symbol
table - see the source code for L<Template::TT3::Grammar::TT3> for an example.
The following constants define aliases for the slots in the metadata list.

    CONFIG              # configuration parameters
    ELEMS               # reference to elements factory
    LPREC               # leftward precedence
    RPREC               # rightward precedence

The final two constants are used by element evaluation methods.  

    SELF                # 0
    CONTEXT             # 1

The element classes have many small methods that do very little.  We try 
to avoid shifting items off the stack wherever possible (for the sake
of speed) and instead reference arguments directly on the stack.

So instead of something like this:

    sub some_method {
        my ($self, $context) = @_;
        $self->something_trivial($context);
    }

You'll instead see:

    sub some_method {
        $_[SELF]->something_trivial($_[CONTEXT]);
    }

Which is slightly more meaningful than:

    sub some_method {
        $_[0]->something_trivial($_[1]);
    }

=head2 :all

Imports all the constants defined by this module.

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

This module is a subclass of L<Badger::Constants>.

See L<Badger::Exporter> for more information on exporting variables.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

