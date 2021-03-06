package Template::TT3::View::Tree;

use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::View';

sub view_tree {
    my ($self, $tree) = @_;
    $tree->view($self);
}


sub view_block {
    my ($self, $block) = @_;
    return join(
        "\n", 
        grep { defined $_ }
        map { $_->view($self) }
        $block->expressions
    );
}

1;
