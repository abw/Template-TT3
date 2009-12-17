package Template::TT3::App::Site;

use Template::TT3::Site;
use Template::TT3::Class
    version   => 2.718,
    debug     => 0,
    base      => 'Template::TT3::App',
    constant  => {
        SITE  => 'Template::TT3::Site',
    };

our $NAME   = 'TT3 Site';
our $AUTHOR = 'Andy Wardley';
our $DATE   = 'December 2009';
our $ABOUT  = q{
    This application can be used to build a web site built from static
    page templates.   
};

our $USAGE = q{
    $ tt3 site --file /path/to/config.yaml \n
    $ tt3 site --file /path/to/config.yaml --help \n
    $ ttd site --file /path/to/config.yaml --all \n
    $ ttd site --file /path/to/config.yaml --verbose 
};

our $OPTIONS = [
    {   
        name   => 'file|-f!',
        about  => 'Main configuration file for site',
        args   => 'file',
    },
    {   
        name   => 'all|-a',
        about  => 'Process all page templates',
    },
    {   
        name   => 'summary|-s',
        about  => 'Show summary of actions',
    },
    {   
        name   => 'quiet|-q',
        about  => 'Suppress output',
    },
];


sub run {
    my $self = shift;
    my $app  = $self->validate;
    my $site = $self->site;

    $self->credits 
        if $app->{ verbose }
        or $app->{ summary };

    $site->build($app);
}


sub site {
    my $self = shift;
    my $app  = $self->{ app };
    $app->{ map } ||= $app->{ file };
    return $self->SITE->new($app);
}

1;
