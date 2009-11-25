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


sub token_error {
    my $self   = shift;
    my $type   = shift;
    my $token  = shift;
    my $text   = join(BLANK, @_);
    my $posn   = $token && $token->pos;
    
    $self->raise_error(
        $type => {
            info     => $text,
            token    => $token,
            position => $posn,
        },
    );
}


sub token_error_msg {
    my $self   = shift;
    my $type   = shift;
    my $token  = shift;
    my $text   = $self->message(@_);
    return $self->token_error($type, $token, $text);
}


sub syntax_error {
    shift->token_error( syntax => @_ );
}


sub syntax_error_msg {
    shift->token_error_msg( syntax => @_ );
}


sub undef_error {
    shift->token_error( undef => @_ );
}


sub undef_error_msg {
    shift->token_error_msg( undef => @_ );
}


sub debug_callers {
    my $self = shift;
    my $i = 1;
    while (1) {
        my @info = caller($i);
        last unless @info;
        my ($pkg, $file, $line, $sub) = @info;
        warn(
            sprintf(
                "%4s: Called from %s in %s at line %s\n",
                '#' . $i++, $sub, $file, $line
            )
        );
    }
}


sub dump_data_depth {
    my ($self, $data, $depth) = @_;
    local $Badger::Debug::MAX_DEPTH = $depth || 1;
    $self->dump_data($data);
}

1;
