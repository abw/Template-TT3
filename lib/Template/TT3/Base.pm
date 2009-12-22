package Template::TT3::Base;

use Badger::Debug 
    ':debug :dump';

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
        fail    => 'error_msg',         # some modules may re-define
    },
    messages  => {
        no_hub          => '%s object is not attached to a hub',
        bad_method      => 'Invalid %s method specified: %s',
        
        syntax_dot_set  => "You cannot set '%s.%s' to '%s'",
        
        data_missing    => "Missing value: %s",
        data_undef      => "Undefined value: %s",
        data_undef_in   => "Undefined value in %s: %s",
        data_undef_for  => 'Undefined value for %s: %s',
        data_vmethod    => 'Invalid %s method: %s.%s', 

        # OLD_no_vmethod => '"<2>" is not a valid <1> method in "<3>.<2>"', 

    };



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


sub hub {
    my $self = shift;

    return $self->{ hub } 
        ||= return $self->error_msg( no_hub => ref $self || $self );
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


#-----------------------------------------------------------------------
# TODO: move this into element
#-----------------------------------------------------------------------


sub token_error {
    my $self   = shift;
    my $type   = shift;
    my $token  = shift;                     # TODO: put token first
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
    my $token  = shift;                     # TODO: put token first
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

__END__

=head1 NAME

Template::TT3::Base - base class for other TT modules

=head1 SYNOPSIS

    package Template::TT3::ExampleModule;
    
    use Template::TT3::Class
        version => 3.00,
        base    => 'Template::TT3::Base';

=head1 DESCRIPTION

This module implements a common base class for all other TT3 modules.  It is
itself a subclass of L<Badger::Base> which provides the bulk of the 
functionality.  C<Template::TT3::Base> adds a number of methods that are 
specific to the Template Toolkit.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Badger::Base> base class module.  Most, if not all of these 
methods are intended for internal use within subclass modules.

=head2 init_hub($config)

A custom initialisation object method which looks for a
L<hub|Template::TT3::Hub> reference in the C<$config> configuration parameters
and stores it in the C<$self> object. If a hub is not defined as a
configuration parameter then it automatically loads L<Template::TT3::Hub>
and uses its prototype (singleton) object.

=head2 hub()

An accessor method which returns the current hub reference (a
L<Template::TT3::Hub> object). It throws an error if no hub is available.
See L<init_hub()>.

=head2 self()

A trivial method that simply returns the C<$self> object reference.  This is
typically used by L<Template::TT3::Element> objects as a no-op shortcut.

=head2 raise_error($type,$params)

Used to raise exceptions of a particular type.  The C<$type> is forwarded
to L<Template::TT3::Exception> to locate the appropriate exception module.

=head2 token_error($type,$token,$message)

Used to raise exceptions of a particular type from the perspective of a 
particular token element.  This is typically used to report syntax errors,
undefined data errors, missing resource errors, and any other kind of error
that relates to a particular source code fragment.

NOTE: This and the other related methods listed below should probably be moved into
the L<Template::TT3::Element> base class.

=head2 token_error_msg($token, $format, @args)

This method is a wrapper around L<token_error()> use that uses the
L<message()|Badger::Base/message()> method inherited from L<Badger::Base>
to present the error using a pre-defined (in C<$MESSAGES>) message format.

=head2 syntax_error($token, $message)

A wrapper around L<token_error()> use to raise syntax errors.

=head2 syntax_error_msg($token, $message)

A wrapper around L<token_error_msg()> use to raise syntax errors.

=head2 undef_error($token, $message)

A wrapper around L<token_error()> use to raise errors relating to undefined
data values.

=head2 undef_error_msg($token, $format, @args)

A wrapper around L<token_error_msg()> use to raise undefined data errors.

=head2 resource_error($token, $message)

A wrapper around L<token_error()> use to raise errors relating to missing
or invalid resources (templates, files, plugins, etc).

=head2 resource_error_msg($token, $format, @args)

A wrapper around L<token_error_msg()> use to raise resource errors.

=head2 dump_data_depth($data, $depth)

This is a temporary method used for debugging.  It is a wrapper around the
L<dump_data()|Badger::Debug/dump_data()> method which is mixed in from 
L<Badger::Debug>.  The C<$depth> argument can be set to limit to depth to
which the data dumper will traverse.  

TODO: This method should probably be moved into L<Badger::Debug>.

=head1 INTERNAL METHODS

The following methods are defined for internal use.

=head2 _exceptions()

This method loads the L<Template::TT3::Exceptions> module and returns its
class name.

=head2 _exception()

This method instantiates an exception object using the L<Template::TT3::Exceptions> 
factory module loaded via the L<_exceptions()> method.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Badger::Base> base classes.
It also mixes in the methods exported from the L<Badger::Debug> module's
L<:debug|Badger::Debug/:debug> and L<:dump|Badger::Debug/:dump> tag sets.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
