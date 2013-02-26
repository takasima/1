package ContactForm::Upgrade;
use strict;

use ContactForm::Util qw( register_templates_to );

sub _upgrade_functions {
    my $app = MT->instance();
    eval{ # FIXME: new install needs eval?
        require MT::Role;
        my $plugin = MT->component( 'ContactForm' );
        my $role = MT::Role->get_by_key( { name => $plugin->translate( 'Form Administrator' ) } );
        if (! $role->id ) {
            my $role_en = MT::Role->load( { name => 'Form Administrator' } );
            if (! $role_en ) {
                my %values;
                $values{ created_by }  = $app->user->id if $app->user;
                $values{ description } = $plugin->translate( 'Can create contact form, and edit contact form.' );
                $values{ is_system }   = 0;
                $values{ permissions } = "'manage_contactform'";
                $role->set_values( \%values );
                $role->save
                    or return $app->trans_error( 'Error saving role: [_1]', $role->errstr );
            }
        }
        $role = MT::Role->get_by_key( { name => $plugin->translate( 'Manage Feedback Data' ) } );
        if (! $role->id ) {
            my $role_en = MT::Role->load( { name => 'Manage Feedback Data' } );
            if (! $role_en ) {
                my %values;
                $values{ created_by }  = $app->user->id if $app->user;
                $values{ description } = $plugin->translate( 'Can manage contact form feedback.' );
                $values{ is_system }   = 0;
                $values{ permissions } = "'manage_form_feedback'";
                $role->set_values( \%values );
                $role->save
                    or return $app->trans_error( 'Error saving role: [_1]', $role->errstr );
            }
        }
        my %template = (
            dynamic_mtml_bootstrapper => {
                name => 'Contact Form Notification Email',
                path => 'contactform_mail.tmpl',
                type => 'custom',
            },
        );
        register_templates_to( 0, $plugin, \%template );
    };
    return 1;
}

1;
