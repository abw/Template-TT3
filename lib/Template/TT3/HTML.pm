package Template::TT3::HTML;

#use Template::TT3;
use Template::TT3::Type::Text;
use Template::TT3::Element::Text;
use Template::TT3::Element::Command::Raw;
use Template::TT3::Class 
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    utils     => 'self_params',
    codec     => 'html',
    words     => 'METHODS',
    constants => 'BLANK :elements',
    constant  => {
        TEMPLATE    => 'Template::TT3::Template',
        ELEMENT     => 'Template::TT3::Element',
        BLOCK_ELEM  => 'Template::TT3::Element::Block',
        TEXT_ELEM   => 'Template::TT3::Element::Text',
        HTML_ELEM   => 'Template::TT3::Element::Html',
        RAW_ELEM    => 'Template::TT3::Element::Command::Raw',
        TEXT_TYPE   => 'Template::TT3::Type::Text',
    };


# Add an html() method to the template module.  This calls the html() on 
# the expression block.

class(TEMPLATE)->methods(
    html => sub {
        my ($self, $params) = self_params(@_);
        my $context = $self->context( data => $params );
        $self->debug("fetching html from expressions") if DEBUG;
        return $self->block->html($context);
    },
);


# Define an html() method for the block element that calls the html()
# method of each contained expression.  This is equivalent to the text()
# method, except that we're calling the html() method on each element 
# instead of text().

class(BLOCK_ELEM)->methods(
    html => sub {
        join(
            BLANK,
            grep { defined }
            map { $_->html($_[1]) } 
            @{ $_[0]->[EXPR] } 
        );
    },
);


# Alias the html() method for the raw block element to the regular text() 
# method so that raw blocks always bypass any further HTML encoding.

class(RAW_ELEM)->alias(
    html => 'text',
#    html => sub {
#        my ($self, $context) = @_;
#        $self->debug("called html() method on raw element");
#        my $text = $self->text($context);
#        $self->debug("html() block: $text");
#        return $text;
#    },
);


# Add a default html() method to the Template::TT3::Element base class
# that simply HTML encodes the value returned from text()

class(ELEMENT)->methods(
    html => sub {
        encode( $_[SELF]->text($_[CONTEXT]) );
    },
);


# Define the HTML subclass of the text element with an html() method that
# simply returns its own text without further HTML encoding.  This replaces
# the default html() method we added to the base class above.

class(HTML_ELEM)->base(TEXT_ELEM)->methods(
    html => sub {
        $_[SELF]->text( $_[CONTEXT] );
    },
    view => sub {
        $_[CONTEXT]->view_html($_[SELF]);
    },
);



# Add the .html() text virtual method

class(TEXT_TYPE)->var(METHODS)->{ html } = sub {
    my $text = shift;
    encode ref $text ? $$text : $text;
};


1;
