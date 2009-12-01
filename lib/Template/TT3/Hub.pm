package Template::TT3::Hub;

use Template::TT3::Class
    version     => 0.01,
    debug       => 0,
    base        => 'Template::TT3::Base Badger::Hub',
    modules     => ':hub',                # import XXX_MODULE from T::Modules
    utils       => 'params',
    filesystem  => 'VFS FS',
    constants   => 'HASH ARRAY CODE GLOB SCALAR',
    constant    => {
        PRINT_METHOD => 'print',
    },
    config      => [
        'quiet=0',
        'encoding=0',
        'mkdir=1',
        'output',
        'output_path',
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
    filesystem => FILESYSTEM_MODULE,
    templates  => TEMPLATES_MODULE,
    providers  => PROVIDERS_MODULE,
    plugins    => PLUGINS_MODULE,
    dialects   => DIALECTS_MODULE,
    cache      => CACHE_MODULE,
    store      => STORE_MODULE,
};


#-----------------------------------------------------------------------
# The $DELEGATES hash declares methods that can be generated on demand to 
# delegate to an object returned by another method.  For example, the 
# C<< template => 'templates' >> entry specifies that the template() method 
# should delegate to the object returned by the templates() method.  So a 
# call to $hub->template() is the same as $hub->templates->template()
#-----------------------------------------------------------------------

our $DELEGATES  = {
    template   => 'templates',
    provider   => 'providers',
    plugin     => 'plugins',
    dialect    => 'dialects',
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
        $self->output_file($dest, $text, $args);    # output to file
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
#        my $config = $self->{ config };
        
        if ($self->{ output_path }) {
            # create a Badger::Filesystem::Directory object for file output,
            $self->debug(
                "creating virtual filesystem for output in ",
                $self->{ output_path }
            ) if DEBUG;
            
            # check it exists, do a mkdir if the MKDIR flags says that's OK
            my $dir = FS->directory(  $self->{ output_path } )
                        ->must_exist( $self->{ mkdir       } );

            # create virtual filesystem with root at $dir (value drops through)
            VFS->new( root => $dir );   
        }
        elsif (defined $self->{ output_path }) {
            # output_path was explicitly set false - no output for you!
            return $self->error_msg('no_output');
        }
        else {
            $self->debug("output to filesystem") if DEBUG;
            FS->new;
        }
    };
}


sub output_file {
    my $self = shift->prototype;
    my $file = $self->output_filesystem->file(shift);

    $self->debug("output file: ", $file->definitive, "\n") if DEBUG;

    # make sure any intermediate directories between the OUTPUT_DIR and 
    # final destination exist, or can be created if the MKDIR flag is set
    $file->directory->must_exist($self->{ mkdir });
    
    # return the Badger::File object if no additional arguments passed
    return $file unless @_;
    
    # otherwise, arguments are ($text, %args)
    my $text = shift;
    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $fh   = $file->write;
    my $enc  = defined $args->{ binmode  }
                     ? $args->{ binmode  } 
             : defined $args->{ encoding }
                     ? $args->{ encoding } 
             :         $self->{ encoding };

    # hack for testing - allows us to check that binmode/encoding options
    # are properly forwarded to this point
    $DEBUG_BINMODE->($enc) if $DEBUG_BINMODE;
  
    # TODO: move this into Badger::Filesystem:File
    $fh->binmode($enc eq '1' ? () : $enc) if $enc;
    $fh->print($text);
    $fh->close;

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
