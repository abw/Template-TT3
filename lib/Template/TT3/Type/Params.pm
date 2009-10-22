#========================================================================
#
# Template::TT3::Type::Params
#
# DESCRIPTION
#   A wafer thin subclass of T::Type::Hash.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Type::Params;

use Template::TT3::Class
    base     => 'Template::TT3::Type::Hash',
    version  => 3.00,
    debug    => 0,
    utils    => 'blessed',
    constant => {
        PARAMS => __PACKAGE__,
        type   => 'Params',     # capitalised because it's a format type (of sorts)
    };

PARAMS->export_any( qw( PARAMS Params ) );

sub Params {
    return
        # if we only have one argument and it's already HASH then return it,
        # otherwise forward all arguments to the HASH constructor.
        @_ == 1 && blessed($_[0]) && $_[0]->isa(PARAMS)
        ? $_[0]
        : PARAMS->new(@_);
}


1;

1;

__END__

=head1 NAME

Template::TT3::Type::Params - wafer thin subclass of Template::TT3::Type::Hash

=head1 SYNOPSIS

    # see Template::TT3::Type::Hash

=head1 DESCRIPTION

C<Template::TT3::Type::Params> is a wafer thin subclass of L<Template::TT3::Type::Hash>.

It is used to store named parameters that are passed to a subroutine or
object method from TT.  

The subroutine/method can inspect the final argument passed to see if it
is an instance of C<Template::TT3::Type::Params>.  

    foo({ a = 10, b = 20 })   # regular hash array
    foo(a = 10, b = 20)       # named params

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

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
# vim: expandtab shiftwidth=4
