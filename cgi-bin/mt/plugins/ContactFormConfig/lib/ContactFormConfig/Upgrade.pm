package ContactFormConfig::Upgrade;

use strict;
use lib 'addons/ContactForm.pack/lib';

use ContactForm::Util qw( read_from_file plugin_template_path utf8_on );

sub _upgrade_functions {
    my $app = MT->instance();
    eval {
        require File::Spec;
        my $plugin = MT->component( 'ContactFormConfig' );
        my @types = qw( text textarea checkbox select radio checkbox-multiple
                        select-multiple date date-and-time );
        my $tmpl_path = plugin_template_path( $plugin, 'templates' );
        for my $type ( @types ) {
            my $tmpl = File::Spec->catfile( $tmpl_path, "$type.mtml" );
            next unless -f $tmpl;
            my $mtml = utf8_on( read_from_file( $tmpl ) );
            $plugin->set_config_value( "template_type_$type", $mtml );
        }
    };
    return 1;
}

1;
