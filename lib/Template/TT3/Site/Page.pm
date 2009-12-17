package Template::TT3::Site::Page;

use Template::TT3::Class
    version    => 3.00,
    debug      => 0,
    import     => 'class CLASS',
    base       => 'Template::TT3::Base',
    utils      => 'is_object',
    accessors  => 'uri name site',
    constants  => 'ARRAY',
    constant   => {
        PAGE   => 'CR::Web::Page',
        ROOT   => '/',
        SLASH  => '/',
    },
    messages   => { 
        no_site  => 'No web site object specified',
        no_page  => 'No page metadata specified',
        no_uri   => 'No page uri specified',
        no_menu  => 'No menu is defined for the %s page',
    };

use Badger::Logic 'Logic';

our $AUTOLOAD;


sub init {
    my ($self, $config) = @_;

    $self->{ site } = delete $config->{ site };

    my $page = { 
        %{ $config->{ page } || $config } 
    };

    $self->{ page } = $page;
    $self->{ uri  } = $config->{ uri } || $self->{ page }->{ uri } || '';
    
    my @path = split(SLASH, $self->{ uri });
    $self->{ name } = $path[-1];
    
    return $self;
}


sub metadata {
    my $self = shift;
    return $self->{ page };
}


sub page {
    my $self = shift;
    my $uri  = shift 
        || return $self->error_msg('no_uri');

    # check it's not already a page and return it if it is
    return $uri if is_object(CLASS, $uri);

    # resolve any relative URL against the current page URL
    # TODO: use Badger::Web::URL to do this.  Also support '..'
    if ($uri !~ m[^/] && $self->{ uri }) {
        my $base = $self->{ uri };
        # /foo/bar/baz + ./wiz => foo/bar/wiz
        if ($uri =~ s[^\./][]) {
            $base =~ s{/?[^/]*$}{};
            $self->debug("relative page: [$base] [$uri]\n") if DEBUG;
        }
        $base =~ s[/$][];
        $uri = "$base/$uri";
    }

    $self->debug("asking site for page [$uri]  (my base: $self->{ uri })\n") if DEBUG;
    
    # now ask the site for the page
    return $self->{ site }->page($uri)
        || $self->decline( $self->{ site }->reason() );
}

sub pages {
    my ($self, $pages) = @_;

    return [ 
        map { 
            $self->debug("requesting page: $_") if DEBUG;
            $self->page($_) 
                || return $self->error($self->reason) 
        } 
        @$pages
    ];
}


sub input_file {
    my $self = shift;
    return $self->{ input_file }
       ||= $self->site->input_file( $self->{ uri } );
}


sub output_file {
    my $self = shift;
    return $self->{ output_file }
       ||= $self->site->output_file( $self->{ uri } );
}


sub changed {
    my $self    = shift;
    my $infile  = $self->input_file;
    my $outfile = $self->output_file;

    $self->debug(
        " input modified: ", $infile->modified, "\n",
        "output modified: ", $outfile->modified, "\n"
    ) if DEBUG;
    
    return $outfile->exists 
        && $outfile->modified->after( $infile->modified )
         ? 0 : 1;
}


sub tt_dot {
    my ($self, $name) = @_;
    return $self->{ page }->{ $name };
}


sub modified {
    shift->input_file->modified;
}

#-----------------------------------------------------------------------
# Everything after this point is a cut-n-paste from another code base.
# It needs sorting out, making generic, cleaning up, etc.
#-----------------------------------------------------------------------


1;

__END__

# fetch all the pages referenced by page.menu

sub menu_items {
    my $self = shift;
    my $name = shift || 'menu';
    $self->debug("menu items (base: $self->{ uri })\n") if DEBUG;

    my $menu = shift
        || $self->{ $name } 
        || $self->{ page }->{ $name } 
        || return $self->decline_msg( no_menu => $self->{ uri } );
        
    $menu = $self->{ $name } = [ split(/\s+/, $menu) ]
        unless ref $menu eq ARRAY;

    return $menu;
}

sub menu_item {
    my $self  = shift;
    my $name  = shift;
    my $items = $self->menu_items(@_);
    return (grep { $_ eq $name } @$items)
        ? $name
        : $self->decline_msg( not_found => 'menu item' => $name );
}

*menu_pages = \&menu;

sub menu {
    my $self = shift;
    return $self->pages($self->menu_items(@_));
}

sub menu_page {
    my $self = shift;
    my $item = $self->menu_item(@_) || return;
    return $self->page($item);
}

sub tabs {
    shift->menu('tabs');
}

sub section {
    my $self = shift;
    my $path = $self->{ uri };
    
    # if the current page is */index.html then we can inherit the menu
    # from the parent section.
#    $path =~ s[/index.html$][/]g || return;
    $path =~ s[/index.html$][]g || return;    # no trailing slash

    # now ask the site for the "page"
    return $self->{ site }->page($path)
        || $self->decline( $self->{ site }->reason );
}

sub section_menu {
    my $self = shift;
    my $section = $self->section || return;
    return $section->menu;
}

sub parent {
    my $self = shift;
    my $path = $self->{ uri };
    
    $path =~ s{/[^/]+$}{}g || return;

    # now ask the site for the "page"
    return $self->{ site }->page($path)
        || $self->decline( $self->{ site }->reason );
}

sub parent_menu {
    my $self = shift;
    my $parent = $self->parent || return;
    return $parent->menu;
}

sub user_menu {
    my ($self, $user) = @_;
    my $menu = $self->menu();
    return $menu unless $user;
    my $role;
    return [
        grep { ($role = $_->roles) ? $user->role($role) : 1 }
        @$menu
    ];
}

sub access {
    my ($self, $params) = self_params(@_);
    my $logic = $self->{ logic } ||= do {
        my $roles = $self->{ page }->{ role } || [ ];
        $roles = [ $roles ] unless ref $roles eq ARRAY;
        $roles = join(' and ', @$roles);
        length $roles 
            ? Logic($roles)
            : not $self->{ page }->{ locked };
    };
#    $self->debug("logic: ", $self->dump_data($logic), "   params: ", $self->dump_data($params), "");
    return ref $logic
        ? $logic->evaluate($params)
        : $logic;
}
    
# fetch all the pages on the breadcrumb trail from root to the current page

sub trail {
    my $self  = shift;
    delete $self->{ trail } if @_;
    return $self->{ trail } ||= do {
        my $uri   = $self->{ uri }; 
        $uri =~ s[^/][];
        $uri =~ s[\/index.html][];
        my @path  = split(/\/+/, $uri);
        my @trail = map { '/' . join('/', @path[0..$_]) } 0..$#path;
#        $self->debug("TRAIL: ", join(', ', @trail), "\n");
        # we don't throw errors by default because there could be pages missing
        # in the trail (e.g. /foo/bar/baz but no /foo/bar).  However, we forward
        # any arguments passed, so the caller can add { throw => 1 } if they like.
        $self->{ site }->pages(@trail, @_); 
    };
}


# is this page under another uri (for breadcrumb trails, etc.)

sub under {
    my ($self, $uri) = @_;
    $uri = $uri->uri if is_object(ref $self, $uri);
    
    if ($uri eq $self->{ uri }) {
        # exact match
        return 1;
    }
    else {
        # Otherwise make sure we add a '/' to the end of the uri so that we only 
        # match at directory boundaries.  So a page at /food/berries, for example, 
        # should match under /food (/food/) but not /foo (/foo/)
        $uri .= '/' unless $uri =~ m{/$};
        return $self->{ uri } =~ /^$uri/;
    }
}

sub css_class {
    my $self  = shift;
    my $class = $self->{ page }->{ class } || return;
    return ref $class eq ARRAY
        ? join(' ', @$class)
        : $class;
}

sub link {
    my ($self, $params) = self_params(@_);
    my $class = $self->class;
    my $url   = $params->{ url  } || $self->url;
    my $text  = $params->{ text } || $self->name;
    $class = qq( class="$class") if $class;     # extra classes passed in?
    return   qq(<a href="$url"$class>$text</a>);
}

sub NOT_AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    my $item;

    $name =~ s/.*:://;
    return if $name eq 'DESTROY';

    if (@_) {
        $self->debug("SET $name to $_[0]\n") if $DEBUG;
        return ($self->{ page }->{ $name } = shift);
    }
    else {
        $self->debug("GET $name => ", $self->{ page }->{ $name }, "\n") if $DEBUG;
        return $self->{ page }->{ $name };
    }
}


#-----------------------------------------------------------------------
# some special cases
#-----------------------------------------------------------------------

sub title {
    my $self = shift;
    if (@_) {
        $self->{ page }->{ title } = join('', @_);
    }
    return $self->{ page }->{ title } 
        || $self->{ page }->{ name  } 
        || $self->{ uri };
}


1;
