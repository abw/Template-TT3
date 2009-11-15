package Template::TT3::View::Tokens;

use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::View';

sub view_tokens {
    my ($self, $tokens) = @_;
    $self->emit(
        map { $_->view($self) }
        @$tokens
    );
}

1;
