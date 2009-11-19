package Template::TT3::View::Tokens::Source;

use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::View::Tokens',
    constants   => 'BLANK :elements',
    auto_can    => 'can_view';


sub view_tokens {
    my ($self, $tokens) = @_;
    join(
        BLANK,
        grep { defined }
        map  { $_->view($self) }
        @$tokens
    );
}

# Padding is synthetic whitespace that can be added to the token stream.
# e.g. [% foo =%][% bar %] inserts a space of padding after the '=%]' token

sub view_padding {
    return BLANK;
}


# Method generator that accepts calls to any view_XXX() method and constructs
# a new method that simply returns the element token.

sub can_view {
    my ($self, $name) = @_;

    if ($name =~ /^view_(\w+)/) {
        return sub { 
            $_[1]->[TOKEN]
        }
    }
}

1;
