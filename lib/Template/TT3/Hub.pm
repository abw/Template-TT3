package Template::TT3::Hub;

use Template::TT3::Class
    version     => 0.01,
    debug       => 0,
    base        => 'Template::TT3::Base Badger::Hub',
    modules     => ':hub',                # import XXX_MODULE from T::Modules
    utils       => 'params',
    filesystem  => 'VFS FS',
    codec       => 'unicode',
    constants   => 'HASH ARRAY CODE GLOB SCALAR BLANK',
    constant    => {
        PRINT_METHOD => 'print',
    },
    config      => [
        'quiet=0',
        'encoding=0',
        'mkdir=1',
        'output',
        'output_path',
        'output_encoding',
        'output_fs|output_filesystem',
    ],
    alias       => {
        # attach() and detach() don't do anything (at present), but they
        # establish a protocol for multiple front-end modules sharing a hub
        attach => \&self,
        detach => \&self,
    },
    messages    => {
        bad_output => 'Invalid output specified: %s',
        no_output  => 'Filesystem output is disabled (output_path is false)',
    };


#-----------------------------------------------------------------------
# The $COMPONENTS hash declares the methods that can be generated on demand to 
# load and instantiate various sub-components.  e.g. templates() creates and 
# returns a Template::TT3::Templates object (defined as the TEMPLATES_MODULE
# constant in in Template::TT3::Modules and imported via the 'modules' hook)
#-----------------------------------------------------------------------

our $COMPONENTS = { 
    cache      => CACHE_MODULE,
    context    => CONTEXT_MODULE,
    dialects   => DIALECTS_MODULE,
    filesystem => FILESYSTEM_MODULE,
    plugins    => PLUGINS_MODULE,
    providers  => PROVIDERS_MODULE,
    services   => SERVICES_MODULE,
    store      => STORE_MODULE,
    templates  => TEMPLATES_MODULE,
    views      => VIEWS_MODULE,
};


#-----------------------------------------------------------------------
# The $DELEGATES hash declares methods that can be generated on demand to 
# delegate to an object returned by another method.  For example, the 
# C<< template => 'templates' >> entry specifies that the template() method 
# should delegate to the object returned by the templates() method.  So a 
# call to $hub->template() is the same as $hub->templates->template()
#-----------------------------------------------------------------------

our $DELEGATES  = {
    dialect    => 'dialects',
    plugin     => 'plugins',
    provider   => 'providers',
    service    => 'services',
    template   => 'templates',
};


#-----------------------------------------------------------------------
# hack for testing - we allow a test script to install a callback
#-----------------------------------------------------------------------

our $DEBUG_BINMODE  = 0 unless defined $DEBUG_BINMODE;

sub install_binmode_debugger {
    my $self = shift;
    $DEBUG_BINMODE = shift;
}


#-----------------------------------------------------------------------
# methods
#-----------------------------------------------------------------------

sub self {
    $_[0];
}


sub input_glob {
    my $self = shift->prototype;
    my $glob = shift;
    $self->debug("reading from GLOB\n") if DEBUG;
    local $/;
    my $text = <$glob>;
    return $self->{ config }->{ unicode }
        ? decode($text) 
        : $text;
}


sub input_handle {
    my $self = shift->prototype;
    my $fh   = shift;
    my $text = join(BLANK, $fh->getlines);
    return $self->{ config }->{ unicode }
        ? decode($text) 
        : $text;
}



sub output {
    my $self = shift->prototype;
    my $text = shift;
    my $dest = shift || $self->{ config }->{ output };
    my $args = params(@_);

    # if no destination is specified and the output config parameter
    # is a false value then we return the text generated
    return $text unless $dest;

    # Otherwise we've got a plain text file name or reference of some kind
    my $type = ref $dest;

    $self->debug("output [$type] => $dest\n") if DEBUG;

    if (! $type) {
        $self->output_file($dest, $args)->write($text);    # output to file
#        $self->output_file($dest, $text, $args);    # output to file
    }
    elsif (blessed $dest) {
        my $code = $dest->can(PRINT_METHOD)
            || return $self->error_msg( bad_output => $dest );
        return $code->($dest, $text);               # call object's print() method
    }
    elsif ($type eq CODE) {
        return $dest->($text);                      # call subroutine
    }
    elsif ($type eq GLOB) {
        return print $dest $text;                   # print to GLOB (e.g. STDOUT)
    }
    elsif ($type eq SCALAR) {
        $$dest .= $text;                            # append to text ref
        return $dest;
    }
    elsif ($type eq ARRAY) {
        push @$dest, $text;                         # push onto list
        return $dest;
    }
    else {
        return $self->error_msg( bad_output => $dest );
    }
}


sub output_filesystem {
    my $self = shift->prototype;
    
    return $self->{ output_fs } ||= do {
        my $encoding = $self->{ output_encoding } || $self->{ encoding };
        my @args     = $encoding ? (encoding => $encoding) : ();
        
        if ($self->{ output_path }) {
            # create a Badger::Filesystem::Directory object for file output,
            $self->debug(
                "creating virtual filesystem for output in ",
                $self->{ output_path }
            ) if DEBUG;
            
            # check it exists, doing a mkdir if the flag says it's OK
            my $dir = FS->directory(  $self->{ output_path } )
                        ->must_exist( $self->{ mkdir       } );

            # create virtual filesystem with root at $dir
            VFS->new( root => $dir, @args );
        }
        elsif (defined $self->{ output_path }) {
            # output_path was explicitly set false - no output for you!
            return $self->error_msg('no_output');
        }
        else {
            # create regular filesystem object
            $self->debug("output to filesystem") if DEBUG;
            FS->new(@args);
        }
    };
}


sub output_file {
    my $self = shift->prototype;
    my $file = $self->output_filesystem->file(@_);

    $self->debug("output file: ", $file->definitive, "\n") if DEBUG;

    # make sure any intermediate directories between the output_path and 
    # final destination exist, or can be created if the mkdir flag is set
    # TODO: move this into Badger::Filesystem?
    $file->directory->must_exist($self->{ mkdir });
    
    return $file;
}


sub destroy {
    my $self = shift;
    $self->debug("destroying hub() $self") if DEBUG;

    # nothing to do yet
}


sub DESTROY {
    $_[0]->debug("DESTROY $_[0]") if DEBUG;
    shift->destroy;
}


1;
