package Template::TT3::Type::Tree;

use Template::TT3::Class
    version     => 3.00,
    debug       => 0,
    base        => 'Template::TT3::Type',
    utils       => 'blessed',
    auto_can    => 'view_method',
    config      => 'root!',
    init_method => 'configure',
    constant    => {
        TREE    => __PACKAGE__,
        VIEWS   => 'Template::TT3::Views',
        type    => 'Tree'
    },
    exports     => {
        any     => 'TREE Tree',
    };

our $AUTOLOAD;

use Template::TT3::Views;


sub Tree {
    # if we only have one argument and it's already a TREE then return it,
    # otherwise forward all arguments to the TREE constructor.
    return @_ == 1 
        && blessed($_[0]) 
        && $_[0]->isa(TREE)
            ? $_[0]
            : TREE->new(@_);
}


sub view {
    my ($self, $view) = @_;
    $self->{ root }->view($view);
}


sub view_method {
    my ($self, $name, @args) = @_;
    my $type = $name;
    my $view;

    $self->debug("view_method($name)") if DEBUG;

    if ($type =~ s/^view_/tree./) {       # tree.HTML => Tree::HTML
        $self->debug("tree view: $type") if DEBUG;
        $view = VIEWS->view($type, @args)
            || return $self->error_msg( invalid => view => $name );

        return sub {
            shift->view( $view );
        };
    }
}



1;