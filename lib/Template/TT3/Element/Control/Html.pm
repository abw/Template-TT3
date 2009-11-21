package Template::TT3::Element::Control::Html;

use Template::TT3::HTML;
use Template::TT3::Class 
    version    => 3.00,
    debug      => 0,
    base       => 'Template::TT3::Element::Keyword',
    constants  => ':elements DOT',
    constant   => {
        SKIP_WORDS => {
            map { $_ => 1 }
            qw( = is ) 
        },
    },
    alias      => {
        text   => \&value,
        values => \&value,
    },
    messages => {
        html_undef => 'Undefined value returned by %s expression: %s',
        no_output  => 'Output tokens are not accessible to HTML control.',
    };


sub parse_expr {
    my ($self, $token, $scope, $prec, $force) = @_;

    # skip over the HTML keyword and any whitespace
    $$token->next_skip_ws($token);

    # skip over '=' or 'is'
    $$token->in(SKIP_WORDS, $token);
    
    # parse the next expression    
    $self->[EXPR] = $$token->parse_expr($token, $scope)
        || return $self->missing( expression => $token );
    
    return $self;
}


sub value {
    my ($self, $context) = @_;
    my $expr = $self->[EXPR];
    my $flag = $expr->value($context);
    
    return $self->error_msg( html_undef => $self->[TOKEN], $expr->source )
        unless defined $flag;

    $self->debug("Setting HTML: $flag") if DEBUG;
    
    my $output = $context->scope->output
        || return $self->error_msg('no_output');
        
    $output->text_type(
        $flag ? 'html' : 'text'
    );
    
    return ();
}


1;
