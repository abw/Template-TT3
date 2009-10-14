package Template::TT3::Constants;

use Badger::Class 
    version  => 3.00,
    base     => 'Badger::Constants',
    constant => {
        # chomp flags for removing whitespace around tags
        CHOMP_NONE      => 0,            # do not remove whitespace
        CHOMP_ONE       => 1,            # remove one line of whitespace
        CHOMP_COLLAPSE  => 2,            # collapse all whitespace to a single space
        CHOMP_ALL       => 3,            # remove all whitespace including newlines
    
        # parser flags
        NO_WHITESPACE   => 0,            # don't skip leading whitespace 
        SKIP_WHITESPACE => 1,            # skip leading whitespace
        
        VARIABLES_SLOT  => 0,
        METHODS_SLOT    => 1,
        CONFIG_SLOT     => 2,
        NAME_SLOT       => 3,
        VALUE_SLOT      => 4,
        PARENT_SLOT     => 5,
        ARGS_SLOT       => 6,
    },
    exports => {
        any  => 'PRESENT',
        tags => {
            chomp       => 'CHOMP_NONE CHOMP_ONE CHOMP_COLLAPSE CHOMP_ALL',
            whitespace  => 'NO_WHITESPACE SKIP_WHITESPACE',
            type_slots  => 'VARIABLES_SLOT METHODS_SLOT CONFIG_SLOT
                            NAME_SLOT VALUE_SLOT ARGS_SLOT PARENT_SLOT',
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

