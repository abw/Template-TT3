package Template::TT3::View::Tokens::Debug;

use Template::TT3::Class
    version     => 2.7,
    debug       => 0,
    base        => 'Template::TT3::View::Tokens',
    constants   => 'ARRAY :elem_slots',
    utils       => 'params refaddr',
    import      => 'class',
    config      => 'show_pos=1 show_refs=0',
    init_method => 'configure';


our $TRIM_TEXT = 64;


#sub init {
#    my ($self, $config) = @_;
#    $self->debug("init: ", $self->dump_data($config));
#    return $self;
#}


#-----------------------------------------------------------------------
# general purpose methods for emitting elements
#-----------------------------------------------------------------------

sub emit {
    my $self = shift;
    join(
        "\n",
        grep { defined }
        map  { ref $_ eq ARRAY ? @$_ : $_ }
        @_
    );
}


sub emit_head {
    my ($self, $name, $pos, $body, @attrs) = @_;
    my $attrs = $self->emit_attrs($pos, @attrs);
    return "<$name$attrs:$body>";
}


sub emit_attrs {
    my ($self, $pos, @args) = @_;
    my @attrs;

    push(@attrs, '@' . $pos) 
        if defined $pos && $self->{ show_pos };

    if (@args) {
        my $params = params(@args);
        push(
            @attrs, 
            map { "$_=$params->{ $_ }" } 
            grep { defined $params->{ $_ } }
            sort keys %$params
        );
    }
    return @attrs 
        ? '[' . join(', ', @attrs) . ']'
        : '';
}



sub emit_body {
    my ($self, $name, $pos, $body) = @_;
    $pos = defined $pos ? '@' . $pos : '';
    $body =~ s/^/$self->{ pad }/gm if $self->{ indent };
    chomp $body;
    return "<$name$pos:\n$body\n>";
}


sub emit_set {
    my ($self, $name, $value) = @_;
    return "<SET:$name=$value>";
}

sub emit_text {
    my ($self, $text) = @_;
    $text =~ s/\n/\\n/g;
    $text =~ s/\t/\\t/g;
    $text = substr($text, 0, $TRIM_TEXT) . '...' 
        if $TRIM_TEXT && length($text) > $TRIM_TEXT - 3;
    return $text;
}

sub show_refs {
    $_[0]->{ show_refs } ? $_[1]->view_guts : ()
}


#-----------------------------------------------------------------------
# view methods
#-----------------------------------------------------------------------

sub view_element {
    my ($self, $element) = @_;
    $self->emit_head(
        $element->class->id,
        $element->[POS],
        $element,
        $self->show_refs($element),
    )
}


sub view_eof {
    my ($self, $elem) = @_;
    my $attrs = $self->emit_attrs($elem->[POS], $self->show_refs($elem));
    return "<EOF$attrs>";
}

class->methods(
    map {
        my $type = $_;              # lexical copy for closure
        "view_$type" => sub {
            $_[0]->emit_head(
                $type, 
                $_[1]->[POS],
                $_[0]->emit_text( $_[1]->[TOKEN] ),
                $_[0]->show_refs($_[1]),
            );
        }
    }
    qw(
        text comment whitespace padding tag_start tag_end html
        literal word keyword number filename unary binary prefix
        postfix
    )
);



__END__

#-----------------------------------------------------------------------
# main chunks
#-----------------------------------------------------------------------

sub view_tag {
    my ($self, $tag) = @_;
    my $text = $tag->{ text } || '<no text>';
    my $line = $tag->{ start_line } || "";
    if ($line && $tag->{ end_line } && $line != $tag->{ end_line }) {
        $line = " from line $line to $tag->{ end_line }";
    }
    elsif ($line) {
        $line = " at line $line";
    }
    $text =~ s/\n/\\n/g;
    return "<TAG$line:$text>";
}

sub view_expr {
    my ($self, $expr) = @_;
    my ($method, $handler, $result);
    my ($name, @args) = @$expr;
    $method = $self->{ views }->{ $name } 
          ||= $self->can("view_$name")
          ||  return $self->error_msg( no_view => $name );
    $self->debug(" - calling view for '$name'\n") if $DEBUG;
    return $method->($self, @args);
}




#-----------------------------------------------------------------------
# simple emitters
#-----------------------------------------------------------------------

sub view_line {
    my ($self, $line) = @_;
    my $file = $self->{ file } || '<unknown>';
    return "<#file $file line $line>";
}

sub view_integer {
    my ($self, $integer) = @_;
    return "<integer:$integer>";
}

sub view_regex {
    my ($self, $regex, $flags) = @_;
    return "<regex:/$regex/$flags>";
}

sub view_path {
    my ($self, $path) = @_;
    return "<path:$path>";
}


#-----------------------------------------------------------------------
# temp hacks to make things work for testing
#-----------------------------------------------------------------------

sub view_ident {
    my ($self, $ident) = @_;
    return $ident;
}

sub view_squote {
    my ($self, $text) = @_;
    return qq{'$text'};
}

sub view_dquote {
    my ($self, $text) = @_;
    return qq{"$text"};
}


#-----------------------------------------------------------------------
# these methods take sexpr args
#-----------------------------------------------------------------------


sub view_dotop {
    my ($self, $nodes) = @_;
    return '<DOT:' . join('.', map { $self->view_var_node(@$_) } @$nodes) . '>';
}

sub view_variable {
    my ($self, $nodes) = @_;
    return '<VAR:' . join('.', map { $self->view_var_node(@$_) } @$nodes) . '>';
}

#sub view_var_node {
#    my ($self, $name, $args) = @_;
#    $name = $self->view_expr($name);
#    $args = $args ? $self->view_args($args) : "";
#    return "$name$args";
#}

sub view_args {
    my ($self, $args) = @_;
    return '(' . join(', ', map { $self->view_expr($_) } @$args) . ')';
}

sub view_binary {
    my ($self, $left, $op, $right) = @_;
    return join(' ', $self->view_expr($left), $op, $self->view_expr($right));
}

sub view_include {
    my ($self, $paths, $params) = @_;
    return "<INCLUDE $paths $params>";
}

sub view_if {
    my ($self, $expr, $body) = @_;
    # TODO: resolve expr/body? - no I think not - make it very low-level ???
    return $self->emit_body("<IF $expr>", $body, '</IF>');
}

sub view_elsif {
    my ($self, $expr, $body) = @_;
    return $self->emit_content(["<ELSIF $expr>", $body, '</ELSIF>']);
}

sub view_else {
    my ($self, $body) = @_;
    return $self->emit_content(["<ELSE>", $body, '</ELSE>']);
}

sub view_paths {
    my ($self, $paths) = @_;
    return '<PATHS:' . join(', ', map { $self->view_expr($_) } @$paths) . '>';
}

sub DUD_view_path {
    my ($self, $path) = @_;
    return "<PATH:$path>";
}

sub view_params {
    my ($self, $params) = @_;
    return '<PARAMS:' . join(', ', map { $self->view_expr($_) } @$params) . '>';
}

sub view_param {
    my ($self, $name, $value) = @_;
    $name  = $self->view_expr($name);
    $value = $self->view_expr($value);
    return "<PARAM:$name=$value>";
}


1;

