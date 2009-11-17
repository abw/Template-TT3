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
        
        # flags used by elements
        FORCE               => 1,   # used to override operator precedence
        
        # misc symbols
        DOT                 => '.',
        
        CMD_PRECEDENCE      => 100,
        CMD_ELEMENT         => 'cmd_%s',
    },
    exports => {
        any  => 'FORCE DOT',
        tags => {
            chomp       => 'CHOMP_NONE CHOMP_ONE CHOMP_ALL CHOMP_SPACE
                            CHOMP_TAG PRE_CHOMP_FLAGS POST_CHOMP_FLAGS',
            whitespace  => 'NO_WHITESPACE SKIP_WHITESPACE',
            precedence  => 'CMD_PRECEDENCE CMD_ELEMENT',
            type_slots  => {
                # variable slots
                META    => '=0',
                NAME    => '=1',
                VALUE   => '=2',
                PARENT  => '=3',
                # variable metadata slots
                CONFIG  => '=0',
                VARS    => '=1',
                METHODS => '=2',
            },
            elem_slots  => {
                # element slots - the first 4 are common to all elements
                META    => '=0',
                NEXT    => '=1',
                TOKEN   => '=2',
                POS     => '=3',

                # remaining slots have different meanings depending on 
                # the element type
                JUMP    => '=4',    # used to skip over compile time control tags
                EXPR    => '=4',    # unary expression and expr/block...
                BLOCK   => '=5',    # ... expressions use EXPR and/or BLOCK
                LHS     => '=4',    # binary expressions use LHS and RHS
                RHS     => '=5',
                ARGS    => '=6',    # arguments

                # element metadata slots
                CONFIG  => '=0',    # configuration parameters
                ELEMS   => '=1',    # reference to elements factory
                LPREC   => '=2',    # leftward precedence
                RPREC   => '=3',    # rightward precedence
                LEFT    => '=-1',   # binds left    # NOT USED?
                RIGHT   => '=1',    # binds right   # NOT USED?
            },
            eval_args => {
                SELF      => '=0',  # zeroth argument is always $self
                CONTEXT   => '=1',  # first argument is content/visitor/genr
                VISITOR   => '=1',
                VIEW      => '=1',
                GENERATOR => '=1',
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

