package Template::TT3::Element::Dquote;

use Template::TT3::Class::Element
    version => 2.69,
    debug   => 0,
    base    => 'Template::TT3::Element::String',
    view    => 'dquote',
    alias   => {
        value           => \&text,
        values          => \&text,
        parse_filename  => \&parse_expr,
    };


sub parse_expr {
    my ($self, $token, $scope) = @_;
    my $branch = $self->[BRANCH];
    
    $self->advance($token);

    if ($branch) {
        $self->[BLOCK] = $branch->parse_block(\$branch, $scope)
            || $self->fail_missing( branch => $branch );

        my $junk = $branch->remaining_text;
        return $self->error("Trailing text in double quoted string branch: $junk")
            if defined $junk && length $junk;
        
        $self->debug(
            "compiled double quoted string branch: ", 
            $self->[BLOCK]->source,
        ) if DEBUG;
    }

    return $$token->skip_ws($token)
        ->parse_infix($self, $token, $scope, $self->[META]->[LPREC]);
}



sub text {
    # If we have a BLOCK then this is a dynamic string, e.g. "foo $bar"
    # otherwise it's a static string in EXPR
    $_[SELF]->[BLOCK] 
        ? $_[SELF]->[BLOCK]->text($_[CONTEXT])
        : $_[SELF]->[EXPR]
}


1;
