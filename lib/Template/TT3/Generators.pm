#========================================================================
#
# Template::TT3::Generators
#
# DESCRIPTION
#   Factory module for loading and instantiating Template::TT3::Generator
#   objects on demand.
# 
# AUTHOR
#   Andy Wardley <abw@wardley.org>
#
#========================================================================

package Template::TT3::Generators;

use Badger::Factory::Class
    version => 3.00,
    debug   => 0,
    item    => 'generator',
    base    => 'Template::TT3::Base',
    path    => 'Template::TT3::Generator 
                Template::Generator 
                TemplateX::Generator';

# This method overrides the default Badger::Factory behaviour of throwing
# an error when a requested module is not found.  B::F needs some refactoring
# so this may change.

# See T::TT3::Tokens for an example of an object that calls this 
# speculatively.  We don't want to throw an error if the item can't 
# be found so we decline with an undef instead.

sub not_found {
    return undef;
}


1;