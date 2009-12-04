package Template::TT3::View::Tree::VarsHTML;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tree::Vars Template::TT3::View::HTML',
    codec     => 'html',
    auto_can  => 'can_view',
    constants => ':elements',
    config    => 'template source';

our $TRIM_TEXT = 128;


sub view_tree {
    my ($self, $tree) = @_;
    my $vars = $self->SUPER::view_tree($tree);
    return $self->dump_vars($vars);
}

sub dump_vars {
    my ($self, $vars) = @_;
    return join(
        "\n",
        map { $self->dump_var($vars->{ $_ }) }
        sort keys %$vars,
    );
}

sub dump_var {
    my ($self, $var) = @_;
    my $name = $var->{ name };
    $self->div(
        "variable element",
        $self->div(
            head => $name
        ),
        $self->div( 
            body => 
                $var->{ where }
                    ? $self->branch( Uses => $self->dump_wheres( $var->{ where } ) )
                    : (),
                $var->{ vars }
                    ? $self->branch( Vars => $self->dump_vars( $var->{ vars } ) )
                    : (),
        )
    );
}

sub dump_wheres {
    my ($self, $wheres) = @_;
    return $self->div(
        block => map { $self->dump_where($_) } @$wheres
    );
}

sub dump_where {
    my ($self, $where) = @_;
    my $extract;
    
    $self->debug("dump where: ", $self->dump_data($where))
        if DEBUG;
    
    if ($extract = $where->{ extract }) {
        my $off  = $where->{ offset };
        my $len  = $where->{ length };

        if (defined $off && defined $len) {
            my $pre  = substr($extract, 0, $off);
            my $bit  = substr($extract, $off, $len);
            my $post = substr($extract, $off + $len);
            $extract = encode($pre)
                     . $self->span( used_here => encode($bit) )
                     . encode($post);
        }
    };

    return $self->div(
        element => 
            $self->div(
                head => 
                $self->span(
                    $where->{ line } 
                        ? ("info line" => '@' . ' line ' . $where->{ line })
                        : ("info posn" => '@' . $where->{ position })
                ),
                $extract 
                    ? $self->span( source => $self->tidy_text( $extract ) )
                    : ()
            )
    );
}
    


1;