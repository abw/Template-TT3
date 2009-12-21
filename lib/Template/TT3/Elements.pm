package Template::TT3::Elements;

use Badger::Factory::Class
    version   => 3.00,
    debug     => 0,
    item      => 'element',
    base      => 'Template::TT3::Base',
    utils     => 'params',
    path      => 'Template(X)::(XS::)TT3::Element',
    constants => 'PKG';


# We're lazy, so we rely on Badger::Factory (the base class of T::Elements
# which in turn is the base class of T::Grammar) to convert a simple string 
# like "foo_bar" into the appropriate T::Element::FooBar module name.  We
# use dots to delimit namespaces, e.g. 'numeric.add' is expanded to 
# T::Element::Numeric::Add.  However, because we're *really* lazy and can't
# be bothered quoting lots of strings like 'numeric.add' (they have to be
# quoted because the dot can't be bareworded on the left of =>) we define
# a bunch of prefixes that get pre-expanded when the symbol table is imported.
# e.g 'num_add' becomes 'numeric.add' becomes 'T::Element::Numeric::Add'

our $PREFIXES = {
    # short names
    op_         => 'operator.',
    txt_        => 'operator.text.',
    num_        => 'operator.number.',
    bool_       => 'operator.boolean.',
    cmd_        => 'command.',
    ctr_        => 'control.',
    con_        => 'construct.',
    sig_        => 'sigil.',
    var_        => 'variable.',
    html_       => 'HTML.',

    # long names
    operator_   => 'operator.',
    text_       => 'operator.text.',
    number_     => 'operator.number.',
    boolean_    => 'operator.boolean.',
    command_    => 'command.',
    control_    => 'control.',
    construct_  => 'construct.',
    sigil_      => 'sigil.',
    variable_   => 'variable.',
};


*init = \&init_elements;


sub init_elements {
    my ($self, $config) = @_;
    $self->init_factory($config);
    $self->{ prefixes } = $self->class->hash_vars( 
        PREFIXES => $config->{ prefixes }
    );
    $self->debug("prefixes: ", $self->dump_data($self->{ prefixes })) if DEBUG;
    return $self;
}


sub construct {
    my $self = shift;
    my $type = shift;
    $self->constructor($type)->(@_);
}


sub constructor {
    my $self   = shift;
    my $type   = shift;
    my $params = params(@_);

    # add backref to this factory for element instances to use
    # TODO: figure out how to clean up the circular references
    $params->{ elements } = $self;

    return $self->{ constructors }->{ $type } 
       ||= $self->element_class($type)
                ->constructor($params);
}


sub element_class {
    my ($self, $type) = @_;

    # expand any prefix_
    $type =~ s/^([^\W_]+_)/$self->{ prefixes }->{ $1 } || $1/e;
    
    my $e = $self->{ elements };
    return $self->{ elements }->{ $type }
        || $self->find($type)
        || $self->not_found($type);
}


sub not_found {
    shift->error_msg( invalid => element => @_ );
}
            

sub module_names {
    my $self = shift;
    my @bits = 
        map {
            join( '',
                map { s/(.)/\U$1/; $_ }
                split('_')
            );
        }
        map { split /[\.]+/ } @_;

    return (
        join( PKG, map { ucfirst $_ } @bits ),
        join( PKG, @bits )
    );
}



1;
