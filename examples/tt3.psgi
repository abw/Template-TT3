# $ cpan install PSGI and Plack
# $ plackup tt3.psgi

use strict;
use warnings;
use Badger
    lib        => '/home/abw/tt3/lib',
    Filesystem => 'Cwd',
    Class      => 'CLASS';

use Plack::Request;
use Badger::Debug ':dump :debug';
use Template3;

my $app = sub {
    my $env    = shift;
    my $req    = Plack::Request->new($env);
    my $path   = $req->path;
    my $params = $req->parameters;

    if ($path eq '/') {
        $path  = 'index.tt3';
        $params->{ dir } = Cwd;
    }
    
    CLASS->debug("path: $path    params: ", CLASS->dump_data($params));

    my $TT3 = Template3->new( 
        template_path => Cwd 
    );
    
    my $html = $TT3->try->fill(
        file => $path,
        data => $params
    );

    if ($html) {
        my $res  = $req->new_response(200);
        $res->content_type('text/html');
        $res->body($html);
        return $res->finalize;
    }
    else {
        return [ 200, ['Content-Type' => 'text/html'], [ '<pre>', $TT3->error, '</pre>' ] ];
    }
};
