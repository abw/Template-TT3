#============================================================= -*-perl-*-
#
# t/modules/class.t
#
# Test the Template::TT3::Class module.
#
# Written by Andy Wardley <abw@wardley.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use Badger lib => '../../lib';

use Template::TT3::Test 
    tests => 55,
    debug => 'Template::TT3::Class',
    args  => \@ARGV;

$Badger::Class::DEBUG = $DEBUG;

pass('Starting tests for Template::TT3::Class... hold onto your badger');


#-----------------------------------------------------------------------
# test class/classes return Template::TT3::Class object
#-----------------------------------------------------------------------

package Template::TT3::Test::Class1;
use Template::TT3::Class 'class classes';
use Template::TT3::Test;

is( class, 'Template::TT3::Test::Class1', 'class name form inside' );
is( ref class(), 'Template::TT3::Class', 'class sub return Template::TT3::Class object' );

package main;
is ( Template::TT3::Test::Class1->class, 'Template::TT3::Test::Class1', "class name form outside" );
is( ref Template::TT3::Test::Class1->class, 'Template::TT3::Class', 'class method returns Template::TT3::Class object' );


#-----------------------------------------------------------------------
# test loading constants from T::Constants
#-----------------------------------------------------------------------

package Template::TT3::Test::Constants;
use Template::TT3::Class constants => ':elem_slots';
use Template::TT3::Test;
    
is( META, 0, 'META is ' . META );


#-----------------------------------------------------------------------
# test constant generation
#-----------------------------------------------------------------------

package Template::TT3::Test::Constant;

use Template::TT3::Test;
use Template::TT3::Class 
    base     => 'Template::TT3::Base',
    constant => {
        pi => 3.14,
        e  => 2.718,
    },
    import => 'class';
    
class->constant( phi => 1.618 );

is( pi, 3.14, 'In Harry, pi is a constant' );
is( e, 2.718, 'In Harry, e is a constant' );
is( phi(), 1.618, 'In Harry, phi is a constant' );

package main;
my $const = Template::TT3::Test::Constant->new;
ok( $const, 'Created constant' );
is( $const->pi, 3.14,   "Constant pi is a constant" );
is( $const->e, 2.718,   "Constant e is a constant" );
is( $const->phi, 1.618, "Constant phi is a constant" );


#-----------------------------------------------------------------------
# test generation of slot methods for list based objects
#-----------------------------------------------------------------------

package Template::TT3::Test::Slots;
use Template::TT3::Class slots => 'size colour object';

sub new {
    my ($class, @stuff) = @_;
    bless \@stuff, $class;
}

package main;
my $gez = Template::TT3::Test::Slots->new(qw(big red bus));
ok( $gez, 'Created slot test object' );
is( $gez->size,   'big', 'big slot' );
is( $gez->colour, 'red', 'red slot' );
is( $gez->object, 'bus', 'bus slot' );



#-----------------------------------------------------------------------
# test class generator
#-----------------------------------------------------------------------

package main;

use Template::TT3::Class
    generate => [
        Elizabeth => {
            base    => 'Template::TT3::Base',
            version => 2.718,
            methods => {
                foo => sub { 'Elizabeth foo' },
                bar => sub { 'Elizabeth bar' },
            },
            constant => {
                wibble  => 'pleasantly',
            },
        },
        Pippin => {
            base    => 'Elizabeth',
            version => 3.142,
            methods => {
                bar => sub { 'Pippin bar' },
                baz => sub { 'Pippin baz' },
            },
            constant => 'frusset => pouch, greet=thricefold',
        },
    ];

Template::TT3::Class->generate( 
    Philip => {
        base    => 'Pippin',
        version => 1.618,
        methods => {
            baz => sub { 'Phillip baz' },
        },
    },
);

my $liz = Elizabeth->new;
ok( $liz, 'Created Elizabeth' );
is( $liz->VERSION, 2.718, "Elizabeth's version is 2.718" );
is( $liz->foo, 'Elizabeth foo', 'Elizbeth foo' );
is( $liz->bar, 'Elizabeth bar', 'Elizbeth bar' );
is( $liz->wibble, 'pleasantly', 'Elizbeth wibbles pleasantly' );

my $pip = Pippin->new;
ok( $pip, 'Created Pippin' );
is( $pip->VERSION, 3.142, "Pippin's version is 3.14" );
is( $pip->foo, 'Elizabeth foo', 'Pippin foo' );
is( $pip->bar, 'Pippin bar', 'Pippin bar' );
is( $pip->baz, 'Pippin baz', 'Pippin baz' );
is( $pip->wibble, 'pleasantly', 'Pippin wibble' );
is( $pip->frusset, 'pouch', 'Pippin frusset pouch' );
is( $pip->greet, 'thricefold', 'Pippin greets thricefold' );

my $phil = Philip->new;
ok( $phil, 'Created Philip' );
is( $phil->VERSION, 1.618, "Philip's version is 1.618" );
is( $phil->foo, 'Elizabeth foo', 'Philip foo' );
is( $phil->bar, 'Pippin bar', 'Philip bar' );
is( $phil->baz, 'Phillip baz', 'Philip baz' );


#-----------------------------------------------------------------------
# test subclass option
#-----------------------------------------------------------------------

package Susan;

use Template::TT3::Class
    base     => 'Template::TT3::Base',
    version  => 42,
    subclass => 'Tom Dick',
    subclass => {
        Larry => { version => 43 },
    };

package main;

my $sue = Susan->new();
ok( $sue, 'created Susan' );
is( $sue->VERSION, 42, 'Sue version' );

my $tom = Tom->new();
ok( $tom, 'created Tom' );
is( $tom->VERSION, 42, 'Tom version' );

my $dick = Dick->new();
ok( $dick, 'created Dick' );
is( $dick->VERSION, 42, 'Dick version' );

my $wall = Larry->new();
ok( $wall, 'created Larryt' );
is( $wall->VERSION, 43, 'Larry version' );


#-----------------------------------------------------------------------
# test throws option
#-----------------------------------------------------------------------

package Chucker;
use Template::TT3::Class
    base    => 'Template::TT3::Base',
    debug   => 0,
    throws  => 'food';

package main;
is( Chucker->throws,       'food',  'Chucker throws food' );
is( $Chucker::THROWS,      'food',  "It's very bad behaviour" );
is( Chucker->throws('egg'), 'egg',  'Chucky Egg' );
is( $Chucker::THROWS,       'egg',  'Now that was a great game' );
is( Chucker->throws,        'egg',  'So was Manic Miner' );


#-----------------------------------------------------------------------
# test messages option
#-----------------------------------------------------------------------

package Nigel;
use Template::TT3::Class
    base     => 'Template::TT3::Base',
    debug    => 0,
    import   => 'class',
    messages => {
        one_louder  => "Well, it's %s louder",
        do_you_wear => "Do you wear %0?",
    };

class->messages( goes_up_to => 'This <1> goes up to <2>' );

package main;
my $nigel = Nigel->new;
is( $nigel->message( one_louder => 'one' ), 
    "Well, it's one louder", "It's One louder"
);
is( $nigel->message( goes_up_to => amp => 'eleven' ), 
    "This amp goes up to eleven", 'Goes up to eleven' 
);


#-----------------------------------------------------------------------
# test alias method
#-----------------------------------------------------------------------

package Template::TT3::Test::Alias;
use Template::TT3::Class
    base    => 'Template::TT3::Base',
    debug   => 0,
    import  => 'class';

sub foo {
    'this is foo';
}

class->alias( bar => 'foo' );

package main;

my $alias = Template::TT3::Test::Alias->new;
is( $alias->foo, 'this is foo', 'alias foo' );
is( $alias->bar, 'this is foo', 'alias bar' );


package Template::TT3::Test::SubAlias;
use Template::TT3::Class
    base    => 'Template::TT3::Test::Alias',
    alias   => {
        wiz => 'foo',
    };

package main;

$alias = Template::TT3::Test::SubAlias->new;
is( $alias->foo, 'this is foo', 'sub alias foo' );
is( $alias->bar, 'this is foo', 'sub alias bar' );
is( $alias->wiz, 'this is foo', 'sub alias wiz' );



__END__
#-----------------------------------------------------------------------
# test classes get autoloaded
#-----------------------------------------------------------------------

use Class::Top;
my $top = Class::Top->new;
my $mid = Class::Middle->new;
my $bot = Class::Bottom->new;

if ($DEBUG) {
    print "HERITAGE: ", join(', ', $top->class->heritage), "\n";
    print "Top ISA: ", join(', ', @Class::Top::ISA), "\n";
    print "Middle ISA: ", join(', ', @Class::Middle::ISA), "\n";
    print "Bottom ISA: ", join(', ', @Class::Bottom::ISA), "\n";
}

is( $bot->bottom, 'on the bottom', 'bot is on the bottom' );
is( $mid->bottom, 'on the bottom', 'mid is on the bottom' );
is( $top->bottom, 'on the bottom', 'top is on the bottom' );
is( $mid->middle, 'in the middle', 'mid is in the middle' );
is( $top->middle, 'in the middle', 'top is in the middle' );
is( $top->top, 'on the top', 'op on the top' );

is( $bot->id, 'class.bottom', 'bot id' );
is( $mid->id, 'class.middle', 'mid id' );
is( $top->id, 'class.top', 'top id' );

__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
