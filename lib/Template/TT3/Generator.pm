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
    unless (ref $node eq 'ARRAY') {
        die "invalid node: $node\n";
    }
    my ($type, @args) = @$node;
    my $method = 'generate_' . lc $type;
    $self->debug("METHOD: $method\n");
    $self->$method(@args);
}

sub generate_tokens {
    my ($self, $tokens) = @_;
    return join(
        '',
        map { $_->generate($self) }
        @$tokens
    );
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

sub generate_whitespace {
    my ($self, $text) = @_;
    return "<WS>$text</WS>";
}

sub generate_tag_start {
    my ($self, $text) = @_;
    return "<TAG_START>$text</TAG_START>";
}

sub generate_tag_end {
    my ($self, $text) = @_;
    return "<TAG_END>$text</TAG_END>";
}

sub generate_word {
    my ($self, $text) = @_;
    return "<WORD>$text</WORD>";
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

sub OLD_generate_dot {
    my ($self, $dot, $lhs, $rhs) = @_;
    $self->debug("DOT: [$lhs] [$rhs]");
    return join(
        $dot,
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub OLD_generate_add {
    my ($self, $lhs, $rhs) = @_;
    return join(
        ' + ',
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub generate_binop {
    my ($self, $op, $lhs, $rhs) = @_;
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