package Template::TT3::View::Tree::Vars;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tree',
    utils     => 'is_object',
    auto_can  => 'can_view',
    constants => ':elements',
    config    => 'template source',
    modules   => 'ELEMENT_MODULE';


sub view_tree {
    my ($self, $tree) = @_;

    my $vars = { };
    local $self->{ vars } = $vars;
    
    $tree->view($self);
    
    return $vars;
}


sub var {
    my ($self, $name) = @_;
    return $self->{ vars }->{ $name } ||= {
        name => $name,
        used => 0,
    };
}

sub var_used {
    my ($self, $var, $element, $from, $length) = @_;
    my $source = $self->{ source };
    
    $from ||= $element->[POS];
    
    my $where  = $source 
        ? $source->whereabouts( position => $from )
        : { position => $from, extract => $element->source };

    $where->{ length } = $length || length $element->[TOKEN];

    $var = $self->var($var)
        unless ref $var;
    
    $var->{ used }++;

    $self->debug(
        "found use of variable $var->{ name } at: ", 
        $self->dump_data($where)
    ) if DEBUG;
    
    my $wheres = $var->{ where } ||= [ ];
    push(@$wheres, $where);

    return $var;
}


sub view_variable {
    my ($self, $element) = @_;
    return $self->var_used( $element->source, $element );
}


sub view_dot {
    my ($self, $elem) = @_;
    my $lhs   = $elem->[LHS]->view($self) || return;
    my $rhs   = $elem->[RHS]->source;
    my $from  = $elem->left_edge->[POS];
    my $redge = $elem->right_edge;
    my $to    = $redge->[POS] + length $redge->[TOKEN];
    my $len   = $to - $from;
    
    $self->debug("got LHS for dot LHS: $lhs    RHS: $rhs")
        if DEBUG;

    return $self->var_used( 
        # hack to replace $lhs with $self
        var($lhs, $rhs),
        $elem,
        $from, $len
    );
}

sub view_dquote {
    my ($self, $elem) = @_;
    my $branch = $elem->[BRANCH];
    while ($branch && ! $branch->eof) {
        $branch->view($self);
        $branch = $branch->[NEXT];
    }
}    

sub can_view {
    my ($self, $name) = @_;
    return sub {
        my ($self, $elem) = @_;
        for my $e (EXPR, BLOCK, ARGS, BRANCH) {
            $elem->[$e]->view($self) 
                if $elem->[$e]
                && is_object(ELEMENT_MODULE, $elem->[$e]);
        }
#        shift->debug("doing nothing for $name ($_[0])");
    }
#    return \&do_nothing;
}


sub do_nothing {
    return;
}


1;