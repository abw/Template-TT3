package Template::TT3::Class::Element;

use Carp;
use Template::TT3::Class
    version    => 0.01,
    debug      => 0,
    uber       => 'Template::TT3::Class',
    modules    => 'ELEMENT_MODULE ELEMENT_ROLE_MODULE',
    constants  => 'ARRAY HASH CODE DELIMITER PKG DOT BLANK',
    utils      => 'camel_case',
    hooks      => {
        type       => \&type,
        roles      => \&roles,
        parse_expr => \&parse_expr,
    },
    constant   => {
        BASE_OP => 'Template::TT3::Element::Operator',
    };


our $DEBUG_OPS = 0;

# We have to do these after the above so that class() is property defined.

CLASS->export_before( 
    sub {
        # Create a Template::TT3::Class::Element metaclass object as a wrapper
        # around the target class and then call its element() method to 
        # prepare the class as an element subclass
        my ($class, $target) = @_;
        return if $target eq 'Badger::Class';
        class($target, $class)
            ->constants(':elements');
    }
);

CLASS->export_after( 
    sub {
        my ($class, $target) = @_;
        return if $target eq 'Badger::Class';
        class($target, $class)
            ->type
            ->base( $class->ELEMENT_MODULE );
    },
);


sub type {
    my ($self, $type) = @_;

    # We may have been called explicitly with a custom 'type => XXX' hook.
    # In which case, the implicit type() called by "after export" action will
    # create a duplicate.  So we return silently if a type() method is 
    # already defined.  Otherwise we create it as a constant subroutine.
    return $self
        if $self->code_ref('type');
    
    unless ($type) {
        $type = $self->{ name };
        $type = $1 if $type =~ /Element::(.*)$/;
        $type = lc $type;
        $type =~ s/\W+/_/g;
    }

    $self->debug("setting type for $self to $type") if DEBUG;
    
    $self->method( type => sub() { $type } );
    
    return $self;
}


sub roles {
    my ($self, $roles) = @_;
    my $base = $self->ELEMENT_ROLE_MODULE;

    $roles = [ split(DELIMITER, $roles) ]
        unless ref $roles eq ARRAY;

    $self->mixin( 
        map { 
            join(
                PKG, $base, map { camel_case($_) } split(/\./, $_)
            ) 
        } 
        @$roles 
    );
}

sub type_role {
    shift->roles( join(DOT, @_ ) );
}

sub parse_expr {
    shift->type_role( expr => @_ );
}

sub generate_elements {
    my $self = shift;
    my $spec = shift;
    my $args = @_ == 1 && ref $_[0] ? shift : [ @_ ];

    # methods gives us a list of method names that we want to alias to
    my $methods = $spec->{ methods } || 'value';
    $methods = [ split(DELIMITER, $methods) ]
        unless ref $methods eq ARRAY;

    $args = 
        ref $args eq ARRAY ? [ @$args ]     # a copy we can mutate
      : ref $args eq HASH  ? [ %$args ]     # flatten hash to list
      : die "Invalid arguments provided to generate_ops() : $args";

    while (@$args) {
        # First item is name, then any mixin/base classes, followed by a
        # CODE reference which should be installed as the value() method,
        # with an alias of values() pointing at the same subroutine.
        my ($name, @bases, $base, $code);
        $name = shift @$args;
        $name = $self->{ name }.PKG.camel_case($name);
        
        # TODO: change these bases to mixin roles
        while (@$args && ! ref $args->[0]) {
            $base = shift @$args;
            push(
                @bases,
                $base =~ /::/
                    ? $base
                    : BASE_OP.PKG.camel_case($base)
            );
        }

        push(@bases, $self->{ name });
        
        die "No subroutine specified for $name in generate_ops()"
            unless @$args && ($code = shift @$args);

        die "Invalid subroutine specified for $name in generate_ops(); $code"
            unless ref $code eq CODE;

        if ($DEBUG_OPS) {
            # generate wrapper that calls debug_ops() before the real sub
            my $real = $code;
            $code = sub {
                $_[0]->debug_op($_[1]);
                $real->(@_);
            };
        };
        
#        print "++ $name\n";

        class->export(
            $name => [
                base    => \@bases,
                methods => {
                    map { $_ => $code }
                    @$methods
                }
            ]
        );
    }
    return $self;
}

sub generate_text_elements {
    shift->generate_ops(
        { methods => 'text value values' },
        @_
    );
}



1;
__END__

sub parse_expr {
    shift->debug("parse_expr");
}

1;

__END__
This module should define a metaclass module for constructing elements.

Current element construction looks something like this:

    use Template::TT3::Class 
        version    => 3.00,
        base       => 'Template::TT3::Element',
        constants  => ':elements',
        as         => 'filename',
        view       => 'literal',
        constant   => {
            SEXPR_FORMAT => '<literal:%s>',
        },
        alias      => {
            parse_word  => 'advance',
            name        => \&text,
            value       => \&text,
            values      => \&text,
            source      => \&text,
        };

We should be able to reduce it to something like this:

    use Template::TT3::Element::Class 
        version    => 3.00,
        type       => 'literal',
        parse_expr => 'filename',
        alias_to   => {
            text   => 'name value values source'
        };

Implicit actions:

    * add element base class
    * export :elements constants (rename this while we're at it)
    * type implies view

Another current example:

    use Template::TT3::Class 
        version   => 3.00,
        debug     => 0,
        base      => 'Template::TT3::Element::Operator::InfixRight
                      Template::TT3::Element::Operator::Assignment
                      Template::TT3::Element',
        import    => 'class',
        as        => 'pair',
        constants => ':elements',
        constant  => {
            SEXPR_FORMAT => '<assign:<%s><%s>>', 
        },
        alias     => {
            as_pair => 'self',          # I can do pairs, me
            number  => \&value,         # FIXME
            values  => \&value,         # TODO: parallel assignment
        };

Should be:

    use Template::TT3::Class 
        version  => 3.00,
        debug    => 0,
        parse    => {
            infix  => 'right',
            assign => 1,                # er.... not sure
        }
        as        => 'pair',            # better name or is this OK?
        alias_to  => {
            value => 'number values'
            self  => 'as_pair',         # should be implicit 
        };
