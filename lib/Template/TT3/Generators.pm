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

1;