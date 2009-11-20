package Template::TT3::Type::Code;

use Template::TT3::Class
    version   => 3.00,
    debug     => 0,
    base      => 'Template::TT3::Type',
    utils     => 'is_object',
    constant  => {
        CODE  => __PACKAGE__,
        type  => 'Code',
    },
    exports   => {
        any   => 'CODE Code',
    };


our $METHODS   = {
    # ref/type methods
    ref      => __PACKAGE__->can('ref'),
    type     => \&type,

    # constructor methods
    new      => \&new,
};
    
    
sub Code {
    return @_ == 1 && is_object( CODE, $_[0] )
        ? $_[0]
        : CODE->new(@_);
}

sub new {
    my ($class, $code) = @_;
    $class = CORE::ref($class) || $class;

    return is_object($class, $code)
        ? $code
        : bless $code, $class;
}

sub call {
    my $self = shift;
    $self->(@_);
}


1;

__END__

