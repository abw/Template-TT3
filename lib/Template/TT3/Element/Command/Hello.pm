package Template::TT3::Element::Command::Hello;

use Template::TT3::Class 
    version    => 2.71,
    base       => 'Template::TT3::Element::Command',
    as         => 'null_expr',
    alias      => {
        value  => \&text,
        values => \&text,
    };


sub text {
    'Hello World!'
}


sub html {
    '<b>Hello World!</b>'
}


1;
