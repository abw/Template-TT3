package Template::TT3::Base;

use Badger::Debug ':debug :dump';

use Badger::Utils;
use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Base',
    constants => 'BLANK',
    import    => 'class',
    constant  => {
        base_id     => 'Template',
        EXCEPTIONS  => 'Template::TT3::Exceptions',
    },
    alias     => {
        _params => \&Badger::Utils::params,
    };


sub _exceptions {
    class($_[0]->EXCEPTIONS)->load->name;
}

sub _exception {
    my $self = shift;
    
    # account for the fact that Badger::Base's error()/throw() methods will
    # want to call this argless
    return @_
        ? $self->_exceptions->item(@_)
        : $self->SUPER::exception;
}

sub raise_error {
    my $self   = shift;
    my $type   = shift;
    my $params = _params(@_);
    $params->{ type } = $type;
    $self->_exception( $type => $params )->throw;
}

sub syntax_error {
    shift->raise_error( syntax => @_ );
}

sub OLD_raise_error_msg {
    my $self   = shift;
    my $type   = shift;
    my $token  = shift;
    my $text   = $self->message(@_);
    return $self->raise_error($type, $token, $text);
}
    
        

sub OLD_syntax_error_msg {
    shift->raise_error_msg( syntax => @_ );
}


1;
