package Template::TT3::View::Tree::HTML;

use Template::TT3::Class
    version   => 2.7,
    debug     => 0,
    base      => 'Template::TT3::View::Tree Template::TT3::View::HTML',
    import    => 'class',
    codec     => 'html',
    constants => ':elements',
    constant  => {
        ATTR    => '%s="%s"',
        ELEMENT => "<%s%s>%s</%s>",
    },
    alias => {
        view_html => \&view_text,
        view_dot  => \&view_binary,
    };

our $TRIM_TEXT = 128;

sub html_text {
    my ($self, $text) = @_;
    $text =~ s/\n/<br>/g;
    $text =~ s/\t/ /g;
    return $text;
}


sub element {
    my ($self, $type, $elem, @content) = @_;
      
    $self->div(
        "$type element",
        $self->div(
            head => 
            $self->span( "info type" => $type ),
            $self->span( "info posn" => '@' . $elem->[POS] ),
            $self->span( source => $self->tidy_text( encode($elem->source) ) ),
        ),
        @content
            ? $self->div( body => @content )
            : ()
    );
}


sub view_block {
    my ($self, $block) = @_;
    $self->div( 
        block => join(
            "\n", 
            map { $_->view($self) }
            $block->expressions
        )
    )
}

sub view_text {
    my ($self, $elem) = @_;
    $self->div(
        "text element",
        $self->div(
            head => 
            $self->span( "info type" => 'text' ),
            $self->span( "info posn" => '@' . $elem->[POS] ),
            $self->span( source => $self->tidy_text( encode($elem->[TOKEN]) ) ),
#            $self->span( source => '&laquo;' . $self->tidy_text( $elem->[TOKEN] ) . '&raquo;'),
        ),
    );
}

sub view_squote {
    my ($self, $elem) = @_;
    $self->element( 
        'squote string element' => $elem,
    );
}

sub view_html_element {
    my ($self, $elem) = @_;
    $self->element( 
        "html keyword element", $elem,
        $elem->[BLOCK]->view($self)
    )
}


sub view_dquote {
    my ($self, $elem) = @_;
    my $block = $elem->[BLOCK];
    my ($type, $text);
    
    if ($block) {
        $type = 'dquote string';
        $text = $block->view($self);
    }
    else {
        $type = 'string';
        $text = $self->div( 
            'text element' => 
            $self->div(
                head => 
                $self->span( "info type" => 'text' ),
                $self->span( "info posn" => '@' . $elem->[POS] ),
                $self->span( source => $self->tidy_text( encode($elem->[EXPR]) ) ),
            ),
        );
    }
    
    $self->element( 
        "$type element" => $elem,
        $text,
    );
}


sub view_binary {
    my ($self, $elem) = @_;
    $self->element( 
        'binary expr' => $elem,
        $self->div( 'lhs '      => $elem->[LHS]->view($self) ),
        $self->div( 'operator element' => $elem->[TOKEN] ),
        $self->div( 'rhs '      => $elem->[RHS]->view($self) ),
    );
}

sub view_prefix {
    my ($self, $elem) = @_;
    $self->element( 
        'prefix unary expr' => $elem,
        $self->div( 'operator element' => $elem->[TOKEN] ),
        $self->div( 'rhs '      => $elem->[RHS]->view($self) ),
    );
}

sub view_postfix {
    my ($self, $elem) = @_;
    $self->element( 
        'postfix unary expr' => $elem,
        $self->div( 'lhs '      => $elem->[LHS]->view($self) ),
        $self->div( 'operator element' => $elem->[TOKEN] ),
    );
}

sub view_pair {
    my ($self, $elem) = @_;
    my $lhs = $elem->[LHS]->view($self);
    for ($lhs) {
        s/(<div class=")variable/${1}word/;
        s/(<span class="info type">)variable/${1}word/g;
    }
    $self->element( 
        'binary pair expr' => $elem,
        $self->div( 'lhs '      => $lhs ),
        $self->div( 'operator element' => $elem->[TOKEN] ),
        $self->div( 'rhs '      => $elem->[RHS]->view($self) ),
    );
}

sub view_parens {
    my ($self, $elem) = @_;
    $self->element( 
        'parens expr' => $elem,
        $self->div( 'operator element' => '(' ),
        $self->div( 'lhs'              => $elem->[EXPR]->view($self) ),
        $self->div( 'operator element' => ')' ),
    );
}

sub view_list {
    my ($self, $elem) = @_;
    $self->element( 
        'list expr' => $elem,
        $self->div( 'operator element' => '[' ),
        $self->div( 'lhs'              => $elem->[EXPR]->view($self) ),
        $self->div( 'operator element' => ']' ),
    );
}

sub view_hash {
    my ($self, $elem) = @_;
    $self->element( 
        'hash expr' => $elem,
        $self->div( 'operator element' => '{' ),
        $self->div( 'lhs'              => $elem->[EXPR]->view($self) ),
        $self->div( 'operator element' => '}' ),
    );
}

sub view_filename {
    my ($self, $elem) = @_;
    $self->element( 
        "filename element" => $elem
    );
}

sub view_if {
    my ($self, $elem) = @_;
    $self->element( 
        'if keyword' => $elem,
        $self->branch( Test => $elem->[EXPR]->view($self) ),
        $self->branch( True => $elem->[BLOCK]->view($self) ),
        $elem->[ELSE]
            ? $self->branch( Else => $elem->[ELSE]->view($self) )
            : ()
    );
}

sub view_for {
    my ($self, $elem) = @_;
    $self->element( 
        'for keyword' => $elem,
        $elem->[ARGS]
            ? $self->branch( Item => $elem->[ARGS]->view($self) )
            : (),
        $self->branch( List => $elem->[EXPR]->view($self) ),
        $self->branch( Then => $elem->[BLOCK]->view($self) ),
        $elem->[ELSE]
            ? $self->branch( Else => $elem->[ELSE]->view($self) )
            : ()
    );
}

sub view_with {
    my ($self, $elem) = @_;
    $self->element( 
        'with keyword' => $elem,
        $self->branch( Data  => $elem->[ARGS]->view($self) ),
        $self->branch( Block => $elem->[BLOCK]->view($self) ),
    );
}

sub view_just {
    my ($self, $elem) = @_;
    $self->element( 
        'just keyword' => $elem,
        $self->branch( Data  => $elem->[ARGS]->view($self) ),
        $self->branch( Block => $elem->[BLOCK]->view($self) ),
    );
}

sub view_fill {
    my ($self, $elem) = @_;
    $self->element( 
        'fill keyword' => $elem,
        $self->branch( Template => $elem->[EXPR]->view($self) ),
    );
}

sub view_blockdef {
    my ($self, $elem) = @_;
    $self->element( 
        'block keyword' => $elem,
        # TODO: args
        $elem->[EXPR]
            ? $self->branch( Name  => $elem->[EXPR]->view($self) )
            : (),
        $self->branch( Block => $elem->[BLOCK]->view($self) ),
    );
}

sub view_sub {
    my ($self, $elem) = @_;
    $self->element( 
        'sub keyword' => $elem,
        # TODO: args
        $elem->[EXPR]
            ? $self->branch( Name  => $elem->[EXPR]->view($self) )
            : (),
        $self->branch( Block => $elem->[BLOCK]->view($self) ),
    );
}

sub view_apply {
    my ($self, $elem) = @_;
    $self->element( 
        'sub keyword' => $elem,
        $self->branch( Call => $elem->[EXPR]->view($self) ),
        $elem->[ARGS]
            ? $self->branch( Args  => $elem->[ARGS]->view($self) )
            : (),
    );
}

sub view_slot {
    my ($self, $elem) = @_;
    $self->element( 
        'slot keyword' => $elem,
        $self->branch( Name  => $elem->[EXPR]->view($self) ),
        $self->branch( Block => $elem->[BLOCK]->view($self) ),
    );
}


sub view_into {
    my ($self, $elem) = @_;
    $self->element( 
        'into keyword' => $elem,
        $self->branch( Template => $elem->[EXPR]->view($self) ),
        $self->branch( Block    => $elem->[BLOCK]->view($self) ),
    );
}

sub view_raw {
    my ($self, $elem) = @_;
    $self->element( 
        'raw keyword' => $elem,
        $elem->[BLOCK]->view($self) 
    );
}

sub OLD_view_html {
    my ($self, $elem) = @_;
    $self->element( 
        'html keyword' => $elem,
        $elem->[TOKEN] 
    );
}

sub view_is {
    my ($self, $elem) = @_;
    $self->element( 
        'is keyword' => $elem,
        $self->div( 'lhs ' => $elem->[LHS]->view($self) ),
        $self->div( 'operator element' => $elem->[TOKEN] ),
        $self->div( 'rhs ' => $elem->[RHS]->view($self) ),
    );
}


sub view_element {
    my ($self, $elem) = @_;
    $self->div( 
        element => $elem
    );
}


class->methods(
    map {
        my $type = $_;              # lexical copy for closure
        "view_$type" => sub {
            $_[0]->span( "$type element", $_[0]->tidy_text( $_[1]->[TOKEN], $TRIM_TEXT ) )
        }
    }
    qw(
        comment padding terminator
    )
);

class->methods(
    map {
        my $type = $_;              # lexical copy for closure
        "view_$type" => sub {
            $_[0]->element( "$type element", $_[1] )
        }
    }
    qw( keyword number variable word )
);

    
1;

__END__
our $TRIM_TEXT = 64;
our $AUTOLOAD;




class->methods(
    map {
        my $type = $_;              # lexical copy for closure
        "view_$type" => sub {
            $_[0]->span( $type, $_[1]->[TOKEN] )
        }
    }
    qw(
        text comment padding html element terminator string
        literal word keyword number filename unary binary prefix
        postfix
    )
);


sub view_whitespace {
    my ($self, $elem) = @_;
    my $text = $elem->[TOKEN];
    $text =~ s/\n/ \n<span class="nl"><\/span>/g;
    $self->span( whitespace => $text );
}

sub view_squote {
    my ($self, $elem) = @_;
    $self->span( squote => "'", $elem->[TOKEN], "'" );
}

sub view_dquote {
    my ($self, $elem) = @_;
    $self->span( dquote => '"', $elem->[TOKEN], '"' );
}

sub view_tag_start {
    my ($self, $elem) = @_;
    return '<span class="tag">'
        . $self->span( tag_start => $elem->[TOKEN] );
}

sub view_tag_end {
    my ($self, $elem) = @_;
    return $self->span( tag_end => $elem->[TOKEN] )
        . '</span>';
}

sub view_eof {
    my ($self, $elem) = @_;
    return $self->span( eof => '--EOF--' );
}
