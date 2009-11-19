package Template::TT3::Tag::Control;

use Template::TT3::Grammar::Control;
use Template::TT3::Elements::Punctuation;
use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Template::TT3::Tag::Inline',
    utils     => 'refaddr',
    constants => ':elements',
    constant  => {
        GRAMMAR => 'Template::TT3::Grammar::Control',
        EOF     => 'Template::TT3::Element::Eof',
    };

our $EOF;


sub tokens {
    my ($self, $input, $output, $scope) = @_;
    my $first = $output->last;
    my $end   = $self->SUPER::tokens($input, $output, $scope);
    my $last  = $self->parse($first, $input, $output, $scope);
    
    # set a forward reference from the first token to the last, so that 
    # we can skip over any control tokens when parsing runtime expressions.
    $self->debug("setting BRANCH on $first ($first->[TOKEN]) to $last ($last->[TOKEN]) : ", refaddr $last)
        if DEBUG;
        
    $first->[BRANCH] = $last;    # skip to last token
    
    return $end;
}


sub parse {
    my ($self, $token, $input, $output, $scope) = @_;
    my ($last, $exprs, $text);

    $self->debug("scope is $scope") if DEBUG;
    
    # we need to put a temporary EOF on the end of the token stream so that
    # we can parse the tokens that we've got into expressions.
    $last = $output->last;
    $last->[NEXT] = $EOF ||= EOF->new;
    
    $self->debug("parsing control tag") if DEBUG;

    if ($exprs = $token->as_exprs(\$token)) {
        $self->debug("parsed control tag: ", $exprs->sexpr) if DEBUG;

        # Evaluate expressions in the current scope.  We call text() (rather
        # than value() or values()) to force any undefined values to be 
        # reported.  It's OK for an expression to yield an undefined value()
        # but not text() (TODO: perhaps better to have different variable
        # objects for undefined vs not_found
#        local $scope->{ tag } = $self;
        $exprs->text( $scope->context );
    }

    # check for unparsed text
    $token->skip_ws(\$token);
    $self->error("Unexpected text in control tag: $text")
        if ($text = $token->remaining_text) && length $text;
    
    # FIXME: wind over any unparsed tokens
#    while ($token && $token->skip_ws(\$token)) {
#        last if $token->eof;
#        print "** IGNORED ** ", $token->token, "\n";
#        $token = $token->next;
#    }
    

    # clear temporary EOF token
    $last->[NEXT] = undef;
    
    return $last;

}

1;

__END__
    # we need to add a dummy EOF token to the end of the stream so that
    # our parse rules terminate properly
    my $exprs = $token->as_exprs(\$token);
    while ($token = $token->next_skip_ws) {
        print "** ", $token->token, "\n";
        $last = $token;
    }
    
    $token = $last;
    
    # wind forward over any trailing whitespace - FIX ME
    while ($token && ($token = $token->next)) {
        $last = $token;
        # FIXME: 
#        $token = $last->skip_ws
#            || return $self->error("Unexpected control token: ", $token->token);
    }
    
    $final->[NEXT] = $after;
    
    return $last;
}



1;

__END__

=head1 NAME

Template::TT3::Tag::Control

=head1 DESCRIPTION

A base class for all tags that embed compile time controls.
