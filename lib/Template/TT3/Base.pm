package Template::TT3::Base;

use Badger::Debug ':debug :dump';

use Badger::Utils;
use Template::TT3::Class
    version   => 0.01,
    debug     => 0,
    base      => 'Badger::Base',
    constants => 'BLANK',
    import    => 'class',
    modules   => 'EXCEPTIONS_MODULE HUB_MODULE',
    constant  => {
        base_id     => 'Template',
    },
    alias     => {
        _params => \&Badger::Utils::params,
    },
    messages  => {
        no_hub => '%s object is not attached to a hub',
    };


sub hub {
    my $self = shift;

    return $self->{ hub } 
        ||= return $self->error_msg( no_hub => ref $self || $self );
}


sub init_hub {
    my ($self, $config) = @_;

    # Look for a hub reference passed to us in the config, otherwise load and
    # instantiate the HUB_MODULE. We lookup HUB_MODULE via the $self reference 
    # so that subclasses can redefine the method to return a different hub 
    # module, otherwise we end up with the default value imported as the 
    # HUB_MODULE constant via the 'modules' import hook above.
    $self->{ hub } = $config->{ hub } 
        || class( $self->HUB_MODULE )->load->name;
        
    return $self;
}


sub self {
    # This is a dummy method that simply returns $_[0], i.e. $self.
    # It is provided as a convenient do-nothing method that subclasses can
    # alias to.
    $_[0];
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


sub resource_error {
    shift->token_error( resource => @_ );
}


sub resource_error_msg {
    shift->token_error_msg( resource => @_ );
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


sub _exceptions {
    class( $_[0]->EXCEPTIONS_MODULE )->load->name;
}


sub _exception {
    my $self = shift;
    
    # account for the fact that Badger::Base's error()/throw() methods will
    # want to call this argless
    return @_
        ? $self->_exceptions->item(@_)
        : $self->SUPER::exception;
}



1;
