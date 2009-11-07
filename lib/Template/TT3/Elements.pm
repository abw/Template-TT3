package Template::TT3::Elements;

use Badger::Factory::Class
    version   => 3.00,
    debug     => 0,
    item      => 'element',
    base      => 'Template::TT3::Base',
    utils     => 'params',
    path      => ['Template::TT3::Element', 'TemplateX::TT3::Element'],
    constants => 'PKG';


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
