package Template::TT3::Element::Command::Decode;

use Template::TT3::Class 
    version    => 3.00,
    base       => 'Template::TT3::Element::Command::Encode',
    constants  => ':elem_slots :eval_args',
    constant   => {
        ARG_NAME => 'decoder',
    },
    alias      => {
        value  => \&text,
        values => \&value,
    };


sub text {
    $_[SELF]->codec( $_[CONTEXT] )->decode( 
        $_[SELF]->[RHS]->text( $_[CONTEXT] )
    );
}


1;
