package Template::TT3::Tokens;

use Template::TT3::Elements::Core;
use Template::TT3::Views;
use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Base',
    import    => 'class',
    vars      => 'AUTOLOAD',
    accessors => 'tokens',
    modules   => 'VIEWS_MODULE',
    constants => ':elements HASH ARRAY',
    constant  => {
        ELEMENTS => 'Template::TT3::Elements',
        TEXT     => 'text',
    },
    messages => {
        bad_method => "Invalid method '%s' called on %s at %s line %s",
    };

*init = \&init_tokens;


sub init_tokens {
    my ($self, $config) = @_;
    my $factory = $config->{ elements };
    
    if (! $factory || ! ref $factory || blessed $factory) {
        # these are the simple cases that we handle below: no factory (use
        # the default), custom factory name, or custom factory object
    }
    elsif (ref $factory eq HASH) {
        # e.g. elements => { elem1 => 'My::Element1' }
        # we can pass this onto the default factory
        $factory = undef;  
    }
    elsif (ref $factory eq ARRAY) {
        # e.g. elements => [ My::Elements => { elem1 => 'My::Element1' } ]
        # stuff the elements back into the config
        $config->{ elements } = $factory->[1];
        $factory = $factory->[0];
    }
    else {
        return $self->error_msg( invalid => elements => $factory );
    }
    
    # if we haven't got a factory name then use the default
    $factory ||= $self->ELEMENTS;

    # create factory object from the class name (unless it's already one)
    $factory   = $factory->new($config)
        unless ref $factory;
    
    $self->debug("elements factory: $factory") if DEBUG;
    
    $self->{ elements  } = $factory;
    $self->{ element   } = { };  #$self->{ elements }->constructors;
    $self->{ tokens    } = [ ];
    $self->{ config    } = $config;
    
    $self->text_type( $config->{ text_type } || TEXT );
    
    return $self;
}


sub text_type {
    my ($self, $type) = @_;
    my $elem = $self->token_element($type)
        || die "barf\n";

    $self->{ text_elem } 
        = $self->{ text_elems }->{ $type } 
      ||= $self->token_element($type)
      ||  return $self->error_msg( invalid => text_type => $type );
      
    $self->{ text_type } = $type;
}


sub finish {
    return $_[0];
}


# generate() is old, view() is new
sub generate {
    my ($self, $generator) = @_;
    return $generator->generate_tokens($self->{ tokens });
}


sub view {
    my ($self, $view) = @_;
    return $view->view_tokens($self->{ tokens });
}


# TODO: it would be better if we could subclass T::Type::List here so we can
# inherit all the list methods, first(), last(), size(), etc.  But alas, 
# T::Tokens isn't a list... it's a hash with a tokens => [ ] list ref.

sub first {
    $_[0]->{ tokens }->[0];
}


sub last {
    $_[0]->{ tokens }->[-1];
}


sub size {
    scalar @{ $_[0]->{ tokens } };
}


sub token_element {
    my ($self, $type) = @_;
    my ($elem, $class);

    $self->debug("token_element($type)") if DEBUG;

    $elem = $self->{ element }->{ $type };

    if ($elem) {
        # Good - we've got an existing constructor function for the element
    }
    elsif (defined $elem) {
        # If the element has a defined but false (0) entry then we've 
        # looked for it before and couldn't find it so we won't bother again
        return;
    }
    else {
        # Nothing cached - see if the factory can load a module for it.
        $elem = $self->{ element  }->{ $type } 
              = $self->{ elements }->constructor( $type )
             || return;
    }

    # NOTE: I'm a little suspicious here... we could be overdoing the 
    # caching via closure.  If we have two different T::Tokens objects then
    # the first could be defining methods that the second uses.  That's OK
    # until we have 2 or more concurrent T::Tokens objects with different 
    # configurations.  That said, unless anything in the configuration
    # significantly changes the behaviour of the element then it shouldn't
    # be a problem.  Once the element module is loaded, a constructor 
    # function should Just Work, regardless of which object calls it. 
        
    $self->debug("found $type => $elem") if DEBUG;
    
    return $elem;
}


sub token_method {
    my ($self, $name) = @_;
    my $type = $name;

    # Only generate XXX_token() methods for XXX tokens that we know about
    return unless ($type =~ s/_token$//);

    my $elem = $self->token_element($type) || return;

    # create closure that binds over $name to create op and push into tokens
    my $method = sub {
        my $this   = shift;
        my $tokens = $this->{ tokens };
        # This is the correct way to do it... but we need to handle missing
        # entries in $this->{ element } in case we have mutiple T::Tokens
        # objects in play at the same time - the first could define a method
        # for an element that doesn't have a constructor in the second.  So
        # until I've had a chance to think it over, we'll bind over the known
        # constructor.  It's probably best to require people to subclass anyway.
        # my $token  = $this->{ make_op }->{ $type }->(@_);
#        $elem = $this->{ element }->{ $type };
        $this->debug("creating $name element with arguments: ", join(', ', @_))
            if DEBUG;
        
        my $token = $elem->(@_);

        # add the NEXT link from the preceding token if there is one
        $tokens->[-1]->[NEXT] = $token
            if @$tokens;

        # push the token onto the end of the list
        push(@$tokens, $token);
        
        return $token;
    };

    # register closure as a method
    $self->class->method( $name => $method );

    return $method;
}


sub token {
    my ($self, $token) = @_;
    my $tokens = $self->{ tokens };

    # add the NEXT link from the preceding token if there is one
    $tokens->[-1]->[NEXT] = $token
        if @$tokens;

    # push the token onto the end of the list
    # NOTE: this causes Perl to segfault with a blown stack at cleanup with 
    # large lists (upwards of ~30k tokens).  
    # See http://rt.perl.org/rt3/Ticket/Display.html?id=70253
    push(@$tokens, $token);
        
    return $token;
}


sub text_token {
    my $self   = shift;

    $self->debug("creating $self->{ text_type } element with arguments: ", join(', ', @_))
        if DEBUG;

    my $tokens = $self->{ tokens };
    my $token  = $self->{ text_elem }->(@_);

    # add the NEXT link from the preceding token if there is one
    $tokens->[-1]->[NEXT] = $token
        if @$tokens;

    # push the token onto the end of the list
    push(@$tokens, $token);
        
    return $token;
}

sub text {
    shift->first->remaining_text;
}


sub tree {
    shift->first->parse(@_);
}


sub can {
    my ($self, $name, @args) = @_;
    my $target;

    return $self->SUPER::can($name)
        || $self->token_method($name)
        || $self->view_method($name, @args)
        || $self->generator_method($name);
}


sub AUTOLOAD {
    my ($self, @args) = @_;
    my ($name) = ($AUTOLOAD =~ /([^:]+)$/ );
    return if $name eq 'DESTROY';
    my $method;

    $self->debug("AUTOLOAD $name\n") if DEBUG;

    # give the can() method a chance to generate a component or delegate
    # method for us
    if ($method = $self->can($name, @args)) {
        return $method->($self, @args);
    }

    return $self->error_msg( bad_method => $name, ref $self, (caller())[1,2] );
}



#-----------------------------------------------------------------------
# old stuff needs cleaning up
#-----------------------------------------------------------------------

use Template::TT3::Generators;
use constant GENERATORS => 'Template::TT3::Generators';

# generator_method() is old, view_method() is new
sub generator_method {
    my ($self, $name) = @_;
    my $type = $name;
    my $gen;

    $self->debug("generator_method($name)") if DEBUG;

    if ($type =~ s/^generate_/tokens./) {       # tokens.HTML => Tokens::HTML
        $self->debug("token generator: $type") if DEBUG;
        $gen = GENERATORS->generator($type)
            || return $self->error_msg( invalid => generator => $name );
    }
    elsif ($gen = GENERATORS->generator('tokens.' . $name)) {
        $self->debug("got tokens generator: tokens.$name") if DEBUG;
        # OK, we've got a generator
    }
    else {
        return;
    }

    # create closure and register it as a method
    my $method = sub {
        shift->generate( $gen );
    };
    $self->class->method( $name => $method );

    return $method;
}

sub view_method {
    my ($self, $name, @args) = @_;
    my $type = $name;
    my $view;

    $self->debug("view_method($name)") if DEBUG;

    # map a view_XXX() method to a tokens.XXX string which the factory
    # which map to Template::View::Tokens::XXX
    return 
        unless $type =~ s/^view_/tokens./;

    # create closure and register it as a method
    my $method = sub {
        my $this = shift;
        my $view = VIEWS_MODULE->view($type, @_)
            || return $self->error_msg( invalid => view => $name );

        $self->debug(
            "token view: $type with args: ", 
            $self->dump_data(\@_)
        ) if DEBUG;

        $this->view( $view );
    };
    $self->class->method( $name => $method );

    return $method;
}

sub html {
    shift->view_HTML(@_);
}
        
sub sexpr {
    # FIXME
    shift->generate( GENERATORS->generator('debug') );
}


1;


__END__

=head1 SYNOPSIS

    use Template::TT3::Tokens;
    
    # create a token list
    my $tokens = Template::TT3::Tokens->new;
    
    # push tokens onto the list, specifying token text and position.
    # e.g. to tokenise: "Hello [% name %]"
    $tokens->text_token('Hello ', 0);
    $tokens->tag_start_token('[%', 6);
    $tokens->whitespace_token(' ', 8);
    $tokens->word_token('name', 9);
    $tokens->whitespace_token(' ', 13);
    $tokens->tag_end_token('%]', 14);

=head1 DESCRIPTION

This module implements an object which is used to construct a list of 
tokens scanned from the source text of a template.  

Each token is represented as a L<Template::TT3::Element> object (or subclass
thereof).  These are loaded on demand by the L<Template::TT3::Elements>
factory module.

The token methods are also created on demand. For example, the C<text_token()>
method doesn't exist until you first call it. At this point, the L<AUTOLOAD>
method will be invoked which will in turn call the L<token_method()> method.
This then asks the L<Template::TT3::Elements> factory to load whatever 
module corresponds to the C<text> element type.  If it successfully loads 
a module then the L<token_method()> method constructs a new C<text_token()>
method that delegates to the element class.  From that point on, the 
C<text_token()> method is defined and can be called directly.

The end result is that you can call any C<xxx_token()> method and have it 
automatically load the element corresponding to the C<xxx> prefix.  This
makes it possible to define any number of custom element types without 
having to worry about loading them all in advance on the off-chance that
they may be used.

=head1 CONFIGURATION OPTIONS

=head2 elements

The C<elements> option can be used to define the elements that the
C<Template::TT3::Tokens> object should recognise.  

The default value is C<Template::TT3::Elements>.  If you want to use a
different element factory module then you can specify it by name:

    my $tokens = Template::TT3::Tokens->new(
        elements => 'My::Elements',
    );

Or you can provide a reference to an element factory object:

    my $tokens = Template::TT3::Tokens->new(
        elements => My::Elements->new(),
    );

If you want to use the default C<Template::TT3::Elements> factory module 
but with some additional elements of your own then you can specify them as
a hash reference.

    my $tokens = Template::TT3::Tokens->new(
        elements => {
            foo => 'My::Element::Foo',
            bar => 'My::Element::Bar',
        },
    );

This is short-hand convention for the following code:

    my $tokens = Template::TT3::Tokens->new(
        elements => Template::TT3::Elements->new(
            elements => {
                foo => 'My::Element::Foo',
                bar => 'My::Element::Bar',
            },
        ),
    );

If you want to specify a custom element module I<and> some custom elements
then provide them as items in an array reference, like so:

    my $tokens = Template::TT3::Tokens->new(
        elements => [
            'My::Elements' => {
                foo => 'My::Element::Foo',
                bar => 'My::Element::Bar',
            },
        },
    );

This has the same effect as the following more explicit code:

    my $tokens = Template::TT3::Tokens->new(
        elements => My::Elements->new(
            elements => {
                foo => 'My::Element::Foo',
                bar => 'My::Element::Bar',
            },
        ),
    );

=head1 METHODS

=head2 new()

=head2 generate()

=head2 first()

=head2 last()

=head2 can()

=head2 token_method()

=head2 AUTOLOAD

