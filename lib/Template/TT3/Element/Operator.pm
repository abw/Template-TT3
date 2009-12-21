package Template::TT3::Element::Operator;

use Template::TT3::Class 
    version   => 3.00,
    constants => ':elements',
    utils     => 'xprintf',
    view      => 'operator';


sub OLD_parse_dotop {
    # Operators can't be dotops by default - this is really a nasty quick
    # hack to mask the parse_dotop() method in T::Element::Number which 
    # allows a number to be used as a dotop.  Because all our numeric
    # ops are subclasses of T::E::Number (the core problem, I think) that
    # means they inherit the parse_dotop() method and think they are valid
    # syntax after a dot, e.g. foo.**

    # FIXME: this include 'or' 'and', etc, and other keywords (unless we 
    # patch in another method in the keyword/command class to override it,
    # but then it's starting to get messy).  This is a quick hack.
    
    return undef;
}


sub OLD_no_rhs_expr { 
    my ($self, $token) = @_;
    
    # We throw an error for now.  It's conceivable that we might want to
    # do some error recovery here.  We could generate a warning, wind the
    # token pointer forward to the next terminator token, and return a  
    # parse_error element containing information about the error.  But for
    # now, we'll just throw an error.
    my $next = $token 
        && $$token->skip_ws->[TOKEN]
        || '';
    
    $self->syntax_error_msg( 
        $$token,
        length $next
            ? ( no_rhs_expr_got => $self->[TOKEN], $next )
            : ( no_rhs_expr     => $self->[TOKEN] )
    );
}


sub debug_op {
    $_[0]->debug_at(
        { format => '[pos:<pos>] <msg>]', pos => $_[0]->[POS] },
        xprintf(
            $_[0]->DEBUG_FORMAT, 
            $_[0]->[TOKEN],
            map { $_ ? ($_->source, $_->value($_[1])) : ('', '') }
            $_[0]->[LHS],
            $_[0]->[RHS],
        )
    );
}

1;

__END__
#-----------------------------------------------------------------------
# Template::TT3::Element::Operator;
#
# Base class for operator mixins.  Not that this is NOT a subclass of
# Template::TT3::Element as we don't want to inherit all the default 
# methods.  This allows us to put an operator mixin at the start of the
# base path (@ISA) for a subclass.  This will add the methods defined
# below, but leave any other methods to be inherited from subsequent 
# base classes in the @ISA list.
#-----------------------------------------------------------------------



