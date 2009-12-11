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
        
        # flags used by elements
        FORCE               => 1,   # used to override operator precedence

        # parsing constants
        ARG_PRECEDENCE      => 200,
        CMD_PRECEDENCE      => 100,
        CMD_ELEMENT         => 'cmd_%s',
        
        FROM_TEXT           => 'template text',
        FROM_CODE           => 'template code',
        FROM_HANDLE         => 'template read from file handle',
        
        TEXT_SCHEME         => 'text',
        FILE_SCHEME         => 'file',
        CODE_SCHEME         => 'code',
        NAME_SCHEME         => 'name',
        COLON               => ':',
    },
    exports => {
        any  => 'FORCE',
        tags => {
            chomp       => 'CHOMP_NONE CHOMP_ONE CHOMP_ALL CHOMP_SPACE
                            CHOMP_TAG PRE_CHOMP_FLAGS POST_CHOMP_FLAGS',
            cache       => 'CACHE_ALL CACHE_NONE',
            from        => 'FROM_TEXT FROM_CODE FROM_HANDLE',
            scheme      => 'TEXT_SCHEME FILE_SCHEME CODE_SCHEME NAME_SCHEME COLON',
            whitespace  => 'NO_WHITESPACE SKIP_WHITESPACE',
            precedence  => 'ARG_PRECEDENCE CMD_PRECEDENCE CMD_ELEMENT',
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
            args => {
                SELF    => '=0',    # zeroth argument is always $self
                ARG1    => '=1',
                ARG2    => '=2',
                ARG3    => '=3',
                ARG4    => '=4',
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
                # TODO: rename ELSE as BRANCH
                ELSE     => '=7',    # reference to follow-on block, e.g. else
                BRANCH   => '=7',    # used to skip over compile time control tags
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
                VISITOR   => '=1',
                VIEW      => '=1',
                GENERATOR => '=1',
            },
            lookup => {
                LOOKUP_ID      => '=0',
                LOOKUP_EXPIRES => '=1',
            },
        },
    };

1;

__END__

=head1 NAME

Template::TT3::Constants - defines constants for other TT3 modules

=head1 SYNOPSIS

    use Template::TT3::Constants ':chomp';
    print CHOMP_COLLAPSE;     # 2

=head1 DESCRIPTION

This module defines a number of constants used by other modules in the
Template Toolkit.  It is a subclass of L<Badger::Constants> and inherits
all of the default constants defined therein.

Constants can be used by specifying the L<Template::TT3::Constants> package 
explicitly as part of the name:

    use Template::TT3::Constants;
    print Template::TT3::Constants::CHOMP_COLLAPSE;   # 2

Constants may be imported into the caller's namespace by naming them as 
options to the C<use Template::TT3::Constants> statement:

    use Template::TT3::Constants 'CHOMP_COLLAPSE';
    print CHOMP_COLLAPSE;   # 2

Alternatively, one of the tagset identifiers may be specified
to import different sets of constants.

    use Template::TT3::Constants ':chomp';
    print CHOMP_COLLAPSE;   # 2

=head1 EXPORTABLE TAG SETS

The following tag sets and associated constants are defined: 

    :chomp              # whitespace chomping around tags
        CHOMP_NONE
        CHOMP_ONE
        CHOMP_COLLAPSE
        CHOMP_ALL

    :whitespace         # whitespace skipping inside tags
        NO_WHITESPACE
        SKIP_WHITESPACE
    
    :var_slots          # internal slots for variable objects
        ## TODO ##

    :all                # all the above constants.

=head1 AUTHOR

Andy Wardley L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Badger::Exporter> for more information on exporting variables.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

