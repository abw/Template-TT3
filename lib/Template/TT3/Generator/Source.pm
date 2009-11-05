package Template::TT3::Generator::Source;

use Template::TT3::Class
    version  => 2.7,
    debug    => 0,
    import   => 'class',
    base     => 'Template::TT3::Generator';

sub that {
    $_[1];
}

class->methods(
    map { ("generate_$_" => \&that) }
    qw( ident keyword number text whitespace tag_start tag_end 
        word variable binop )
);

sub generate_squote {
    my ($self, $text) = @_;
# pre-escaping is turned off
#    $text =~ s/(['\/])/\\$1/g;
    return qq{'$text'};
}

sub generate_dquote {
    my ($self, $text) = @_;
# pre-escaping is turned off
#    $text =~ s/(["\/])/\\$1/g;
    return qq{"$text"};
}

sub generate_varnode {
    my ($self, $name, $args) = @_;
    $args = $args
        ? '(' . join(', ', map { $self->generate($_) } @$args) . ')'
        : '';
    return $name . $args;
}

sub generate_exprs {
    my ($self, $exprs) = @_;
    return join(
        '',
        map { $self->generate($_) }
        @$exprs
    );
}

sub generate_namespace {
    my ($self, $name, $space) = @_;
    return "$name:$space";
}

sub generate_prefix {
    my ($self, $op, $rhs) = @_;
    return $op;
}

sub generate_postfix {
    my ($self, $op, $lhs) = @_;
    return $op;
}

sub generate_punctuation {
    my ($self, $mark) = @_;
    return $mark;
}

sub generate_do {
    my ($self, $op) = @_;
    return $op;
}

1;

__END__

=head1 NAME

Template::TT3::Generator::Source - re-generate original source

=head1 SYNOPSIS

    Template::TT3::Generator::Source;

    # TODO

=head1 DESCRIPTION

# TODO

=head1 METHODS

=head2 new()

# TODO

=head2 generate($item)

TODO

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.

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

