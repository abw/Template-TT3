# This is a quick hack to decompile opcode tree

package Template::TT3::Generator;

use Template::TT3::Class
    version => 2.7,
    debug   => 0,
    base    => 'Template::TT3::Base';

our $NUM   = 'num:';   
our $VAR   = 'var:';   
our $KEY   = 'key:';   
our $IDENT = 'ident:'; 

*generate = \&generate_node;

sub generate_node {
    my ($self, $node) = @_;
    my ($type, @args) = @$node;
    my $method = "generate_$type";
    $self->$method(@args);
}

sub generate_IDENT {
    my ($self, $ident) = @_;
    return $IDENT . $ident;
}

sub generate_KEYWORD {
    my ($self, $key) = @_;
    return $KEY . $key;
}

sub generate_NUMBER {
    my ($self, $num) = @_;
    return $NUM . $num;
}

sub generate_SQUOTE {
    my ($self, $text) = @_;
    return "'$text'";
}

sub generate_DQUOTE {
    my ($self, $text) = @_;
    return qq{"$text"};
}

sub generate_TEXT {
    my ($self, $text) = @_;
    return $text;
}

sub generate_VARIABLE {
    my ($self, $var) = @_;
    return $VAR . $self->generate($var);
}

sub generate_VARNODE {
    my ($self, $name, $args) = @_;
    $args = $args
        ? '(' . join(', ', map { $self->generate($_) } @$args) . ')'
        : '';
    return $name . $args;
}

sub generate_DOTOP {
    my ($self, $lhs, $rhs) = @_;
    return join(
        '.',
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub generate_EXPRS {
    my ($self, $exprs) = @_;
    return join(
        '; ',
        map { $self->generate($_) }
        @$exprs
    );
}

sub generate_NAMESPACE {
    my ($self, $name, $space) = @_;
    return "[namespace:$name:$space]";
}

