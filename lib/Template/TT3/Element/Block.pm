package Template::TT3::Element::Block;

use Template::TT3::Utils;
use Template::TT3::Type::Params 'PARAMS';
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'block',
    constants => ':elements BLANK',
    constant  => {
        SEXPR_FORMAT  => "<block:%s>",
        SOURCE_FORMAT => '%s',
        SOURCE_JOINT  => '; ',
    },
    alias     => {
        exprs  => \&expressions,
        value  => \&text,
    };


sub text {
    $_[SELF]->debug("block text(): ", $_[SELF]->source) if DEBUG;
    join(
        BLANK,
        grep { defined }                # TODO: warn
        map { $_->text($_[1]) } 
        @{ $_[0]->[EXPR] } 
    );
}


sub values {
    $_[SELF]->debug("block values(): ", $_[SELF]->source) if DEBUG;
    map { $_->values($_[CONTEXT]) } 
    @{ $_[SELF]->[EXPR] } 
}


sub pairs {
    $_[SELF]->debug("block pairs(): ", $_[SELF]->source) if DEBUG;
    map { $_->pairs($_[CONTEXT]) } 
    @{ $_[SELF]->[EXPR] } 
}


sub params {
    $_[SELF]->debug("block params(): ", $_[SELF]->source) if DEBUG;

    my ($self, $context, $posit, $named) = @_;
    $posit ||= [ ];
    
    # FIXME: this is a temporary hack during development to try out 
    # different approaches for identifying named parameters supplied by
    # TT
    $named ||= $Template::TT3::Utils::TT_PARAMS_BLESS 
        ? (bless { }, $Template::TT3::Utils::TT_PARAMS_BLESS)
        : { };
    
    $_->params($context, $posit, $named)
        for @{ $_[SELF]->[EXPR] };
    
    push(@$posit, $named) 
        if $named && %$named;

    $self->debug("returning [$named]", $self->dump_data($posit)) if DEBUG;
    return @$posit;
}


sub variable {
    # a block of text can be converted to a text variable in order to 
    # perform dotops on it.
    $_[CONTEXT]->{ variables }
         ->use_var( $_[SELF], $_[SELF]->text( $_[CONTEXT] ) );
}


sub expressions {
    wantarray
        ? @{ $_[SELF]->[EXPR] }
        :    $_[SELF]->[EXPR];
}


sub sexpr {
    my $self   = shift;
    my $format = shift || $self->SEXPR_FORMAT;
    my $body   = join(
        "\n",
        map { $_->sexpr } 
        @{ $self->[EXPR] }
    );
    $body =~ s/^/  /gsm if $body;
    sprintf(
        $format,
        $body ? ("\n" . $body . "\n") : ''
    );
}


sub source {
    my $self   = shift;
    my $format = shift || $self->SOURCE_FORMAT;
    my $joint  = shift || $self->SOURCE_JOINT;
    sprintf(
        $format,
        join(
            $joint,
            map { $_->source } 
            @{ $self->[EXPR] }
        )
    );
}


1;

__END__

=head1 NAME

Template:TT3::Element::Block - element representing a block of elements

=head1 DESCRIPTION

This module implements a subclass of L<Template::TT3::Element>. It acts as a
container for a sequence of other elements.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Template::TT3::Element>, L<Template::TT3::Base> and L<Badger::Base>
base classes.

=head2 text()

=head2 value()

An alias to L<text()>.

=head2 values()

=head2 pairs()

=head2 params()

=head2 variable()

=head2 expressions() / exprs()

=head1 AUTHOR

Andy Wardley L<http://wardley.org>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Badger::Base>,
L<Template::TT3::Base>,
L<Template::TT3::Element>.

=cut

# Local Variables:
# mode: Perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
