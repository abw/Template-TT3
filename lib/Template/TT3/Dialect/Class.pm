package Template::TT3::Dialect::Class;

use Carp;
use Template::TT3::Class
    version    => 0.01,
    debug      => 0,
    uber       => 'Template::TT3::Class',
    constants  => 'ARRAY',
    modules    => 'DIALECT_MODULE',
    hooks      => {
#       grammar => \&grammar,
        tagset  => \&tagset,
        tags    => \&tags,
    };


sub tagset {
    my ($self, $tagset) = @_;

    if (ref $tagset eq ARRAY) {
        $self->var( TAGSET_MODULE => $tagset->[0] );
        $self->var( TAGSET        => $tagset->[1] );
    }
    elsif (ref $tagset) {
        $self->var( TAGSET => $tagset );
    }
    else {
        $self->var( TAGSET_MODULE => $tagset );
    }
        
    $self->base( DIALECT_MODULE );
}

sub tags {
    my ($self, $tags) = @_;
    $self->var( TAGS => $tags );
    $self->base( DIALECT_MODULE );
}


1;