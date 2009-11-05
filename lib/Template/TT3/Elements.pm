package Template::TT3::Elements;

use Badger::Factory::Class
    version   => 3.00,
    debug     => 0,
    item      => 'element',
    base      => 'Template::TT3::Base',
    utils     => 'params',
    path      => ['Template::TT3::Element', 'Template::TT3::Op'],
    constants => 'PKG';


# TODO: Add constructor() and construct() methods and cache constructors
# internally.  The elements object needs to be able to create new elements
# so that element objects can call it to upgrade themselves to new elements
# (e.g. a word calling $self->[META]->{ elements }->construct(var => $self) )

# TODO: Fuckola!  The construct() method inherited from Badger::Factory
# conflicts with the construct() method that we want to add to construct
# a new element

sub OLD_found_module {
    my ($self, $type, $module, $args) = @_;
    my $params = params(@$args);
    $params->{ elements } = $self;
    $self->{ class }->{ $type } = $module;
    $self->debug("Found module: $type => $module") if DEBUG;
    return $module->constructor($params);
}

sub found_array_NOT_NEEDED {
    my ($self, $type, $array, $args) = @_;
    my $params = params(@$args);
    my ($module, $cfg) = @$array;
    $params = { %$cfg, %$params, elements => $self };
    $self->{ class }->{ $type } = $module;
    $self->debug("Found module array: $type => $module") if DEBUG;
    return $module->constructor($params);
}

sub OLD_construct {
    my ($self, $type, $class, $args) = @_;
    $self->debug("constructing class: $type => $class") if DEBUG;
#    return $class->constructor(elements => $self->{ elements });
    return $class;
#    return $class->new(@$args);
}

sub element_class {
    my ($self, $type) = @_;
    return $self->{ elements }->{ $type }
        || $self->find($type)
        || $self->not_found($type);
}

sub constructor {
    my $self = shift;
    my $type = shift;
    my $params = params(@_);

    # add backref to this factory for element instances to use
    # TODO: figure out how to clean up the circular references
    $params->{ elements } = $self;

    return $self->{ constructors }->{ $type } 
       ||= $self->element_class($type)->constructor($params);
}

sub construct {
    shift->constructor(shift)->(@_);
}

#sub element_class {
#    my ($self, $type) = @_;
#    # we might have the class name cached, otherwise we need to load the 
#    # element first and then it should appear in $self->{ class }
#    return $self->{ class }->{ $type }
#        || $self->element($type)
#        && $self->{ class }->{ $type };
##        || $self->error_msg( invalid => element => $type );
#}

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
