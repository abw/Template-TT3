package Template::TT3::Site::Reporter;

use Template::TT3::Class
    version   => 2.71,
    debug     => 0,
    base      => 'Badger::Reporter::App Template::TT3::Base';

our $EVENTS = [
    {
        name    => 'rendered',
        colour  => 'green',
        message => '  + %s',
        summary => '%5d page%s rendered',
    },
    {
        name    => 'mkdir',
        colour  => 'green',
        message => '  + %-64s (mkdir)',
        summary => '%5d directories created',
    },
    {
        name    => 'unchanged',
        colour  => 'cyan',
        message => '  - %-64s (unchanged)',
        summary => '%5d page%s unchanged',
        verbose => 1,
    },
    {
        name    => 'ignored',
        colour  => 'blue',
        message => '  - %-64s (ignored)',
        summary => '%5d page%s ignored',
        verbose => 1,
    },
    {
        name    => 'nodir',
        colour  => 'yellow',
        message => "  - %-64s (no mkdir)",
        summary => '%5d page%s skipped (no destination directory)',
    },
    {
        name    => 'failed',
        colour  => 'red',
        message => "  ! %-64s **ERROR**\n%s",
        summary => '%5d page%s failed',
    },
#    {
#        name    => 'info',
#        colour  => 'cyan',
#        message => '%s',
#        summary => '',
#    },
#    {
#        name    => 'detail',
#        colour  => 'cyan',
#        message => '%s',
#        summary => '',
#        verbose => 1,
#    },
];

1;
