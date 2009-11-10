package Template::TT3::Generator::Debug;

use Template::TT3::Class
    version  => 2.7,
    debug    => 0,
    base     => 'Template::TT3::Generator';

sub generate_tokens {
    my ($self, $tokens) = @_;
    return join(
        "\n",
        map { $_->generate($self) }
        @$tokens
    );
}

sub generate_ident {
    my ($self, $ident) = @_;
    return "<ident:$ident>";
}

sub generate_keyword {
    my ($self, $keyword) = @_;
    return "<keyword:$keyword>";
}

sub generate_number {
    my ($self, $number) = @_;
    return "<number:$number>";
}

sub generate_squote {
    my ($self, $text) = @_;
    return "<squote:'$text'>";
}

sub generate_dquote {
    my ($self, $text) = @_;
    return qq{<dquote:"$text">};
}

sub generate_text {
    my ($self, $text) = @_;
    $text =~ s/\n/\\n/g;
    return "<text:$text>";
}

sub generate_whitespace {
    my ($self, $text) = @_;
    $text =~ s/\n/\\n/g;
    return "<whitespace:$text>";
}

sub generate_tag_start {
    my ($self, $text) = @_;
    return "<tag_start:$text>";
}

sub generate_tag_end {
    my ($self, $text) = @_;
    return "<tag_end:$text>";
}

sub generate_word {
    my ($self, $text) = @_;
    return "<word:$text>";
}

sub generate_variable {
    my ($self, $var) = @_;
#    return '<var:' . $self->generate($var) . '>';
    return '<var:' . $var . '>';
}

sub generate_varnode {
    my ($self, $name, $args) = @_;
    $args = $args
        ? '(' . join(', ', map { $self->generate($_) } @$args) . ')'
        : '';
    return $name . $args;
}

sub generate_binop {
    my ($self, $op, $lhs, $rhs) = @_;

    # Bugger - there's a problem using elements for both tokens and 
    # expresssions.  When inspecting a token list, we want a dotop to 
    # render as '.', but when inspecting an expression tree, we want a 
    # dotop to render as 'lhs.rhs'.  I guess we have to use different 
    # generators for token and expression views.

    return "<binop:$op>";

    return join(
        $op,
        map { $self->generate($_) }
        $lhs, $rhs
    );
}

sub generate_prefix {
    my ($self, $op, $rhs) = @_;
    return "<prefix:$op>";
}

sub generate_punctuation {
    my ($self, $punc) = @_;
    return "<punctuation:$punc>";
}

sub generate_postfix {
    my ($self, $op, $lhs) = @_;
    return "<postfix:$op>";
}

sub generate_exprs {
    my ($self, $exprs) = @_;
    return join(
        "\n",
        map { $self->generate($_) }
        @$exprs
    );
}

sub generate_namespace {
    my ($self, $name, $space) = @_;
    return "<namespace:$name:$space>";
}

1;
__END__
*generate_dot_ident = \&generate_ident;

sub generate_template {
    my ($self, $body) = @_;
    return $self->generate_body( template => $body );
}

sub generate_body {
    my ($self, $name, $list) = @_;
    $self->body($name, map { $self->generate($_) } @$list);
}

sub body {
    my ($self, $name, @items) = @_;
    my $body = '';
    foreach my $item (@items) {
        $item =~ s/\n/\n  /g;
        $body .= "  $item\n";
    }
    return "<$name:\n$body>";
}


#-----------------------------------------------------------------------
# simple tokens: number, path, text, comment, etc.
#-----------------------------------------------------------------------

sub generate_value {
    my ($self, $value) = @_;
    return $self->generate($value);
}

sub generate_line {
    my ($self, $line) = @_;
    return "<line:$line>";
}

sub generate_comment {
    my ($self, $comment) = @_;
    return "<comment:$comment>";
}

sub generate_integer {
    my ($self, $value) = @_;
    return "<integer:$value>";
}

sub generate_number {
    my ($self, $value) = @_;
    return "<number:$value>";
}

sub generate_data {
    my ($self, $item) = @_;
    $item = $self->generate($item);
    $item =~ s/\n/\n  /g;
    return "<data:\n  $item\n>";
}

sub generate_path {
    my ($self, $path) = @_;
    return "<path:$path>";
}

sub generate_paths {
    my ($self, $paths) = @_;
    return $self->generate_body( paths => $paths );
}

sub generate_filename {
    my ($self, $file) = @_;
    return "<filename:$file>";
}

sub generate_text {
    my ($self, $text) = @_;
    my $textref = ref $text eq 'SCALAR' ? $text : \$text;
    $$textref =~ s/\n/\\n/g;
    return "<text:$$textref>";
}

sub generate_squote {
    my ($self, $value) = @_;
    return "<squote:$value>";
}

sub generate_test {
    my ($self, $item) = @_;
    return "<test:$item>";
}

sub generate_gen_debug {        # TODO: is this needed?
    my ($self, $info) = @_;
    $info->{ src } =~ s/\n/\\n/g;
    $info->{ src } =~ s/\s+/ /g;
    return "<debug:$info->{ type } at line $info->{ line }: $info->{ src }>";
}


#-----------------------------------------------------------------------
# compound elements: 
#   hash                    { a = b, c = d }
#   list                    [ a b c ]
#   qwlist                  qw( foo bar baz )
#   parens                  (a, b, c)
#   range                   1..10
#   tuple                   a => 10
#   double quoted string    "foo $bar baz"
#-----------------------------------------------------------------------

sub generate_hash {
    my ($self, $list) = @_;
    return $self->generate_body( hash => $list );
}

sub generate_list {
    my ($self, $list) = @_;
    return $self->generate_body( list => $list );
}

sub generate_qwlist {
    my ($self, $left, $list, $right) = @_;
    for ($list) {
        s/^\s+//;
        s/\s+$//;
        s/\s+/ /g;
    }
    return "<qwlist($left, $right):$list>";
}

sub generate_parens {
    my ($self, $term) = @_;
    $term = $self->generate($term);
    $term =~ s/\n/\n  /g;
    return "<parens:\n  $term\n>";
}

sub generate_range {
    my ($self, $from, $to) = @_;
    $from  = $self->generate($from);
    $to    = $self->generate($to);
    foreach ($from, $to) {
        s/\n/\n  /g;
    }
    return "<range:\n  $from\n  $to\n>";
}

sub generate_tuple {
    my ($self, $name, $value) = @_;
    $value = $self->generate($value);
    $value =~ s/\n/\n  /g;

    if (ref $name) {
        $name = $self->generate($name);
        $name =~ s/\n/\n  /g;
        return "<tuple:\n  $name\n  $value\n>";
    }
    else {
        return "<$name:\n  $value\n>";
    }
}

sub generate_dquote {
    my ($self, $list) = @_;
    my $items = '';
    my $out;

    if (ref $list) {
        foreach my $item (@$list) {
            if (ref $item) {
                $out = $self->generate($item);
                $out =~ s/\n/\n  /g;
            }
            else {
                $out = "<text:$item>";
            }
            $items .= "  $out\n";
        }
    }
    else {
        $items = "  <text:$list>\n";
    }

    return "<dquote:\n$items>";
}




#-----------------------------------------------------------------------
# variables
#-----------------------------------------------------------------------

sub generate_variable {
    my ($self, $nodes) = @_;
    my ($nodeout, $argout);
    my $debug = $self->{ DEBUG };
    my $out = '';

    $self->debug("variable($nodes - ", scalar(@$nodes), " item(s))\n") if $debug;

    foreach my $node (@$nodes) {
        my ($name, $args) = @$node;
        $self->debug(" - node: $name\n") if $debug;

        $name = $self->generate($name);
        $args = $self->generate_variable_args($args);
        $name =~ s/\n/\n    /g;
        $args =~ s/\n/\n    /g;
        $args = "    $args\n" if $args;
        $out .= "  <node:\n    $name\n$args  >\n";
    }

    return "<variable:\n$out>";
}

sub generate_ident {
    my ($self, $name, $args) = @_;
    if ($args && @$args) {
        my $argtext = '';
        foreach my $arg (@$args) {
            $arg = $self->generate($arg);
            $arg =~ s/\n/\n    /g;
            $argtext .= "    $arg\n";
        }
        return "<ident:\n  <name:$name>\n  <args:\n$argtext  >\n>";
    }
    else {
        return "<ident:$name>";
    }
}

sub generate_variable_args {
    my ($self, $args) = @_;
    my $argout;

    if ($args) {
        my $argtext = '';
        foreach my $arg (@$args) {
            $argout = $self->generate($arg);
            $argout =~ s/\n/\n  /g;
            $argtext .= "  $argout\n";
        };
        return "<args:\n$argtext>";
    }
    else {
        return '';
    }
}

sub generate_args {
    my ($self, $args) = @_;

    if ($args && @$args) {
        my $argtext = '';
        foreach my $arg (@$args) {
            my $text = $self->generate($arg);
            $text =~ s/\n/\n  /g;
            $argtext .= "  $text\n";
        }
        $args = "<args:\n$argtext>\n";
    }
    else {
        $args = "<no args>\n";
    }

    return $args;
}

sub generate_param {
    my ($self, $name, $value) = @_;
    $value = $self->generate($value);
    $value =~ s/\n/\n  /g;

    if (ref $name) {
        $name = $self->generate($name);
        $name =~ s/\n/\n  /g;
        return "<param:\n  $name\n  $value\n>";
    }
    else {
        return "<$name:\n  $value\n>";
    }
}

sub generate_params {
    my ($self, $params) = @_;
    my $args = "";

    if ($params && @$params) {
        my $ptext = '';
        foreach my $param (@$params) {
            my $text = $self->generate($param);
            $text =~ s/\n/\n    /g;
            $ptext .= "    $text\n";
        }
        $args = "<args:\n$ptext  >\n";
    }
    else {
        $args = "<no args>\n";
    }
    return $args;
}


sub generate_expand {
    my $self = shift;
    my $item = $self->generate_variable(shift);
    $item =~ s/\n/\n  /g;
    return "<expand:\n  $item\n>";
}

sub generate_root {
    my $self = shift;
    my $item = $self->generate(shift);
    $item =~ s/\n/\n  /g;
    return "<root:\n  $item\n>";
}

#-----------------------------------------------------------------------
# expressions
#-----------------------------------------------------------------------

sub generate_prefix {
    my ($self, $op, $term) = @_;
    $term = $self->generate($term);
    $term =~ s/\n/\n  /g;
    return "<prefix:\n  <op:$op>\n  $term\n>";
}

sub generate_postfix {
    my ($self, $op, $term) = @_;
    $term = $self->generate($term);
    $term =~ s/\n/\n  /g;
    return "<postfix:\n  <op:$op>\n  $term\n>";
}

sub generate_unary {
    my ($self, $op, $term) = @_;
    $term = $self->generate($term);
    $term =~ s/\n/\n  /g;
    return "<unary:\n  <op:$op>\n  $term\n>";
}

sub generate_binary {
    my ($self, $left, $op, $right) = @_;
    local $" = ', ';
    my $items = '';
    my $out;
    
    $left  = $self->generate($left);
    $right = $self->generate($right);

    for ($left, $right) {
        s/\n/\n  /g;
    }
    return "<binary:\n  $left\n  <op:$op>\n  $right\n>";
}

sub OLD_generate_binary {
    my ($self, $list, @others) = @_;
    local $" = ', ';
    $self->debug("binary(", join(', ', @$list), ")\n") if $DEBUG;
    my $items = '';
    my $out;
    
    $self->dump($list);

    foreach my $item (@$list) {
        $out = ref $item ? $self->generate($item) : "<op:$item>";
        $out =~ s/\n/\n  /g;
        $items .= "  $out\n";
    }
    return "<binary:\n$items>";
}

sub dump {
    my $self = shift;
    use Data::Dumper;
    print Dumper(shift);
}

sub OLD_generate_tertiary {
    my ($self, $expr, $true, $false) = @_;

    $expr  = $self->generate($expr);
    $true  = $self->generate($true);
    $false = $self->generate($false);
    foreach ($expr, $true, $false) {
        s/\n/\n    /g;
    }
    return "<tertiary:\n  <expression:\n    $expr\n  >\n  <true:\n    $true\n  >\n  <false:\n    $false\n  >\n>";
}

sub generate_ternary {
    my ($self, $test, $then, $else) = @_;

    $test = $self->generate($test);
    $then = $self->generate($then);
    $else = $self->generate($else);
    foreach ($test, $then, $else) {
        s/\n/\n    /g;
    }
    return "<ternary:\n  <test:\n    $test\n  >\n  <then:\n    $then\n  >\n  <else:\n    $else\n  >\n>";
}


sub generate_dump {
    my ($self, $list) = @_;
    my ($out, $items);
    
    foreach my $item (@$list) {
        next unless defined $item;
        $out = $self->generate($item) || return $self->error("generate_dump() failed");
        $out =~ s/\n/\n  /g;
        $items .= "  $out\n";
    }
    return "[\n$items]";
}

#-----------------------------------------------------------------------
# prime directives
#-----------------------------------------------------------------------

sub generate_get {
    my ($self, $item) = @_;
    $item = $self->generate($item);
    $item =~ s/\n/\n  /g;
    return "<get:\n  $item\n>";
}

sub generate_set {
    my ($self, $list) = @_;
    return $self->body( set => map { $self->generate_assign(@$_) } @$list );
}

sub generate_assign {
    my ($self, $var, $val) = @_;
    return $self->body( assign => map { $self->generate($_) } $var, $val );
}

sub generate_block {
    my ($self, @list) = @_;
    return $self->generate_body( block => @list );
}

sub generate_include {
    my ($self, $paths, $args) = @_;
    $paths = $self->generate_paths($paths);
    $paths =~ s/\n/\n  /g;
    $args = $self->generate_params($args);
    return "<include:\n  $paths\n  $args>";
}

sub generate_process {
    my ($self, $paths, $args) = @_;
    $paths = $self->generate_paths($paths);
    $paths =~ s/\n/\n  /g;
    $args = $self->generate_params($args);
    return "<process:\n  $paths\n  $args>";
}

sub generate_wrapper {
    my ($self, $paths, $args, $content) = @_;
    $paths = $self->generate_paths($paths);
    $paths =~ s/\n/\n  /g;
    $args = $self->generate_params($args);
    $content = $self->generate($content);
    $content =~ s/\n/\n  /g;
    return "<wrapper:\n  $paths\n  $args  $content\n>";
}

sub generate_for {
    my ($self, $var, $item) = @_;
    $var  = $self->generate($var);
    $var  =~ s/\n/\n  /g;
    $item = $self->generate($item);
    $item =~ s/\n/\n  /g;
    return "<for:\n  <data:$var>\n  $item\n>";
}

# TODO: generate_while()

# TODO: generate_if()

# TODO: generate_switch()

sub generate_case {
    my ($self, $expr, $block) = @_;
    $self->debug("case()\n") if $DEBUG;
    $expr = $expr ? $self->generate($expr) : "<default case>";
    $expr =~ s/\n/\n  /g;
    $block = $self->generate($block);
    $block =~ s/\n/\n  /g;
    return "<case:\n  $expr\n  $block\n>";
}

sub generate_macro {
    my ($self, $ident, $args, $content) = @_;
    $ident = $self->generate($ident);
    $args  = $self->generate_args($args);
    $args  =~ s/\n/\n  /g;
    $content = $self->generate($content);
    $content =~ s/\n/\n  /g;
    return "<macro:\n  $ident\n  $args$content\n>";
}

sub generate_end {
    my ($self, $list) = @_;
    my $items = '';
    my $out;

    foreach my $item (@$list) {
        $out = $self->generate($item);
        $out =~ s/\n/\n  /g;
        $items .= "  $out\n";
    }
    return "<end>";
}


#-----------------------------------------------------------------------
# old code used in development
#-----------------------------------------------------------------------

sub _default {
    my ($self, $name, @items) = @_;
    my ($out, $items);

    foreach my $item (@items) {
        next unless defined $item;
        $out = $self->generate($item) || return $self->error("_default generate failed");
        $out =~ s/\n/\n  /g;
        $items .= "  $out\n";
    }
    if (ref $name) {
        $name = $self->generate($name);
        $name =~ s/\n/\n  /g;
        return "[\n  $name\n$items]";
    }
    return "<$name:\n$items>";
}


#------------------------------------------------------------------------
# define debug generator for Template::Directive::If
#------------------------------------------------------------------------

package Template::Directive::If;


    
1;

__END__

=head1 NAME

Template::TT3::Generator::Debug - debugging code generator

=head1 SYNOPSIS

    Template::TT3::Generator::Debug;

    # TODO

=head1 DESCRIPTION

# TODO

=head1 METHODS

=head2 new()

# TODO

=head2 generate($item)

TODO

=head1 AUTHOR

Andy Wardley  E<lt>abw@wardley.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:

