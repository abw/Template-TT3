package Template::TT3::Generator::Tokens::HTML;

use Template::TT3::Class
    version  => 2.7,
    debug    => 0,
    base     => 'Template::TT3::Generator',
    codec    => 'html',
    constant => {
        ATTR    => '%s="%s"',
        ELEMENT => '<%s%s>%s</%s>',
    };

our $AUTOLOAD;


sub HTML {
    my ($name, $attrs, @content) = @_;
    my $attr = $attrs
        ? join(
            ' ',
            '',     # dummy first entry to get leading space
            map { sprintf( ATTR, $_ , encode( $attrs->{ $_ } ) ) }
            sort keys %$attrs
          )
        : '';
            
    return sprintf( ELEMENT, $name, $attr, join('', @content), $name );
}

sub span {
    my $self      = shift;
    my $css_class = shift;
    HTML( span => { class => $css_class }, @_ );
}


sub generate_squote {
    shift->span( squote => "'", @_, "'" );
}

sub generate_dquote {
    shift->span( dquote => '"', @_, '"' );
}

sub generate_tag_start {
    return '<span class="tag">'
        . shift->span( tag_start => @_ );
}

sub generate_tag_end {
    return shift->span( tag_start => @_ )
        . '</span>';
}

sub generate_varnode {
    my ($self, $name, $args) = @_;
    $args = $args
        ? '(' . join(', ', map { $self->generate($_) } @$args) . ')'
        : '';
    return $name . $args;
}

sub generate_binop {
    shift->span( binop => shift );
}

sub generate_exprs {
    my ($self, $exprs) = @_;
    return join(
        "\n",
        map { $self->generate($_) }
        @$exprs
    );
}

sub AUTOLOAD {
    my $self   = shift;
    my ($name) = ($AUTOLOAD =~ /([^:]+)$/ );
    return if $name eq 'DESTROY';

    if ($name =~ s/^generate_//) {
        return $self->span( $name => @_ );
    }

    my ($pkg, $file, $line) = caller;
    my $class = ref $self || $self;
    return $self->error_msg( bad_method => $name, $class, $file, $line );
}


1;

__END__

=head1 NAME

Template::TT3::Generator::Debug - debugging code generator

=head1 SYNOPSIS

    Template::TT3::Generator::Debug;

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

