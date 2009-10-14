#========================================================================
#
# CR::Hub
#
# DESCRIPTION
#   Central hub for the Completely Retail system.
#
# AUTHOR
#   Andy Wardley <abw@wardley.org> July 2008 - January 2009
#
# TODO: sort out the components with the base class.  Add DESTROY to 
# cleanup cached references.
#========================================================================

package CR::Hub;

use CR::Class
    version   => 0.01,
    debug     => { default => 0, import => ':dump' },
    base      => 'Badger::Web::Hub CR::Base',
    import    => 'class',
    utils     => 'params md5_hex xprintf tprintf',
    codec     => 'storable+base64',
    constants => 'ARRAY HASH DEFAULT',
    constant  => {
        TEMPLATE_ENGINE => 'webapp',
    },
    methods   => {
        email => \&emailer,
    };

our $CONFIG     = 'CR::Config';
our $COMPONENTS = { 
    imager                  => 'CR::Imager',
    importer                => 'CR::Importer',
    reporter                => 'CR::Reporter',
    geo_importer            => 'CR::Importer::Geography',
    bugsy_importer          => 'CR::Importer::Bugsy',
    legacy_importer         => 'CR::Importer::Legacy',
    listing_importer        => 'CR::Importer::Listings',
    landsec_importer        => 'CR::Importer::LandSecurities',
    cushwake_importer       => 'CR::Importer::CushmanWakefield',
    sanderson_importer      => 'CR::Importer::SandersonWeatherall',
    smith_price_importer    => 'CR::Importer::SmithPrice',
    bclong_importer         => 'CR::Importer::BCLong',
    latlng_importer         => 'CR::Importer::FixLatLng',
    goad_importer           => 'CR::Importer::Goad',
    goad_map_importer       => 'CR::Importer::GoadMaps',
    retailer_importer       => 'CR::Importer::GoadRetailers',
    rss_importer            => 'CR::Importer::RSS',
    company_importer        => 'CR::Importer::Companies',
    sas_importer            => 'CR::Importer::SAS',
    ar_importer             => 'CR::Importer::AR',
    geo_cleaner             => 'CR::Cleaner::Geography',
    # mask the sessions defined in Badger::Web::Hub
    sessions                => 0,
};
our $DELEGATES  = {
    # $hub->model() method is delegated to $hub->database->model() and so on
    model       => 'database',
    sessions    => 'model',
};
our $PROTOTYPE;

sub new {
    my $class = shift;
    return $PROTOTYPE ||= $class->SUPER::new(@_);
}

sub database {
    my $self = shift->prototype;
    $self->debug("Fetching database") if DEBUG;
    return $self->{ database } ||= do {
        my $conf = $self->config->database;
        $self->configure( 
            database => { 
                %$conf, 
                hub => $self, 
            } 
        );
    };
}

sub legacy_database {
    my $self = shift->prototype;
    $self->debug("Fetching legacy database") if DEBUG;

    return $self->{ legacy_database } ||= do {
        my $conf = $self->config->legacy_database;
        $self->debug("using legacy database configuration: ", $self->dump_data($conf)) if DEBUG;
        $self->configure( 
            legacy_database => { 
                %$conf, 
                hub => $self, 
            } 
        );
    };
}
