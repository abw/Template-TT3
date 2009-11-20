package Template::TT3::Element::Block;

use Template::TT3::Type::Params 'PARAMS';
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Element',
    view      => 'block',
    constants => ':elements BLANK',
    constant  => {
        SEXPR_FORMAT  => "<block:%s>",
        SOURCE_FORMAT => '%s',
        SOURCE_JOINT  => '; ',
    },
    alias     => {
        exprs  => \&expressions,
        value  => \&text,
#        values => \&text,
    };


sub text {
    $_[SELF]->debug("block text(): ", $_[SELF]->source) if DEBUG;
    join(
        BLANK,
        grep { defined }                # TODO: warn
        map { $_->text($_[1]) } 
        @{ $_[0]->[EXPR] } 
    );
}


sub values {
    $_[SELF]->debug("block values(): ", $_[SELF]->source) if DEBUG;
    map { $_->values($_[CONTEXT]) } 
    @{ $_[SELF]->[EXPR] } 
}


sub pairs {
    $_[SELF]->debug("block pairs(): ", $_[SELF]->source) if DEBUG;
    map { $_->pairs($_[CONTEXT]) } 
    @{ $_[SELF]->[EXPR] } 
}


sub params {
    $_[SELF]->debug("block params(): ", $_[SELF]->source) if DEBUG;

    my ($self, $context, $posit, $named) = @_;
    $posit ||= [ ];
    $named ||= bless { }, PARAMS;
    
    $_->params($context, $posit, $named)
        for @{ $_[SELF]->[EXPR] };
    
    push(@$posit, $named) 
        if $named && %$named;

    $self->debug("returning ", $self->dump_data($posit)) if DEBUG;
    return @$posit;
}


sub variable {
    # a block of text can be converted to a text variable in order to 
    # perform dotops on it.
    $_[CONTEXT]->{ variables }
         ->use_var( $_[SELF], $_[SELF]->text( $_[CONTEXT] ) );
}


sub expressions {
    wantarray
        ? @{ $_[SELF]->[EXPR] }
        :    $_[SELF]->[EXPR];
}


sub sexpr {
    my $self   = shift;
    my $format = shift || $self->SEXPR_FORMAT;
    my $body   = join(
        "\n",
        map { $_->sexpr } 
        @{ $self->[EXPR] }
    );
    $body =~ s/^/  /gsm if $body;
    sprintf(
        $format,
        $body ? ("\n" . $body . "\n") : ''
    );
}


sub source {
    my $self   = shift;
    my $format = shift || $self->SOURCE_FORMAT;
    my $joint  = shift || $self->SOURCE_JOINT;
    sprintf(
        $format,
        join(
            $joint,
            map { $_->source } 
            @{ $self->[EXPR] }
        )
    );
}


1;