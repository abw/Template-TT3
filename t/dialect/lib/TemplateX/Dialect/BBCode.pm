package TemplateX::Dialect::BBCode;

use base 'Template::TT3::Dialect';

our $TAGSET = [
    bold => {
        start   => '[b]',
        end     => '[/b]',
        type    => 'replace',
        replace => sub {
            my ($self, $text) = @_;
            return "<b>$text</b>";
        }
    },
    italic => {
        start   => '[i]',
        end     => '[/i]',
        type    => 'replace',
        replace => sub {
            my ($self, $text) = @_;
            return "<i>$text</i>";
        }
    },
];

1;
