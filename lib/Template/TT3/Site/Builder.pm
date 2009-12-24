package Template::TT3::Site::Builder;

use Template::TT3::Class
    version     => 2.71,
    debug       => 0,
    base        => 'Badger::Filesystem::Visitor Template::TT3::Base',
    accessors   => 'site',
    config      => [
        'all=0',
        'mkdir=1',
        'site!',
        'reporter',
    ];


sub accept_file {
    my ($self, $file) = @_;
    my $site = $self->site;
    my $page = $site->page( file => $file );
    
    my $infile  = $page->input_file;
    my $outfile = $page->output_file;
    
    return $self->report( unchanged => $infile )
    unless $self->{ all }
        || $page->changed;

    my $outdir = $outfile->directory;
    
    unless ($outdir->exists) {
        if ($self->{ mkdir }) {
            $outdir->mkdir;
            $self->report( mkdir => $outdir );
        }
        else {
            return $self->report( nodir => $outdir );
        }
    }
    
    # TODO: service params from page metadata, e.g. custom layout, 
    # header, footer, etc.
    my $engine = $self->site->engine;
    my $data = {
        Site => $site,
        Page => $page,
    };
    my $env = {
        input  => $infile->path,
        output => $outfile,
        data   => $data,
    };
    
    return $engine->try->render($env)
        ? $self->report( rendered => $infile )
        : $self->report( failed => $infile, $engine->reason );
}


sub reject_file {
    my ($self, $file) = @_;
    $self->debug("reject_file($file)") if DEBUG;
    $self->report( ignored => $file );
    return 1;
}


sub reject_directory {
    my ($self, $dir) = @_;
    $self->debug("reject_directory($dir)") if DEBUG;
    $self->report( ignored => $dir );
    return 1;
}


sub leave_directory {
    my ($self, $dir) = @_;
    $self->debug("leave_file($dir)") if DEBUG;
    $self->report( ignored => $dir );
    return 1;
}


sub report {
    my $self     = shift;
    my $reporter = $self->{ reporter } || return;
    $reporter->report(@_);
}


sub summary {
    my $self     = shift;
    my $reporter = $self->{ reporter } || return;
    $reporter->summary(@_);
}


sub report_preview {
    my $self     = shift;
    my $reporter = $self->{ reporter } || return;
}


sub report_building {
    my $self     = shift;
    my $reporter = $self->{ reporter } || return;
    $reporter->section("Building Site");
}


sub report_summary {
    my $self     = shift;
    my $reporter = $self->{ reporter } || return;
    my $summary  = $reporter->summary(@_) || return;
    $reporter->section('Summary');
    $reporter->say($summary);
}


1;


1;

__END__

=head1 NAME

Template::TT3::Site::Builder - web site builder

=head1 SYNOPSIS

    use Template3;
    
    # create a web site object
    my $site = Template3->site(
        # TODO: rename this 'config' (or add an alias)
        file => '/path/to/site/config.yaml',
    );
    
    # create and invoke a builder
    $site->build;
    
=head1 DESCRIPTION

This module implements a filesystem visitor that visits each of the pages
in a web site and processes them.  Consult the documentation for 
L<Template::TT3::Site> for further information.

=head1 CONFIGURATION OPTIONS

In most cases you shouldn't need to manually create a
C<Template::TT3::Site::Builder> object yourself. Calling the
L<builder()|Template::TT3::Site/builder()> method on a L<Template::TT3::Site>
object will create one for you. Or you can call the
L<build()|Template::TT3::Site/build()> to create and invoke a builder object.

=head2 site

A reference to a L<Template::TT3::Site> object representing the web site.

=head2 mkdir

A flag indicating if directories should be created in the output directory.
This is set to C<1> by default meaning that directories will be automatically
created.  Set it to C<0> to disable this functionality.

=head2 all

The builder will usually only build pages that have a source template that is
newer than any previously build output page.  In other words, it doesn't build
pages that haven't changed since they were last built.

Set this flag to any true value (e.g. C<1>) to indicate that you want all
pages built regardless.

=head2 reporter

An optional reference to a L<Badger::Reporter> module which can be used to 
report the outcome of the builder's actions.  The L<Template::TT3::Site>
module's L<builder()|Template::TT3::Site/builder()> (and indirectly, 
L<build()|Template::TT3::Site/build()>) methods automatically create a 
L<Template::TT3::Site::Reporter> object and forward it to the builder.

=head1 VISITOR CONFIGURATION OPTIONS

In addition to the custom configuration options listed above, you can 
also specify any of the configuration options accepts by the 
L<Badger::Filesystem::Visitor> base class.  

    my $builder = $site->builder(
        accept   => '*.tt3',        # find these files
        ignore   => '*.tmp'         # ignore these files    
        enter    => 1,              # enter sub-directories
        leave    => '.git',         # leave .git dirs unvisited
    );

The important options are summarised below.  See L<Badger::Filesystem::Visitor>
for further information.

=head2 files / accept

Specify the files that you want to match.  

=head2 no_files / ignore

Specify the files that you want to ignore.

=head2 in_dirs / enter

Specify the directories that you want to enter into.

=head2 not_in_dirs / leave

Specify the directories that you don't want to enter into.

=head1 METHODS

This module implements the following methods in addition to those inherited
from the L<Badger::Filesystem::Visitor>, L<Template::TT3::Base> and
L<Badger::Base> base class modules.

=head2 accept_file($file)

Called by the visitor's traversal method when an acceptable (according to the
L<VISITOR CONFIGURATION OPTIONS> specified) file is visited.  This method 
renders the page and reports the fact to any L<reporter> defined.

=head2 reject_file($file)

Called by the visitor's traversal method when an unacceptable file is visited.
It reports the fact that it has ignored the file to any L<reporter> defined.

=head2 reject_dir($dir)

Called by the visitor's traversal method when an unacceptable directory is
visited. It reports the fact that it has ignored the directory to any
L<reporter> defined.

=head2 leave_dir($dir)

Called by the visitor's traversal method when it elects to not enter a
sub-directory based on it's selection criteria (the L<in_dirs> and
L<not_in_dirs> configuration options).  It reports the fact that it
has ignored the directory to any L<reporter> defined.

=head2 report($type,$message)

This method is used by various other methods to raise a report with any
L<reporter> object defined. If none is defined then it silently returns.

=head2 summary()

Fetches a text summary of the build activity from any L<reporter> object
defined. If none is defined then it returns C<undef>.

=head2 report_preview()

This method generates a short preview report giving an overview of the 
configuration options for the builder.  It raises the report with any 
L<reporter> object defined.  If none is defined then the method silently
returns.  In the usual case, this will have the effect of printing the 
report to C<STDOUT>.

=head2 report_summary()

This method fetches the build L<summary()> and then sends it back to any 
L<reporter> defined to output it.  In the usual case this will have the 
effect of printing the report to C<STDOUT>.

=head1 AUTHOR

Andy Wardley  L<http://wardley.org/>

=head1 COPYRIGHT

Copyright (C) 1996-2009 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO.

This module inherits methods from the L<Badger::Factory>,
L<Template::TT3::Base> and L<Badger::Base> base classes.

Builders are usually created by a L<Template::TT3::Site> object.
They use a L<Template::TT3::Site::Reporter> object to report their
actions.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
