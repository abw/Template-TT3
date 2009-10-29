# This is a quick hack to decompile opcode tree

package Template::TT3::Generator;

use Template::TT3::Class
    version  => 2.7,
    debug    => 0,
    base     => 'Template::TT3::Base',
    utils    => 'is_object',
    constant => {
        OP => 'Template::TT3::Op',
    };

our $NUM   = 'num:';   
our $VAR   = 'var:';   
our $KEY   = 'key:';   
our $IDENT = 'ident:'; 

*generate = \&generate_node;

sub generate_node {
    my ($self, $node) = @_;
    if (is_object(OP, $node)) {
        $self->debug("got opcode") if DEBUG;
        return $node->generate($self);
    }
    my ($type, @args) = @$node;
    my $method = 'generate_' . lc $type;
    $self->$method(@args);
}

sub generate_ident {
    my ($self, $ident) = @_;
    return $IDENT . $ident;
}

sub generate_keyword {
    my ($self, $key) = @_;
    return $KEY . $key;
}

sub generate_number {
    my ($self, $num) = @_;
    return $NUM . $num;
}

sub generate_squote {
    my ($self, $text) = @_;
    return "'$text'";
}

sub generate_dquote {
    my ($self, $text) = @_;
    return qq{"$text"};
}

sub generate_text {
    my ($self, $text) = @_;
    return $text;
}

sub generate_variable {
    my ($self, $var) = @_;
    return $VAR . $self->generate($var);
}

sub generate_varnode {
    my ($self, $name, $args) = @_;
    $args = $args
        ? '(' . join(', ', map { $self->generate($_) } @$args) . ')'
        : '';
    return $name . $args;
}

sub generate_dot {
    my ($self, $lhs, $rhs) = @_;
    return join(
        '.',
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub generate_add {
    my ($self, $lhs, $rhs) = @_;
    return join(
        ' + ',
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub generate_binop {
    my ($self, $lhs, $op, $rhs) = @_;
    return join(
        $op,
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub generate_exprs {
    my ($self, $exprs) = @_;
    return join(
        '; ',
        map { $self->generate($_) }
        @$exprs
    );
}

sub generate_namespace {
    my ($self, $name, $space) = @_;
    return "[namespace:$name:$space]";
}

1;